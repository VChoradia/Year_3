package com.example.shopping_todo_list.ui.add_edit_todo

import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.material.OutlinedTextField
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import com.example.shopping_todo_list.ui.theme.Shopping_todo_listTheme
import androidx.compose.ui.platform.LocalContext
import androidx.compose.material.Button
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Surface
import androidx.compose.material.Text
import androidx.compose.ui.Modifier
import androidx.compose.ui.tooling.preview.Preview
import java.util.Calendar
import android.app.DatePickerDialog
import android.content.Context
import android.widget.DatePicker
@Composable
fun Create() {
    Surface(
        modifier = Modifier.fillMaxSize(),
        color = MaterialTheme.colors.background
    ) {
        Column(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth()
        ) {
            // Reusing the text fields from the View function
            TextFields(LocalContext.current)

            // Additional Create-specific content if needed
        }
    }
}


@Composable
fun TextFields(context: Context){
    // Reusable set of text fields
    var text by remember { mutableStateOf("") }
    OutlinedTextField (
        value = text,
        label = { Text(text = "Title") },
        onValueChange = { newText -> text = newText },
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    )

    var descriptionText by remember { mutableStateOf("") }
    OutlinedTextField (
        value = descriptionText,
        label = { Text(text = "Description") },
        onValueChange = { newValue -> descriptionText = newValue },
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .height(120.dp)
    )

    var locationText by remember { mutableStateOf("") }
    OutlinedTextField(
        value = locationText,
        label = { Text(text = "Location") },
        onValueChange = { newValue -> locationText = newValue },
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
    )
    var priorityText by remember { mutableStateOf("") }
    OutlinedTextField(
        value = priorityText,
        label = { Text(text = "Priority") },
        onValueChange = { newValue -> priorityText = newValue },
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .height(50.dp)
    )
    var selectedDate by remember { mutableStateOf(Calendar.getInstance()) }
    val context = LocalContext.current

    OutlinedTextField(
        value = "${selectedDate.get(Calendar.DAY_OF_MONTH)}/${selectedDate.get(Calendar.MONTH) + 1}/${selectedDate.get(Calendar.YEAR)}",
        onValueChange = {},
        label = { Text("Date") },
        modifier = Modifier.fillMaxWidth()
    )

    Spacer(modifier = Modifier.height(8.dp))

    Button(onClick = {
        val datePicker = DatePickerDialog(
            context,
            { _: DatePicker, year: Int, month: Int, dayOfMonth: Int ->
                selectedDate.set(year, month, dayOfMonth)
            },
            selectedDate.get(Calendar.YEAR),
            selectedDate.get(Calendar.MONTH),
            selectedDate.get(Calendar.DAY_OF_MONTH)
        )
        datePicker.show()
    }) {
        Text("Select Date")
    }
}




@Preview(showBackground = true)
@Composable
fun PreviewCreateScreen() {
    Shopping_todo_listTheme {
        Create()
    }
}