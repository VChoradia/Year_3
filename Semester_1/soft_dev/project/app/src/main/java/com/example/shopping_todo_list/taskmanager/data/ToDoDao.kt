package com.example.shopping_todo_list.taskmanager.data

import android.net.Uri
import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import kotlinx.coroutines.flow.Flow

@Dao
interface ToDoDao {

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertTodo(todo: ToDo)

    @Delete
    suspend fun deleteTodo(todo: ToDo)

    @Query("SELECT * FROM todo WHERE id = :id")
    suspend fun getToDoById(id: Int): ToDo?

    @Query("SELECT * FROM todo")
    fun getTodos(): Flow<List<ToDo>>

//    Budget Related
    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun setBudget(budget: Budget)

    @Delete
    suspend fun deleteBudget(budget: Budget)

    @Query("SELECT budget FROM budget ORDER BY id DESC LIMIT 1")
    suspend fun getBudget(): Double?

    @Query("SELECT SUM(moneySpent) FROM todo WHERE strftime('%m', receiptDate) = :month")
    suspend fun monthlySpend(month: String) : Double

    @Query("UPDATE todo SET isDone = :done WHERE id = :id")
    suspend fun updateTodoDoneStatus(done: Boolean?, id: Int?)

    @Query("UPDATE todo SET receiptPhoto = :receiptPhoto, receiptDate = :receiptDate, moneySpent = :moneySpent WHERE id = :id")
    suspend fun saveReceipt(id: Int?, receiptPhoto: Uri?, receiptDate: Int?, moneySpent: Double?)
}