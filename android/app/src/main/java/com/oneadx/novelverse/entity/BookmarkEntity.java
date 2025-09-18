package com.oneadx.novelverse.entity;

import androidx.room.Entity;
import androidx.room.Index;
import androidx.room.PrimaryKey;
@Entity(tableName = "bookmarks",
        indices = {@Index(value = {"novelId","chapterId","offset"})})
public class BookmarkEntity {
    @PrimaryKey(autoGenerate = true) public long id;
    public long novelId;
    public long chapterId;
    public int offset;
    public String note;
}