package dev.jamaah.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/**
 * JVM tests for the pure buffering core of NativeDiagnostics (2026-11-04).
 * The context-dependent shell (load/persist scheduling) stays covered by the
 * device-side evidence pipeline; here the rules themselves are pinned.
 */
class DiagnosticHistoryTest {

    private fun fresh() = DiagnosticHistory(maxEvents = NativeEventRetention.MAX_EVENTS)

    @Test
    fun appendShapesEntriesInWireOrderAndDropsNullValues() {
        val history = fresh()
        history.append(
            at = "2026-11-04T01:42:00.087Z",
            event = "adhan_alarm_receiver_fired",
            lockWaitMs = 3,
            values = mapOf(
                "notificationId" to 207610,
                "kind" to "adhan",
                "reason" to null as String?,
                "entryDeltaMs" to 87,
            ),
        )
        val snapshot = history.snapshot()
        assertEquals(1, snapshot.size)
        val keys = snapshot[0].keys.toList()
        // at, event, then caller values — recordLockWaitMs stays out at <100 ms.
        assertEquals("at", keys[0])
        assertEquals("event", keys[1])
        assertEquals("notificationId", keys[2])
        assertFalse(snapshot[0].containsKey("reason"))
        assertEquals(87, snapshot[0]["entryDeltaMs"])
        // Derived from notificationId because no correlationId was given.
        assertEquals("notification_207610", snapshot[0]["correlationId"])
    }

    @Test
    fun recordLockWaitIsKeptOnlyWhenItReachedTheReportingFloor() {
        val history = fresh()
        history.append("t1", "e1", 99, emptyMap())
        history.append("t2", "e2", 100, emptyMap())
        val snapshot = history.snapshot()
        assertFalse(snapshot[0].containsKey("recordLockWaitMs"))
        assertEquals(100, snapshot[1]["recordLockWaitMs"])
    }

    @Test
    fun correlationIdPrefersTheExplicitValue() {
        val history = fresh()
        history.append(
            "t", "e", null,
            mapOf("correlationId" to "notification_207610", "id" to 5),
        )
        assertEquals("notification_207610", history.snapshot()[0]["correlationId"])
    }

    @Test
    fun correlationIdIsAbsentWithoutAnyIdOrExplicitValue() {
        val history = fresh()
        history.append("t", "e", null, mapOf("reason" to "job_stopped_by_system"))
        assertNull(history.snapshot()[0]["correlationId"])
    }

    @Test
    fun restoreAddsTheEntryExactlyAsStored() {
        val history = fresh()
        history.restore(linkedMapOf("at" to "t", "event" to "d", "correlationId" to "c", "id" to 1))
        val restored = history.snapshot()[0]
        // No re-derivation: the stored shape is authoritative.
        assertEquals(listOf("at", "event", "correlationId", "id"), restored.keys.toList())
    }

    @Test
    fun snapshotAppliesRetentionInPlaceProtectingDeliveryEvents() {
        val history = fresh()
        // Far past the routine cap (180): most routine events must fall away,
        // while every delivery event survives next to the retention window.
        repeat(400) { history.append("2026-11-04T00:0$it", "daily_refresh_started", null, emptyMap()) }
        repeat(10) { history.append("2026-11-04T01:4$it", "adhan_alarm_receiver_fired", null, emptyMap()) }
        repeat(200) { history.append("2026-11-04T02:0$it", "daily_refresh_started", null, emptyMap()) }

        val snapshot = history.snapshot()
        assertEquals(190, snapshot.size)
        assertEquals(10, snapshot.count { it["event"] == "adhan_alarm_receiver_fired" })

        // The buffer itself now holds only the retained entries; a second
        // snapshot is a no-op.
        assertEquals(190, history.size())
        assertEquals(190, history.snapshot().size)
    }

    @Test
    fun snapshotOnAnEmptyBufferIsEmptyAndStaysSafe() {
        val history = fresh()
        assertTrue(history.snapshot().isEmpty())
        assertEquals(0, history.size())
    }

    @Test
    fun softMemoryBoundKeepsTheListWithinTwiceTheCapWithoutExplicitPersist() {
        val history = fresh()
        repeat(1500) { history.append("t$it", "daily_refresh_started", null, emptyMap()) }
        // Growth is capped between persists: the automatic snapshot fires the
        // moment the soft bound is crossed, collapsing the list to the
        // retention window (180 routine entries + the one append that tripped
        // it), and the remaining 299 appends land after it.
        assertTrue(history.size() <= NativeEventRetention.MAX_EVENTS * 2)
        assertEquals(180 + 299, history.size())
    }
}
