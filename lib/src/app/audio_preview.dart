import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/adhan_alerts.dart';
import '../domain/adhan_recordings.dart';

/// Plays a bundled sound for "Preview" in the alert settings, and stops it.
abstract interface class AudioPreview {
  /// Completes when the sound has finished or was stopped.
  Future<void> play(String asset);
  Future<void> stop();
}

/// The sound each Adhan mode plays, or null when the mode has none of its own
/// (the platform's sound, or silence). Full plays [fullSource]: a bundled
/// asset or the user's own file.
String? previewAssetFor(
  AdhanSoundMode mode, {
  String? fullSource,
  ShortAdhan shortAdhan = ShortAdhan.azanShort,
}) => switch (mode) {
  AdhanSoundMode.full =>
    fullSource ?? adhanRecordingById(kDefaultAdhanRecording).asset,
  AdhanSoundMode.short => shortAdhan.asset,
  AdhanSoundMode.standard || AdhanSoundMode.silent => null,
};

class JustAudioPreview implements AudioPreview {
  final _player = AudioPlayer();

  /// just_audio copies each asset to a cache file named after its path and
  /// reuses it, so a sound replaced under the same name in an update would
  /// keep playing the old file. Cleared once per launch, before first use.
  static Future<void>? _cacheCleared;

  @override
  Future<void> play(String asset) async {
    await (_cacheCleared ??= AudioPlayer.clearAssetCache().catchError((_) {}));
    await _player.stop();
    // The user's own sounds are files (2026-10-15); the rest are assets.
    if (asset.startsWith('/')) {
      await _player.setFilePath(asset);
    } else {
      await _player.setAsset(asset);
    }
    await _player.play();
  }

  @override
  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}

final audioPreviewProvider = Provider<AudioPreview>((ref) {
  final preview = JustAudioPreview();
  ref.onDispose(preview.dispose);
  return preview;
});
