package com.oneadx.novelverse.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.Query;

import com.oneadx.novelverse.entity.BookmarkEntity;

import java.util.List;

@Dao
public interface BookmarkDao {
    @Insert
    long insert(BookmarkEntity b);

    @Query("SELECT * FROM bookmarks WHERE novelId = :novelId ORDER BY id DESC")
    List<BookmarkEntity> byNovel(long novelId);
}
