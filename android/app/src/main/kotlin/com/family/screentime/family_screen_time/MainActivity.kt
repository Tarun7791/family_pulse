package com.family.screentime.family_screen_time

import android.app.AppOpsManager
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Process
import android.provider.Settings
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.*

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.family.screentime/usage"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            try {
                when (call.method) {
                    "checkUsagePermission" -> {
                        result.success(checkUsagePermission())
                    }
                    "openUsageSettings" -> {
                        openUsageSettings()
                        result.success(null)
                    }
                    "getScreenTime" -> {
                        result.success(getTodayScreenTime())
                    }
                    "getAppUsageBreakdown" -> {
                        result.success(getAppUsageBreakdown())
                    }
                    else -> {
                        result.notImplemented()
                    }
                }
            } catch (e: Exception) {
                result.error("NATIVE_ERROR", e.message, null)
            }
        }
    }

    private fun checkUsagePermission(): Boolean {
        val appOps = getSystemService(Context.APP_OPS_SERVICE) as AppOpsManager
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        } else {
            appOps.checkOpNoThrow(AppOpsManager.OPSTR_GET_USAGE_STATS, Process.myUid(), packageName)
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    private fun openUsageSettings() {
        val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
        startActivity(intent)
    }

    private fun getTodayScreenTime(): Int {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        // queryAndAggregateUsageStats is more robust as it combines overlapping buckets
        val statsMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        var totalTime: Long = 0
        
        for (usageStats in statsMap.values) {
            totalTime += usageStats.totalTimeInForeground
        }

        val totalMinutes = (totalTime / (1000 * 60)).toInt()
        android.util.Log.d("UsageStats", "Total Screen Time Calculated: $totalMinutes min (Raw ms: $totalTime)")
        return totalMinutes
    }

    private fun getAppUsageBreakdown(): List<Map<String, Any>> {
        val usageStatsManager = getSystemService(Context.USAGE_STATS_SERVICE) as UsageStatsManager
        val calendar = Calendar.getInstance()
        calendar.set(Calendar.HOUR_OF_DAY, 0)
        calendar.set(Calendar.MINUTE, 0)
        calendar.set(Calendar.SECOND, 0)
        calendar.set(Calendar.MILLISECOND, 0)
        val startTime = calendar.timeInMillis
        val endTime = System.currentTimeMillis()

        val statsMap = usageStatsManager.queryAndAggregateUsageStats(startTime, endTime)
        val breakdown = mutableListOf<Map<String, Any>>()
        
        // Convert map to list and filter/sort
        val sortedStats = statsMap.values
            .filter { it.totalTimeInForeground > 0 }
            .sortedByDescending { it.totalTimeInForeground }
            .take(10) // Take top 10 for better variety

        for (usageStats in sortedStats) {
            val appMap = mutableMapOf<String, Any>()
            val packageName = usageStats.packageName
            
            // Extract a readable name
            val label = packageName.split(".").last()
                .replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() }
            
            appMap["appName"] = label
            appMap["minutes"] = (usageStats.totalTimeInForeground / (1000 * 60)).toInt()
            breakdown.add(appMap)
        }
        return breakdown
    }
}
