package com.example.shopping_todo_list.ui.add_edit_todo

import android.Manifest
import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Check
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shopping_todo_list.util.UiEvent
import com.vanpra.composematerialdialogs.MaterialDialog
import com.vanpra.composematerialdialogs.datetime.date.datepicker
import com.vanpra.composematerialdialogs.datetime.time.timepicker
import com.vanpra.composematerialdialogs.rememberMaterialDialogState
import java.time.LocalDate
import java.time.LocalTime


@SuppressLint("UnusedMaterialScaffoldPaddingParameter")
@Composable
fun AddEditToDoScreen(
     onPopBackStack: () -> Unit,
     viewModel: AddEditTodoViewModel = hiltViewModel()
) {
     var selectedDate by remember { mutableStateOf(LocalDate.MAX) }
     var selectedTime by remember { mutableStateOf(LocalTime.NOON) }
     var permGranted by remember { mutableStateOf(false) }
     var alarmPermGranted by remember { mutableStateOf(false)}
     val scaffoldState = rememberScaffoldState()
     val timeDialogState = rememberMaterialDialogState()
     val dateDialogState = rememberMaterialDialogState()
     var showError by remember { mutableStateOf(false) }


     val requestPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
          if (isGranted) {
               permGranted = true
          }
     }

     val requestAlarmPermissionLauncher = rememberLauncherForActivityResult(ActivityResultContracts.RequestPermission()) { isGranted ->
          if (isGranted) {
               alarmPermGranted = true
          }
     }

     LaunchedEffect(key1 = true) {
          viewModel.uiEvent.collect { event ->
               when (event) {
                    is UiEvent.PopBackStack -> onPopBackStack()
                    is UiEvent.ShowSnackBar -> {
                         scaffoldState.snackbarHostState.showSnackbar(
                              message = event.message,
                              actionLabel = event.action
                         )
                    }

                    else -> Unit
               }

          }
     }


     Scaffold(
          scaffoldState = scaffoldState,
          modifier = Modifier
               .fillMaxSize()
               .padding(16.dp),
          floatingActionButton = {
               FloatingActionButton(onClick = {
                    if (AddEditTodoViewModel.isValidCoordinates(viewModel.latitude, viewModel.longitude) && viewModel.distance >= 50.0) {
                         showError = false
                         viewModel.onEvent(AddEditToDoEvent.OnSaveToDoClick)
                    } else {
                         showError = true
                    }
               }) {
                    Icon(imageVector = Icons.Default.Check, contentDescription = "Save")
               }
          }

     ) {

//          var showDialog by remember { mutableStateOf(false) }

          Column(
               modifier = Modifier.fillMaxSize()
          ) {
               OutlinedTextField(
                    value = viewModel.title, onValueChange = {
                         viewModel.onEvent(AddEditToDoEvent.OnTitleChange(it))
                    },
                    label = {
                         Text(text = "Title")
                    },
                    modifier = Modifier
                         .fillMaxWidth()
                         .padding(vertical = 8.dp)
               )

               Spacer(modifier = Modifier.height(8.dp))

               OutlinedTextField(
                    value = viewModel.description, onValueChange = {
                         viewModel.onEvent(AddEditToDoEvent.OnDescriptionChange(it))
                    },
                    label = {
                         Text(text = "Description")

                    },
                    modifier = Modifier
                         .fillMaxWidth()
                         .padding(vertical = 8.dp)
                         .height(120.dp)
               )
               Spacer(modifier = Modifier.height(8.dp))

               val priorities = listOf("High", "Medium", "Low")
               var expanded by remember { mutableStateOf(false) }
               var selectedPriority by remember { mutableStateOf(viewModel.priority) }

               Box {
                    OutlinedTextField(
                         value = viewModel.priority,
                         onValueChange = {
                              viewModel.onEvent(AddEditToDoEvent.OnPriorityChange(it))
                              selectedPriority = it

                         },
                         placeholder = {
                              Text(text = "Priority")
                         },
                         singleLine = false,
                         modifier = Modifier
                              .fillMaxWidth()
                              .padding(vertical = 8.dp)
                              .height(55.dp)
                              .onFocusChanged {
                                   expanded = it.isFocused
                              },
                         trailingIcon = { // Add this to your OutlinedTextField
                              Icon(
                                   imageVector = Icons.Filled.ArrowDropDown, // This is the arrow icon
                                   contentDescription = "Dropdown Icon"
                              )
                         }
                    )

                    DropdownMenu(
                         expanded = expanded,
                         onDismissRequest = { expanded = false },
                         modifier = Modifier
                              .fillMaxWidth()
                              .align(Alignment.BottomStart)
                    ) {
                         priorities.forEach { priority ->
                              DropdownMenuItem(onClick = {
                                   viewModel.onEvent(AddEditToDoEvent.OnPriorityChange(priority))
                                   selectedPriority = priority
                                   expanded = false
                              }) {
                                   Text(text = priority)
                              }
                         }
                    }

               }


               if(permGranted) {
                    Row {
                         OutlinedTextField(
                              value = if (viewModel.latitude != 0.0 || viewModel.longitude != 0.0) "${viewModel.latitude}, ${viewModel.longitude}" else "",
                              onValueChange = {
                                   val inputValues = it.split(",")
                                   val latitude =
                                        inputValues[0].takeIf { it.isNotBlank() }?.toDoubleOrNull()
                                             ?: 0.0
                                   val longitude =
                                        inputValues.getOrNull(1)?.trim()?.toDoubleOrNull() ?: 0.0
                                   viewModel.onEvent(AddEditToDoEvent.OnLatitudeChange(latitude))
                                   viewModel.onEvent(AddEditToDoEvent.OnLongitudeChange(longitude))
                              },
                              placeholder = {
                                   Text(text = "Latitude, Longitude")
                              },
                              modifier = Modifier
                                   .padding(vertical = 8.dp)
                                   .height(55.dp)
                                   .width(300.dp)
                         )
                    }

                    OutlinedTextField(
                         value = viewModel.distance.toString(),
                         onValueChange = { newDistance: String ->
                              viewModel.onEvent(AddEditToDoEvent.OnDistanceChange(newDistance.toDouble()))
                         },
                         label = { Text("Distance (in Metre Radius)") },
                         modifier = Modifier
                              .fillMaxWidth()
                              .padding(vertical = 8.dp)
                    )
               } else {
                    Button(onClick = {   requestPermissionLauncher.launch(Manifest.permission.ACCESS_COARSE_LOCATION)
                         requestPermissionLauncher.launch(Manifest.permission.ACCESS_FINE_LOCATION)

                    }) {
                         Text("Click here to enable location")
                    }
               }

               val context = LocalContext.current

               if(alarmPermGranted) {
                    Column(
                         horizontalAlignment = Alignment.CenterHorizontally,
                         verticalArrangement = Arrangement.Center
                    ) {
                         Button(onClick = {
                              dateDialogState.show()
                         }) {
                              Text(text = "Pick date")
                         }
                         if (viewModel.dueDate != null) {
                              Text(text = viewModel.dueDate.toString())
                         } else {
                              Text(text = "")
                         }


                         Button(onClick = {
                              timeDialogState.show()
                         }) {
                              Text(text = "Pick time")
                         }
                         if (viewModel.dueTime != null) {
                              Text(text = viewModel.dueTime.toString())
                         } else {
                              Text(text = "")
                         }



                         MaterialDialog(
                              dialogState = dateDialogState,
                              buttons = {
                                   positiveButton(text = "Ok") {
                                        Toast.makeText(
                                             context,
                                             "Clicked ok",
                                             Toast.LENGTH_LONG
                                        ).show()
                                   }
                                   negativeButton(text = "Cancel")
                              }
                         ) {
                              datepicker(
                                   initialDate = LocalDate.now(),
                                   title = "Pick a date",
                              ) {
                                   selectedDate = it
                                   viewModel.onEvent(AddEditToDoEvent.OnDueDateChange(it))
                              }
                         }

                         MaterialDialog(
                              dialogState = timeDialogState,
                              buttons = {
                                   positiveButton(text = "Ok") {
                                        Toast.makeText(
                                             context,
                                             "Clicked ok",
                                             Toast.LENGTH_LONG
                                        ).show()
                                   }
                                   negativeButton(text = "Cancel")
                              }
                         ) {
                              timepicker(
                                   initialTime = viewModel.dueTime ?: LocalTime.MIDNIGHT,
                                   title = "Pick a time",
                                   timeRange = LocalTime.MIDNIGHT..LocalTime.MAX
                              ) {
                                   selectedTime = it
                                   viewModel.onEvent(AddEditToDoEvent.OnDueTimeChange(it))
                              }
                         }
                    }
               } else {
                    Button(onClick = {
                         requestAlarmPermissionLauncher.launch(Manifest.permission.SCHEDULE_EXACT_ALARM)
                    }) {
                         Text("Click here to enable permission to schedule alarm")
                    }
               }


               if (showError) {
                    Text("Invalid coordinates or distance. Please enter valid latitude and longitude and distance (minimum distance - 50.0).", color = Color.Red)
               }

               if (viewModel.isDone) {
                    OutlinedTextField(
                         value = viewModel.moneySpent.toString(), onValueChange = {
                              viewModel.onEvent(AddEditToDoEvent.OnMoneySpentChange(it.toDouble()))
                         },
                         label = {
                              Text(text = "Spendings")
                         },
                         modifier = Modifier
                              .fillMaxWidth()
                              .padding(vertical = 8.dp)
                    )

                    OutlinedTextField(
                         value = (viewModel.receiptDate).toString(),
                         onValueChange = {
                              val inputValue = it.toIntOrNull()
                              if (inputValue != null && inputValue in 1..12) {
                                   viewModel.onEvent(AddEditToDoEvent.OnReceiptDateChange((inputValue)))
                              } else if (inputValue == null) {
                                   viewModel.onEvent(AddEditToDoEvent.OnReceiptDateChange(0))
                              } else if (inputValue % 10 == 0) {
                                   viewModel.onEvent(AddEditToDoEvent.OnReceiptDateChange((inputValue / 10)))
                              }
                         },
                         label = {
                              Text(text = "Month Of Purchase")
                         },
                         modifier = Modifier
                              .fillMaxWidth()
                              .padding(vertical = 8.dp)
                    )



                    val imageUri = viewModel.receiptPhoto


                    if (imageUri != null) {
                         val inputStream = context.contentResolver.openInputStream(imageUri)
                         if (inputStream != null) {
                              val bitmap = BitmapFactory.decodeStream(inputStream)
                              Image(
                                   bitmap = bitmap.asImageBitmap(),
                                   contentDescription = "Displayed Image"
                              )
                         }
                    }

               }
          }
     }
}

