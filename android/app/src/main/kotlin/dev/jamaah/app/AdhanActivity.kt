package dev.jamaah.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.KeyEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject
import java.lang.ref.WeakReference

/**
 * The full-screen Adhan: shown over the lock screen when the phone is idle, with
 * one large Stop. The volume keys stop it too. Plain native views, so it appears
 * at once without starting the Flutter engine: the Horizon page ([AdhanPage])
 * when the alarm carries what to draw, else the plain one.
 */
class AdhanActivity : Activity() {
    private var page: AdhanPage? = null
    private var alarmId = 0L

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        open.add(WeakReference(this))

        val alarm = intent.getStringExtra(AdhanService.EXTRA_ALARM)
            ?.let { AdhanAlarm.fromJson(JSONObject(it)) }
        if (alarm == null) {
            NativeDiagnostics.record(this, "adhan_full_screen_shown", mapOf(
                "reason" to "missing_alarm_payload",
            ))
            finish()
            return
        }
        alarmId = alarm.id.toLong()
        NativeDiagnostics.record(this, "adhan_full_screen_shown", mapOf(
            "alarmId" to alarm.id,
            "correlationId" to "notification_${alarm.id}",
            "syncId" to alarm.syncId,
            "kind" to alarm.kind,
            "prayer" to alarm.prayer,
            "scheduledAtEpochMillis" to alarm.atMillis,
            "horizonScreen" to (alarm.screen != null),
        ))
        val screen = alarm.screen
        if (screen != null) {
            val horizon = AdhanPage(
                activity = this,
                screen = screen,
                stopLabel = alarm.stopLabel,
                onStop = { stop() },
                onDismiss = { finish() },
            )
            page = horizon
            drawUnderSystemBars(lightInk = horizon.lightInk)
            setContentView(horizon.root)
        } else {
            setContentView(layout(alarm))
        }
    }

    /** The sky runs under the status and navigation bars, as in the app. */
    @Suppress("DEPRECATION")
    private fun drawUnderSystemBars(lightInk: Boolean) {
        window.statusBarColor = Color.TRANSPARENT
        window.navigationBarColor = Color.TRANSPARENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // No scrim behind the bars: the sky shows through.
            window.isNavigationBarContrastEnforced = false
            window.isStatusBarContrastEnforced = false
        }
        var flags = View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
            View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or
            View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
        if (!lightInk && Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            flags = flags or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
        }
        window.decorView.systemUiVisibility = flags
    }

    private fun showOverLockScreen() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(true)
            setTurnScreenOn(true)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun dp(value: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

    /** Calm and plain, in the Horizon dark surface colours: for an alarm stored
     * before the Horizon page existed. */
    private fun layout(alarm: AdhanAlarm) = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        setBackgroundColor(Color.parseColor("#14151C"))
        val pad = dp(32f).toInt()
        setPadding(pad, pad, pad, pad)

        addView(TextView(context).apply {
            text = alarm.title
            setTextColor(Color.parseColor("#ECEDF2"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 40f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })
        if (alarm.timeLabel.isNotEmpty()) {
            addView(TextView(context).apply {
                text = alarm.timeLabel
                setTextColor(Color.parseColor("#ECEDF2"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
                gravity = Gravity.CENTER
            })
        }
        addView(TextView(context).apply {
            text = alarm.body
            setTextColor(Color.parseColor("#A3A6B3"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
            setPadding(0, dp(16f).toInt(), 0, dp(48f).toInt())
        })
        addView(Button(context).apply {
            text = alarm.stopLabel
            isAllCaps = false
            setTextColor(Color.parseColor("#14151C"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#ECEDF2"))
                cornerRadius = dp(28f)
            }
            minHeight = dp(72f).toInt()
            minWidth = dp(220f).toInt()
            setOnClickListener { stop() }
        })
    }

    private fun stop() {
        AdhanService.stop(this, dismissActivity = false)
        ended()
    }

    /** Playing has stopped: the Horizon page says so and waits for Dismiss;
     * the plain page simply closes. */
    private fun ended(dismiss: Boolean = false) {
        clearScreenAwakeFlags()
        if (dismiss || page == null) {
            finish()
        } else {
            page?.showStopped()
        }
    }

    private fun clearScreenAwakeFlags() {
        window.clearFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
                WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON,
        )
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setTurnScreenOn(false)
        }
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            stop()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
        clearScreenAwakeFlags()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O_MR1) {
            setShowWhenLocked(false)
        } else {
            @Suppress("DEPRECATION")
            window.clearFlags(WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED)
        }
        NativeDiagnostics.record(this, "adhan_full_screen_closed", mapOf(
            "alarmId" to alarmId.takeIf { it > 0 },
            "correlationId" to alarmId.takeIf { it > 0 }?.let { "notification_$it" },
        ))
        open.removeAll { it.get() == null || it.get() == this }
        super.onDestroy()
    }

    companion object {
        private val open = mutableListOf<WeakReference<AdhanActivity>>()

        fun intent(context: Context, alarm: AdhanAlarm): Intent =
            Intent(context, AdhanActivity::class.java)
                .putExtra(AdhanService.EXTRA_ALARM, alarm.toJson().toString())
                .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_NO_USER_ACTION)

        /** The recording ended or was stopped elsewhere (face down, the
         * notification): the page says so, or closes. */
        fun endAll(dismiss: Boolean = false) {
            open.mapNotNull { it.get() }.forEach { it.ended(dismiss) }
        }
    }
}
