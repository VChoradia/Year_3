package com.example.shopping_todo_list.ui.completedtask_page

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.BottomNavigation
import androidx.compose.material.BottomNavigationItem
import androidx.compose.material.Card
import androidx.compose.material.Icon
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.SnackbarResult
import androidx.compose.material.Text
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.rememberScaffoldState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shopping_todo_list.ui.theme.Blue1
import com.example.shopping_todo_list.ui.todo_list.ToDoListEvent
import com.example.shopping_todo_list.ui.todo_list.ToDoListViewModel
import com.example.shopping_todo_list.ui.todo_list.TodoSection
import com.example.shopping_todo_list.util.UiEvent


@SuppressLint("UnusedMaterialScaffoldPaddingParameter")
@Composable
fun CompletedPage(
    onNavigate: (UiEvent.Navigate) -> Unit,
    viewModel: ToDoListViewModel = hiltViewModel()
){
    val todos = viewModel.todos.collectAsState(initial = emptyList())
    val scaffoldState = rememberScaffoldState()

    LaunchedEffect(key1 = true){
        viewModel.uiEvent.collect{event ->
            when(event) {
                is UiEvent.ShowSnackBar -> {
                    val result = scaffoldState.snackbarHostState.showSnackbar(
                        message = event.message,
                        actionLabel = event.action
                    )
                    if (result == SnackbarResult.ActionPerformed) {
                        viewModel.onEvent(ToDoListEvent.OnUndoDeleteClick)
                    }
                }
                is UiEvent.Navigate -> onNavigate(event)
                else -> Unit
            }
        }
    }
    Scaffold(
        scaffoldState = scaffoldState,
        topBar = {
            TopAppBar(
                backgroundColor = Blue1,
                contentColor = MaterialTheme.colors.onPrimary
            ) {
                Text(
                    "Completed Tasks",
                    style = TextStyle(
                        fontWeight = FontWeight.Bold,
                        fontSize = 25.sp
                    ),
                    modifier = Modifier.fillMaxWidth(),
                    textAlign = TextAlign.Center
                )
            }
        },
        bottomBar = {
            BottomNavigation {

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.Home, contentDescription = "Wallet", modifier = Modifier.size(32.dp)) },
                    label = { Text("Home") },
                    selected = false, // You can manage the selected state using a variable
                    onClick = {
                        // Handle click to navigate to another page
                        viewModel.onEvent(ToDoListEvent.OnHomePageClick)
                    }

                )

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.AccountBalanceWallet, contentDescription = "Wallet", modifier = Modifier.size(32.dp)) },
                    label = { Text("Budget") },
                    selected = false, // You can manage the selected state using a variable
                    onClick = {
                        // Handle click to navigate to another page
                        viewModel.onEvent(ToDoListEvent.OnBudgetClick)
                    }

                )

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.Check, contentDescription = "Completed", modifier = Modifier.size(32.dp)) },
                    label = { Text("Tasks") },
                    selected = false, // You can manage the selected state using a variable
                    onClick = {
                        viewModel.onEvent(ToDoListEvent.OnCompletedPageClick)
                    }
                )

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.Add, contentDescription = "Add", modifier = Modifier.size(32.dp)) },
                    label = { Text("Add Task") },
                    selected = false, // You can manage the selected state using a variable
                    onClick = {
                        viewModel.onEvent(ToDoListEvent.OnAddTodoClick)
                    }
                )
            }
        }

    )

    {


        LazyColumn(
            modifier = Modifier.fillMaxSize(),
            content = {
                item {
                    Spacer(modifier = Modifier.height(60.dp)) // Adjust height as needed
                }

                item {
                    Card(
                        modifier = Modifier.padding(8.dp),
                        elevation = 0.dp,
                        shape = RoundedCornerShape(8.dp),
                        backgroundColor = Blue1.copy(alpha = 0.1f) // Change 'Green' to your desired color
                    ) {
                        TodoSection(
                            "Tasks", Blue1.copy(0.7f),
                            todos.value.filter {  it.isDone == true },
                            viewModel::onEvent
                        )

                    }
                }

                item {
                    Spacer(modifier = Modifier.height(60.dp)) // Adjust height as needed
                }
            }
        )


    }
}

