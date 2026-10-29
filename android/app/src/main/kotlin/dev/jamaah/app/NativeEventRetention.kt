package dev.jamaah.app

/** Keeps delivery lifecycles ahead of repetitive alarm registration history. */
internal object NativeEventRetention {
    const val MAX_EVENTS = 600
    private const val MAX_ROUTINE_EVENTS = 180

    fun retainedIndices(events: List<String>): List<Int> {
        val retained = events.indices.toMutableList()
        while (retained.size > MAX_EVENTS ||
            retained.count { !isDeliveryEvent(events[it]) } > MAX_ROUTINE_EVENTS
        ) {
            val oldestRoutine = retained.indexOfFirst { !isDeliveryEvent(events[it]) }
            retained.removeAt(if (oldestRoutine >= 0) oldestRoutine else 0)
        }
        return retained
    }

    private fun isDeliveryEvent(event: String): Boolean =
        event.startsWith("adhan_alarm_receiver_") ||
            event.startsWith("adhan_alarm_replace_") ||
            event.startsWith("adhan_service_") ||
            event.startsWith("adhan_audio_") ||
            event.startsWith("adhan_playback_") ||
            event.startsWith("adhan_full_screen_") ||
            event.endsWith("_failed") ||
            event == "notification_sync_lock_busy" ||
            event == "notification_sync_lock_expired" ||
            event.contains("notification_post") ||
            event.contains("notification_cancel") ||
            event.contains("notification_state") ||
            event.contains("notification_replaced")
    // `adhan_alarm_cancel_completed` is deliberately bookkeeping, not delivery:
    // one replace-all emits one per alarm (~80), which overnight crowded the
    // whole next morning's receiver evidence out of the buffer (seen in a
    // device export 2026-10-29, where Fajr's handoff was gone by noon).
}
