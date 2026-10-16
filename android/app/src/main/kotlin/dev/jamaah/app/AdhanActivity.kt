package dev.jamaah.app

import android.app.Activity
import android.app.KeyguardManager
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

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        showOverLockScreen()
        open.add(WeakReference(this))

        val alarm = intent.getStringExtra(AdhanService.EXTRA_ALARM)
            ?.let { AdhanAlarm.fromJson(JSONObject(it)) }
        if (alarm == null) {
            finish()
            return
        }
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
            (getSystemService(Context.KEYGUARD_SERVICE) as KeyguardManager)
                .requestDismissKeyguard(this, null)
        } else {
            @Suppress("DEPRECATION")
            window.addFlags(
                WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
                    WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON or
                    WindowManager.LayoutParams.FLAG_DISMISS_KEYGUARD,
            )
        }
        window.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
    }

    private fun dp(value: Float) =
        TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, value, resources.displayMetrics)

    /** Calm and plain, in the app's palette: dark forest, light ink, one green button. */
    private fun layout(alarm: AdhanAlarm) = LinearLayout(this).apply {
        orientation = LinearLayout.VERTICAL
        gravity = Gravity.CENTER
        setBackgroundColor(Color.parseColor("#0F1713"))
        val pad = dp(32f).toInt()
        setPadding(pad, pad, pad, pad)

        addView(TextView(context).apply {
            text = alarm.title
            setTextColor(Color.parseColor("#E8EFE9"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 40f)
            typeface = Typeface.DEFAULT_BOLD
            gravity = Gravity.CENTER
        })
        if (alarm.timeLabel.isNotEmpty()) {
            addView(TextView(context).apply {
                text = alarm.timeLabel
                setTextColor(Color.parseColor("#E8EFE9"))
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 28f)
                gravity = Gravity.CENTER
            })
        }
        addView(TextView(context).apply {
            text = alarm.body
            setTextColor(Color.parseColor("#93A398"))
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 18f)
            gravity = Gravity.CENTER
            setPadding(0, dp(16f).toInt(), 0, dp(48f).toInt())
        })
        addView(Button(context).apply {
            text = alarm.stopLabel
            isAllCaps = false
            setTextColor(Color.WHITE)
            setTextSize(TypedValue.COMPLEX_UNIT_SP, 22f)
            background = GradientDrawable().apply {
                setColor(Color.parseColor("#3F8F69"))
                cornerRadius = dp(28f)
            }
            minHeight = dp(72f).toInt()
            minWidth = dp(220f).toInt()
            setOnClickListener { stop() }
        })
    }

    private fun stop() {
        AdhanService.stop(this)
        ended()
    }

    /** Playing has stopped: the Horizon page says so and waits for Dismiss;
     * the plain page simply closes. */
    private fun ended() {
        window.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        page?.showStopped() ?: finish()
    }

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_VOLUME_UP || keyCode == KeyEvent.KEYCODE_VOLUME_DOWN) {
            stop()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }

    override fun onDestroy() {
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
        fun endAll() {
            open.mapNotNull { it.get() }.forEach { it.ended() }
        }
    }
}
