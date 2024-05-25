package com.example.shopping_todo_list.ui.add_edit_todo

import android.Manifest.permission.ACCESS_BACKGROUND_LOCATION
import android.annotation.SuppressLint
import android.app.AlarmManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.core.app.ActivityCompat
import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.shopping_todo_list.broadcast_receivers.AlarmBroadcastReceiver
import com.example.shopping_todo_list.broadcast_receivers.GeofenceBroadcastReceiver
import com.example.shopping_todo_list.taskmanager.data.ToDo
import com.example.shopping_todo_list.taskmanager.data.ToDoRepository
import com.example.shopping_todo_list.util.UiEvent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofencingClient
import com.google.android.gms.location.GeofencingRequest
import com.google.android.gms.location.LocationServices
import dagger.hilt.android.lifecycle.HiltViewModel
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.util.Locale
import javax.inject.Inject


@HiltViewModel
class AddEditTodoViewModel @Inject constructor (
    private val repository: ToDoRepository,
    savedStateHandle: SavedStateHandle,
    @ApplicationContext private val appContext: Context

): ViewModel() {

    var todo by mutableStateOf<ToDo?>(null)
        private set

    var title by mutableStateOf("")
        private set

    var description by mutableStateOf("")
        private set

    var priority by mutableStateOf("")
        private set

    var isDone by mutableStateOf(false)
        private set

    var receiptPhoto by mutableStateOf<Uri?>(null)
        private set

    var receiptDate by mutableStateOf<Int?>(null)
        private set

    var moneySpent by mutableStateOf(0.0)
        private set
    var dueDate by mutableStateOf<LocalDate?>(null)
        private set
    var dueTime by mutableStateOf<LocalTime?>(null)
        private set
    var latitude by mutableStateOf(0.0)
        private set
    var longitude by mutableStateOf(0.0)
        private set
    var distance by mutableStateOf(100.0)
        private set

    var geofenceList: MutableList<Geofence> = mutableListOf()

    private val _uiEvent = Channel<UiEvent>()
    val uiEvent = _uiEvent.receiveAsFlow()


    init {
        val todoId = savedStateHandle.get<Int>("todoId")!!


        if (todoId != -1) {
            viewModelScope.launch {
                Log.d("todoId", todoId.toString())
                repository.getToDoById(todoId)?.let { todo ->
                    title = todo.title
                    description = todo.description ?: ""
                    priority = todo.priority ?: ""
                    isDone = todo.isDone ?: false
                    receiptPhoto = todo.receiptPhoto
                    receiptDate = todo.receiptDate
                    moneySpent = todo.moneySpent ?: 0.0
                    dueDate = todo.dueDate ?: null
                    dueTime = todo.dueTime ?: null
                    latitude = todo.latitude ?: 0.0
                    longitude = todo.longitude ?: 0.0
                    distance = todo.distance ?: 0.0
                }

            }

            this@AddEditTodoViewModel.todo = todo

        }

        if (todoId == -1) {
            val suggestionTitle = savedStateHandle.get<String>("title")!!
            val suggestionDescription = savedStateHandle.get<String>("description")!!
            viewModelScope.launch {

                this@AddEditTodoViewModel.title = suggestionTitle
                this@AddEditTodoViewModel.description = suggestionDescription

            }
        }

    }


    fun onEvent(event: AddEditToDoEvent) {
        when (event) {
            is AddEditToDoEvent.OnTitleChange -> {
                title = event.title
            }

            is AddEditToDoEvent.OnDescriptionChange -> {
                description = event.description
            }

            is AddEditToDoEvent.OnPriorityChange -> {
                priority = event.priority
            }

            is AddEditToDoEvent.OnIsDoneChange -> {
                isDone = event.isDone
            }

            is AddEditToDoEvent.OnReceiptPhotoChange -> {
                receiptPhoto = event.receiptPhoto
            }

            is AddEditToDoEvent.OnReceiptDateChange -> {
                receiptDate = event.receiptDate
            }

            is AddEditToDoEvent.OnMoneySpentChange -> {
                moneySpent = event.moneySpent
            }

            is AddEditToDoEvent.OnDueDateChange -> {
                dueDate = event.dueDate
            }

            is AddEditToDoEvent.OnDueTimeChange -> {
                dueTime = event.dueTime
            }

            is AddEditToDoEvent.OnLatitudeChange -> {
                latitude = event.latitude
            }

            is AddEditToDoEvent.OnLocationChange -> {
                longitude = event.longitude
                latitude = event.latitude
            }

            is AddEditToDoEvent.OnLongitudeChange -> {
                longitude = event.longitude
            }

            is AddEditToDoEvent.OnDistanceChange -> {
                distance = event.distance
            }

            is AddEditToDoEvent.OnSaveReceipt -> {
                viewModelScope.launch {
                    Log.d("on save", event.id.toString())
                    repository.saveReceipt(
                        event.id,
                        event.receiptPhoto,
                        event.receiptDate,
                        event.moneySpent
                    )
                    sendUiEvent(UiEvent.PopBackStack)
                }
            }

            is AddEditToDoEvent.OnSaveToDoClick -> {
                viewModelScope.launch {
                    if (title.isBlank()) {
                        sendUiEvent(
                            UiEvent.ShowSnackBar(
                                message = "Title cannot be empty"
                            )
                        )
                        return@launch
                    }
                    if (priority == "") {
                        priority = "Medium"
                    }

                    val todo = ToDo(
                        id = todo?.id,
                        title = title,
                        description = description,
                        isDone = todo?.isDone ?: false,
                        priority = priority,
                        receiptDate = receiptDate,
                        receiptPhoto = receiptPhoto,
                        moneySpent = moneySpent,
                        dueDate = dueDate,
                        dueTime = dueTime,
                        latitude = latitude,
                        longitude = longitude,
                        distance = distance
                    )
                    repository.insertTodo(todo)

                    if(dueDate != null && dueTime != null) {
                            scheduleToast(appContext, convertToMillis(dueDate!!, dueTime!!), requestCode = 33)
                    }


                    if (latitude != 0.0 && longitude != 0.0) {
                        setupGeofence(latitude, longitude, distance.toFloat())
                    }

                    sendUiEvent(UiEvent.PopBackStack)
                }
            }

            else -> {}
        }

    }


    private fun sendUiEvent(event: UiEvent) {
        viewModelScope.launch {
            _uiEvent.send(event)
        }
    }

    private fun setupGeofence(latitude: Double, longitude: Double, radius: Float) {
        val geofence = Geofence.Builder()
            .setRequestId("Geofence: ")
            .setCircularRegion(latitude, longitude, radius)
            .setExpirationDuration(Geofence.NEVER_EXPIRE)
            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER)
            .build()

        val geofencingRequest = GeofencingRequest.Builder().apply {
            setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            addGeofence(geofence)
        }.build()

        val geofencePendingIntent: PendingIntent by lazy {
            val intent = Intent(appContext, GeofenceBroadcastReceiver::class.java)

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                PendingIntent.getBroadcast(appContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
            } else {
                PendingIntent.getBroadcast(appContext, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
            }
        }

        val geofencingClient = LocationServices.getGeofencingClient(appContext)
        if (ActivityCompat.checkSelfPermission(
                appContext,
                ACCESS_BACKGROUND_LOCATION
            ) != PackageManager.PERMISSION_GRANTED
        ) {
            return
        }

        geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent).run {
            addOnSuccessListener {
                Log.d("Geofence", "added successfully")
            }
            addOnFailureListener {
                    exception ->
                Log.e("Geofence", "Failed to add geofence: ${exception.message}")
            }
        }
    }

    companion object {
        fun isValidCoordinates(latitude: Double, longitude: Double): Boolean {
            val validLatitude = (latitude >= -90.0) && (latitude <= 90.0)
            val validLongitude = (longitude >= -180.0) && (longitude <= 180.0)
            return validLatitude && validLongitude
        }
        fun convertToMillis(localDate: LocalDate, localTime: LocalTime): Long {
            val localDateTime = localDate.atTime(localTime)
            val zonedDateTime = localDateTime.atZone(ZoneId.systemDefault())
            return try {
                zonedDateTime.toInstant().toEpochMilli()
            } catch (e: Exception) {
                Log.d("Alarm", "Error - time set too far in future")
                0
            }
        }

        fun scheduleToast(context: Context, triggerTime: Long, requestCode: Int) {
            Log.d("AlarmToast", "In scheduled Toast")
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, AlarmBroadcastReceiver::class.java)

            // Specify FLAG_IMMUTABLE for PendingIntent
            val pendingIntent = PendingIntent.getBroadcast(context, requestCode, intent, PendingIntent.FLAG_IMMUTABLE)
            try {
                alarmManager.setExact(AlarmManager.RTC_WAKEUP, triggerTime, pendingIntent)
                Log.d("AlarmToast", "Alarm Set")
            } catch(e: SecurityException) {
                Log.d("AlarmToast", e.toString())
            }
        }

    }
}



