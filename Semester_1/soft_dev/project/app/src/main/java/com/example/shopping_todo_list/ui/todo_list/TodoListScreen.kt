package com.example.shopping_todo_list.ui.todo_list

import android.annotation.SuppressLint
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Home
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shopping_todo_list.ui.theme.Blue1
import com.example.shopping_todo_list.ui.theme.DeepGreen
import com.example.shopping_todo_list.ui.theme.Ochre
import com.example.shopping_todo_list.util.UiEvent



@SuppressLint("UnusedMaterialScaffoldPaddingParameter")
@Composable
fun TodoListScreen(
    onNavigate: (UiEvent.Navigate) -> Unit,
    viewModel: ToDoListViewModel = hiltViewModel()
){
    val todos = viewModel.todos.collectAsState(initial = emptyList())
    val scaffoldState = rememberScaffoldState()
//    var shouldPerformUndo: Boolean by remember { mutableStateOf(false) }

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
                    "ShopEasy",
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
                    icon = { Icon(imageVector = Icons.Default.Home, contentDescription = "Home", modifier = Modifier.size(32.dp)) },
                    label = { Text("Home") },
                    selected = false,
                    onClick = {
                        viewModel.onEvent(ToDoListEvent.OnHomePageClick)
                    }

                )


                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.AccountBalanceWallet, contentDescription = "Wallet", modifier = Modifier.size(32.dp)) },
                    label = { Text("Budget") },
                    selected = false,
                    onClick = {
                        viewModel.onEvent(ToDoListEvent.OnBudgetClick)
                    }

                )

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.Check, contentDescription = "Completed", modifier = Modifier.size(32.dp)) },
                    label = { Text("Tasks") },
                    selected = false,
                    onClick = {
                        viewModel.onEvent(ToDoListEvent.OnCompletedPageClick)
                    }
                )

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = { Icon(imageVector = Icons.Default.Add, contentDescription = "Add", modifier = Modifier.size(32.dp)) },
                    label = { Text("Add Task") },
                    selected = false,
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
                    Spacer(modifier = Modifier.height(8.dp)) // Adjust height as needed
                }

                if (todos.value.isEmpty()){

                    item {
                        Card(
                            modifier = Modifier.padding(10.dp),
                            elevation = 0.dp,
                            shape = RoundedCornerShape(8.dp),
                            backgroundColor = Blue1.copy(alpha = 0.1f) // Change 'Green' to your desired color,
                        ) {
                            Column(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(bottom = 16.dp)
                            ) {
                                Text(
                                    text = "Welcome Back!",
                                    style = TextStyle(fontSize = 20.sp, fontWeight= FontWeight.Bold,color = Blue1),
                                    modifier = Modifier.padding(20.dp)
                                )


                                Text(
                                    text = "Task Suggestions",
                                    style = TextStyle(fontSize = 18.sp, fontWeight= FontWeight.Bold),
                                    modifier = Modifier.padding(start= 20.dp, top = 10.dp)
                                )

                                Column {

                                    Column(
                                        modifier = Modifier
                                            .clickable {
                                                viewModel.onEvent(ToDoListEvent.OnSuggestionClick(-1,"ALDI", "Milk, Bread, Eggs, Potatoes, Bananas, Bacon, Butter, Juice, Biscuits"))
                                            }
                                    ) {
                                        Spacer(modifier = Modifier.height(16.dp))
                                        Row (
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ){
                                            Row (modifier = Modifier.fillMaxHeight(),

                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Column(
                                                    modifier = Modifier.padding(10.dp),
//
                                                )


                                                {
                                                    Row(
                                                        modifier = Modifier
                                                            .fillMaxWidth()
                                                            .border(width = 1.dp, color = Color.White)
                                                            .background(Color.White)
                                                            .padding(10.dp),
                                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                                        verticalAlignment = Alignment.CenterVertically




                                                    ) {
                                                        Text(
                                                            text = "ALDI",
                                                            modifier = Modifier.padding(start = 12.dp), fontWeight = FontWeight.Bold

                                                        )

                                                        Text(
                                                            text = "Milk, Bread, Butter, Juice, Biscuits",
                                                            modifier = Modifier
                                                                .padding(start = 20.dp,),
                                                            color = Color.Gray
                                                        )
                                                        Row(
                                                            modifier = Modifier.fillMaxWidth(),
                                                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                                                            verticalAlignment = Alignment.CenterVertically
                                                        ) {
                                                            Spacer(modifier = Modifier.weight(1f))

                                                        }
                                                    }

                                                }


                                            }
                                        }
                                    }
                                    Spacer(modifier = Modifier.height(16.dp))
                                    Box(
                                        modifier = Modifier
                                            .clickable {
                                                viewModel.onEvent(ToDoListEvent.OnSuggestionClick(-1,"Tesco", "Cheese, Snacks, Cereal"))
                                            }
                                    ) {
                                        Spacer(modifier = Modifier.height(16.dp))
                                        Row (
                                            modifier = Modifier.fillMaxWidth(),
                                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                                            verticalAlignment = Alignment.CenterVertically
                                        ){
                                            Row (modifier = Modifier.fillMaxHeight(),

                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Column(
                                                    modifier = Modifier.padding(10.dp),
//
                                                )


                                                {
                                                    Row(
                                                        modifier = Modifier
                                                            .fillMaxWidth()
                                                            .border(width = 1.dp, color = Color.White)
                                                            .background(Color.White)
                                                            .padding(10.dp),
                                                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                                                        verticalAlignment = Alignment.CenterVertically




                                                    ) {
                                                        Text(
                                                            text = "Tesco",
                                                            modifier = Modifier.padding(start = 12.dp), fontWeight = FontWeight.Bold

                                                        )

                                                        Text(
                                                            text = "Frozen food, Snacks, Cereal",
                                                            modifier = Modifier
                                                                .padding(start = 20.dp,),
                                                            color = Color.Gray
                                                        )
                                                        Row(
                                                            modifier = Modifier.fillMaxWidth(),
                                                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                                                            verticalAlignment = Alignment.CenterVertically
                                                        ) {
                                                            Spacer(modifier = Modifier.weight(1f))

                                                        }
                                                    }

                                                }


                                            }
                                        }
                                    }

                                }
                            }
                        }
                    }
                }
                else {
                    item {
                        Card(
                            modifier = Modifier.padding(8.dp),
                            elevation = 0.dp,
                            shape = RoundedCornerShape(8.dp),
                            backgroundColor = Color.Red.copy(alpha = 0.1f) // Change 'Green' to your desired color
                        ) {
                            TodoSection(
                                "High Priority", Color.Red.copy(0.7f),
                                todos.value.filter { it.priority == "High" && it.isDone == false },
                                viewModel::onEvent
                            )


                        }
                    }
                    item {
                        Card(
                            modifier = Modifier.padding(8.dp),
                            elevation = 0.dp,
                            shape = RoundedCornerShape(8.dp),
                            backgroundColor = Color.Yellow.copy(alpha = 0.1f)
                        ) {
                            TodoSection(
                                "Medium Priority", Ochre,
                                todos.value.filter { it.priority == "Medium" && it.isDone == false },
                                viewModel::onEvent
                            )
                        }
                    }
                    item {
                        Card(
                            modifier = Modifier.padding(8.dp),
                            elevation = 0.dp,
                            shape = RoundedCornerShape(8.dp),
                            backgroundColor = Color.Green.copy(alpha = 0.1f)
                        ) {
                            TodoSection(
                                "Low Priority", DeepGreen,
                                todos.value.filter { it.priority == "Low" && it.isDone == false },
                                viewModel::onEvent
                            )
                        }
                    }
                }

                item {
                    Spacer(modifier = Modifier.height(60.dp)) // Adjust height as needed
                }
            }
        )


    }
}

