package com.example.shopping_todo_list.ui.budget_page

import android.annotation.SuppressLint
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.BottomNavigation
import androidx.compose.material.BottomNavigationItem
import androidx.compose.material.Button
import androidx.compose.material.Icon
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Scaffold
import androidx.compose.material.Text
import androidx.compose.material.TextField
import androidx.compose.material.TextFieldDefaults
import androidx.compose.material.TopAppBar
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.AccountBalanceWallet
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.rememberScaffoldState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shopping_todo_list.ui.theme.Shapes
import com.example.shopping_todo_list.util.UiEvent
import kotlin.math.absoluteValue
import com.example.shopping_todo_list.ui.theme.Blue1 as Blue1


@SuppressLint("UnusedMaterialScaffoldPaddingParameter")
@Composable
fun BudgetPage(
    onNavigate: (UiEvent.Navigate) -> Unit,
    viewModel: BudgetPageViewModel = hiltViewModel()
) {
    var budget = viewModel.currBudget
    val scaffoldState = rememberScaffoldState()

    val currentBudget = viewModel.current.value.toDoubleOrNull() ?: 0.0
    val totalMoneySpent = viewModel.totalMoneySpentInCurrentMonth.value

    var balance = currentBudget - totalMoneySpent
    var status = ""

    status = if (balance > 0){
        "under"
    }
    else if (balance  < 0) {
        "over"
    } else {
        "equal to"
    }

    balance = balance.absoluteValue



    val current by viewModel.current

    LaunchedEffect(key1 = true) {
        viewModel.uiEvent.collect {event ->
            when(event) {
                is UiEvent.Navigate -> onNavigate(event)
                is UiEvent.ShowSnackBar -> {
                    scaffoldState.snackbarHostState.showSnackbar(
                        message = event.message,
                        actionLabel = event.action
                    )
                }
                else-> Unit
            }

        }
    }

    Scaffold(
        scaffoldState = scaffoldState,
        modifier = Modifier.fillMaxSize(),


        bottomBar = {
            BottomNavigation {

                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = {
                        Icon(imageVector = Icons.Default.Home,
                            contentDescription = "Home",
                            modifier = Modifier.size(32.dp)) },
                    label = { Text("Home") },
                    selected = false,
                    onClick = {viewModel.onEvent(BudgetEvent.OnHomePageClick)}
                )
                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = {
                        Icon(imageVector = Icons.Default.AccountBalanceWallet,
                            contentDescription = "Wallet",
                            modifier = Modifier.size(32.dp)) },
                    label = { Text("Budget") },
                    selected = false,
                    onClick = {viewModel.onEvent(BudgetEvent.OnBudgetClick)}
                )
                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = {
                        Icon(imageVector = Icons.Default.Check,
                            contentDescription = "Completed",
                            modifier = Modifier.size(32.dp)) },
                    label = { Text("Tasks") },
                    selected = false,
                    onClick = {viewModel.onEvent(BudgetEvent.OnCompletedPageClick)}
                )
                BottomNavigationItem(
                    modifier = Modifier.height(90.dp),
                    icon = {
                        Icon(imageVector = Icons.Default.Add,
                            contentDescription = "Add",
                            modifier = Modifier.size(32.dp)) },
                    label = { Text("Add Task") },
                    selected = false,
                    onClick = {viewModel.onEvent(BudgetEvent.OnAddTodoClick)}
                )
            }
        }

    ){
        Column(
        modifier = Modifier.fillMaxSize()
        ) {
            TopAppBar(
                backgroundColor = Blue1,
                contentColor = MaterialTheme.colors.onPrimary
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.Center
                ) {
                    Text(
                        "Monthly Budget: ${viewModel.current.value}",
                        style = TextStyle(
                            fontWeight = FontWeight.Bold,
                            fontSize = 25.sp
                        )
                    )
                }
            }
        }
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(top = 60.dp, start = 8.dp, end = 8.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {

            var isError by remember { mutableStateOf(false) }
            var submitMessage by remember { mutableStateOf("") }

            Spacer(modifier = Modifier.height(15.dp))
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center,
                modifier = Modifier.width(400.dp)
            ) {

                Text("£", style = TextStyle(fontSize = 35.sp))
                Spacer(modifier = Modifier.width(8.dp))

                TextField(
                    value = viewModel.currBudget,
                    shape = Shapes.small,
                    onValueChange = {
                            viewModel.onEvent(BudgetEvent.OnBudgetChange(it))
                    },
                    modifier = Modifier.width(200.dp),
                    colors = TextFieldDefaults.textFieldColors(
                        textColor = Color.Gray,
                        disabledTextColor = Color.Transparent,
                        focusedIndicatorColor = Color.Transparent,
                        unfocusedIndicatorColor = Color.Transparent,
                        disabledIndicatorColor = Color.Transparent
                    ),
                    keyboardOptions = KeyboardOptions.Default.copy(
                        keyboardType = KeyboardType.Number
                    ),
                    isError = isError,
                    placeholder = {
                        if (isError) {
                            Text("Invalid Input", color = Color.Red)
                        } else {
                            Text("0.00")
                        }
                    },
                )
            }

            Spacer(modifier = Modifier.width(8.dp))

            Button(onClick = {
                viewModel.onEvent(BudgetEvent.SetBudget(budget.toDouble()))

//                if (!isError) {
//                    submitMessage = "Amount submitted: £$budget"
//                }
            }) {
                Text("Submit")
            }

            // Spacer to separate the TextField and Submit Message
            Spacer(modifier = Modifier.height(16.dp))

            // Submit Message
            if (submitMessage.isNotEmpty()) {
                Text(submitMessage)
            }


        }
        BudgetGraph()

        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(bottom = 70.dp),
            contentAlignment = Alignment.BottomCenter,
        ) {
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(10.dp))
//                    .border(border = BorderStroke(width = 1.dp, color = Blue1))
                    .padding(16.dp)
            ) {
                Column {
                    Text(
                        text = "Monthly Spending: £${viewModel.totalMoneySpentInCurrentMonth.value}",
                        style = MaterialTheme.typography.h6,
                        fontWeight = FontWeight.Medium,
                    )
                    Text(
                        text = "£${balance} $status budget",
                        style = MaterialTheme.typography.h6,
                        fontWeight = FontWeight.Medium,
                        color = Blue1
                    )
                }
            }
        }
    }
}


// Function to check if a string is a valid decimal number
private fun isValidDecimal(value: String): Boolean {
    return value.toDoubleOrNull() != null
}


