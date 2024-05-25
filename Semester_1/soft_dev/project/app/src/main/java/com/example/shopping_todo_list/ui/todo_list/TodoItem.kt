package com.example.shopping_todo_list.ui.todo_list

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.Checkbox
import androidx.compose.material.Icon
import androidx.compose.material.IconButton
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Delete
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.shopping_todo_list.taskmanager.data.ToDo

@Composable
fun TodoItem(
    todo: ToDo,
    onEvent: (ToDoListEvent) -> Unit,
    modifier: Modifier = Modifier
){

    Row (
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ){
        Row (modifier = Modifier.fillMaxHeight(),

            verticalAlignment = Alignment.CenterVertically){
            Column(
                modifier = Modifier
                    .clip(RoundedCornerShape(0.dp))
                    .weight(0.9f)
                    .height(IntrinsicSize.Max), // Adding the border here

                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = todo.title,
                        modifier = Modifier
                            .padding(top = 12.dp, start = 12.dp, end = 30.dp)
                            .width(50.dp),
                        fontWeight = FontWeight.Bold
                    )

                    todo.description?.let {
                        Text(
                            text = it,
                            modifier = Modifier
                                .padding(
                                    top =12.dp,
                                    start = 12.dp
                                )
                                .width(150.dp),
                            color = Color.Gray

                        )
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(2.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Spacer(modifier = Modifier.weight(1f))
                        IconButton(
                            onClick = { onEvent(ToDoListEvent.OnDeleteToDoClick(todo)) }
                        ) {
                            Icon(imageVector = Icons.Default.Delete, contentDescription = "Delete")
                        }

                        Checkbox(
                            checked = todo.isDone == true,
                            onCheckedChange = { isChecked ->
                                onEvent(ToDoListEvent.OnDoneChange(todo, isChecked))
                            }
                        )
                    }
                }
            }
        }
    }
}
