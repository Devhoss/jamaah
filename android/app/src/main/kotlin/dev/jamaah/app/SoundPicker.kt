package dev.jamaah.app

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.provider.OpenableColumns
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.util.UUID

/**
 * Lets the user pick an audio file from their phone and copies it into the
 * app's own storage (2026-10-15), so a custom Adhan or reminder sound keeps
 * working whatever happens to the original. Android's document picker grants
 * only the chosen file: no storage permission is needed.
 */
class SoundPicker(private val activity: Activity) {
    private var pending: MethodChannel.Result? = null

    fun pick(result: MethodChannel.Result) {
        if (pending != null) {
            result.error("busy", "A file is already being picked", null)
            return
        }
        pending = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT)
            .addCategory(Intent.CATEGORY_OPENABLE)
            .setType("audio/*")
        activity.startActivityForResult(intent, REQUEST)
    }

    /** True when [requestCode] was ours. */
    fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        if (requestCode != REQUEST) return false
        val result = pending ?: return true
        pending = null
        val uri = data?.data
        if (resultCode != Activity.RESULT_OK || uri == null) {
            result.success(null)
            return true
        }
        try {
            result.success(copy(activity, uri))
        } catch (e: Exception) {
            result.error("copy_failed", e.message, null)
        }
        return true
    }

    companion object {
        private const val REQUEST = 7311

        /** Copies [uri] to files/sounds/<uuid>.<ext>; returns its path and name. */
        fun copy(context: Context, uri: Uri): Map<String, String> {
            val name = displayName(context, uri) ?: "Sound"
            val ext = name.substringAfterLast('.', "").takeIf { it.length in 1..5 } ?: "audio"
            val dir = File(context.filesDir, "sounds").apply { mkdirs() }
            val file = File(dir, "${UUID.randomUUID()}.$ext")
            context.contentResolver.openInputStream(uri).use { input ->
                requireNotNull(input) { "Cannot read the file" }
                file.outputStream().use { input.copyTo(it) }
            }
            return mapOf("path" to file.absolutePath, "name" to name.substringBeforeLast('.'))
        }

        private fun displayName(context: Context, uri: Uri): String? =
            context.contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { c -> if (c.moveToFirst()) c.getString(0) else null }
    }
}
