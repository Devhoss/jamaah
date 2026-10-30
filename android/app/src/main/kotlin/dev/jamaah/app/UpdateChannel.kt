package dev.jamaah.app

import android.content.Context
import android.content.Intent
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.security.MessageDigest

/**
 * The in-app updater's install step (2026-10-31, modelled on openGym's
 * InstallPlugin): verify the downloaded update APK's SHA-256 by streaming it
 * and let the system package installer take over. An update like Jama'ah's,
 * distributed side-loaded from GitHub Releases, is exactly what this
 * permission flow is for; the "install unknown apps" grant is Android's own
 * prompt at the first install.
 *
 * Usage from Dart (lib/src/data/updates/update_installer.dart):
 *   await UpdateInstaller().install(sha256: '<64 hex>');
 *
 * The file is streamed through SHA-256 before the installer opens, and a
 * mismatch is refused and deleted: a half-finished or tampered download
 * installs nothing. Both arguments are required and checked ([UpdateFile]).
 */
object UpdateChannel {
    const val NAME = "dev.jamaah.app/update"
    private val main = Handler(Looper.getMainLooper())

    fun register(messenger: BinaryMessenger, context: Context) {
        MethodChannel(messenger, NAME).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val fileName = call.argument<String>("fileName")
                    val sha256 = call.argument<String>("sha256")
                    if (!UpdateFile.nameOk(fileName)) {
                        result.error("name", "not an update file name", null)
                        return@setMethodCallHandler
                    }
                    if (!UpdateFile.hashOk(sha256)) {
                        result.error("hash", "sha256 is required", null)
                        return@setMethodCallHandler
                    }
                    // Only the app's own cache directory: an argument never
                    // points anywhere else, whatever it says.
                    val file = File(context.cacheDir, fileName)
                    if (!file.exists()) {
                        result.error("missing", "no $fileName in the cache", null)
                        return@setMethodCallHandler
                    }
                    val expected = sha256!!.trim().lowercase()
                    // A 110 MB read on the platform thread would freeze the
                    // app; the answer must reach the main thread anyway.
                    Thread {
                        val counted = runCatching { digest(file) }
                        main.post {
                            when {
                                counted.isFailure -> result.error(
                                    "hashing",
                                    counted.exceptionOrNull()?.message,
                                    null,
                                )
                                counted.getOrNull() != expected -> {
                                    file.delete()
                                    result.error(
                                        "mismatch",
                                        "the download may be corrupted or tampered with",
                                        null,
                                    )
                                }
                                else -> {
                                    try {
                                        startInstall(context, file)
                                        result.success(true)
                                    } catch (error: Exception) {
                                        result.error("intent", error.message, null)
                                    }
                                }
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startInstall(context: Context, file: File) {
        // The authority is exactly the one the manifest declares; the path
        // configuration (res/xml/file_paths.xml) shares the cache only.
        val uri = FileProvider.getUriForFile(
            context,
            context.packageName + ".fileprovider",
            file,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(
                Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_GRANT_READ_URI_PERMISSION,
            )
        }
        context.startActivity(intent)
    }

    /** Streams [file] through SHA-256; a hundred megabytes stay off the heap. */
    private fun digest(file: File): String {
        val md = MessageDigest.getInstance("SHA-256")
        val buffer = ByteArray(1 shl 16)
        FileInputStream(file).use { stream ->
            while (true) {
                val read = stream.read(buffer)
                if (read < 0) break
                if (read > 0) md.update(buffer, 0, read)
            }
        }
        return md.digest().joinToString("") { "%02x".format(it) }
    }
}
