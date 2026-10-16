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

    fun replaceAll(context: Context, alarms: List<AdhanAlarm>) {
        for (old in stored(context)) cancel(context, old.id)
        val future = alarms.filter { it.atMillis > System.currentTimeMillis() }
        save(context, future)
        for (alarm in future) register(context, alarm)
    }

    /** Puts the stored alarms back after a reboot or an app update. */
    fun restore(context: Context) {
        val future = stored(context).filter { it.atMillis > System.currentTimeMillis() }
        save(context, future)
        for (alarm in future) register(context, alarm)
    }

    fun find(context: Context, id: Int): AdhanAlarm? = stored(context).firstOrNull { it.id == id }

    fun forget(context: Context, id: Int) = save(context, stored(context).filter { it.id != id })

    fun stored(context: Context): List<AdhanAlarm> {
        val raw = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY, null)
            ?: return emptyList()
        return try {
            val array = JSONArray(raw)
            (0 until array.length()).map { AdhanAlarm.fromJson(array.getJSONObject(it)) }
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun save(context: Context, alarms: List<AdhanAlarm>) {
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
        if (exact) {
            manager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, intent)
        } else {
            // Without the exact-alarm permission: inexact, and the app says so.
            manager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, alarm.atMillis, intent)
        }
    }

    private fun cancel(context: Context, id: Int) {
        val manager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        manager.cancel(pendingIntent(context, id))
    }
}

/** Fires at an Adhan time and hands it to [AdhanService]. */
class AdhanAlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getIntExtra(EXTRA_ID, -1)
        val alarm = AdhanAlarms.find(context, id) ?: return
        AdhanAlarms.forget(context, id)
        AdhanService.start(context, alarm)
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
            Intent.ACTION_MY_PACKAGE_REPLACED,
            "android.intent.action.QUICKBOOT_POWERON",
            -> AdhanAlarms.restore(context)
        }
    }
}
