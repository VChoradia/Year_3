package com.example.shopping_todo_list.taskmanager.data

import androidx.room.Entity
import androidx.room.PrimaryKey

@Entity
data class Budget(
    @PrimaryKey val id: Int? = null,
    val budget: Double? = null
)
