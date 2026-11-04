package dev.jamaah.app

/**
 * Pure, Android-free core of the native diagnostics history buffer, extracted
 * so the buffering rules are JVM-unit-testable without a device (2026-11-04).
 *
 * Why: NativeDiagnostics.record used to re-read and re-serialise the whole
 * stored buffer on every single event. A fired adhan emits ~18 events within
 * ~150 ms, so the main thread churned the entire history (up to 600 rich
 * entries) that many times per alarm — the background ANR Sentry captured on
 * the Galaxy A53 (@1.0.6+7, main thread in JSONArray.toString, 04:54 Kuwait)
 * and the sluggish feel of the app on that phone. Now record() appends in
 * ~O(1) and one coalesced writer persists the buffer per burst.
 *
 * Entries keep the exact wire format the reports have always used —
 * at, event, [recordLockWaitMs], caller values (nulls dropped), derived
 * correlationId in that key order — so Dart-side report composition needs no
 * change. Callers serialise access (NativeDiagnostics holds its lock).
 */
internal class DiagnosticHistory(private val maxEvents: Int) {

    private val entries = ArrayList<LinkedHashMap<String, Any?>>()

    fun size(): Int = entries.size

    fun all(): List<Map<String, Any?>> = entries.toList()

    /** Appends one shaped entry following the report wire format. */
    fun append(at: String, event: String, lockWaitMs: Int?, values: Map<String, Any?>) {
        val entry = LinkedHashMap<String, Any?>()
        entry["at"] = at
        entry["event"] = event
        if (lockWaitMs != null && lockWaitMs >= 100) entry["recordLockWaitMs"] = lockWaitMs
        values.forEach { (key, value) -> if (value != null) entry[key] = value }
        val alarmId = (values["alarmId"] as? Number)?.toInt()
            ?: (values["notificationId"] as? Number)?.toInt()
            ?: (values["id"] as? Number)?.toInt()
        val correlationId = values["correlationId"] as? String
            ?: alarmId?.let { "notification_$it" }
        if (correlationId != null) entry["correlationId"] = correlationId
        entries.add(entry)
        // Soft memory bound: retention normally runs once per persist, but a
        // runaway caller must not be allowed to grow the list without limit.
        if (entries.size > maxEvents * 2) snapshot()
    }

    /** Restores an already-shaped entry loaded from storage; no derivation. */
    fun restore(entry: Map<String, Any?>) {
        entries.add(LinkedHashMap(entry))
    }

    /** Applies retention in place and returns the retained entries. */
    fun snapshot(): List<Map<String, Any?>> {
        if (entries.isEmpty()) return emptyList()
        val indices = NativeEventRetention.retainedIndices(
            entries.map { entry -> entry["event"].toString() },
        )
        val retained = indices.map { entries[it] }
        entries.clear()
        entries.addAll(retained)
        return retained
    }
}
