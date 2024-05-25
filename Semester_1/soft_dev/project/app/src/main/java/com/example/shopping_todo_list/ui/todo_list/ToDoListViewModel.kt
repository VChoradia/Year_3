package com.example.shopping_todo_list.ui.todo_list

import android.net.Uri
import android.util.Log
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
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
import java.time.LocalDate
import java.time.LocalTime
import javax.inject.Inject

@HiltViewModel
class ToDoListViewModel @Inject constructor(
    private val repository: ToDoRepository
): ViewModel() {

    val todos = repository.getTodos()

    private val _uiEvent = Channel<UiEvent>()
    val uiEvent = _uiEvent.receiveAsFlow()

    private var deletedTodo: ToDo? = null

    var title by mutableStateOf("")
        private set

    var description by mutableStateOf("")
        private set

    var priority by mutableStateOf("")
        private set

    var isDone by mutableStateOf(false)
        private set

    var receiptPhoto by mutableStateOf<Uri?>(null)
        private set

    var receiptDate by mutableStateOf<Int?>(null)
        private set

    var moneySpent by mutableStateOf(0.0)
        private set

    var dueDate by mutableStateOf<LocalDate?>(null)
        private set

    var dueTime by mutableStateOf<LocalTime?>(null)
        private set

    var latitude by mutableStateOf(0.0)
        private set

    var longitude by mutableStateOf(0.0)
        private set

    var distance by mutableStateOf(0.0)
        private set

    fun onEvent(event: ToDoListEvent) {
        when (event) {
            is ToDoListEvent.OnToDoClick -> {
                Log.d("ToDoListViewModel", "Todo clicked: ${event.todo.id}")
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO + "?todoId=${event.todo.id}&title=${""}&description=${""}"))
            }
            is ToDoListEvent.OnSuggestionClick -> {
                Log.d("ToDoListViewModel", "Suggestion Clicked")
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO + "?id=${-1}&title=${event.title}&description=${event.description}"))
            }

            is ToDoListEvent.OnBudgetClick -> {
                Log.d("ToDoListViewModel", "Budget icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.BUDGET_PAGE))
            }

            is ToDoListEvent.OnCompletedPageClick -> {
                Log.d("ToDoListViewModel", "Completed icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.COMPLETED_PAGE))
            }

            is ToDoListEvent.OnHomePageClick -> {
                Log.d("ToDoListViewModel", "Home Page")
                sendUiEvent(UiEvent.Navigate(Routes.TODO_LIST))
            }

            is ToDoListEvent.OnAddTodoClick -> {
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO))
            }

            is ToDoListEvent.OnUndoDeleteClick -> {
                deletedTodo?.let { todo ->
                    viewModelScope.launch {
                        repository.insertTodo(todo)
                        deletedTodo = null
                    }
                }
            }

            is ToDoListEvent.OnDeleteToDoClick -> {
                viewModelScope.launch {
                    deletedTodo = event.todo
                    repository.deleteTodo(event.todo)
                    sendUiEvent(UiEvent.ShowSnackBar(
                        message = "ToDo deleted",
                        action = "Undo"
                    ))
                }
            }

            is ToDoListEvent.OnDoneChange -> {
                viewModelScope.launch {
                    repository.updateTodoDoneStatus(event.todo.id, event.isDone)

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