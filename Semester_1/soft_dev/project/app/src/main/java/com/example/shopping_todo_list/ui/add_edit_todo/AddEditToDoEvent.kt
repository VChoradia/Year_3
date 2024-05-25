package com.example.shopping_todo_list.ui.add_edit_todo

import android.net.Uri
import java.time.LocalDate
import java.time.LocalTime

sealed class AddEditToDoEvent {

    data class OnTitleChange(val title: String): AddEditToDoEvent()
    data class OnDescriptionChange(val description: String): AddEditToDoEvent()
    data class OnPriorityChange(val priority: String): AddEditToDoEvent()
    data class OnIsDoneChange(val isDone: Boolean): AddEditToDoEvent()
    data class OnReceiptPhotoChange(val receiptPhoto: Uri): AddEditToDoEvent()
    data class OnReceiptDateChange(val receiptDate: Int): AddEditToDoEvent()
    data class OnMoneySpentChange(val moneySpent: Double): AddEditToDoEvent()
    data class OnLocationChange(val longitude: Double, val latitude: Double): AddEditToDoEvent()
    data class OnLongitudeChange(val longitude: Double): AddEditToDoEvent()
    data class OnLatitudeChange(val latitude: Double): AddEditToDoEvent()
    data class OnDistanceChange(val distance: Double): AddEditToDoEvent()
    data class OnDueTimeChange(val dueTime: LocalTime): AddEditToDoEvent()
    data class OnDueDateChange(val dueDate: LocalDate): AddEditToDoEvent()

    object OnSaveToDoClick: AddEditToDoEvent()
    data class OnSaveReceipt(val id: Int, val receiptPhoto: Uri?, val receiptDate: Int?, val moneySpent: Double?): AddEditToDoEvent()

}
