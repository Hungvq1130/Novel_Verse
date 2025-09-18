package com.oneadx.novelverse.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import com.oneadx.novelverse.entity.ProgressEntity;
@Dao
public interface ProgressDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE) void upsert(ProgressEntity p);
    @Query("SELECT * FROM progress WHERE novelId = :novelId LIMIT 1") ProgressEntity byNovel(long novelId);
}