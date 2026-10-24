package dev.jamaah.app

import android.app.AlarmManager
import android.app.NotificationManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.PowerManager
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.TimeZone

/** Bounded native lifecycle history shared by the foreground and refresh engines. */
object NativeDiagnostics {
    private const val PREFS = "jamaah_diagnostics_native"
    private const val KEY_EVENTS = "events"
    private const val MAX_EVENTS = 300
    private val lock = Any()

    fun record(context: Context, event: String, values: Map<String, Any?> = emptyMap()) {
        synchronized(lock) {
            try {
                val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                val current = runCatching { JSONArray(prefs.getString(KEY_EVENTS, "[]")) }
                    .getOrElse { JSONArray() }
                val retained = (0 until current.length()).mapNotNull { i ->
                    current.optJSONObject(i)
                }.toMutableList()
                val timestamp = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
                    timeZone = TimeZone.getTimeZone("UTC")
                }.format(Date())
                val entry = JSONObject().put("at", timestamp).put("event", event)
                values.forEach { (key, value) -> if (value != null) entry.put(key, value) }
                retained.add(entry)
                while (retained.size > MAX_EVENTS) {
                    // Bulk registration is noisy. Keep receiver, service and
                    // playback evidence ahead of routine schedule bookkeeping.
                    val expendable = retained.indexOfFirst { !isLifecycle(it.optString("event")) }
                    retained.removeAt(if (expendable >= 0) expendable else 0)
                }
                val next = JSONArray()
                retained.forEach(next::put)
                prefs.edit().putString(KEY_EVENTS, next.toString()).apply()
            } catch (_: Exception) {
                // Diagnostics must never interrupt an alarm or audio playback.
            }
        }
    }

    private fun isLifecycle(event: String): Boolean =
        event.contains("receiver") || event.contains("service") ||
            event.contains("playback") || event.contains("audio_asset") ||
            event.contains("audio_route")

    fun events(context: Context): List<Map<String, Any?>> = synchronized(lock) {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY_EVENTS, "[]") ?: "[]"
        runCatching {
            val array = JSONArray(raw)
            (0 until array.length()).mapNotNull { i ->
                val item = array.optJSONObject(i) ?: return@mapNotNull null
                item.keys().asSequence().associateWith { key -> item.opt(key) }
            }
        }.getOrDefault(emptyList())
    }

    fun environment(context: Context): Map<String, Any?> {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val notifications = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
        val exact = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            mapOf("status" to if (alarms.canScheduleExactAlarms()) "granted" else "denied",
                "api" to "AlarmManager.canScheduleExactAlarms")
        } else mapOf("status" to "not_applicable", "api" to "AlarmManager.canScheduleExactAlarms")
        val postNotifications = if (Build.VERSION.SDK_INT >= 33) {
            if (context.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED)
                "granted" else "denied"
        } else "not_applicable"
        val requestedPermissions = runCatching {
            context.packageManager.getPackageInfo(context.packageName, PackageManager.GET_PERMISSIONS)
                .requestedPermissions?.toSet()
        }.getOrNull()
        val fullScreen = if (Build.VERSION.SDK_INT >= 34) {
            if (notifications.canUseFullScreenIntent()) "granted" else "denied"
        } else "not_applicable"
        val scheduleExactPermissionCheck = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (context.checkSelfPermission(android.Manifest.permission.SCHEDULE_EXACT_ALARM) == PackageManager.PERMISSION_GRANTED)
                "granted" else "denied"
        } else "not_applicable"
        val useExactPermissionCheck = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (context.checkSelfPermission("android.permission.USE_EXACT_ALARM") == PackageManager.PERMISSION_GRANTED)
                "granted" else "denied"
        } else "not_applicable"
        val channels = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            notifications.notificationChannels.map { channel ->
                mapOf(
                    "id" to channel.id,
                    "importance" to channel.importance,
                    "enabled" to (channel.importance != NotificationManager.IMPORTANCE_NONE),
                    "soundConfigured" to (channel.sound != null),
                    "vibrationEnabled" to channel.shouldVibrate(),
                )
            }
        } else emptyList()
        val zone = TimeZone.getDefault()
        return mapOf(
            "androidApiLevel" to Build.VERSION.SDK_INT,
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "androidVersion" to Build.VERSION.RELEASE,
            "osBuild" to Build.DISPLAY,
            "timezoneId" to zone.id,
            "utcOffsetMinutes" to (zone.getOffset(System.currentTimeMillis()) / 60_000),
            "notificationsEnabled" to notifications.areNotificationsEnabled(),
            "postNotificationsPermission" to postNotifications,
            "exactAlarmCapability" to exact,
            "scheduleExactAlarmManifestDeclaration" to permissionDeclaration(
                requestedPermissions,
                android.Manifest.permission.SCHEDULE_EXACT_ALARM,
            ),
            "scheduleExactAlarmCheckSelfPermission" to scheduleExactPermissionCheck,
            "useExactAlarmManifestDeclaration" to permissionDeclaration(
                requestedPermissions,
                "android.permission.USE_EXACT_ALARM",
            ),
            "useExactAlarmCheckSelfPermission" to useExactPermissionCheck,
            "fullScreenIntentCapability" to fullScreen,
            "batteryOptimizationExempt" to power.isIgnoringBatteryOptimizations(context.packageName),
            "channels" to channels,
        )
    }

    private fun permissionDeclaration(permissions: Set<String>?, permission: String): String =
        permissions?.let { if (permission in it) "declared" else "not_declared" } ?: "unknown"
}
