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

/// The bundled sound each Adhan mode plays, or null when the mode has none of
/// its own (the platform's sound, or silence). Full plays [fullRecording].
String? previewAssetFor(
  AdhanSoundMode mode, {
  String fullRecording = kDefaultAdhanRecording,
}) => switch (mode) {
  AdhanSoundMode.full => adhanRecordingById(fullRecording).asset,
  AdhanSoundMode.short => kShortAdhanAsset,
  AdhanSoundMode.standard || AdhanSoundMode.silent => null,
};

class JustAudioPreview implements AudioPreview {
  final _player = AudioPlayer();

  @override
  Future<void> play(String asset) async {
    await _player.stop();
    await _player.setAsset(asset);
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
