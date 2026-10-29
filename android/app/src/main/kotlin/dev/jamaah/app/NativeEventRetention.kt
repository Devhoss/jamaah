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
            event.startsWith("adhan_alarm_cancel_") ||
            event.startsWith("adhan_alarm_replace_") ||
            event.startsWith("adhan_service_") ||
            event.startsWith("adhan_audio_") ||
            event.startsWith("adhan_playback_") ||
            event.endsWith("_failed") ||
            event == "notification_sync_lock_busy" ||
            event == "notification_sync_lock_expired" ||
            event.contains("notification_post") ||
            event.contains("notification_cancel") ||
            event.contains("notification_state") ||
            event.contains("notification_replaced")
}
