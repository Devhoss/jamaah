package dev.jamaah.app

import android.content.Context
import android.content.Intent
import android.os.Build
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * The channel to the Adhans the app plays itself (full recording, full screen,
 * or anything set to ring on silent): see AdhanAlarms, AdhanService and
 * AdhanActivity. Registered on the app's own engine and on the background
 * engine of [DailyRefreshJob], so a refresh with no screen open can replace
 * them too.
 */
object AdhanChannel {
    const val NAME = "dev.jamaah.app/adhan"

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "replaceAll" -> {
                    val list = call.arguments as? List<*> ?: emptyList<Any>()
                    AdhanAlarms.replaceAll(
                        context,
                        list.mapNotNull { (it as? Map<*, *>)?.let(AdhanAlarm::fromMap) },
                    )
                    result.success(null)
                }
                "stored" -> result.success(
                    AdhanAlarms.stored(context).map {
                        mapOf("id" to it.id, "at" to it.atMillis, "title" to it.title, "body" to it.body)
                    },
                )
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
}
