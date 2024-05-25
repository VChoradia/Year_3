package com.example.shopping_todo_list.ui.budget_page

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import androidx.activity.compose.setContent
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.shopping_todo_list.ui.theme.Shopping_todo_listTheme
import com.example.shopping_todo_list.util.Routes

class BudgetActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            Shopping_todo_listTheme {
                val navController = rememberNavController()
                NavHost(
                    navController = navController,
                    startDestination = Routes.BUDGET_PAGE
                ) {
                    composable(Routes.BUDGET_PAGE) {
                        BudgetPage(onNavigate = {
                            navController.navigate(it.route)
                        })
                    }
                }
            }
        }
    }
}


