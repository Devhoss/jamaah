package dev.jamaah.app

import android.content.pm.PackageManager
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The Places key is restricted to this app's package and signing
        // certificate. A request made from Dart has to name both itself, so the
        // certificate is read from the installed package: it is then right for
        // whichever key signed this build, with nothing hard-coded.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "dev.jamaah.app/identity")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signingCertSha1" -> result.success(signingCertSha1())
                    else -> result.notImplemented()
                }
            }
    }

    /** Upper-case hex SHA-1 of the first signing certificate, or null. */
    private fun signingCertSha1(): String? = try {
        val signature = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNING_CERTIFICATES,
            )
            // The certificate the APK is signed with now, which is what Google
            // compares (not the oldest one in a rotation history).
            info.signingInfo?.apkContentsSigners?.firstOrNull()
        } else {
            @Suppress("DEPRECATION")
            packageManager.getPackageInfo(packageName, PackageManager.GET_SIGNATURES)
                .signatures?.firstOrNull()
        }
        signature?.let { sig ->
            MessageDigest.getInstance("SHA-1").digest(sig.toByteArray())
                .joinToString("") { "%02X".format(it) }
        }
    } catch (e: Exception) {
        null
    }
}
