package dev.jamaah.app

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class AdhanPlaybackDiagnosticsTest {
    private fun alarm(kind: String) = AdhanAlarm(
        id = 207530,
        atMillis = 1_800_000_000_000,
        title = "Adhan",
        body = "Fajr",
        sound = "full",
        recording = "audio/full/fajr.mp3",
        raw = "",
        ringInSilent = false,
        fullScreen = true,
        vibrate = false,
        stopLabel = "Stop",
        timeLabel = "04:00",
        kind = kind,
    )

    @Test
    fun receiverHandoffInvokesServiceStarterForEveryPlannerKind() {
        var started = mutableListOf<String>()

        for (kind in listOf("adhan", "iqama", "preAdhan", "extra")) {
            assertTrue("kind $kind must reach the service", AdhanPlaybackDiagnostics.handoffIfValid(alarm(kind)) { started.add(it.kind) })
        }
        assertEquals(listOf("adhan", "iqama", "preAdhan", "extra"), started)

        started = mutableListOf()
        assertFalse(AdhanPlaybackDiagnostics.handoffIfValid(alarm("unknown")) { started.add(it.kind) })
        assertEquals("a corrupt kind starts nothing", 0, started.size)
    }

    @Test
    fun audioAssetResolutionKeepsUserFilesSeparateFromFlutterAssets() {
        assertTrue(AdhanPlaybackDiagnostics.usesFlutterAsset("full", "audio/full/fajr.mp3"))
        assertTrue(AdhanPlaybackDiagnostics.usesFlutterAsset("short", "audio/short.mp3"))
        assertFalse(AdhanPlaybackDiagnostics.usesFlutterAsset("full", "/data/user/0/recordings/fajr.mp3"))
        assertFalse(AdhanPlaybackDiagnostics.usesFlutterAsset("silent", "audio/full/fajr.mp3"))
        assertEquals(
            "flutter_assets/audio/full/fajr.mp3",
            AdhanPlaybackDiagnostics.flutterAssetDescriptorPath("audio/full/fajr.mp3"),
        )
    }

    @Test
    fun playbackFailureDetailsRetainMediaErrorCodesAndExceptionDetails() {
        assertEquals(
            mapOf("reason" to "media_error", "errorCode" to 100, "extraCode" to -19),
            AdhanPlaybackDiagnostics.failureDetails("media_error", errorCode = 100, extraCode = -19),
        )

        val exception = IllegalStateException("decoder initialization failed")
        assertEquals(
            mapOf(
                "reason" to "prepare_or_start_failed",
                "errorClass" to "IllegalStateException",
                "errorMessage" to "decoder initialization failed",
                "errorCode" to "IllegalStateException",
            ),
            AdhanPlaybackDiagnostics.failureDetails("prepare_or_start_failed", error = exception),
        )
    }
}
