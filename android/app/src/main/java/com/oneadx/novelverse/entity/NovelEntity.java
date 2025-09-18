package com.oneadx.novelverse.entity;

import androidx.annotation.NonNull;
import androidx.room.Entity;
import androidx.room.PrimaryKey;

@Entity(tableName = "novels")
public class NovelEntity {
    @PrimaryKey(autoGenerate = true) public long id;
    @NonNull public String title;
    public String author;
    public String coverPath;     // có thể null
    public String description;   // ngắn
    public long createdAt;
    public long updatedAt;
}