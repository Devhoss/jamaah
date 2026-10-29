package dev.jamaah.app

/** Pure helpers used by the Android alarm handoff and playback diagnostics. */
internal object AdhanPlaybackDiagnostics {
    fun isValidAlarmKind(kind: String): Boolean = kind == "adhan" || kind == "iqama"

    fun handoffIfValid(alarm: AdhanAlarm, start: (AdhanAlarm) -> Unit): Boolean {
        if (!isValidAlarmKind(alarm.kind)) return false
        start(alarm)
        return true
    }

    fun isUserFile(recording: String): Boolean = recording.startsWith("/")

    fun usesFlutterAsset(sound: String, recording: String): Boolean =
        !isUserFile(recording) && (sound == "full" || sound == "short") && recording.isNotEmpty()

    fun flutterAssetDescriptorPath(asset: String): String = "flutter_assets/$asset"

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
