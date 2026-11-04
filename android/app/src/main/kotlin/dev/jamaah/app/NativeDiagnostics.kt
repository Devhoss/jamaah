package dev.jamaah.app

import android.app.AlarmManager
import android.app.Notification
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
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/** Bounded native lifecycle history shared by the foreground and refresh engines. */
object NativeDiagnostics {
    private const val PREFS = "jamaah_diagnostics_native"
    private const val KEY_EVENTS = "events"
    // Compresses a record burst (a fired adhan emits ~18 events within ~150 ms)
    // into one buffer write instead of a full-history rewrite per event.
    private const val PERSIST_DELAY_MS = 250L
    private val lock = Any()
    private val history = DiagnosticHistory(maxEvents = NativeEventRetention.MAX_EVENTS)
    private var loaded = false
    private var persistPending = false
    private val persistExecutor = Executors.newSingleThreadScheduledExecutor { runnable ->
        Thread(runnable, "jamaah-diagnostics-persist").apply { isDaemon = true }
    }
    private val timestampFormat: SimpleDateFormat by lazy {
        SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'", Locale.US).apply {
            timeZone = TimeZone.getTimeZone("UTC")
        }
    }

    fun record(context: Context, event: String, values: Map<String, Any?> = emptyMap()) {
        // Stamped before the lock: a record whose turn comes late would otherwise
        // inherit the queue's time and smear the whole receiver chain onto one
        // timestamp (2026-10-30). [recordLockWaitMs] shows the wait when it was
        // long enough to matter.
        val wallSoonest = Date()
        val lockEntered = System.nanoTime()
        try {
            synchronized(lock) {
                ensureHistoryLoaded(context)
                val lockWaitMs = ((System.nanoTime() - lockEntered) / 1_000_000).toInt()
                history.append(
                    at = timestampFormat.format(wallSoonest),
                    event = event,
                    lockWaitMs = if (lockWaitMs >= 100) lockWaitMs else null,
                    values = values,
                )
                schedulePersistLocked(context)
            }
        } catch (_: Exception) {
            // Diagnostics must never interrupt an alarm or audio playback.
        }
    }

    fun events(context: Context): List<Map<String, Any?>> = synchronized(lock) {
        ensureHistoryLoaded(context)
        history.all()
    }

    /** Loads the stored buffer exactly once per process; afterwards the
     *  in-memory history is authoritative and storage is read never again. */
    private fun ensureHistoryLoaded(context: Context) {
        if (loaded) return
        loaded = true
        runCatching {
            val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .getString(KEY_EVENTS, "[]") ?: "[]"
            val array = JSONArray(raw)
            for (i in 0 until array.length()) {
                val item = array.optJSONObject(i) ?: continue
                val entry = LinkedHashMap<String, Any?>()
                for (key in item.keys()) entry[key] = item.opt(key)
                history.restore(entry)
            }
        }.getOrNull()
    }

    private fun schedulePersistLocked(context: Context) {
        if (persistPending) return
        persistPending = true
        val appContext = context.applicationContext
        persistExecutor.schedule(
            { persist(appContext) },
            PERSIST_DELAY_MS,
            TimeUnit.MILLISECONDS,
        )
    }

    private fun persist(context: Context) {
        // Cleared before snapshotting so any record arriving during the
        // serialization schedules its own follow-up persist.
        val json = synchronized(lock) {
            persistPending = false
            JSONArray().apply {
                for (entry in history.snapshot()) put(JSONObject(entry))
            }.toString()
        }
        try {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
                .edit().putString(KEY_EVENTS, json).apply()
        } catch (_: Exception) {
            // Diagnostics must never interrupt an alarm or audio playback.
        }
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
        val activeResult = runCatching {
            notifications.activeNotifications.map { status ->
                val notification = status.notification
                mapOf(
                    "id" to status.id,
                    "tagPresent" to (status.tag != null),
                    "channelId" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                        notification.channelId
                    } else null,
                    "category" to notification.category,
                    "titlePresent" to (notification.extras?.getCharSequence(Notification.EXTRA_TITLE)?.isNotEmpty() == true),
                    "textPresent" to (notification.extras?.getCharSequence(Notification.EXTRA_TEXT)?.isNotEmpty() == true),
                    "visibility" to notification.visibility,
                    "ongoing" to (notification.flags and Notification.FLAG_ONGOING_EVENT != 0),
                    "foregroundService" to (notification.flags and Notification.FLAG_FOREGROUND_SERVICE != 0),
                    "grouped" to (!status.groupKey.isNullOrEmpty()),
                    "postTimeEpochMillis" to status.postTime,
                )
            }
        }
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
            "activeNotifications" to activeResult.getOrElse { emptyList() },
            "activeNotificationsQuery" to if (activeResult.isSuccess) "succeeded" else
                "failed:${activeResult.exceptionOrNull()?.javaClass?.simpleName ?: "unknown"}",
        )
    }

    private fun permissionDeclaration(permissions: Set<String>?, permission: String): String =
        permissions?.let { if (permission in it) "declared" else "not_declared" } ?: "unknown"
}
