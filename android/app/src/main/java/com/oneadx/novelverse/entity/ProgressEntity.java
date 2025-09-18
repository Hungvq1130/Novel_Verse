package com.oneadx.novelverse.entity;

import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;
@Entity(tableName = "progress",
        indices = {@Index(value = {"novelId"}, unique = true)})
public class ProgressEntity {
    @PrimaryKey(autoGenerate = true) public long id;
    public long novelId;
    public long chapterId;
    public int offset; // vị trí cuộn (pixel hoặc %), tuỳ bạn
}