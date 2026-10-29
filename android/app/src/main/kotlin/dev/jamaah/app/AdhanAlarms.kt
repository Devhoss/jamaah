package dev.jamaah.app

import android.app.AlarmManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import org.json.JSONArray
import org.json.JSONObject

/**
 * One Adhan the app plays itself: the full recording, or any Adhan shown full
 * screen. Everything else is an ordinary scheduled notification (Dart side).
 */
data class AdhanAlarm(
    val id: Int,
    val atMillis: Long,
    val title: String,
    val body: String,
    /** "full", "short", "standard", "silent", or "raw" for [raw]. */
    val sound: String,
    /** Full and short: the Flutter asset path of the chosen recording or clip. */
    val recording: String,
    /** "raw": a bundled sound in res/raw by name (a reminder's chime or clip). */
    val raw: String,
    val ringInSilent: Boolean,
    val fullScreen: Boolean,
    val vibrate: Boolean,
    /** At most this long, in seconds; 0 plays to the end (2026-10-15). */
    val maxSeconds: Int = 0,
    /** "Stop", in the app's language (the native side has no strings file). */
    val stopLabel: String,
    /** The Adhan time as the user's clock shows it, for the full-screen page. */
    val timeLabel: String,
    /** "adhan", or a reminder's kind: decides which one keeps the sound when
     * two fire at once (2026-10-15). */
    val kind: String = "adhan",
    val prayer: String = "unknown",
    val syncId: String? = null,
    /** The full-screen page's sky, sun path and words, worked out in Dart
     * (lib/src/app/adhan_screen.dart); null for an alarm stored before it. */
    val screen: JSONObject? = null,
) {
    fun toJson(): JSONObject = JSONObject()
        .put("id", id)
        .put("at", atMillis)
        .put("title", title)
        .put("body", body)
        .put("sound", sound)
        .put("recording", recording)
        .put("raw", raw)
        .put("ringInSilent", ringInSilent)
        .put("fullScreen", fullScreen)
        .put("vibrate", vibrate)
        .put("maxSeconds", maxSeconds)
        .put("stopLabel", stopLabel)
        .put("timeLabel", timeLabel)
        .put("kind", kind)
        .put("prayer", prayer)
        .also { o -> syncId?.let { o.put("syncId", it) } }
        .also { o -> screen?.let { o.put("screen", it) } }

    companion object {
        fun fromJson(o: JSONObject) = AdhanAlarm(
            id = o.getInt("id"),
            atMillis = o.getLong("at"),
            title = o.optString("title"),
            body = o.optString("body"),
            sound = o.optString("sound", "full"),
            recording = o.optString("recording", ""),
            raw = o.optString("raw", ""),
            ringInSilent = o.optBoolean("ringInSilent"),
            fullScreen = o.optBoolean("fullScreen"),
            vibrate = o.optBoolean("vibrate", true),
            maxSeconds = o.optInt("maxSeconds", 0),
            stopLabel = o.optString("stopLabel", "Stop"),
            timeLabel = o.optString("timeLabel", ""),
            kind = o.optString("kind", "adhan"),
            prayer = o.optString("prayer", "unknown"),
            syncId = o.optString("syncId").takeIf { it.isNotEmpty() },
            screen = o.optJSONObject("screen"),
        )

        fun fromMap(m: Map<*, *>) = AdhanAlarm(
            id = (m["id"] as Number).toInt(),
            atMillis = (m["at"] as Number).toLong(),
            title = m["title"] as? String ?: "",
            body = m["body"] as? String ?: "",
            sound = m["sound"] as? String ?: "full",
            recording = m["recording"] as? String ?: "",
            raw = m["raw"] as? String ?: "",
            ringInSilent = m["ringInSilent"] == true,
            fullScreen = m["fullScreen"] == true,
            vibrate = m["vibrate"] != false,
            maxSeconds = (m["maxSeconds"] as? Number)?.toInt() ?: 0,
            stopLabel = m["stopLabel"] as? String ?: "Stop",
            timeLabel = m["timeLabel"] as? String ?: "",
            kind = m["kind"] as? String ?: "adhan",
            prayer = m["prayer"] as? String ?: "unknown",
            syncId = m["syncId"] as? String,
            screen = (m["screen"] as? Map<*, *>)?.let { JSONObject(it) },
        )
    }
}

/**
 * The app's own Adhan alarms. They are stored, so a reboot can put them back
 * (the system forgets alarms when it restarts), and each fires
 * [AdhanAlarmReceiver], which starts [AdhanService].
 *
 * The Dart side always hands over the complete set for the coming days, so
 * [replaceAll] cancels whatever is no longer in it: nothing is ever doubled.
 */
object AdhanAlarms {
    private const val PREFS = "jamaah_adhan_alarms"
    private const val KEY = "alarms"
    private val lock = Any()

    fun replaceAll(context: Context, alarms: List<AdhanAlarm>, syncId: String? = null) = synchronized(lock) {
        val duplicateIds = alarms.groupingBy { it.id }.eachCount().filterValues { it > 1 }
        require(duplicateIds.isEmpty()) { "Duplicate native alarm IDs: ${duplicateIds.size}" }
        val old = storedUnlocked(context)
        val future = alarms.filter { it.atMillis > System.currentTimeMillis() }
            .map { if (syncId == null) it else it.copy(syncId = syncId) }
        NativeDiagnostics.record(context, "adhan_alarm_replace_started", mapOf(
            "oldCount" to old.size,
            "requestedCount" to alarms.size,
            "futureCount" to future.size,
            "filteredPastCount" to (alarms.size - future.size),
            "syncId" to syncId,
        ))
        for (item in old) cancel(context, item, syncId, "replace_all")
        // Keep the desired set durable before registering it so the next refresh
        // or reboot can repair any alarms lost to process death.
        saveUnlocked(context, future)
        val failures = mutableListOf<Pair<Int, Exception>>()
        for (alarm in future) {
            try {
                register(context, alarm)
            } catch (error: Exception) {
                failures += alarm.id to error
            }
        }
        NativeDiagnostics.record(context, "adhan_alarm_replace_completed", mapOf(
            "requestedCount" to future.size,
            "registrationFailures" to failures.size,
            "failedIds" to failures.map { it.first },
            "syncId" to syncId,
        ))
        if (failures.isNotEmpty()) {
            throw IllegalStateException("${failures.size} native alarms could not be registered", failures.first().second)
        }
    }

    /** Puts the stored alarms back after a reboot or an app update. */
    fun restore(context: Context) = synchronized(lock) {
        val future = storedUnlocked(context).filter { it.atMillis > System.currentTimeMillis() }
        NativeDiagnostics.record(context, "adhan_alarm_restore_started", mapOf("futureCount" to future.size))
        saveUnlocked(context, future)
        val failures = mutableListOf<Pair<Int, Exception>>()
        for (alarm in future) {
            try {
                register(context, alarm)
            } catch (error: Exception) {
                failures += alarm.id to error
            }
        }
        NativeDiagnostics.record(context, "adhan_alarm_restore_completed", mapOf(
            "requestedCount" to future.size,
            "registrationFailures" to failures.size,
        ))
        if (failures.isNotEmpty()) {
            throw IllegalStateException("${failures.size} native alarms could not be restored", failures.first().second)
        }
    }

    /** Consume the record atomically so duplicate receiver callbacks cannot start it twice. */
    fun take(context: Context, id: Int): AdhanAlarm? = synchronized(lock) {
        val alarms = storedUnlocked(context)
        val alarm = alarms.firstOrNull { it.id == id }
        if (alarm != null) saveUnlocked(context, alarms.filterNot { it.id == id })
        alarm
    }

    fun stored(context: Context): List<AdhanAlarm> = synchronized(lock) { storedUnlocked(context) }

    private fun storedUnlocked(context: Context): List<AdhanAlarm> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { AdhanAlarm.fromJson(array.getJSONObject(it)) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun saveUnlocked(context: Context, alarms: List<AdhanAlarm>) {
        val array = JSONArray()
        alarms.forEach { array.put(it.toJson()) }
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
            .putString(KEY, array.toString()).apply()
    }

    private fun pendingIntent(context: Context, id: Int): PendingIntent = PendingIntent.getBroadcast(
        context,
        id,
        Intent(context, AdhanAlarmReceiver::class.java).putExtra(AdhanAlarmReceiver.EXTRA_ID, id),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
    )

    private fun register(context: Context, alarm: AdhanAlarm) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val intent = pendingIntent(context, alarm.id)
        val exact = Build.VERSION.SDK_INT < Build.VERSION_CODES.S || manager.canScheduleExactAlarms()
        val diagnostic = mapOf(
            "notificationId" to alarm.id,
            "correlationId" to "notification_${alarm.id}",
            "syncId" to alarm.syncId,
            "kind" to alarm.kind,
            "prayer" to alarm.prayer,
            "scheduledAtEpochMillis" to alarm.atMillis,
            "exactCapability" to exact,
            "exactCapabilityApi" to "AlarmManager.canScheduleExactAlarms",
        )
        NativeDiagnostics.record(context, "adhan_alarm_registration_requested", diagnostic)
        if (exact) {
            try {
                manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, intent)
                NativeDiagnostics.record(context, "adhan_alarm_registration_completed", diagnostic + mapOf("mode" to "exact"))
            } catch (error: SecurityException) {
                try {
                    manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, intent)
                    NativeDiagnostics.record(context, "adhan_alarm_registration_completed", diagnostic + mapOf(
                        "exactCapability" to false,
                        "mode" to "inexact_fallback",
                        "fallbackReason" to "exact_access_revoked_during_registration",
                    ))
                } catch (fallbackError: Exception) {
                    recordRegistrationFailure(context, diagnostic, fallbackError, "inexact_fallback_failed")
                    throw fallbackError
                }
            }
        } else {
            // Without the exact-alarm permission: inexact, and the app says so.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, intent)
            NativeDiagnostics.record(context, "adhan_alarm_registration_completed", diagnostic + mapOf("mode" to "inexact"))
        }
    }

    private fun recordRegistrationFailure(
        context: Context,
        diagnostic: Map<String, Any?>,
        error: Exception,
        code: String,
    ) {
        NativeDiagnostics.record(context, "adhan_alarm_registration_failed", diagnostic + mapOf(
            "errorClass" to error.javaClass.simpleName,
            "errorCode" to code,
        ))
    }

    private fun cancel(context: Context, alarm: AdhanAlarm, syncId: String?, reason: String) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(pendingIntent(context, alarm.id))
        NativeDiagnostics.record(context, "adhan_alarm_cancel_completed", mapOf(
            "notificationId" to alarm.id,
            "correlationId" to "notification_${alarm.id}",
            "syncId" to syncId,
            "previousSyncId" to alarm.syncId,
            "kind" to alarm.kind,
            "prayer" to alarm.prayer,
            "scheduledAtEpochMillis" to alarm.atMillis,
            "reason" to reason,
        ))
    }
}

/** Fires at an Adhan time and hands it to [AdhanService]. */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        NativeDiagnostics.record(context, "adhan_alarm_receiver_entered", mapOf(
            "action" to intent.action,
            "hasAlarmId" to intent.hasExtra(EXTRA_ID),
            "source" to "AdhanAlarmReceiver",
        ))
        val id = intent.getIntExtra(EXTRA_ID, -1)
        NativeDiagnostics.record(context, "adhan_alarm_receiver_id_validated", mapOf(
            "notificationId" to id,
            "correlationId" to "notification_$id",
            "valid" to (id >= 0),
        ))
        if (id < 0) return
        val alarm = try {
            AdhanAlarms.take(context, id)
        } catch (error: Exception) {
            NativeDiagnostics.record(context, "adhan_alarm_receiver_failed", mapOf(
                "notificationId" to id,
                "errorClass" to error.javaClass.simpleName,
                "errorMessage" to error.message,
                "errorCode" to error.javaClass.simpleName,
            ))
            return
        }
        if (alarm == null) {
            NativeDiagnostics.record(context, "adhan_alarm_receiver_validated", mapOf(
                "notificationId" to id,
                "foundStoredAlarm" to false,
                "validKind" to false,
            ))
            return
        }
        val validKind = AdhanPlaybackDiagnostics.isValidAlarmKind(alarm.kind)
        NativeDiagnostics.record(context, "adhan_alarm_receiver_validated", mapOf(
            "notificationId" to id,
            "correlationId" to "notification_$id",
            "foundStoredAlarm" to true,
            "validKind" to validKind,
            "kind" to alarm.kind,
            "prayer" to alarm.prayer,
            "syncId" to alarm.syncId,
            "scheduledAtEpochMillis" to alarm.atMillis,
        ))
        if (!validKind) return
        NativeDiagnostics.record(context, "adhan_alarm_receiver_fired", mapOf(
            "notificationId" to id,
            "correlationId" to "notification_$id",
            "kind" to alarm.kind,
            "prayer" to alarm.prayer,
            "syncId" to alarm.syncId,
            "scheduledAtEpochMillis" to alarm.atMillis,
        ))
        try {
            val evidence = mapOf<String, Any?>(
                "notificationId" to id,
                "correlationId" to "notification_$id",
                "kind" to alarm.kind,
                "prayer" to alarm.prayer,
                "syncId" to alarm.syncId,
                "scheduledAtEpochMillis" to alarm.atMillis,
            )
            NativeDiagnostics.record(context, "adhan_service_start_requested", evidence)
            val handedOff = AdhanPlaybackDiagnostics.handoffIfValid(alarm) {
                AdhanService.start(context, it)
            }
            if (!handedOff) return
            NativeDiagnostics.record(context, "adhan_service_start_result", evidence + mapOf(
                "acceptedBySystem" to true,
            ))
        } catch (error: Exception) {
            NativeDiagnostics.record(context, "adhan_service_start_result", mapOf(
                "notificationId" to id,
                "correlationId" to "notification_$id",
                "kind" to alarm.kind,
                "prayer" to alarm.prayer,
                "syncId" to alarm.syncId,
                "scheduledAtEpochMillis" to alarm.atMillis,
                "acceptedBySystem" to false,
                "errorClass" to error.javaClass.simpleName,
                "errorMessage" to error.message,
                "errorCode" to (error as? android.app.ForegroundServiceStartNotAllowedException)?.let { "foreground_service_start_not_allowed" },
            ))
        }
    }

    companion object {
        const val EXTRA_ID = "adhan_id"
    }
}

/** Puts the stored Adhan alarms back after a reboot or an app update. */
class AdhanBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        when (intent.action) {
            Intent.ACTION_BOOT_COMPLETED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> AdhanAlarms.restore(context)
            Intent.ACTION_MY_PACKAGE_REPLACED -> {
                NativeDiagnostics.record(
                    context,
                    "app_updated",
                    mapOf(
                        "fullScreenIntentCapability" to
                            AdhanService.canUseFullScreen(context),
                    ),
                )
                AdhanAlarms.restore(context)
            }
        }
    }
}
