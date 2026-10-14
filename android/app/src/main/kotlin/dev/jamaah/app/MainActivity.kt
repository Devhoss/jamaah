package dev.jamaah.app

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.hardware.GeomagneticField
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.security.MessageDigest

class MainActivity : FlutterActivity() {
    private var pendingLocation: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger

        // The Places key is restricted to this app's package and signing
        // certificate. A request made from Dart has to name both itself, so the
        // certificate is read from the installed package: it is then right for
        // whichever key signed this build, with nothing hard-coded.
        MethodChannel(messenger, "dev.jamaah.app/identity")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "signingCertSha1" -> result.success(signingCertSha1())
                    else -> result.notImplemented()
                }
            }

        // The Adhans the app plays itself: see AdhanChannel.
        AdhanChannel.register(messenger, this)

        // The plan is renewed daily even when the app is not opened.
        DailyRefreshJob.schedule(this)

        // Location is asked for at two levels: approximate for prayer times,
        // precise only when the user searches for mosques nearby. A plugin that
        // requests every location permission in the manifest would offer precise
        // at the first prompt, so the request is made here with exactly the
        // permissions each step needs.
        MethodChannel(messenger, "dev.jamaah.app/location")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "status" -> result.success(locationStatus())
                    "request" -> requestLocation(call.argument<Boolean>("precise") == true, result)
                    else -> result.notImplemented()
                }
            }

        // The compass reads magnetic north; the Qibla bearing is from true
        // north. Android's World Magnetic Model gives the difference, offline.
        MethodChannel(messenger, "dev.jamaah.app/compass")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "declination" -> {
                        val lat = call.argument<Double>("latitude")
                        val lng = call.argument<Double>("longitude")
                        if (lat == null || lng == null) {
                            result.error("args", "latitude and longitude are required", null)
                        } else {
                            val field = GeomagneticField(
                                lat.toFloat(),
                                lng.toFloat(),
                                0f,
                                System.currentTimeMillis(),
                            )
                            result.success(field.declination.toDouble())
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun granted(permission: String) =
        checkSelfPermission(permission) == PackageManager.PERMISSION_GRANTED

    private fun locationStatus(): Map<String, Boolean> = mapOf(
        "fine" to granted(Manifest.permission.ACCESS_FINE_LOCATION),
        "coarse" to granted(Manifest.permission.ACCESS_COARSE_LOCATION),
        // False after a "don't ask again" (or a second denial on Android 11+):
        // the system will not show the dialog, only Settings can change it.
        "canAsk" to (
            granted(Manifest.permission.ACCESS_COARSE_LOCATION) ||
                shouldShowRequestPermissionRationale(Manifest.permission.ACCESS_COARSE_LOCATION) ||
                !askedBefore()
            ),
    )

    private fun requestLocation(precise: Boolean, result: MethodChannel.Result) {
        if (pendingLocation != null) {
            result.error("busy", "A location request is already showing", null)
            return
        }
        val wanted = if (precise) {
            // Android 12+ requires coarse alongside fine; the dialog then lets the
            // user choose precise or approximate.
            arrayOf(Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION)
        } else {
            arrayOf(Manifest.permission.ACCESS_COARSE_LOCATION)
        }
        if (wanted.all { granted(it) }) {
            result.success(locationStatus())
            return
        }
        pendingLocation = result
        markAsked()
        requestPermissions(wanted, LOCATION_REQUEST)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray,
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != LOCATION_REQUEST) return
        pendingLocation?.success(locationStatus())
        pendingLocation = null
    }

    private fun askedBefore() =
        getPreferences(MODE_PRIVATE).getBoolean("location_asked", false)

    private fun markAsked() =
        getPreferences(MODE_PRIVATE).edit().putBoolean("location_asked", true).apply()

    /** Upper-case hex SHA-1 of the signing certificate, or null. */
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

    private companion object {
        const val LOCATION_REQUEST = 7301
    }
}
