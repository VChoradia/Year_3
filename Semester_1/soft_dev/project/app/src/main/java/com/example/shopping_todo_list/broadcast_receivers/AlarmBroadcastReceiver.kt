package com.example.shopping_todo_list.broadcast_receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class AlarmBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Log.d("Alarm Received", "DAMMNNN")
        Toast.makeText(context, "Reminder: tesco meal deal", Toast.LENGTH_LONG).show()
    }
}