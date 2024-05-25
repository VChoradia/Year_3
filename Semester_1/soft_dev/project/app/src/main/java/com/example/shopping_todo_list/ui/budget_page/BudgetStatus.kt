package com.example.shopping_todo_list.ui.budget_page

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.example.shopping_todo_list.ui.theme.Blue1

@Composable
fun BudgetStatus() {
    return Box(
        modifier = Modifier
            .fillMaxSize()
            .padding(bottom = 50.dp),
        contentAlignment = Alignment.BottomCenter,
    ) {
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .border(border = BorderStroke(width = 1.dp, color = Blue1))
                .padding(16.dp)
        ) {
            Column {
                Text(
                    text = "Amount spent £10",
                    style = MaterialTheme.typography.h6,
                    fontWeight = FontWeight.Medium,
                )
                Text(
                    text = "£10 over budget",
                    style = MaterialTheme.typography.h6,
                    fontWeight = FontWeight.Medium,
                    color = Blue1
                )
            }
        }
    }
}
