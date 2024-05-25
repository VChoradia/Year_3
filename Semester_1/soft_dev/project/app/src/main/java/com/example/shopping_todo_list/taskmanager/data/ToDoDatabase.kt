package com.example.shopping_todo_list.taskmanager.data

import androidx.room.Database
import androidx.room.RoomDatabase

import androidx.room.TypeConverters
import androidx.room.migration.Migration

@Database(
    entities = [ToDo::class, Budget::class],
    version = 3
)
@TypeConverters(Converters::class)
abstract class ToDoDatabase: RoomDatabase() {
    abstract val dao: ToDoDao

    companion object {
        val MIGRATION_1_2: Migration = DatabaseMigrations.MIGRATION_1_2
        val MIGRATION_2_3: Migration = DatabaseMigrations.MIGRATION_2_3
        val MIGRATION_3_2: Migration = DatabaseMigrations.MIGRATION_3_2
    }

}

