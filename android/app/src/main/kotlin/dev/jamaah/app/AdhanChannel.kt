package dev.jamaah.app

import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.PowerManager
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import android.os.SystemClock
import java.util.UUID

/**
 * The channel to the Adhans the app plays itself (full recording, full screen,
 * or anything set to ring on silent): see AdhanAlarms, AdhanService and
 * AdhanActivity. Registered on the app's own engine and on the background
 * engine of [DailyRefreshJob], so a refresh with no screen open can replace
 * them too.
 */
object AdhanChannel {
    const val NAME = "dev.jamaah.app/adhan"
    private const val SYNC_LEASE_MILLIS = 120_000L
    private val syncLeaseLock = Any()
    private var syncLeaseToken: String? = null
    private var syncLeaseExpiresAt = 0L

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "replaceAll" -> {
                    val arguments = call.arguments
                    val syncId = (arguments as? Map<*, *>)?.get("syncId") as? String
                    val list = when (arguments) {
                        is List<*> -> arguments
                        is Map<*, *> -> arguments["alarms"] as? List<*> ?: emptyList<Any>()
                        else -> emptyList<Any>()
                    }
                    try {
                        AdhanAlarms.replaceAll(
                            context,
                            list.mapNotNull { (it as? Map<*, *>)?.let(AdhanAlarm::fromMap) },
                            syncId,
                        )
                        result.success(null)
                    } catch (error: Exception) {
                        result.error("adhan_alarm_replace_failed", error.javaClass.simpleName, null)
                    }
                }
                "acquireSyncLock" -> result.success(acquireSyncLock(context))
                "releaseSyncLock" -> {
                    releaseSyncLock(context, call.argument<String>("token"))
                    result.success(null)
                }
                "stored" -> result.success(
                    AdhanAlarms.stored(context).map {
                        mapOf(
                            "id" to it.id,
                            "at" to it.atMillis,
                            "title" to it.title,
                            "body" to it.body,
                            "kind" to it.kind,
                            "prayer" to it.prayer,
                            "syncId" to it.syncId,
                            "channelId" to it.channelId,
                            "soundMode" to it.sound,
                            "ringInSilent" to it.ringInSilent,
                            "fullScreen" to it.fullScreen,
                        )
                    },
                )
                "diagnosticEvents" -> result.success(NativeDiagnostics.events(context))
                "diagnosticEnvironment" -> result.success(NativeDiagnostics.environment(context))
                "playNow" -> {
                    val map = call.arguments as? Map<*, *>
                    if (map != null) AdhanService.start(context, AdhanAlarm.fromMap(map))
                    result.success(null)
                }
                "stop" -> {
                    AdhanService.stop(context)
                    result.success(null)
                }
                "canUseFullScreen" -> result.success(AdhanService.canUseFullScreen(context))
                "scheduleTestAdhan" -> {
                    // Debug/instrumentation builds only (the Dart side decides:
                    // kDebugMode or a TEST_ADHAN dart-define): the method
                    // channel is reachable only from this app's process, so the
                    // gate cannot be bypassed from outside. One alarm, minutes
                    // away, through the real store, registration and service —
                    // to measure this phone's delivery (2026-10-30 report).
                    val args = call.arguments as? Map<*, *>
                    val at = (args?.get("at") as? Number)?.toLong()
                    if (at == null || at < System.currentTimeMillis()) {
                        result.error("test_adhan_invalid", "at must be a future epoch millis", null)
                    } else {
                        try {
                            val alarm = AdhanAlarm(
                                id = uniqueTestAlarmId(context, at),
                                atMillis = at,
                                title = args["title"] as? String ?: "Test",
                                body = args["body"] as? String ?: "",
                                sound = args["sound"] as? String ?: "full",
                                recording = args["recording"] as? String ?: "",
                                raw = args["raw"] as? String ?: "",
                                ringInSilent = args["ringInSilent"] == true,
                                fullScreen = args["fullScreen"] == true,
                                vibrate = args["vibrate"] != false,
                                maxSeconds = (args["maxSeconds"] as? Number)?.toInt() ?: 0,
                                stopLabel = args["stopLabel"] as? String ?: "Stop",
                                timeLabel = args["timeLabel"] as? String ?: "",
                                kind = "adhan",
                                prayer = "test",
                            )
                            AdhanAlarms.addTest(context, alarm)
                            result.success(mapOf("id" to alarm.id))
                        } catch (error: Exception) {
                            result.error("test_adhan_failed", error.javaClass.simpleName, null)
                        }
                    }
                }
                "batteryOptimizationExempt" -> {
                    val power = context.getSystemService(Context.POWER_SERVICE) as PowerManager
                    result.success(power.isIgnoringBatteryOptimizations(context.packageName))
                }
                "openFullScreenSettings" -> {
                    if (Build.VERSION.SDK_INT >= 34) {
                        context.startActivity(
                            Intent(
                                android.provider.Settings.ACTION_MANAGE_APP_USE_FULL_SCREEN_INTENT,
                                android.net.Uri.parse("package:${context.packageName}"),
                            ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
                        )
                    }
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * An id wide of the planner's own: epoch seconds, unique per invocation;
     * two calls in the same second (or an id already in the store) walk
     * forward until free, so the second alarm is not silently swallowed.
     */
    private fun uniqueTestAlarmId(context: Context, at: Long): Int {
        val existing = AdhanAlarms.stored(context).map { it.id }.toSet()
        var id = ((at / 1000L) % Int.MAX_VALUE).toInt()
        while (id in existing) id++
        return id
    }

    private fun acquireSyncLock(context: Context): String? = synchronized(syncLeaseLock) {
        val now = SystemClock.elapsedRealtime()
        if (syncLeaseToken != null && now < syncLeaseExpiresAt) {
            NativeDiagnostics.record(context, "notification_sync_lock_busy")
            return@synchronized null
        }
        if (syncLeaseToken != null) {
            NativeDiagnostics.record(context, "notification_sync_lock_expired")
        }
        UUID.randomUUID().toString().also { token ->
            syncLeaseToken = token
            syncLeaseExpiresAt = now + SYNC_LEASE_MILLIS
            NativeDiagnostics.record(context, "notification_sync_lock_acquired")
        }
    }

    private fun releaseSyncLock(context: Context, token: String?) = synchronized(syncLeaseLock) {
        if (token != null && token == syncLeaseToken) {
            syncLeaseToken = null
            syncLeaseExpiresAt = 0L
            NativeDiagnostics.record(context, "notification_sync_lock_released")
        } else {
            NativeDiagnostics.record(context, "notification_sync_lock_release_ignored")
        }
    }
}
