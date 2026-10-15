import 'dart:math' as math;

/// One star, in the design's 390-wide frame (x scales with the screen width;
/// y stays in logical pixels from the top).
class Star {
  const Star({
    required this.x,
    required this.y,
    required this.size,
    required this.brightness,
    required this.period,
    required this.phase,
  });

  final double x;
  final double y;

  /// Diameter, 0.8..2.4 px.
  final double size;

  /// Fades with height: `max(0.25, 1 − y/320)`.
  final double brightness;

  /// Seconds per twinkle, 2.6..5.6 (rounded so it divides [StarField.loop]).
  final double period;

  /// 0..1 offset into the twinkle.
  final double phase;

  /// Opacity at [seconds] into the motion loop: 0.25 → 1 → 0.25 per period,
  /// times [brightness]. Steady (the brightest point) when motion is off.
  double opacityAt(double? seconds) {
    if (seconds == null) return brightness;
    final f = ((seconds / period) + phase) % 1;
    final wave = (1 - math.cos(2 * math.pi * f)) / 2; // 0 → 1 → 0
    return brightness * (0.25 + 0.75 * wave);
  }
}

/// The seeded star field (spec §3.3): 46 stars in the top 300 px, the same
/// positions every time. Same generator as the design prototype.
abstract final class StarField {
  static const count = 46;
  static const frameWidth = 390.0;
  static const height = 300.0;

  /// Every animated part of the sky repeats within this many seconds, so one
  /// looping controller can drive them all without a visible jump.
  static const loop = 48.0;

  static final List<Star> stars = _generate();

  static List<Star> _generate() {
    var seed = 7;
    double rnd() {
      seed = (seed * 9301 + 49297) % 233280;
      return seed / 233280;
    }

    return List.unmodifiable([
      for (var i = 0; i < count; i++)
        () {
          final x = rnd() * frameWidth;
          final y = rnd() * height;
          final size = 0.8 + rnd() * 1.6;
          final delay = rnd() * 4;
          final rawPeriod = 2.6 + rnd() * 3;
          // Snap to loop / n so the loop is seamless.
          final n = (loop / rawPeriod).round().clamp(9, 18);
          final period = loop / n;
          return Star(
            x: x,
            y: y,
            size: size,
            brightness: math.max(0.25, 1 - y / 320),
            period: period,
            phase: (delay / period) % 1,
          );
        }(),
    ]);
  }
}
