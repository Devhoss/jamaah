package dev.jamaah.app

import android.app.job.JobInfo
import android.app.job.JobParameters
import android.app.job.JobScheduler
import android.app.job.JobService
import android.content.ComponentName
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.TimeUnit

/**
 * Renews the two-week notification plan once a day, even when the app is not
 * opened (2026-10-14). Android runs it at a time of its choosing, about once a
 * day; it starts the app's Dart code with no screen (`backgroundRefresh` in
 * main.dart), which reads what is stored and syncs, then says "done".
 *
 * JobScheduler rather than a WorkManager library: it is part of Android, so the
 * app needs no new dependency.
 */
class DailyRefreshJob : JobService() {
    private var engine: FlutterEngine? = null
    private val handler = Handler(Looper.getMainLooper())

    override fun onStartJob(params: JobParameters): Boolean {
        val loader = FlutterInjector.instance().flutterLoader()
        loader.startInitialization(applicationContext)
        loader.ensureInitializationComplete(applicationContext, null)
        val e = FlutterEngine(applicationContext) // registers the plugins
        engine = e
        val messenger = e.dartExecutor.binaryMessenger
        AdhanChannel.register(messenger, applicationContext)
        MethodChannel(messenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "done") {
                result.success(null)
                finish(params)
            } else {
                result.notImplemented()
            }
        }
        // Never longer than a minute, whatever happens on the Dart side.
        handler.postDelayed({ finish(params) }, TimeUnit.MINUTES.toMillis(1))
        e.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint(loader.findAppBundlePath(), ENTRYPOINT),
        )
        return true
    }

    override fun onStopJob(params: JobParameters): Boolean {
        release()
        return true // try again later
    }

    private fun finish(params: JobParameters) {
        if (engine == null) return
        release()
        jobFinished(params, false)
    }

    private fun release() {
        handler.removeCallbacksAndMessages(null)
        engine?.destroy()
        engine = null
    }

    companion object {
        private const val JOB_ID = 7301
        private const val CHANNEL = "dev.jamaah.app/background"
        private const val ENTRYPOINT = "backgroundRefresh"

        /** Asks Android for the daily run, once; kept across reboots. */
        fun schedule(context: Context) {
            val scheduler = context.getSystemService(JobScheduler::class.java) ?: return
            if (scheduler.getPendingJob(JOB_ID) != null) return
            scheduler.schedule(
                JobInfo.Builder(JOB_ID, ComponentName(context, DailyRefreshJob::class.java))
                    .setPeriodic(TimeUnit.HOURS.toMillis(24), TimeUnit.HOURS.toMillis(6))
                    .setPersisted(true)
                    .build(),
            )
        }
    }
}
