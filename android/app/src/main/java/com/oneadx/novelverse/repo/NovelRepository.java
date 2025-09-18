package com.oneadx.novelverse.repo;

import android.content.Context;
import android.net.Uri;

import androidx.room.Room;

import com.oneadx.novelverse.db.NovelDb;
import com.oneadx.novelverse.entity.ChapterEntity;
import com.oneadx.novelverse.entity.NovelEntity;
import com.oneadx.novelverse.entity.ProgressEntity;

import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

public class NovelRepository {
    private final Context ctx;
    private final NovelDb db;

    public NovelRepository(Context ctx) {
        this.ctx = ctx.getApplicationContext();
        this.db = Room.databaseBuilder(this.ctx, NovelDb.class, "novel.db")
                .fallbackToDestructiveMigration()
                .build();
    }

    private static String readAll(InputStream is) throws Exception {
        ByteArrayOutputStream bos = new ByteArrayOutputStream();
        byte[] buf = new byte[8192];
        int r;
        while ((r = is.read(buf)) != -1) {
            bos.write(buf, 0, r);
        }
        return new String(bos.toByteArray(), StandardCharsets.UTF_8);
    }

    private InputStream open(Uri uri) throws Exception {
        if ("content".equals(uri.getScheme())) {
            return ctx.getContentResolver().openInputStream(uri);
        }
        if ("file".equals(uri.getScheme())) {
            return new FileInputStream(new File(uri.getPath()));
        }
        return ctx.getContentResolver().openInputStream(uri);
    }

    public long importTxt(Uri uri) throws Exception {
        String all;
        try (InputStream is = open(uri)) {
            all = readAll(is);
        }

        // Regex tách chương
        Pattern p = Pattern.compile("(?m)^(?:Chương|CHƯƠNG|Chapter|CHAPTER|Phần|PHẦN)\\s*\\d+.*$");
        Matcher m = p.matcher(all);
        List<int[]> spans = new ArrayList<>();
        List<String> titles = new ArrayList<>();
        while (m.find()) {
            if (!spans.isEmpty()) {
                spans.get(spans.size() - 1)[1] = m.start();
            }
            spans.add(new int[]{m.start(), all.length()});
            titles.add(all.substring(m.start(), m.end()).trim());
        }
        if (spans.isEmpty()) {
            int step = Math.min(all.length(), 12000); // theo ký tự
            for (int i = 0, idx = 0; i < all.length(); i += step, idx++) {
                int end = Math.min(all.length(), i + step);
                spans.add(new int[]{i, end});
                titles.add("Chương " + (idx + 1));
            }
        }

        long now = System.currentTimeMillis();
        NovelEntity n = new NovelEntity();
        n.title = guessTitleFromUri(uri);
        n.author = "";
        n.createdAt = now;
        n.updatedAt = now;
        long novelId = db.novelDao().insert(n);

        File dir = new File(ctx.getFilesDir(), "novels/" + novelId);
        if (!dir.exists()) dir.mkdirs();

        List<ChapterEntity> chapters = new ArrayList<>();
        for (int i = 0; i < spans.size(); i++) {
            int s = spans.get(i)[0], e = spans.get(i)[1];
            String title = titles.get(i);
            String chapterText = all.substring(s, e).trim();
            if (chapterText.startsWith(title)) {
                chapterText = chapterText.substring(title.length()).trim();
            }
            File cf = new File(dir, i + ".txt");
            try (FileOutputStream fos = new FileOutputStream(cf)) {
                fos.write(chapterText.getBytes(StandardCharsets.UTF_8));
            }
            ChapterEntity c = new ChapterEntity();
            c.novelId = novelId;
            c.indexInBook = i;
            c.title = title;
            c.contentPath = cf.getAbsolutePath();
            c.length = chapterText.length();
            chapters.add(c);
        }
        db.chapterDao().insertAll(chapters);
        return novelId;
    }

    public long importEpub(Uri uri) throws Exception {
        throw new Exception("EPUB parser not implemented yet.");
    }

    public List<Map<String, Object>> getNovels(int page, int pageSize) {
        int offset = Math.max(0, page) * Math.max(1, pageSize);
        List<NovelEntity> list = db.novelDao().list(pageSize, offset);
        List<Map<String, Object>> out = new ArrayList<>();
        for (NovelEntity n : list) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", n.id);
            m.put("title", n.title);
            m.put("author", n.author);
            m.put("coverPath", n.coverPath);
            out.add(m);
        }
        return out;
    }

    public List<Map<String, Object>> getChapters(long novelId) {
        List<ChapterEntity> list = db.chapterDao().byNovel(novelId);
        List<Map<String, Object>> out = new ArrayList<>();
        for (ChapterEntity c : list) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", c.id);
            m.put("indexInBook", c.indexInBook);
            m.put("title", c.title);
            out.add(m);
        }
        return out;
    }

    public String getChapterContent(long chapterId) {
        com.oneadx.novelverse.entity.ChapterEntity c = db.chapterDao().get(chapterId);
        if (c == null) return "";
        try (FileInputStream fis = new FileInputStream(new File(c.contentPath))) {
            return readAll(fis);
        } catch (Exception e) {
            return "";
        }
    }

    public void updateProgress(long novelId, long chapterId, int offset) {
        ProgressEntity p = new ProgressEntity();
        p.novelId = novelId;
        p.chapterId = chapterId;
        p.offset = offset;
        db.progressDao().upsert(p);
    }

    public List<Map<String, Object>> search(String q) {
        List<NovelEntity> list = db.novelDao().search(q == null ? "" : q.trim());
        List<Map<String, Object>> out = new ArrayList<>();
        for (NovelEntity n : list) {
            Map<String, Object> m = new HashMap<>();
            m.put("id", n.id);
            m.put("title", n.title);
            out.add(m);
        }
        return out;
    }

    private String guessTitleFromUri(Uri uri) {
        String last = uri.getLastPathSegment();
        if (last == null) return "New Novel";
        int dot = last.lastIndexOf('.');
        return dot > 0 ? last.substring(0, dot) : last;
    }
    public long addChapter(long novelId, String title, String content, Integer desiredIndex) throws Exception {
        // Tính index: nếu không truyền, tự lấy maxIndex + 1
        Integer max = db.chapterDao().maxIndex(novelId);
        int index = desiredIndex != null ? desiredIndex : ((max == null ? -1 : max) + 1);

        // Thư mục chương
        File dir = new File(ctx.getFilesDir(), "novels/" + novelId);
        if (!dir.exists()) dir.mkdirs();

        // Ghi file
        File cf = new File(dir, index + ".txt");
        try (FileOutputStream fos = new FileOutputStream(cf)) {
            fos.write(content.getBytes(StandardCharsets.UTF_8));
        }

        // Insert DB
        ChapterEntity c = new ChapterEntity();
        c.novelId = novelId;
        c.indexInBook = index;
        c.title = (title == null || title.isEmpty()) ? ("Chương " + (index + 1)) : title;
        c.contentPath = cf.getAbsolutePath();
        c.length = content.length();
        long rowId = db.chapterDao().insertOne(c);

        // Cập nhật updatedAt của Novel
        NovelEntity n = db.novelDao().get(novelId);
        if (n != null) {
            n.updatedAt = System.currentTimeMillis();
            db.novelDao().update(n);
        }
        return rowId;
    }
    public int importMoreFromTxt(long novelId, Uri uri) throws Exception {
        String all;
        try (InputStream is = open(uri)) { all = readAll(is); }

        // Tách chương
        Pattern p = Pattern.compile("(?m)^(?:Chương|CHƯƠNG|Chapter|CHAPTER|Phần|PHẦN)\\s*\\d+.*$");
        Matcher m = p.matcher(all);
        List<int[]> spans = new ArrayList<>();
        List<String> titles = new ArrayList<>();
        while (m.find()) {
            if (!spans.isEmpty()) spans.get(spans.size() - 1)[1] = m.start();
            spans.add(new int[]{m.start(), all.length()});
            titles.add(all.substring(m.start(), m.end()).trim());
        }
        if (spans.isEmpty()) return 0;

        // Lấy index lớn nhất hiện có
        Integer max = db.chapterDao().maxIndex(novelId);
        int base = (max == null ? -1 : max) + 1;  // điểm bắt đầu append

        int appended = 0;
        for (int localIdx = 0; localIdx < spans.size(); localIdx++) {
            int s = spans.get(localIdx)[0], e = spans.get(localIdx)[1];
            String title = titles.get(localIdx);
            String content = all.substring(s, e).trim();
            if (content.startsWith(title)) content = content.substring(title.length()).trim();

            // indexInBook mới = base + localIdx
            addChapter(novelId, title, content, base + localIdx);
            appended++;
        }
        return appended;
    }



}
