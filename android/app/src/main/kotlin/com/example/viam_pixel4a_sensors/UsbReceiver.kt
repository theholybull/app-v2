package com.example.viam_pixel4a_sensors

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.hardware.usb.UsbDevice
import android.hardware.usb.UsbManager
import android.os.Build
import android.util.Log

class UsbReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        Log.d("ViamUsbReceiver", "USB event: ${intent?.action}")
        
        when (intent?.action) {
            UsbManager.ACTION_USB_DEVICE_ATTACHED -> {
                val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                Log.d("ViamUsbReceiver", "USB device attached: ${device?.deviceName}")
                
                // Start service to handle USB connection
                val serviceIntent = Intent(context, ViamBackgroundService::class.java)
                serviceIntent.putExtra("usb_attached", true)
                serviceIntent.putExtra("usb_device", device?.deviceName)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context?.startForegroundService(serviceIntent)
                } else {
                    context?.startService(serviceIntent)
                }
            }
            
            UsbManager.ACTION_USB_DEVICE_DETACHED -> {
                val device: UsbDevice? = intent.getParcelableExtra(UsbManager.EXTRA_DEVICE)
                Log.d("ViamUsbReceiver", "USB device detached: ${device?.deviceName}")
                
                // Notify service of USB disconnection
                val serviceIntent = Intent(context, ViamBackgroundService::class.java)
                serviceIntent.putExtra("usb_detached", true)
                serviceIntent.putExtra("usb_device", device?.deviceName)
                
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    context?.startForegroundService(serviceIntent)
                } else {
                    context?.startService(serviceIntent)
                }
            }
        }
    }
}