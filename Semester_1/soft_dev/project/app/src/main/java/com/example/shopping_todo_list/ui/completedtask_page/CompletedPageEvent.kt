package com.example.shopping_todo_list.ui.completedtask_page

import com.example.shopping_todo_list.taskmanager.data.ToDo

sealed class CompletedPageEvent {

    data class OnDeleteToDoClick(val todo: ToDo): CompletedPageEvent()
    data class OnDoneChange(val todo: ToDo, val isDone: Boolean): CompletedPageEvent()
    object OnUndoDeleteClick: CompletedPageEvent()
    data class OnToDoClick(val todo: ToDo): CompletedPageEvent()
    object OnAddTodoClick: CompletedPageEvent()
    object OnBudgetClick: CompletedPageEvent()
    object OnCompletedPageClick: CompletedPageEvent()
    object OnHomePageClick: CompletedPageEvent()

}
