package com.moonnstar.moonnlove

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "moonnlove/game_detector"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getForegroundApp" -> {
                        val data = getForegroundApp()
                        result.success(data)
                    }
                    "hasUsagePermission" -> result.success(hasUsagePermission())
                    "openUsageSettings" -> {
                        openUsageSettings()
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun getForegroundApp(): Map<String, Any>? {
        if (!hasUsagePermission()) return null
        val usm = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val end = System.currentTimeMillis()
        val start = end - 10 * 60 * 1000
        val events = usm.queryEvents(start, end)
        var lastPackage: String? = null
        var lastTime = 0L
        val event = UsageEvents.Event()
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.MOVE_TO_FOREGROUND) {
                if (event.packageName != packageName) {
                    lastPackage = event.packageName
                    lastTime = event.timeStamp
                }
            }
        }
        if (lastPackage == null) return null
        return mapOf("package" to lastPackage, "since" to lastTime)
    }

    private fun hasUsagePermission(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.LOLLIPOP) return true
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = appOps.checkOpNoThrow(
            AppOpsManager.OPSTR_GET_USAGE_STATS,
            android.os.Process.myUid(),
            packageName
        )
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {
            try {
                val intent = Intent(Settings.ACTION_SETTINGS)
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
            } catch (_: Exception) {}
        }
    }
}
