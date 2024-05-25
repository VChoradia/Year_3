package com.example.shopping_todo_list.ui.receipt_page

import android.annotation.SuppressLint
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.Button
import androidx.compose.material.MaterialTheme
import androidx.compose.material.Text
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Check
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.shopping_todo_list.ui.add_edit_todo.AddEditToDoEvent
import com.example.shopping_todo_list.ui.add_edit_todo.AddEditTodoViewModel
import com.example.shopping_todo_list.util.UiEvent
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import java.io.InputStream
import java.util.Calendar

@SuppressLint("UnusedMaterialScaffoldPaddingParameter")
@Composable
fun ReceiptPage(
    taskId: Int, onPopBackStack: () -> Unit,
    viewModel: AddEditTodoViewModel = hiltViewModel()
) {
    val scaffoldState = rememberScaffoldState()
    var imageBitmap by remember { mutableStateOf<ImageBitmap?>(null) }
    var permGranted by remember { mutableStateOf(false) }

    LaunchedEffect(key1 = true) {
        viewModel.uiEvent.collect { event ->
            when (event) {
                is UiEvent.PopBackStack -> onPopBackStack()
                is UiEvent.ShowSnackBar -> {
                    scaffoldState.snackbarHostState.showSnackbar(
                        message = event.message,
                        actionLabel = event.action)}
                else -> Unit
            }
        }
    }

    val requestPermissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { isGranted ->
        if (isGranted) {
            permGranted = true
        }
    }
    DisposableEffect(Unit) {
        requestPermissionLauncher.launch(android.Manifest.permission.READ_EXTERNAL_STORAGE)
        onDispose { /* cleanup code if needed */ }
    }
    val context = LocalContext.current
    val launcher =
        rememberLauncherForActivityResult(contract = ActivityResultContracts.GetContent()) {
                uri: Uri? ->
            uri?.let {
                viewModel.onEvent((AddEditToDoEvent.OnReceiptPhotoChange(uri)))
                val inputStream: InputStream? = context.contentResolver.openInputStream(uri)
                inputStream?.use { stream ->
                    val bitmap = BitmapFactory.decodeStream(stream)
                    imageBitmap = bitmap.asImageBitmap()
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
                viewModel.onEvent(
                    AddEditToDoEvent.OnSaveReceipt(
                        taskId,
                        viewModel.receiptPhoto,
                        viewModel.receiptDate,
                        viewModel.moneySpent
                    )
                )
            }) {
                Icon(
                    imageVector = Icons.Default.Check,
                    contentDescription = "Save "
                )

            }
        }
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Task Completed!",
                style = MaterialTheme.typography.h4,
                fontSize = 24.sp,
                modifier = Modifier.padding(bottom = 16.dp)
            )

            if (permGranted) {
                // Button to launch image selection
                Button(
                    onClick = { launcher.launch("image/*") }, // Specify the MIME type you want to allow
                    modifier = Modifier
                        .padding(bottom = 16.dp)
                        .height(56.dp)
                        .fillMaxWidth()
                ) {
                    Text("Upload Receipt")
                }
            } else {
                // Button to request permissions
                Button(
                    onClick = {
                        requestPermissionLauncher.launch(android.Manifest.permission.READ_EXTERNAL_STORAGE)
                    },
                    modifier = Modifier
                        .padding(bottom = 16.dp)
                        .height(56.dp)
                        .fillMaxWidth()
                ) {
                    Text("Enable permissions in the settings to upload a receipt photo")
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            // Display the selected image
            imageBitmap?.let {
                Image(
                    bitmap = it,
                    contentDescription = "Selected Image",
                    modifier = Modifier
                        .size(120.dp)
                        .padding(8.dp)
                        .wrapContentSize(align = Alignment.TopStart)
                )
            }

            Text(text = "Enter Spendings:")

            OutlinedTextField(
                value = viewModel.moneySpent.toString(),
                onValueChange = {
                    val calendar = Calendar.getInstance().get(Calendar.MONTH)
                    viewModel.onEvent(AddEditToDoEvent.OnMoneySpentChange(it.toDouble()))
                    viewModel.onEvent(AddEditToDoEvent.OnReceiptDateChange(calendar + 1))
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 8.dp)
            )

        }
    }
}
