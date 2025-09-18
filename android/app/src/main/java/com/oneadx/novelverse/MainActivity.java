package com.oneadx.novelverse;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

import android.net.Uri;
import android.os.Handler;
import android.os.Looper;

import com.oneadx.novelverse.repo.NovelRepository;

import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class MainActivity extends FlutterActivity {
    private MethodChannel channel;
    private final ExecutorService exec = Executors.newSingleThreadExecutor();
    private final Handler main = new Handler(Looper.getMainLooper());
    private NovelRepository repo;

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        repo = new NovelRepository(getApplicationContext());
        channel = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), "novel_core");

        channel.setMethodCallHandler((call, result) -> {
            switch (call.method) {
                case "getNovels": {
                    Integer page = call.argument("page");
                    Integer size = call.argument("pageSize");
                    final int p = page == null ? 0 : page;
                    final int ps = size == null ? 20 : size;
                    exec.execute(() -> {
                        // chạy ở background
                        java.util.List<java.util.Map<String, Object>> out = repo.getNovels(p, ps);
                        // trả về trên main
                        main.post(() -> result.success(out));
                    });
                    break;
                }

                case "getChapters": {
                    Number novelId = call.argument("novelId");
                    final long nid = novelId.longValue();
                    exec.execute(() -> {
                        java.util.List<java.util.Map<String, Object>> out = repo.getChapters(nid);
                        main.post(() -> result.success(out));
                    });
                    break;
                }

                case "getChapterContent": {
                    Number chapterId = call.argument("chapterId");
                    final long cid = chapterId.longValue();
                    exec.execute(() -> {
                        String content = repo.getChapterContent(cid);
                        main.post(() -> result.success(content));
                    });
                    break;
                }

                case "importTxt": {
                    String uri = call.argument("uri");
                    exec.execute(() -> {
                        try {
                            long id = repo.importTxt(android.net.Uri.parse(uri));
                            main.post(() -> result.success(id));
                        } catch (Exception e) {
                            main.post(() -> result.error("IMPORT_TXT_FAIL", e.getMessage(), null));
                        }
                    });
                    break;
                }

                case "updateProgress": {
                    Number novelId = call.argument("novelId");
                    Number chapterId = call.argument("chapterId");
                    Integer offset = call.argument("offset");
                    final long nid = novelId.longValue();
                    final long cid = chapterId.longValue();
                    final int off = offset == null ? 0 : offset;
                    exec.execute(() -> {
                        repo.updateProgress(nid, cid, off);         // background
                        main.post(() -> result.success(true));      // main
                    });
                    break;
                }

                case "search": {
                    String q = call.argument("q");
                    final String query = q == null ? "" : q;
                    exec.execute(() -> {
                        java.util.List<java.util.Map<String, Object>> out = repo.search(query);
                        main.post(() -> result.success(out));
                    });
                    break;
                }
                case "addChapter": {
                    Number novelId = call.argument("novelId");
                    String title = call.argument("title");
                    String content = call.argument("content");
                    Number desiredIndex = call.argument("index"); // có thể null
                    long nid = novelId.longValue();
                    Integer idx = desiredIndex == null ? null : desiredIndex.intValue();
                    exec.execute(() -> {
                        try {
                            long rowId = repo.addChapter(nid, title, content, idx);
                            main.post(() -> result.success(rowId));
                        } catch (Exception e) {
                            main.post(() -> result.error("ADD_CHAPTER_FAIL", e.getMessage(), null));
                        }
                    });
                    break;
                }

                case "importMoreFromTxt": {
                    Number novelId = call.argument("novelId");
                    String uri = call.argument("uri");
                    long nid = novelId.longValue();
                    exec.execute(() -> {
                        try {
                            int added = repo.importMoreFromTxt(nid, android.net.Uri.parse(uri));
                            main.post(() -> result.success(added));
                        } catch (Exception e) {
                            main.post(() -> result.error("IMPORT_MORE_FAIL", e.getMessage(), null));
                        }
                    });
                    break;
                }

                default:
                    result.notImplemented();
            }
        });
    }
}
