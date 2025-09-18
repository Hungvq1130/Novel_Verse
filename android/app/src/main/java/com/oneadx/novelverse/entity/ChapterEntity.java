package com.oneadx.novelverse.entity;

import androidx.room.Entity;
import androidx.room.ForeignKey;
import androidx.room.Index;
import androidx.room.PrimaryKey;

@Entity(
        tableName = "chapters",
        indices = {@Index(value = {"novelId","indexInBook"}, unique = true)},
        foreignKeys = @ForeignKey(
                entity = NovelEntity.class,
                parentColumns = "id",
                childColumns = "novelId",
                onDelete = ForeignKey.CASCADE   // <<<<<<<<<<  quan trọng
        )
)
public class ChapterEntity {
    @PrimaryKey(autoGenerate = true)
    public long id;

    public long novelId;
    public int indexInBook;
    public String title;
    public String contentPath;
    public int length;
}
