package com.example.shopping_todo_list.ui.completedtask_page

import android.util.Log
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.shopping_todo_list.taskmanager.data.ToDo
import com.example.shopping_todo_list.taskmanager.data.ToDoRepository
import com.example.shopping_todo_list.util.Routes
import com.example.shopping_todo_list.util.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class CompletedPageViewModel @Inject constructor(
    private val repository: ToDoRepository
): ViewModel() {


    val completed_todos = repository.getTodos()
    private val _uiEvent = Channel<UiEvent>()
    val uiEvent = _uiEvent.receiveAsFlow()

    private var deletedTodo: ToDo? = null

    fun onEvent(event: CompletedPageEvent){
        when(event){
            is CompletedPageEvent.OnToDoClick -> {
                Log.d("ToDoListViewModel", "Todo clicked: ${event.todo.id}")
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO + "?todoId=${event.todo.id}"))

            }

            is CompletedPageEvent.OnBudgetClick -> {
                Log.d("ToDoListViewModel", "Budget icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.BUDGET_PAGE))

            }

            is CompletedPageEvent.OnCompletedPageClick -> {
                Log.d("ToDoListViewModel", "Completed icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.COMPLETED_PAGE))

            }

            is CompletedPageEvent.OnAddTodoClick -> {
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO))
            }

            is CompletedPageEvent.OnHomePageClick -> {
//                Log.d("ToDoListViewModel", "Completed icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.TODO_LIST))

            }

            is CompletedPageEvent.OnUndoDeleteClick -> {
                deletedTodo?.let { todo ->
                    viewModelScope.launch {
                        repository.insertTodo(todo)
                        deletedTodo = null
                    }
                }
            }

            is CompletedPageEvent.OnDeleteToDoClick -> {
                viewModelScope.launch {
                    deletedTodo = event.todo
                    repository.deleteTodo(event.todo)
                    sendUiEvent(UiEvent.ShowSnackBar(
                        message = "ToDo deleted",
                        action = "Undo"
                    ))
                }
            }

            is CompletedPageEvent.OnDoneChange -> {
                viewModelScope.launch {
                    repository.insertTodo(
                        event.todo.copy(
                            isDone = event.isDone
                        )
                    )
                }
                if (event.isDone) {
                    sendUiEvent(UiEvent.Navigate(Routes.RECEIPT_PAGE + "?todoId=${event.todo.id}"))
                }

            }
        }
    }

    private fun sendUiEvent(event: UiEvent) {
        viewModelScope.launch {
            _uiEvent.send(event)

        }
    }
}
