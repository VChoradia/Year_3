package com.example.shopping_todo_list.broadcast_receivers

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

class GeofenceBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent) {
        Log.d("Geofence", "Geofence triggered!")
        // This method is called when the BroadcastReceiver is receiving an Intent broadcast.
        Toast.makeText(context, "Geofence triggered! You're in the proximity of your desired location!", Toast.LENGTH_LONG).show()
    }
}
