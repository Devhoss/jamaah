import 'dart:math' as math;

import 'sun_path_geometry.dart';

/// Where and how the moon is drawn at one minute.
class MoonPlacement {
  const MoonPlacement({
    required this.point,
    required this.rotationDegrees,
    required this.opacity,
  });

  final PathPoint point;

  /// Turns the drawing so its lit side (+x) faces the sun.
  final double rotationDegrees;

  /// 0 when the moon is below the horizon.
  final double opacity;

  bool get visible => opacity > 0;
}

/// The moon's phase and place, from the Hijri day (spec §3.5).
///
/// An illustration, not astronomy: it only has to be right enough that a young
/// crescent hangs low in the west after Maghrib.
class MoonPhase {
  const MoonPhase(this.age);

  /// Age in days ≈ Hijri day − 0.5 (the day after the user's Hijri adjustment).
  factory MoonPhase.fromHijriDay(int hijriDay) => MoonPhase(hijriDay - 0.5);

  static const synodicMonth = 29.53;

  /// The moon rises later each day by about this many minutes.
  static const lagMinutesPerDay = 50.5;

  static const opacityWhileSunUp = 0.35;
  static const opacityAfterSunset = 0.95;

  /// The unlit disc's fill.
  static const discFill = 0.12;

  final double age;

  /// Illuminated fraction k, 0 (new) .. 1 (full).
  double get illuminated =>
      (1 - math.cos(2 * math.pi * age / synodicMonth)) / 2;

  /// Less than half lit: the terminator bulges toward the lit side.
  bool get isCrescent => illuminated < 0.5;

  /// The x-radius of the terminator ellipse for a moon of [radius].
  double terminatorRadius(double radius) =>
      radius * (1 - 2 * illuminated).abs();

  /// The minute whose sun position the moon takes: it trails the sun.
  double moonMinute(double minute) => minute - age * lagMinutesPerDay;

  /// The moon at [minute] on [path].
  MoonPlacement placeAt(SunPathGeometry path, double minute) {
    final mt = moonMinute(minute);
    final moon = path.positionAt(mt).point;
    final sun = path.positionAt(minute);
    final angle = math.atan2(sun.point.y - moon.y, sun.point.x - moon.x);
    final up = path.isDay(mt);
    return MoonPlacement(
      point: moon,
      rotationDegrees: angle * 180 / math.pi,
      opacity: !up
          ? 0
          : (sun.altitude > 0 ? opacityWhileSunUp : opacityAfterSunset),
    );
  }
}
