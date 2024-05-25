package com.example.shopping_todo_list


import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.example.shopping_todo_list.ui.add_edit_todo.AddEditToDoScreen
import com.example.shopping_todo_list.ui.budget_page.BudgetPage
import com.example.shopping_todo_list.ui.theme.Shopping_todo_listTheme
import com.example.shopping_todo_list.ui.receipt_page.ReceiptPage
import com.example.shopping_todo_list.ui.todo_list.TodoListScreen
import com.example.shopping_todo_list.util.Routes
import dagger.hilt.android.AndroidEntryPoint
import com.example.shopping_todo_list.ui.completedtask_page.CompletedPage

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        setContent {
            Shopping_todo_listTheme {

                val navController = rememberNavController()
                NavHost(
                    navController = navController,
                    startDestination = Routes.TODO_LIST
                ) {
                    composable(Routes.TODO_LIST) {
                        TodoListScreen(onNavigate = {
                            navController.navigate(it.route)
                        })
                    }
                    composable(
                        route = Routes.ADD_EDIT_TODO + "?todoId={todoId}&title={title}&description={description}",
                        arguments = listOf(
                            navArgument(name = "todoId") {
                                type = NavType.IntType
                                defaultValue = -1
                            },
                            navArgument(name = "title") {
                                type = NavType.StringType
                                defaultValue = ""
                            },
                            navArgument(name = "description") {
                                type = NavType.StringType
                                defaultValue = ""
                            })
                    ) {
                        AddEditToDoScreen(onPopBackStack = {
                            navController.popBackStack()
                        })
                    }
                    composable(Routes.COMPLETED_PAGE) {
                        CompletedPage(onNavigate = {
                            navController.navigate(it.route)
                        })
                    }
                    composable(Routes.BUDGET_PAGE) {
                        BudgetPage(onNavigate = {
                            navController.navigate(it.route)
                        })
                    }
                    composable(
                        route = Routes.RECEIPT_PAGE + "?todoId={todoId}",
                        arguments = listOf(navArgument("todoId") { type = NavType.IntType })
                    ) { navBackStackEntry ->
                        // Extract the task ID from the navBackStackEntry
                        val taskId = navBackStackEntry.arguments?.getInt("todoId") ?: -1
                        // Call MyAppPage with the task ID
                        ReceiptPage(
                            taskId = taskId,
                            onPopBackStack = { navController.popBackStack() }
                        )
                    }
                }
            }
        }
    }
}


