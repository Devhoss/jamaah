package dev.jamaah.app

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.media.AudioAttributes
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.media.VolumeProvider
import android.media.session.MediaSession
import android.media.session.PlaybackState
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.os.SystemClock
import android.os.VibrationEffect
import android.os.Vibrator
import org.json.JSONObject

/**
 * Plays an Adhan the app handles itself: the full recording (too long to be a
 * notification sound) and any Adhan shown full screen.
 *
 * - Plays through the alarm volume only when the user chose "ring when the phone
 *   is on silent"; otherwise through the notification volume, which a phone on
 *   silent mutes. Nothing surprises anyone in a quiet room by default.
 * - Stops on the notification's Stop action, the full-screen page's Stop button,
 *   the volume keys (anywhere, see [startVolumeKeyWatch]), turning the phone
 *   face down, or the end of the recording.
 */
class AdhanService : Service(), SensorEventListener {
    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var sensors: SensorManager? = null
    private var faceDownStopArmed = false
    private var faceDownSince = 0L
    private var current: AdhanAlarm? = null
    private var session: MediaSession? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP || intent?.action == ACTION_DISMISS) {
            finish(
                keepAlert = false,
                dismissActivity = intent?.getBooleanExtra(EXTRA_DISMISS_ACTIVITY, true) == true,
            )
            return START_NOT_STICKY
        }
        val json = intent?.getStringExtra(EXTRA_ALARM)
        val alarm = try {
            json?.let { AdhanAlarm.fromJson(JSONObject(it)) }
        } catch (error: Exception) {
            NativeDiagnostics.record(this, "adhan_service_start_failed", mapOf(
                "reason" to "invalid_alarm_payload",
                "errorClass" to error.javaClass.simpleName,
                "errorMessage" to error.message,
                "errorCode" to error.javaClass.simpleName,
            ))
            stopSelf()
            return START_NOT_STICKY
        }
        if (alarm == null) {
            NativeDiagnostics.record(this, "adhan_service_start_failed", mapOf("reason" to "missing_or_invalid_alarm"))
            stopSelf()
            return START_NOT_STICKY
        }
        NativeDiagnostics.record(this, "adhan_service_entered", mapOf("notificationId" to alarm.id, "kind" to alarm.kind))
        ensureChannel(this)
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val playing = current
        // Two at once (a Jama’ah reminder due at the Adhan, 2026-10-15): neither
        // is lost. An Adhan is never cut short by a reminder: the reminder is
        // shown, silently. Anything else takes the sound, and the one it
        // replaces stays in the notification shade.
        if (playing != null && playing.kind == "adhan" && alarm.kind != "adhan") {
            keepForeground(buildNotification(playing, playing = true))
            manager.notify(alarm.id, buildNotification(alarm, playing = false))
            NativeDiagnostics.record(this, "adhan_notification_post_returned", mapOf(
                "notificationId" to alarm.id,
                "channelId" to CHANNEL_ID,
                "kind" to alarm.kind,
                "postingApi" to "NotificationManager.notify",
                "result" to "returned",
            ))
            return START_NOT_STICKY
        }
        if (playing != null) {
            manager.notify(playing.id, buildNotification(playing, playing = false))
        }
        release()
        current = alarm
        try {
            keepForeground(buildNotification(alarm, playing = true))
            NativeDiagnostics.record(this, "adhan_service_foreground_established", mapOf("notificationId" to alarm.id))
            NativeDiagnostics.record(this, "adhan_notification_post_returned", mapOf(
                "notificationId" to PLAYING_ID,
                "alarmId" to alarm.id,
                "channelId" to CHANNEL_ID,
                "kind" to alarm.kind,
                "postingApi" to "Service.startForeground",
                "result" to "returned",
            ))
            play(alarm)
        } catch (error: Exception) {
            NativeDiagnostics.record(this, "adhan_service_start_failed", mapOf(
                "notificationId" to alarm.id,
                "errorClass" to error.javaClass.simpleName,
                "errorMessage" to error.message,
                "errorCode" to error.javaClass.simpleName,
            ))
            finish(keepAlert = true, dismissActivity = true)
        }
        return START_NOT_STICKY
    }

    /** Every start must (re)enter the foreground, even one that plays nothing. */
    private fun keepForeground(notification: Notification) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                PLAYING_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(PLAYING_ID, notification)
        }
    }

    private fun play(alarm: AdhanAlarm) {
        val power = getSystemService(Context.POWER_SERVICE) as PowerManager
        wakeLock = power.newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "jamaah:adhan").apply {
            acquire(10 * 60 * 1000L)
        }

        val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
        val ringer = audio.ringerMode
        if (alarm.vibrate && ringer != AudioManager.RINGER_MODE_SILENT) vibrate()

        val usage = if (alarm.ringInSilent) {
            AudioAttributes.USAGE_ALARM
        } else {
            AudioAttributes.USAGE_NOTIFICATION
        }
        NativeDiagnostics.record(this, "adhan_audio_route", mapOf(
            "notificationId" to alarm.id,
            "ringInSilent" to alarm.ringInSilent,
            "ringerMode" to when (ringer) {
                AudioManager.RINGER_MODE_SILENT -> "silent"
                AudioManager.RINGER_MODE_VIBRATE -> "vibrate"
                else -> "normal"
            },
            "alarmStreamVolume" to audio.getStreamVolume(AudioManager.STREAM_ALARM),
            "alarmStreamMaxVolume" to audio.getStreamMaxVolume(AudioManager.STREAM_ALARM),
            "notificationStreamVolume" to audio.getStreamVolume(AudioManager.STREAM_NOTIFICATION),
        ))
        // A full-screen page stays up for at least a minute, even when the sound
        // is short (or there is none), so it can be seen and dismissed.
        if (alarm.fullScreen) handler.postDelayed(minimumEnd, 60_000L)
        val shortAdhan = Uri.parse("android.resource://$packageName/${R.raw.azan_short}")
        val source: Uri? = when (alarm.sound) {
            // The chosen recording (full) or clip (short) is read from the
            // Flutter assets below; the short Adhan stands in if there is none.
            "full", "short" -> if (alarm.recording.isEmpty()) shortAdhan else null
            "standard" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            // A reminder's chime or clip, by its res/raw name (kept by keep.xml).
            "raw" -> resources.getIdentifier(alarm.raw, "raw", packageName)
                .takeIf { it != 0 }
                ?.let { Uri.parse("android.resource://$packageName/$it") }
            else -> null // silent: shown, not heard
        }
        // The user's own file (2026-10-15): an absolute path, for a full Adhan
        // or ("file") a reminder.
        val fromFile = alarm.recording.startsWith("/") &&
            (alarm.sound == "full" || alarm.sound == "file")
        val fromAssets = !fromFile &&
            (alarm.sound == "full" || alarm.sound == "short") && alarm.recording.isNotEmpty()
        // What plays if the user's file cannot: the reminder's own bundled sound,
        // or the short Adhan.
        val fallback = alarm.raw.takeIf { it.isNotEmpty() }
            ?.let { resources.getIdentifier(it, "raw", packageName) }
            ?.takeIf { it != 0 }
            ?.let { Uri.parse("android.resource://$packageName/$it") }
            ?: shortAdhan
        NativeDiagnostics.record(this, "adhan_audio_source_selected", mapOf(
            "notificationId" to alarm.id,
            "soundMode" to alarm.sound,
            "ringInSilent" to alarm.ringInSilent,
            "audioUsage" to if (alarm.ringInSilent) "alarm" else "notification",
            "source" to when {
                fromFile -> "user_file"
                fromAssets -> "flutter_asset"
                source == null -> "silent"
                alarm.sound == "raw" -> "raw_resource"
                alarm.sound == "standard" -> "platform_default"
                else -> "bundled_short_fallback"
            },
            "asset" to alarm.recording.takeIf { fromAssets },
        ))
        if (alarm.maxSeconds > 0) {
            handler.postDelayed(capEnd, alarm.maxSeconds * 1000L)
        } else if (alarm.kind == "adhan") {
            // A player that never reports completion must not leave an Adhan
            // foreground service and notification running indefinitely.
            handler.postDelayed(capEnd, MAX_ADHAN_PLAYBACK_MILLIS)
        }
        if (source == null && !fromAssets && !fromFile) {
            // Silent alerts have no MediaPlayer completion callback. Let a
            // full-screen alert stay visible for its minimum display time,
            // then complete it through minimumEnd like a short recording.
            soundDone = true
            if (!alarm.fullScreen) finish(keepAlert = true, dismissActivity = true)
            startFlipWatch()
            return
        }
        NativeDiagnostics.record(this, "adhan_audio_playback_requested", mapOf(
            "notificationId" to alarm.id,
            "kind" to alarm.kind,
            "ringInSilent" to alarm.ringInSilent,
        ))
        fun attributes() = AudioAttributes.Builder()
            .setUsage(usage)
            .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
            .build()
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(attributes())
                when {
                    fromFile -> setDataSource(alarm.recording)
                    fromAssets -> setAssetSource(this, alarm.recording, shortAdhan)
                    else -> setDataSource(this@AdhanService, source!!)
                }
                setOnCompletionListener { soundEnded() }
                setOnErrorListener { _, what, extra ->
                    NativeDiagnostics.record(this@AdhanService, "adhan_playback_failed", mapOf("notificationId" to alarm.id, "reason" to "media_error", "errorCode" to what, "extraCode" to extra))
                    finish(keepAlert = true, dismissActivity = true); true
                }
                prepare()
                start()
                NativeDiagnostics.record(this@AdhanService, "adhan_playback_started", mapOf("notificationId" to alarm.id, "kind" to alarm.kind, "ringInSilent" to alarm.ringInSilent))
            }
        } catch (e: Exception) {
            NativeDiagnostics.record(this, "adhan_playback_failed", mapOf("notificationId" to alarm.id, "reason" to "prepare_or_start_failed", "errorClass" to e.javaClass.simpleName, "errorMessage" to e.message, "errorCode" to e.javaClass.simpleName))
            player?.release()
            player = null
            if (!fromFile) {
                finish(keepAlert = true, dismissActivity = true)
                return
            }
            // The user's file would not play (moved, damaged, an odd format):
            // the bundled sound instead, so the alert is never silent.
            try {
                player = MediaPlayer().apply {
                    setAudioAttributes(attributes())
                    setDataSource(this@AdhanService, fallback)
                    setOnCompletionListener { soundEnded() }
                    setOnErrorListener { _, what, extra ->
                        NativeDiagnostics.record(this@AdhanService, "adhan_playback_failed", mapOf("notificationId" to alarm.id, "reason" to "fallback_media_error", "errorCode" to what, "extraCode" to extra))
                        finish(keepAlert = true, dismissActivity = true)
                        true
                    }
                    prepare()
                    start()
                    NativeDiagnostics.record(this@AdhanService, "adhan_playback_started", mapOf("notificationId" to alarm.id, "kind" to alarm.kind, "source" to "bundled_fallback"))
                }
            } catch (e2: Exception) {
                NativeDiagnostics.record(this, "adhan_playback_failed", mapOf("notificationId" to alarm.id, "reason" to "fallback_prepare_or_start_failed", "errorClass" to e2.javaClass.simpleName, "errorMessage" to e2.message, "errorCode" to e2.javaClass.simpleName))
                finish(keepAlert = true, dismissActivity = true)
                return
            }
        }

        startVolumeKeyWatch()
        startFlipWatch()
    }

    /**
     * The volume keys stop it, whether the app is open, in the background or
     * the screen is locked (2026-10-14). While the Adhan plays, a media session
     * with its own volume control claims the volume keys: Android sends them
     * to it instead of changing a stream's volume, and any press ends the
     * Adhan. Headphone and Bluetooth stop or pause buttons end it too. The
     * session goes when the Adhan stops, and the keys work as usual again.
     */
    private fun startVolumeKeyWatch() {
        val stop = { handler.post { finish(keepAlert = false, dismissActivity = false) } }
        session = MediaSession(this, "JamaahAdhan").apply {
            setPlaybackToRemote(
                object : VolumeProvider(VOLUME_CONTROL_RELATIVE, 1, 1) {
                    override fun onAdjustVolume(direction: Int) {
                        if (direction != AudioManager.ADJUST_SAME) stop()
                    }
                },
            )
            setCallback(
                object : MediaSession.Callback() {
                    override fun onStop() {
                        stop()
                    }

                    override fun onPause() {
                        stop()
                    }
                },
            )
            setPlaybackState(
                PlaybackState.Builder()
                    .setActions(
                        PlaybackState.ACTION_STOP or
                            PlaybackState.ACTION_PAUSE or
                            PlaybackState.ACTION_PLAY_PAUSE,
                    )
                    .setState(PlaybackState.STATE_PLAYING, 0L, 1f)
                    .build(),
            )
            isActive = true
        }
    }

    /**
     * Points [player] at a Flutter asset. Flutter packs its assets under
     * flutter_assets/ in the APK, stored uncompressed for audio, so the file can
     * be opened in place. Falls back to the short Adhan if it cannot be read.
     */
    private fun setAssetSource(player: MediaPlayer, asset: String, fallback: Uri) {
        try {
            assets.openFd("flutter_assets/$asset").use { fd ->
                player.setDataSource(fd.fileDescriptor, fd.startOffset, fd.length)
            }
            NativeDiagnostics.record(this, "adhan_audio_asset_resolved", mapOf(
                "asset" to asset,
                "resolved" to true,
                "source" to "flutter_asset",
            ))
        } catch (e: Exception) {
            NativeDiagnostics.record(this, "adhan_audio_asset_fallback", mapOf(
                "asset" to asset,
                "resolved" to false,
                "fallback" to "bundled_short_adhan",
                "errorClass" to e.javaClass.simpleName,
                "errorMessage" to e.message,
                "errorCode" to e.javaClass.simpleName,
            ))
            player.setDataSource(this, fallback)
        }
    }

    /** Face-down stopping arms after the phone has been face up during playback. */
    private fun startFlipWatch() {
        sensors = (getSystemService(Context.SENSOR_SERVICE) as SensorManager).also { manager ->
            manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
                manager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())

    /** Ends a sound that has a time limit (a reminder: 30 seconds). */
    private val capEnd = Runnable {
        current?.let {
            NativeDiagnostics.record(
                this,
                "adhan_playback_interrupted",
                mapOf("notificationId" to it.id, "reason" to "maximum_duration_reached"),
            )
        }
        finish(keepAlert = true, dismissActivity = true)
    }
    private var minimumPassed = false
    private var soundDone = false
    private val minimumEnd = Runnable {
        minimumPassed = true
        if (soundDone) finish(keepAlert = true, dismissActivity = true)
    }

    /** The recording ended: finish, unless a full-screen page is still due its minute. */
    private fun soundEnded() {
        current?.let { NativeDiagnostics.record(this, "adhan_playback_completed", mapOf("notificationId" to it.id, "kind" to it.kind)) }
        soundDone = true
        if (current?.fullScreen != true || minimumPassed) {
            finish(keepAlert = true, dismissActivity = true)
        }
    }

    private fun vibrate() {
        val vibrator = getSystemService(Context.VIBRATOR_SERVICE) as Vibrator
        val pattern = longArrayOf(0, 500, 250, 500)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createWaveform(pattern, -1))
        } else {
            @Suppress("DEPRECATION")
            vibrator.vibrate(pattern, -1)
        }
    }

    override fun onSensorChanged(event: SensorEvent) {
        val z = event.values[2]
        val now = SystemClock.elapsedRealtime()
        if (z > 8.5f) {
            faceDownStopArmed = true
            faceDownSince = 0L
        } else if (faceDownStopArmed && z < -8.5f) {
            if (faceDownSince == 0L) faceDownSince = now
            // Held face down for most of a second, not a phone jostled in a bag.
            if (now - faceDownSince > 700) {
                finish(keepAlert = false, dismissActivity = false)
            }
        } else {
            faceDownSince = 0L
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    /** Ends playback, preserving a quiet alert only when playback ended by itself. */
    private fun finish(keepAlert: Boolean = false, dismissActivity: Boolean = true) {
        val alarm = current
        if (alarm != null && player?.isPlaying == true) {
            NativeDiagnostics.record(this, "adhan_playback_interrupted", mapOf("notificationId" to alarm.id, "reason" to "service_stopped"))
        }
        release()
        current = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        if (alarm != null && keepAlert) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(alarm.id, buildNotification(alarm, playing = false))
        } else if (alarm != null) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.cancel(alarm.id)
        }
        AdhanActivity.endAll(dismissActivity)
        stopSelf()
    }

    private fun release() {
        player?.run {
            try {
                stop()
            } catch (e: Exception) {
                // already stopped
            }
            release()
        }
        player = null
        session?.run {
            isActive = false
            release()
        }
        session = null
        sensors?.unregisterListener(this)
        sensors = null
        handler.removeCallbacks(minimumEnd)
        handler.removeCallbacks(capEnd)
        minimumPassed = false
        soundDone = false
        faceDownStopArmed = false
        faceDownSince = 0L
        wakeLock?.let { if (it.isHeld) it.release() }
        wakeLock = null
    }

    override fun onDestroy() {
        release()
        super.onDestroy()
    }

    private fun buildNotification(alarm: AdhanAlarm, playing: Boolean): Notification {
        val openApp = PendingIntent.getActivity(
            this,
            alarm.id,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this).setPriority(Notification.PRIORITY_HIGH)
        }
        builder
            .setSmallIcon(R.drawable.ic_stat_jamaah)
            .setContentTitle(alarm.title)
            .setContentText(alarm.body)
            .setCategory(Notification.CATEGORY_ALARM)
            .setVisibility(Notification.VISIBILITY_PUBLIC)
            .setContentIntent(openApp)
            // A playing alert remains a foreground service, but users can
            // dismiss its shade notification; deleteIntent below stops audio.
            .setOngoing(false)
            .setAutoCancel(!playing)

        if (playing) {
            val stop = PendingIntent.getService(
                this,
                0,
                Intent(this, AdhanService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            val dismiss = PendingIntent.getService(
                this,
                alarm.id,
                Intent(this, AdhanService::class.java).setAction(ACTION_DISMISS),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
            builder.setDeleteIntent(dismiss)
            builder.addAction(
                Notification.Action.Builder(null, alarm.stopLabel, stop).build(),
            )
            if (alarm.fullScreen && canUseFullScreen(this)) {
                val page = PendingIntent.getActivity(
                    this,
                    alarm.id,
                    AdhanActivity.intent(this, alarm),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
                )
                builder.setFullScreenIntent(page, true)
            }
        }
        return builder.build()
    }

    companion object {
        const val ACTION_STOP = "dev.jamaah.app.STOP_ADHAN"
        const val ACTION_DISMISS = "dev.jamaah.app.DISMISS_ADHAN"
        const val EXTRA_ALARM = "adhan_alarm"
        const val EXTRA_DISMISS_ACTIVITY = "dismiss_activity"
        const val CHANNEL_ID = "adhan_service"
        private const val PLAYING_ID = 7300
        private const val MAX_ADHAN_PLAYBACK_MILLIS = 10 * 60 * 1000L

        fun start(context: Context, alarm: AdhanAlarm) {
            val intent = Intent(context, AdhanService::class.java)
                .putExtra(EXTRA_ALARM, alarm.toJson().toString())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context, dismissActivity: Boolean = true) {
            context.startService(
                Intent(context, AdhanService::class.java)
                    .setAction(ACTION_STOP)
                    .putExtra(EXTRA_DISMISS_ACTIVITY, dismissActivity),
            )
        }

        /** Android 14+ lets the user take this away; without it, a heads-up shows. */
        fun canUseFullScreen(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < 34) return true
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            return manager.canUseFullScreenIntent()
        }

        fun ensureChannel(context: Context) {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
            val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) != null) return
            // The service plays the sound and vibrates itself, so the channel is
            // quiet; it exists to put the Adhan on screen.
            val channel = NotificationChannel(
                CHANNEL_ID,
                context.getString(R.string.app_name) + " · Adhan",
                NotificationManager.IMPORTANCE_HIGH,
            ).apply {
                setSound(null, null)
                enableVibration(false)
                lockscreenVisibility = Notification.VISIBILITY_PUBLIC
            }
            manager.createNotificationChannel(channel)
        }
    }
}
