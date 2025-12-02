package com.example.viam_pixel4a_sensors

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import android.util.Log

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("ViamBootReceiver", "Boot received: ${intent?.action}")
        
        when (intent?.action) {
            Intent.ACTION_BOOT_COMPLETED,
            Intent.ACTION_MY_PACKAGE_REPLACED,
            Intent.ACTION_PACKAGE_REPLACED -> {
                // Start the main service
                val serviceIntent = Intent(context, ViamBackgroundService::class.java)
                serviceIntent.putExtra("auto_start", true)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context?.startForegroundService(serviceIntent)
                } else {
                    context?.startService(serviceIntent)
                }
                
                // Also start the main app
                val mainIntent = Intent(context, MainActivity::class.java)
                mainIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                context?.startActivity(mainIntent)
            }
        }
    }
}