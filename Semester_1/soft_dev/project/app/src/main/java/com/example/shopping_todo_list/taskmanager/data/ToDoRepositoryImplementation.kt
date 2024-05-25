package com.example.shopping_todo_list.taskmanager.data

import android.net.Uri
import kotlinx.coroutines.flow.Flow

class ToDoRepositoryImplementation(
    private val dao: ToDoDao
): ToDoRepository {

    override suspend fun insertTodo(todo: ToDo){
        dao.insertTodo(todo)
    }

    override suspend fun deleteTodo(todo: ToDo){
        dao.deleteTodo(todo)
    }

    override suspend fun getToDoById(id: Int): ToDo? {
        return dao.getToDoById(id)
    }

    override fun getTodos(): Flow<List<ToDo>> {
        return dao.getTodos()
    }

//    Budget Page

    override suspend fun setBudget(budget: Budget){
        dao.setBudget(budget)
    }

    override suspend fun deleteBudget(budget: Budget){
        dao.deleteBudget(budget)
    }

    override suspend fun getBudget(): Double? {
        return dao.getBudget()
    }

    override suspend fun monthlySpend(month: String): Double {
        return dao.monthlySpend(month)
    }

    override suspend fun updateTodoDoneStatus(id: Int?, done: Boolean) {
        dao.updateTodoDoneStatus(done, id)
    }

    override suspend fun saveReceipt(
        id: Int?,
        receiptPhoto: Uri?,
        receiptDate: Int?,
        moneySpent: Double?
    ) {
        dao.saveReceipt(id, receiptPhoto, receiptDate, moneySpent)
    }
}