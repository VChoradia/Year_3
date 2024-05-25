package com.example.shopping_todo_list

import android.app.Application
import androidx.room.Room
import com.example.shopping_todo_list.taskmanager.data.ToDoDatabase
import com.example.shopping_todo_list.taskmanager.data.ToDoRepository
import com.example.shopping_todo_list.taskmanager.data.ToDoRepositoryImplementation
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideToDoDatabase(app: Application): ToDoDatabase{
        return Room.databaseBuilder(
            app,
            ToDoDatabase::class.java,
            "todo_db"
        )
            .addMigrations(
                ToDoDatabase.MIGRATION_1_2,
                ToDoDatabase.MIGRATION_2_3,
                ToDoDatabase.MIGRATION_3_2
            )
            .build()
    }

    @Provides
    @Singleton
    fun provideToDoRepository(db: ToDoDatabase): ToDoRepository{
        return ToDoRepositoryImplementation(db.dao)
    }
}