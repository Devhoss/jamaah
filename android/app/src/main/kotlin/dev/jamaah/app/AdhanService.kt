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
 * - Stops on the notification's Stop action, the full-screen page's Stop button
 *   or volume keys, turning the phone face down, or the end of the recording.
 */
class AdhanService : Service(), SensorEventListener {
    private var player: MediaPlayer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var sensors: SensorManager? = null
    private var faceDownSince = 0L
    private var current: AdhanAlarm? = null

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == ACTION_STOP) {
            finish()
            return START_NOT_STICKY
        }
        val json = intent?.getStringExtra(EXTRA_ALARM)
        val alarm = json?.let { AdhanAlarm.fromJson(JSONObject(it)) }
        if (alarm == null) {
            stopSelf()
            return START_NOT_STICKY
        }
        // A new Adhan replaces one still playing.
        release()
        current = alarm
        ensureChannel(this)
        val notification = buildNotification(alarm, playing = true)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            startForeground(
                PLAYING_ID,
                notification,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_MEDIA_PLAYBACK,
            )
        } else {
            startForeground(PLAYING_ID, notification)
        }
        play(alarm)
        return START_NOT_STICKY
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
        // A full-screen page stays up for at least a minute, even when the sound
        // is short (or there is none), so it can be seen and dismissed.
        if (alarm.fullScreen) handler.postDelayed(minimumEnd, 60_000L)
        val shortAdhan = Uri.parse("android.resource://$packageName/${R.raw.adhan_short}")
        val source: Uri? = when (alarm.sound) {
            // The chosen recording (full) or clip (short) is read from the
            // Flutter assets below; the short Adhan stands in if there is none.
            "full", "short" -> if (alarm.recording.isEmpty()) shortAdhan else null
            "standard" -> RingtoneManager.getDefaultUri(RingtoneManager.TYPE_NOTIFICATION)
            else -> null // silent: shown, not heard
        }
        val fromAssets =
            (alarm.sound == "full" || alarm.sound == "short") && alarm.recording.isNotEmpty()
        if (source == null && !fromAssets) {
            if (!alarm.fullScreen) finish()
            startFlipWatch()
            return
        }
        try {
            player = MediaPlayer().apply {
                setAudioAttributes(
                    AudioAttributes.Builder()
                        .setUsage(usage)
                        .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                        .build(),
                )
                if (fromAssets) {
                    setAssetSource(this, alarm.recording, shortAdhan)
                } else {
                    setDataSource(this@AdhanService, source!!)
                }
                setOnCompletionListener { soundEnded() }
                setOnErrorListener { _, _, _ -> finish(); true }
                prepare()
                start()
            }
        } catch (e: Exception) {
            finish()
            return
        }

        startFlipWatch()
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
        } catch (e: Exception) {
            player.setDataSource(this, fallback)
        }
    }

    /** Turning the phone face down stops it. */
    private fun startFlipWatch() {
        sensors = (getSystemService(Context.SENSOR_SERVICE) as SensorManager).also { manager ->
            manager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)?.let {
                manager.registerListener(this, it, SensorManager.SENSOR_DELAY_NORMAL)
            }
        }
    }

    private val handler = Handler(Looper.getMainLooper())
    private var minimumPassed = false
    private var soundDone = false
    private val minimumEnd = Runnable {
        minimumPassed = true
        if (soundDone) finish()
    }

    /** The recording ended: finish, unless a full-screen page is still due its minute. */
    private fun soundEnded() {
        soundDone = true
        if (current?.fullScreen != true || minimumPassed) finish()
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
        if (z < -8.5f) {
            if (faceDownSince == 0L) faceDownSince = now
            // Held face down for most of a second, not a phone jostled in a bag.
            if (now - faceDownSince > 700) finish()
        } else {
            faceDownSince = 0L
        }
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    /** Stops playing and leaves a plain notification, so the time is not missed. */
    private fun finish() {
        val alarm = current
        release()
        current = null
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_REMOVE)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(true)
        }
        if (alarm != null) {
            val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            manager.notify(alarm.id, buildNotification(alarm, playing = false))
        }
        AdhanActivity.closeAll()
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
        sensors?.unregisterListener(this)
        sensors = null
        handler.removeCallbacks(minimumEnd)
        minimumPassed = false
        soundDone = false
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
            .setOngoing(playing)
            .setAutoCancel(!playing)

        if (playing) {
            val stop = PendingIntent.getService(
                this,
                0,
                Intent(this, AdhanService::class.java).setAction(ACTION_STOP),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
            )
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
        const val EXTRA_ALARM = "adhan_alarm"
        const val CHANNEL_ID = "adhan_service"
        private const val PLAYING_ID = 7300

        fun start(context: Context, alarm: AdhanAlarm) {
            val intent = Intent(context, AdhanService::class.java)
                .putExtra(EXTRA_ALARM, alarm.toJson().toString())
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }

        fun stop(context: Context) {
            context.startService(Intent(context, AdhanService::class.java).setAction(ACTION_STOP))
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
