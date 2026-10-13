// Writes the clearly marked PLACEHOLDER Adhan tones the app ships until a real
// recording with clear usage rights is chosen (AGENTS.md, docs/audio-licence.md).
//
//   dart run tool/generate_placeholder_tones.dart
//
// They are synthesised here, so there is nothing to license: soft sine chimes,
// not an Adhan. Swapping in a recording means replacing these files (same names)
// and bumping kAdhanToneVersion in lib/src/domain/notification_channels.dart,
// so Android creates new channels with the new sound.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

const _sampleRate = 22050;

void main() {
  // A rising fourth and back: calm, short, unmistakably a chime.
  final shortTone = _phrase();
  // The same phrase four times with rests, about 30 seconds, standing in for the
  // full Adhan that the app plays itself.
  final fullTone = [
    for (var i = 0; i < 4; i++) ...[..._phrase(), ..._silence(3.0)],
  ];

  _write('android/app/src/main/res/raw/adhan_short_placeholder.wav', shortTone);
  _write('assets/audio/adhan_short_placeholder.wav', shortTone);
  _write('assets/audio/adhan_full_placeholder.wav', fullTone);
  // Played by the app's own Adhan service (native), which reads raw resources.
  _write('android/app/src/main/res/raw/adhan_full_placeholder.wav', fullTone);
}

List<double> _phrase() => [
  ..._note(440.00, 1.2), // A4
  ..._note(587.33, 1.2), // D5
  ..._note(659.25, 1.6), // E5
  ..._note(587.33, 2.2), // D5, held
];

List<double> _note(double hz, double seconds) {
  final n = (seconds * _sampleRate).round();
  return [
    for (var i = 0; i < n; i++)
      () {
        final t = i / _sampleRate;
        // Soft attack, long decay: a bell, not a beep.
        final envelope = math.min(1.0, t / 0.04) * math.exp(-2.2 * t / seconds);
        final tone =
            math.sin(2 * math.pi * hz * t) +
            0.25 * math.sin(2 * math.pi * hz * 2 * t);
        return 0.32 * envelope * tone;
      }(),
  ];
}

List<double> _silence(double seconds) =>
    List.filled((seconds * _sampleRate).round(), 0.0);

void _write(String path, List<double> samples) {
  final data = ByteData(44 + samples.length * 2);
  void ascii(int offset, String s) {
    for (var i = 0; i < s.length; i++) {
      data.setUint8(offset + i, s.codeUnitAt(i));
    }
  }

  // 16-bit PCM mono WAV.
  ascii(0, 'RIFF');
  data.setUint32(4, 36 + samples.length * 2, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, _sampleRate, Endian.little);
  data.setUint32(28, _sampleRate * 2, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  data.setUint32(40, samples.length * 2, Endian.little);
  for (var i = 0; i < samples.length; i++) {
    final v = (samples[i].clamp(-1.0, 1.0) * 32767).round();
    data.setInt16(44 + i * 2, v, Endian.little);
  }

  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(data.buffer.asUint8List());
  stdout.writeln(
    'wrote $path (${(samples.length / _sampleRate).toStringAsFixed(1)} s)',
  );
}
