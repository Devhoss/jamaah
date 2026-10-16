package dev.jamaah.app

import android.animation.ValueAnimator
import android.app.Activity
import android.content.res.Configuration
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.DashPathEffect
import android.graphics.LinearGradient
import android.graphics.Paint
import android.graphics.RadialGradient
import android.graphics.RectF
import android.graphics.Shader
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.DecelerateInterpolator
import android.widget.Button
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import org.json.JSONObject

/**
 * The full-screen Adhan in the Horizon style (spec §4.2): the prayer's own sky,
 * the sun path as a picture, the prayer's name, a large round Stop with two
 * slow rings while it plays, the Iqama line and how else to stop it. Then
 * "Adhan stopped" and Dismiss.
 *
 * Everything shown was worked out in Dart when the alarm was scheduled
 * (lib/src/app/adhan_screen.dart), so this page draws plain views and appears
 * at once, without starting Flutter.
 */
class AdhanPage(
    private val activity: Activity,
    private val screen: JSONObject,
    private val stopLabel: String,
    private val onStop: () -> Unit,
    private val onDismiss: () -> Unit,
) {
    private val dark = when (screen.optString("theme", "system")) {
        "dark" -> true
        "light" -> false
        else -> (activity.resources.configuration.uiMode and
            Configuration.UI_MODE_NIGHT_MASK) == Configuration.UI_MODE_NIGHT_YES
    }
    private val look: JSONObject =
        screen.optJSONObject(if (dark) "dark" else "light") ?: JSONObject()
    private val arabic = screen.optBoolean("arabic", false)

    private val ink = look.optInt("ink", Color.WHITE)
    private val deep = look.optInt("deep", Color.BLACK)
    private val mute = look.optInt("mute", Color.WHITE)
    private val line = look.optInt("line", Color.WHITE)
    private val fill = look.optInt("fill", ink)

    private val display = font(
        if (arabic) "NotoNaskhArabic-SemiBold.ttf" else "Fraunces-Italic.ttf",
        if (arabic) Typeface.DEFAULT_BOLD else Typeface.create(Typeface.SERIF, Typeface.ITALIC),
    )
    private val ui = font(
        if (arabic) "NotoSansArabic-Regular.ttf" else "InstrumentSans-Regular.ttf",
        Typeface.DEFAULT,
    )
    private val uiStrong = font(
        if (arabic) "NotoSansArabic-SemiBold.ttf" else "InstrumentSans-SemiBold.ttf",
        Typeface.DEFAULT_BOLD,
    )

    private lateinit var stopGroup: View
    private lateinit var stoppedGroup: View
    private lateinit var rings: RingsView
    private lateinit var hint: View

    /** Light ink on the sky means light status-bar icons. */
    val lightInk: Boolean = look.optBoolean("lightInk", true)

    val root: View = build()

    private fun font(file: String, fallback: Typeface): Typeface = try {
        Typeface.createFromAsset(activity.assets, "flutter_assets/assets/fonts/$file")
    } catch (e: Exception) {
        fallback
    }

    private fun dp(value: Float) = TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP, value, activity.resources.displayMetrics,
    )

    private fun text(
        value: String,
        size: Float,
        color: Int,
        face: Typeface = ui,
        spacing: Float = 0f,
    ) = TextView(activity).apply {
        text = value
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
        typeface = face
        gravity = Gravity.CENTER
        letterSpacing = spacing
    }

    private fun build(): View {
        val frame = FrameLayout(activity)
        frame.addView(
            SkyView(activity, look),
            FrameLayout.LayoutParams(MATCH, MATCH),
        )

        val column = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER_HORIZONTAL
            layoutDirection = if (arabic) View.LAYOUT_DIRECTION_RTL else View.LAYOUT_DIRECTION_LTR
            fitsSystemWindows = true
            val pad = dp(24f).toInt()
            setPadding(pad, dp(12f).toInt(), pad, dp(20f).toInt())
        }

        val date = screen.optString("date", "")
        if (date.isNotEmpty()) column.addView(text(date, 14f, mute))
        column.addView(
            SunPathView(activity, screen, look),
            LinearLayout.LayoutParams(MATCH, 0, 0f).apply {
                // Sized from its width in onMeasure.
                height = ViewGroup.LayoutParams.WRAP_CONTENT
                topMargin = dp(8f).toInt()
            },
        )
        column.addView(
            text(
                screen.optString("kicker", ""),
                12f,
                mute,
                uiStrong,
                spacing = if (arabic) 0f else 0.14f,
            ).apply { setPadding(0, dp(18f).toInt(), 0, 0) },
        )
        column.addView(
            text(screen.optString("prayer", ""), if (arabic) 60f else 76f, ink, display)
                .apply {
                    // Fraunces' italic sits low; a little air above it.
                    setPadding(0, dp(2f).toInt(), 0, 0)
                    contentDescription = screen.optString("prayer", "")
                },
        )
        column.addView(text(screen.optString("adhanLine", ""), 18f, mute))

        column.addView(View(activity), LinearLayout.LayoutParams(MATCH, 0, 1f))

        // Playing: the round Stop inside its rings.
        val stop = FrameLayout(activity)
        rings = RingsView(activity, ink)
        stop.addView(rings, FrameLayout.LayoutParams(dp(240f).toInt(), dp(240f).toInt(), Gravity.CENTER))
        stop.addView(
            Button(activity).apply {
                text = stopLabel
                isAllCaps = false
                setTextColor(deep)
                setTextSize(TypedValue.COMPLEX_UNIT_SP, 24f)
                typeface = uiStrong
                stateListAnimator = null
                background = GradientDrawable().apply {
                    shape = GradientDrawable.OVAL
                    setColor(fill)
                }
                contentDescription = screen.optString("stopAccessibility", text.toString())
                setOnClickListener { onStop() }
            },
            FrameLayout.LayoutParams(dp(136f).toInt(), dp(136f).toInt(), Gravity.CENTER),
        )
        stopGroup = stop
        column.addView(stop, LinearLayout.LayoutParams(dp(240f).toInt(), dp(240f).toInt()))

        // Stopped: what happened, and the way out.
        val stopped = LinearLayout(activity).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            visibility = View.GONE
            addView(text(screen.optString("stopped", ""), 24f, ink, uiStrong))
            addView(
                Button(activity).apply {
                    text = screen.optString("dismiss", "")
                    isAllCaps = false
                    setTextColor(ink)
                    setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
                    typeface = uiStrong
                    stateListAnimator = null
                    minHeight = dp(52f).toInt()
                    minWidth = dp(160f).toInt()
                    background = GradientDrawable().apply {
                        cornerRadius = dp(26f)
                        setStroke(dp(1.5f).toInt(), line)
                        setColor(Color.TRANSPARENT)
                    }
                    setOnClickListener { onDismiss() }
                },
                LinearLayout.LayoutParams(WRAP, WRAP).apply { topMargin = dp(20f).toInt() },
            )
        }
        stoppedGroup = stopped
        column.addView(stopped, LinearLayout.LayoutParams(MATCH, dp(240f).toInt()))

        // As much room under the Stop as above it, so it sits in the middle.
        column.addView(View(activity), LinearLayout.LayoutParams(MATCH, 0, 1f))

        val iqama = screen.optString("iqamaLine", "")
        if (iqama.isNotEmpty() && !screen.isNull("iqamaLine")) {
            column.addView(
                text(iqama, 16f, ink).apply { setPadding(0, dp(8f).toInt(), 0, 0) },
            )
        }
        hint = text(screen.optString("hint", ""), 13f, mute).apply {
            setPadding(0, dp(12f).toInt(), 0, 0)
        }
        column.addView(hint)

        frame.addView(column, FrameLayout.LayoutParams(MATCH, MATCH))
        rings.start()
        return frame
    }

    /** The Adhan has stopped (Stop, the volume keys, face down, or its end). */
    fun showStopped() {
        rings.stop()
        stopGroup.visibility = View.GONE
        stoppedGroup.visibility = View.VISIBLE
        // Nothing left to stop.
        hint.visibility = View.INVISIBLE
        stoppedGroup.announceForAccessibility(screen.optString("stopped", ""))
    }

    private companion object {
        const val MATCH = ViewGroup.LayoutParams.MATCH_PARENT
        const val WRAP = ViewGroup.LayoutParams.WRAP_CONTENT
    }
}

/** The sky: five stops, the horizon glow and the shade under the text. */
private class SkyView(context: Activity, private val look: JSONObject) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG)

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        val stops = look.optJSONArray("stops")
        val positions = look.optJSONArray("positions")
        if (stops != null && stops.length() > 1) {
            val colors = IntArray(stops.length()) { stops.getInt(it) }
            val at = FloatArray(stops.length()) {
                positions?.optDouble(it, it / (stops.length() - 1.0))?.toFloat()
                    ?: (it / (stops.length() - 1f))
            }
            paint.shader = LinearGradient(0f, 0f, 0f, h, colors, at, Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)
            paint.shader = null
        }
        // The glow: an ellipse 75% × 16% of the screen at (50%, 22%), fading
        // out at 70% of its radius, as on Today.
        val glow = look.optInt("glow", 0)
        if (Color.alpha(glow) > 0) {
            val rx = w * 0.75f
            val ry = h * 0.16f
            canvas.save()
            canvas.translate(w / 2, h * 0.22f)
            canvas.scale(1f, ry / rx)
            paint.shader = RadialGradient(
                0f, 0f, rx,
                intArrayOf(glow, glow and 0x00FFFFFF),
                floatArrayOf(0f, 0.7f),
                Shader.TileMode.CLAMP,
            )
            canvas.drawCircle(0f, 0f, rx, paint)
            paint.shader = null
            canvas.restore()
        }
        val shade = look.optInt("shade", 0)
        if (Color.alpha(shade) > 0) {
            paint.color = shade
            canvas.drawRect(0f, 0f, w, h, paint)
        }
    }
}

/** The sun path as a picture (spec §3.4): the day arc, the night arc, the
 * prayer markers and the sun at the Adhan, in a 390 × 168 box. */
private class SunPathView(
    context: Activity,
    private val screen: JSONObject,
    look: JSONObject,
) : View(context) {
    private val pathInk = look.optInt("pathInk", Color.WHITE)
    private val stroke = Paint(Paint.ANTI_ALIAS_FLAG).apply {
        style = Paint.Style.STROKE
        strokeCap = Paint.Cap.ROUND
    }
    private val dot = Paint(Paint.ANTI_ALIAS_FLAG)

    init {
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
        // A picture of the sky: sunrise stays on the left in Arabic too.
        layoutDirection = LAYOUT_DIRECTION_LTR
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val w = MeasureSpec.getSize(widthMeasureSpec)
        setMeasuredDimension(w, (w * 168f / 390f).toInt())
    }

    private fun withAlpha(color: Int, alpha: Float) =
        (color and 0x00FFFFFF) or ((alpha * 255).toInt().coerceIn(0, 255) shl 24)

    override fun onDraw(canvas: Canvas) {
        val s = width / 390f
        canvas.save()
        canvas.scale(s, s)
        // Horizon.
        stroke.strokeWidth = 1f
        stroke.pathEffect = null
        stroke.color = withAlpha(pathInk, 0.22f)
        canvas.drawLine(8f, 118f, 382f, 118f, stroke)
        // Day arc above it, night arc below it, dotted.
        stroke.strokeWidth = 2f
        stroke.color = withAlpha(pathInk, 0.55f)
        canvas.drawArc(RectF(45f, 22f, 345f, 214f), 180f, 180f, false, stroke)
        stroke.color = withAlpha(pathInk, 0.3f)
        stroke.pathEffect = DashPathEffect(floatArrayOf(2f, 6f), 0f)
        canvas.drawArc(RectF(45f, 82f, 345f, 154f), 0f, 180f, false, stroke)
        stroke.pathEffect = null
        // The prayers.
        dot.color = withAlpha(pathInk, 0.9f)
        val markers = screen.optJSONArray("markers")
        if (markers != null) {
            for (i in 0 until markers.length()) {
                val p = markers.optJSONArray(i) ?: continue
                canvas.drawCircle(p.optDouble(0).toFloat(), p.optDouble(1).toFloat(), 4f, dot)
            }
        }
        // The sun at the prayer's minute.
        val sun = screen.optJSONObject("sun")
        if (sun != null) {
            val x = sun.optDouble("x").toFloat()
            val y = sun.optDouble("y").toFloat()
            val opacity = sun.optDouble("opacity", 1.0).toFloat()
            val disc = sun.optInt("disc", Color.WHITE)
            val core = sun.optInt("core", Color.WHITE)
            dot.shader = RadialGradient(
                x, y, 30f,
                intArrayOf(withAlpha(disc, 0.45f * opacity), withAlpha(disc, 0f)),
                null,
                Shader.TileMode.CLAMP,
            )
            canvas.drawCircle(x, y, 30f, dot)
            dot.shader = null
            dot.color = withAlpha(disc, opacity)
            canvas.drawCircle(x, y, 11f, dot)
            dot.color = withAlpha(core, opacity)
            canvas.drawCircle(x, y, 7f, dot)
        }
        canvas.restore()
    }
}

/** Two rings that slowly widen from the Stop button while the Adhan plays;
 * still when the phone turns animations off. */
private class RingsView(context: Activity, private val ink: Int) : View(context) {
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply { style = Paint.Style.STROKE }
    private var t = 0.5f
    private var animator: ValueAnimator? = null

    init {
        importantForAccessibility = IMPORTANT_FOR_ACCESSIBILITY_NO
    }

    fun start() {
        if (!ValueAnimator.areAnimatorsEnabled()) return
        animator = ValueAnimator.ofFloat(0f, 1f).apply {
            duration = 3200
            repeatCount = ValueAnimator.INFINITE
            interpolator = DecelerateInterpolator()
            addUpdateListener {
                t = it.animatedValue as Float
                invalidate()
            }
            start()
        }
    }

    fun stop() {
        animator?.cancel()
        animator = null
        visibility = INVISIBLE
    }

    override fun onDetachedFromWindow() {
        animator?.cancel()
        super.onDetachedFromWindow()
    }

    override fun onDraw(canvas: Canvas) {
        val cx = width / 2f
        val cy = height / 2f
        val inner = resources.displayMetrics.density * 68f
        val outer = width / 2f - paint.strokeWidth
        paint.strokeWidth = resources.displayMetrics.density * 1.5f
        for (i in 0 until 2) {
            val f = (t + i * 0.5f) % 1f
            paint.color = (ink and 0x00FFFFFF) or (((1f - f) * 0.45f * 255).toInt() shl 24)
            canvas.drawCircle(cx, cy, inner + (outer - inner) * f, paint)
        }
    }
}
