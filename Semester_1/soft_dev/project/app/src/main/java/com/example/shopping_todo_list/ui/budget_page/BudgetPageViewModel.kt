package com.example.shopping_todo_list.ui.budget_page

import android.util.Log
import androidx.compose.runtime.State
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.shopping_todo_list.taskmanager.data.Budget
import com.example.shopping_todo_list.taskmanager.data.ToDoRepository
import com.example.shopping_todo_list.util.Routes
import com.example.shopping_todo_list.util.UiEvent
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import java.util.Calendar
import javax.inject.Inject

@HiltViewModel
class BudgetPageViewModel @Inject constructor(
    private val repository: ToDoRepository
) : ViewModel() {

    val currentMonth = Calendar.getInstance().get(Calendar.MONTH)
    var currBudget by mutableStateOf("0.0")
        private set

    private var _current = mutableStateOf("0.0")
    val current: State<String> = _current

    var monthlySpendings by mutableStateOf<Map<Int, Double>>(emptyMap())
        private set

    var totalMoneySpentInCurrentMonth = mutableStateOf(0.0)

    private val _uiEvent = Channel<UiEvent>()
    val uiEvent = _uiEvent.receiveAsFlow()

    init {
        refreshData()
    }

    fun refreshData() {
        viewModelScope.launch {
            val x = repository.getBudget().toString() ?: "0.0"
            _current.value = x

            // Collect the todos flow
            repository.getTodos().collect { todos ->
                val filteredTodos = todos.filter {
                    it.receiptDate == (currentMonth + 1)
                }

                val sum = filteredTodos.sumOf { it.moneySpent ?: 0.0 }
                totalMoneySpentInCurrentMonth.value = sum

                val newMonthlySpendings = mutableMapOf<Int, Double>()
                todos.forEach { todo ->
                    val month = todo.receiptDate
                    if (month != null) {
                        val currentSpending = newMonthlySpendings[month] ?: 0.0
                        newMonthlySpendings[month] = currentSpending + (todo.moneySpent ?: 0.0)
                    }
                }
                monthlySpendings = newMonthlySpendings
            }
        }
    }

    fun onEvent(event: BudgetEvent) {
        when (event) {
            is BudgetEvent.OnBudgetChange -> {
                currBudget = event.budget
            }
            is BudgetEvent.OnAddTodoClick -> {
                sendUiEvent(UiEvent.Navigate(Routes.ADD_EDIT_TODO))
            }

            is BudgetEvent.OnBudgetClick -> {
                Log.d("BudgetEvent", "Budget icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.BUDGET_PAGE))

            }

            is BudgetEvent.OnCompletedPageClick -> {
                Log.d("BudgetEvent", "Completed icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.COMPLETED_PAGE))

            }
            is BudgetEvent.OnHomePageClick -> {
                Log.d("ToDoListViewModel", "Completed icon clicked")
                sendUiEvent(UiEvent.Navigate(Routes.TODO_LIST))

            }
            is BudgetEvent.SetBudget -> {
                viewModelScope.launch {
                    repository.setBudget(
                        Budget(1, currBudget.toDouble())
                    )
                    sendUiEvent(UiEvent.PopBackStack)
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
