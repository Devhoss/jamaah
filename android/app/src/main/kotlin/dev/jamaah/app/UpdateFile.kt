package dev.jamaah.app

import java.util.regex.Pattern

/**
 * What the update installer agrees to hand the package installer (2026-10-31,
 * modelled on openGym's UpdateFile): only the update the app itself downloaded
 * into its cache, and only with the checksum the release published next to it.
 * Plain Kotlin, no Android types, so the rules are unit-tested on their own
 * (UpdateFileTest).
 */
internal object UpdateFile {
    /** The one name the updater writes its download under (Jamaah-update.apk). */
    private val NAME = Pattern.compile("Jamaah-update(-[a-z0-9]{1,16})?\\.apk")

    /** A SHA-256 in hex. */
    private val SHA256 = Pattern.compile("[0-9a-fA-F]{64}")

    /** A file name the updater writes: no directory part, one update's shape. */
    fun nameOk(fileName: String?): Boolean =
        fileName != null && NAME.matcher(fileName).matches()

    /** A SHA-256 in hex. Without one nothing is installed: a missing hash is not a pass. */
    fun hashOk(sha256: String?): Boolean =
        sha256 != null && SHA256.matcher(sha256).matches()
}
