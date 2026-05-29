package com.bedbreaker.bedbreaker

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.Service
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import androidx.core.app.NotificationCompat
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

// Starts a headless Flutter engine on boot to reschedule alarms from Hive.
// Stops itself when Dart signals completion, or after 30 seconds as a fallback.
class RescheduleService : Service() {

    private var engine: FlutterEngine? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForegroundCompat()
        rescheduleViaFlutter()
        handler.postDelayed({ stopSelf() }, 30_000)
        return START_NOT_STICKY
    }

    private fun startForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val nm = getSystemService(NotificationManager::class.java)
            nm.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID, "BedBreaker System",
                    NotificationManager.IMPORTANCE_LOW
                ).apply { setShowBadge(false) }
            )
        }
        val notif = NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle("BedBreaker")
            .setContentText("Restoring alarms after restart…")
            .setSmallIcon(R.mipmap.ic_launcher)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setSilent(true)
            .build()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(NOTIF_ID, notif, ServiceInfo.FOREGROUND_SERVICE_TYPE_SHORT_SERVICE)
        } else {
            startForeground(NOTIF_ID, notif)
        }
    }

    private fun rescheduleViaFlutter() {
        val loader = FlutterInjector.instance().flutterLoader()
        if (!loader.initialized()) loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)

        val e = FlutterEngine(applicationContext)
        engine = e

        MethodChannel(e.dartExecutor.binaryMessenger, DART_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "done") {
                    result.success(null)
                    stopSelf()
                }
            }

        e.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "alarmBootCallback")
        )
    }

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onDestroy() {
        handler.removeCallbacksAndMessages(null)
        engine?.destroy()
        engine = null
        super.onDestroy()
    }

    companion object {
        private const val CHANNEL_ID = "bedbreaker_boot"
        private const val DART_CHANNEL = "bedbreaker/boot"
        private const val NOTIF_ID = 8001
    }
}
