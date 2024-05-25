package com.example.shopping_todo_list.ui.todo_list

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.shopping_todo_list.taskmanager.data.ToDo

@Composable
fun TodoSection(
    sectionTitle: String,
    color: Color,
    todosInSection: List<ToDo>,
    onEvent: (ToDoListEvent) -> Unit,

) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(bottom = 30.dp)
    ) {
        Text(
            text = sectionTitle,
            style = TextStyle(fontSize = 20.sp,fontWeight = FontWeight(600),
                textAlign = TextAlign.Right),
            modifier = Modifier.padding(top = 10.dp, bottom = 20.dp, start = 10.dp, end = 30.dp),
            color = color
        )


        Column {
            todosInSection.forEach { todo ->
                Box(
                    modifier = Modifier
                        .padding(top = 15.dp,start = 10.dp, end = 10.dp)
                        .clickable {
                            onEvent(ToDoListEvent.OnToDoClick(todo))
                        }
                        .background(Color.White)

                ) {
                    TodoItem(todo = todo, onEvent = onEvent)
                }
            }
        }
    }
}