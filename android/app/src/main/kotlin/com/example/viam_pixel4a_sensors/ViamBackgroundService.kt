package com.example.viam_pixel4a_sensors

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.util.Log
import androidx.core.app.NotificationCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

class ViamBackgroundService : Service() {
    private var flutterEngine: FlutterEngine? = null
    private var methodChannel: MethodChannel? = null
    private val notificationId = 12345
    private val channelId = "viam_pixel4a_service"
    
    companion object {
        private const val TAG = "ViamBackgroundService"
        
        fun startService(context: Context) {
            val intent = Intent(context, ViamBackgroundService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
        
        fun stopService(context: Context) {
            val intent = Intent(context, ViamBackgroundService::class.java)
            context.stopService(intent)
        }
    }
    
    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Background service created")
        
        createNotificationChannel()
        startForeground(notificationId, createNotification())
        
        // Initialize Flutter engine for background processing
        initializeFlutter()
    }
    
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        Log.d(TAG, "Service started with intent: ${intent?.action}")
        
        when (intent?.action) {
            "USB_ATTACHED" -> {
                val deviceName = intent.getStringExtra("usb_device")
                Log.d(TAG, "USB device attached: $deviceName")
                handleUsbAttached(deviceName)
            }
            "USB_DETACHED" -> {
                val deviceName = intent.getStringExtra("usb_device")
                Log.d(TAG, "USB device detached: $deviceName")
                handleUsbDetached(deviceName)
            }
            "AUTO_START" -> {
                Log.d(TAG, "Auto-start triggered")
                handleAutoStart()
            }
        }
        
        // Return START_STICKY to ensure service restarts if killed
        return START_STICKY
    }
    
    override fun onBind(intent: Intent?): IBinder? {
        return null
    }
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                channelId,
                "Viam Pixel 4a Service",
                NotificationManager.IMPORTANCE_LOW
            ).apply {
                description = "Background service for Viam Pi connection"
                setShowBadge(false)
                enableLights(false)
                enableVibration(false)
            }
            
            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun createNotification(): Notification {
        val intent = Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this, 0, intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        return NotificationCompat.Builder(this, channelId)
            .setContentTitle("Viam Pi Connection")
            .setContentText("Connecting to Raspberry Pi...")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(pendingIntent)
            .setOngoing(true)
            .setSilent(true)
            .build()
    }
    
    private fun updateNotification(title: String, text: String) {
        val notification = NotificationCompat.Builder(this, channelId)
            .setContentTitle(title)
            .setContentText(text)
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setOngoing(true)
            .setSilent(true)
            .build()
        
        val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        notificationManager.notify(notificationId, notification)
    }
    
    private fun initializeFlutter() {
        try {
            flutterEngine = FlutterEngine(this)
            flutterEngine?.dartExecutor?.executeDartEntrypoint(
                DartExecutor.DartEntrypoint.createDefault()
            )
            
            flutterEngine?.let { engine ->
                   methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, "viam_background_service")
               }
            methodChannel?.setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateNotification" -> {
                        val title = call.argument<String>("title") ?: "Viam Pi Connection"
                        val text = call.argument<String>("text") ?: "Service running"
                        updateNotification(title, text)
                        result.success(true)
                    }
                    "getServiceStatus" -> {
                        result.success(mapOf(
                            "is_running" to true,
                            "flutter_engine" to (flutterEngine != null)
                        ))
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            }
            
            Log.d(TAG, "Flutter engine initialized for background service")
        } catch (e: Exception) {
            Log.e(TAG, "Error initializing Flutter: ${e.message}")
        }
    }
    
    private fun handleUsbAttached(deviceName: String?) {
        Log.d(TAG, "Handling USB attachment: $deviceName")
        
        // Notify Flutter side about USB connection
        methodChannel?.invokeMethod("usbAttached", mapOf(
            "device_name" to deviceName,
            "timestamp" to System.currentTimeMillis()
        ))
        
        updateNotification("Viam Pi Connection", "USB device connected: $deviceName")
    }
    
    private fun handleUsbDetached(deviceName: String?) {
        Log.d(TAG, "Handling USB detachment: $deviceName")
        
        // Notify Flutter side about USB disconnection
        methodChannel?.invokeMethod("usbDetached", mapOf(
            "device_name" to deviceName,
            "timestamp" to System.currentTimeMillis()
        ))
        
        updateNotification("Viam Pi Connection", "USB device disconnected: $deviceName")
    }
    
    private fun handleAutoStart() {
        Log.d(TAG, "Handling auto-start")
        
        // Notify Flutter side about auto-start
        methodChannel?.invokeMethod("autoStart", mapOf(
            "timestamp" to System.currentTimeMillis()
        ))
        
        updateNotification("Viam Pi Connection", "Auto-starting...")
    }
    
    override fun onDestroy() {
        Log.d(TAG, "Background service destroyed")
        
        flutterEngine?.destroy()
        flutterEngine = null
        methodChannel = null
        
        super.onDestroy()
    }
}