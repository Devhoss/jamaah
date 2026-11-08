package dev.jamaah.app

/** Pure helpers used by the Android alarm handoff and playback diagnostics. */
internal object AdhanPlaybackDiagnostics {
    /** Every kind the planner hands to the native alarm pathway (2026-10-29):
     * an Adhan, a Jama'ah reminder, the heads-up before an Adhan, and an
     * extra-time alert. All of them start [AdhanService]; a false result means
     * a corrupt payload, which [AdhanAlarmReceiver] keeps in the store for the
     * next sync to repair, never a legitimate alarm. */
    fun isValidAlarmKind(kind: String): Boolean =
        kind == "adhan" || kind == "iqama" || kind == "preAdhan" || kind == "extra"

    fun handoffIfValid(alarm: AdhanAlarm, start: (AdhanAlarm) -> Unit): Boolean {
        if (!isValidAlarmKind(alarm.kind)) return false
        start(alarm)
        return true
    }

    fun isUserFile(recording: String): Boolean = recording.startsWith("/")

    fun usesFlutterAsset(sound: String, recording: String): Boolean =
        !isUserFile(recording) && (sound == "full" || sound == "short") && recording.isNotEmpty()

    // Flutter packs asset entries with spaces percent-encoded
    // ("Mansour%20Al%20Salimi.mp3"), but AssetManager matches entry names
    // exactly: a literal-space lookup throws, and AdhanService then falls
    // back to the short Adhan (tester report, Fajr in the Philippines).
    // Encode like Flutter does when the entry was packed.
    fun flutterAssetDescriptorPath(asset: String): String {
        val out = StringBuilder("flutter_assets/")
        for (c in asset) {
            val unreserved = c in 'A'..'Z' || c in 'a'..'z' || c in '0'..'9' ||
                c == '-' || c == '_' || c == '.' || c == '~' || c == '/'
            if (unreserved) out.append(c)
            else for (b in c.toString().toByteArray(Charsets.UTF_8)) {
                out.append('%')
                out.append("%02X".format(b.toInt() and 0xFF))
            }
        }
        return out.toString()
    }

    fun failureDetails(
        reason: String,
        error: Throwable? = null,
        errorCode: Any? = null,
        extraCode: Any? = null,
    ): Map<String, Any?> = buildMap {
        put("reason", reason)
        error?.let {
            put("errorClass", it.javaClass.simpleName)
            put("errorMessage", it.message)
            if (errorCode == null) put("errorCode", it.javaClass.simpleName)
        }
        errorCode?.let { put("errorCode", it) }
        extraCode?.let { put("extraCode", it) }
    }
}
