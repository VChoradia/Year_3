package com.example.shopping_todo_list.ui.budget_page

sealed class BudgetEvent {
    data class OnBudgetChange(val budget: String): BudgetEvent()
    data class SetBudget(val budget: Double): BudgetEvent()
    object OnAddTodoClick: BudgetEvent()
    object OnBudgetClick: BudgetEvent()
    object OnCompletedPageClick: BudgetEvent()
    object OnHomePageClick: BudgetEvent()

}