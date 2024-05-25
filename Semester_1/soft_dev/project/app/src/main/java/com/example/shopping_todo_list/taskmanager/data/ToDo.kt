package com.example.shopping_todo_list.taskmanager.data

import android.net.Uri
import androidx.room.Entity
import androidx.room.PrimaryKey
import java.time.LocalDate
import java.time.LocalTime

@Entity
data class ToDo(
    @PrimaryKey val id: Int? = null,
    val title: String,
    val description: String? = null,
    val priority: String? = null,
    val isDone: Boolean? = false,
    val receiptPhoto: Uri? = null,
    val receiptDate: Int? = null,
    val moneySpent: Double? = null,
    val dueDate: LocalDate? = null,
    val dueTime: LocalTime? = null,
    val latitude: Double? = null,
    val longitude: Double? = null,
    val distance: Double? = null
)

