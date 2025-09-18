package com.oneadx.novelverse.dao;

import androidx.room.Dao;
import androidx.room.Insert;
import androidx.room.Query;
import androidx.room.Update;

import com.oneadx.novelverse.entity.NovelEntity;

import java.util.List;
@Dao
public interface NovelDao {
    @Insert long insert(NovelEntity n);
    @Update void update(NovelEntity n);
    @Query("SELECT * FROM novels ORDER BY updatedAt DESC LIMIT :limit OFFSET :offset")
    List<NovelEntity> list(int limit, int offset);
    @Query("SELECT * FROM novels WHERE id = :id") NovelEntity get(long id);
    @Query("DELETE FROM novels WHERE id = :id") void delete(long id);
    @Query("SELECT * FROM novels WHERE title LIKE '%' || :q || '%' ORDER BY updatedAt DESC LIMIT 50")
    List<NovelEntity> search(String q);
}