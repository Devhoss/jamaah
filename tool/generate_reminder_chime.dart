// Generates the Jama’ah reminder chime: two soft bell-like notes, rising.
//
//   dart run tool/generate_reminder_chime.dart
//
// The sound is synthesised here, so the project owns it outright: no recording,
// no licence. It is written twice, byte for byte: the notification channel's
// sound and the copy Settings previews. Changing it means bumping
// kReminderChimeVersion in lib/src/domain/notification_channels.dart, because
// Android fixes a channel's sound when the channel is created.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _rate = 22050;

void main() {
  final samples = chime();
  final wav = _wav(samples);
  for (final path in const [
    'android/app/src/main/res/raw/reminder_chime.wav',
    'assets/audio/chime/reminder_chime.wav',
  ]) {
    File(path)
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(wav);
    stdout.writeln('wrote $path (${wav.length} bytes)');
  }
}

/// G5 then C6, a fourth apart, each a struck tone with two quiet overtones
/// that dies away over about a second. 1.8 s in all.
Float64List chime() {
  final out = Float64List((_rate * 1.8).round());
  void note(double startS, double freq, double gain) {
    final start = (startS * _rate).round();
    for (var i = 0; start + i < out.length; i++) {
      final t = i / _rate;
      // A 6 ms rise so there is no click, then an exponential decay.
      final attack = math.min(1.0, t / 0.006);
      final env = attack * math.exp(-t * 3.2);
      final v =
          math.sin(2 * math.pi * freq * t) +
          0.28 * math.sin(2 * math.pi * freq * 2.0 * t) * math.exp(-t * 4) +
          0.12 * math.sin(2 * math.pi * freq * 3.01 * t) * math.exp(-t * 6);
      out[start + i] += gain * env * v;
    }
  }

  note(0.0, 783.99, 0.42);
  note(0.32, 1046.5, 0.38);

  // The last 150 ms fade to silence so the file never ends mid-wave.
  final fade = (0.15 * _rate).round();
  for (var i = 0; i < fade; i++) {
    out[out.length - 1 - i] *= i / fade;
  }
  return out;
}

Uint8List _wav(Float64List samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int at, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(at + i, s.codeUnitAt(i));
    }
  }

  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little); // PCM
  data.setUint16(22, 1, Endian.little); // mono
  data.setUint32(24, _rate, Endian.little);
  data.setUint32(28, _rate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final s = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, s, Endian.little);
  }
  return data.buffer.asUint8List();
}
