package com.example.shopping_todo_list.taskmanager.data
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase

object DatabaseMigrations {
    val MIGRATION_1_2: Migration = object : Migration(1, 2) {
        override fun migrate(database: SupportSQLiteDatabase) {

            // For example, if you were adding a new column 'newColumn'
            database.execSQL("ALTER TABLE ToDo ADD COLUMN dueDate LONG")
            database.execSQL("ALTER TABLE ToDo ADD COLUMN dueTime LONG")
            database.execSQL("ALTER TABLE ToDo ADD COLUMN latitude REAL")
            database.execSQL("ALTER TABLE ToDo ADD COLUMN longitude REAL")
            database.execSQL("ALTER TABLE ToDo ADD COLUMN distance REAL")

        }
    }

    // Add more migrations as needed
     val MIGRATION_2_3: Migration = object : Migration(2, 3) {
         override fun migrate(database: SupportSQLiteDatabase) {
             // Migration logic for version 2 to version 3
             database.execSQL("CREATE TABLE budget (\n" +
                     "    id INTEGER PRIMARY KEY,\n" +
                     "    budget REAL\n" +
                     ");")
         }
     }

    // Migration from version 3 to version 2
    val MIGRATION_3_2: Migration = object : Migration(3, 2) {
        override fun migrate(database: SupportSQLiteDatabase) {
            // Migration logic for version 3 to version 2
            database.execSQL("DROP TABLE IF EXISTS budget")
        }
    }


}

