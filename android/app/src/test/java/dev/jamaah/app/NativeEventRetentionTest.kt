package dev.jamaah.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class NativeEventRetentionTest {
    @Test
    fun registrationBurstsDoNotEvictSeveralDeliveryLifecycles() {
        val events = buildList {
            repeat(800) { add("adhan_alarm_registration_completed") }
            repeat(8) { alarm ->
                add("adhan_alarm_receiver_fired_$alarm")
                add("adhan_service_foreground_established_$alarm")
                add("adhan_notification_post_returned_$alarm")
                add("adhan_audio_source_selected_$alarm")
                add("adhan_playback_started_$alarm")
                add("adhan_playback_completed_$alarm")
            }
        }

        val retained = NativeEventRetention.retainedIndices(events).map(events::get)

        assertEquals(48, retained.count { it.startsWith("adhan_alarm_receiver_fired_") ||
            it.startsWith("adhan_service_foreground_established_") ||
            it.startsWith("adhan_notification_post_returned_") ||
            it.startsWith("adhan_audio_source_selected_") ||
            it.startsWith("adhan_playback_started_") ||
            it.startsWith("adhan_playback_completed_") })
        assertTrue(retained.size <= NativeEventRetention.MAX_EVENTS)
        assertTrue(retained.count { it == "adhan_alarm_registration_completed" } <= 180)
    }

    @Test
    fun oldestRoutineEventsAreDiscardedFirst() {
        val events = buildList {
            add("adhan_alarm_receiver_fired")
            repeat(181) { add("adhan_alarm_registration_completed") }
        }

        val retained = NativeEventRetention.retainedIndices(events).map(events::get)

        assertTrue("receiver event must survive routine registrations", retained.contains("adhan_alarm_receiver_fired"))
        assertEquals(180, retained.count { it == "adhan_alarm_registration_completed" })
    }

    @Test
    fun frequentLockBookkeepingDoesNotCrowdOutReceiverEvidence() {
        val events = buildList {
            add("adhan_alarm_receiver_fired")
            repeat(500) { add("notification_sync_lock_released") }
        }

        val retained = NativeEventRetention.retainedIndices(events).map(events::get)

        assertTrue(retained.contains("adhan_alarm_receiver_fired"))
        assertTrue(retained.size <= NativeEventRetention.MAX_EVENTS)
    }

    @Test
    fun replaceAllCancelBurstsDoNotEvictReceiverEvidence() {
        val events = buildList {
            add("adhan_alarm_receiver_fired")
            add("adhan_service_foreground_established")
            add("adhan_full_screen_shown")
            // One replace-all of a two-week plan cancels ~80 alarms at once;
            // this is bookkeeping, not delivery (2026-10-29).
            repeat(300) { add("adhan_alarm_cancel_completed") }
        }

        val retained = NativeEventRetention.retainedIndices(events).map(events::get)

        assertTrue("receiver evidence must survive a replace-all", retained.contains("adhan_alarm_receiver_fired"))
        assertTrue(retained.contains("adhan_service_foreground_established"))
        assertTrue(retained.contains("adhan_full_screen_shown"))
        assertTrue(retained.size <= NativeEventRetention.MAX_EVENTS)
    }
}
