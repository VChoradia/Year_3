package com.example.shopping_todo_list.taskmanager.data


import android.net.Uri
import kotlinx.coroutines.flow.Flow

interface ToDoRepository {

    suspend fun insertTodo(todo: ToDo)

    suspend fun deleteTodo(todo: ToDo)

    suspend fun getToDoById(id: Int): ToDo?

    fun getTodos(): Flow<List<ToDo>>


//    For Budget Page
    suspend fun setBudget(budget: Budget)

    suspend fun deleteBudget(budget: Budget)

    suspend fun getBudget(): Double?

    suspend fun monthlySpend(month: String): Double?

    suspend fun updateTodoDoneStatus(id: Int?, done: Boolean)

    suspend fun saveReceipt(id: Int?, receiptPhoto: Uri?, receiptDate: Int?, moneySpent: Double?)
}