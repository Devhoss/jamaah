package dev.jamaah.app

import android.content.Context
import android.content.Intent
import android.os.Build
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
                    val list = call.arguments as? List<*> ?: emptyList<Any>()
                    try {
                        AdhanAlarms.replaceAll(
                            context,
                            list.mapNotNull { (it as? Map<*, *>)?.let(AdhanAlarm::fromMap) },
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
                            "kind" to it.kind,
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
