package com.example.shopping_todo_list.ui.todo_list

import com.example.shopping_todo_list.taskmanager.data.ToDo

sealed class ToDoListEvent{
    data class OnDeleteToDoClick(val todo: ToDo): ToDoListEvent()
    data class OnDoneChange(val todo: ToDo, val isDone: Boolean): ToDoListEvent()
    object OnUndoDeleteClick: ToDoListEvent()
    data class OnToDoClick(val todo: ToDo): ToDoListEvent()
    data class OnSuggestionClick(val id: Int, val title: String, val description: String): ToDoListEvent()
    object OnAddTodoClick: ToDoListEvent()
    object OnBudgetClick: ToDoListEvent()
    object OnCompletedPageClick: ToDoListEvent()
    object OnHomePageClick: ToDoListEvent()
}
