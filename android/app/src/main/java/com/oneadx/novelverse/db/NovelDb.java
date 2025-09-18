package com.oneadx.novelverse.db;

import androidx.room.Database;
import androidx.room.RoomDatabase;

import com.oneadx.novelverse.dao.BookmarkDao;
import com.oneadx.novelverse.dao.ChapterDao;
import com.oneadx.novelverse.dao.NovelDao;
import com.oneadx.novelverse.dao.ProgressDao;
import com.oneadx.novelverse.entity.BookmarkEntity;
import com.oneadx.novelverse.entity.ChapterEntity;
import com.oneadx.novelverse.entity.NovelEntity;
import com.oneadx.novelverse.entity.ProgressEntity;

@Database(
        entities = {
                NovelEntity.class,
                ChapterEntity.class,
                ProgressEntity.class,
                BookmarkEntity.class
        },
        version = 1,
        exportSchema = false
)
public abstract class NovelDb extends RoomDatabase {
    public abstract NovelDao novelDao();
    public abstract ChapterDao chapterDao();
    public abstract ProgressDao progressDao();
    public abstract BookmarkDao bookmarkDao();
}
