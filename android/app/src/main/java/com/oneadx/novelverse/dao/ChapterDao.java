package com.oneadx.novelverse.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.OnConflictStrategy;
import androidx.room.Query;

import com.oneadx.novelverse.entity.ChapterEntity;

import java.util.List;
@Dao
public interface ChapterDao {
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    void insertAll(List<ChapterEntity> list);

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    long insertOne(ChapterEntity c); // ⬅️ thêm mới

    @Query("SELECT * FROM chapters WHERE novelId = :novelId ORDER BY indexInBook ASC")
    List<ChapterEntity> byNovel(long novelId);

    @Query("SELECT MAX(indexInBook) FROM chapters WHERE novelId = :novelId")
    Integer maxIndex(long novelId); // ⬅️ lấy chương cuối

    @Query("SELECT * FROM chapters WHERE id = :id")
    ChapterEntity get(long id);
}
