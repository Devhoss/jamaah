import 'dart:math' as math;

import 'sky_color.dart';

/// A point in the sun path's 390 × 168 design box.
class PathPoint {
  const PathPoint(this.x, this.y);

  final double x;
  final double y;

  @override
  String toString() =>
      'PathPoint(${x.toStringAsFixed(1)}, ${y.toStringAsFixed(1)})';
}

/// Where the sun is at one minute.
class SunPosition {
  const SunPosition(this.point, this.altitude);

  final PathPoint point;

  /// `sin a` along the arc: 0 on the horizon, 1 at the top of the day arc,
  /// negative on the night arc.
  final double altitude;

  bool get isUp => altitude >= 0;
}

/// How much of each arc is drawn as the travelled trail.
class SunTrail {
  const SunTrail({required this.day, required this.night});

  /// 0..1 of the day arc, from sunrise.
  final double day;

  /// 0..1 of the night arc, from sunset.
  final double night;
}

/// The sun's two arcs and the inverse mapping used for dragging (spec §3.4).
///
/// Coordinates are in a 390 × 168 box; the painter scales them by its width.
/// The day arc runs from sunrise (left) to sunset (right) above the horizon;
/// the night arc runs back below it. Sunrise stays on the left in Arabic too:
/// it is a picture of the sky (spec §5).
class SunPathGeometry {
  const SunPathGeometry({required this.sunrise, required this.sunset})
    : assert(sunset > sunrise);

  /// Sunrise and sunset in the reference day the designs were drawn on.
  static const reference = SunPathGeometry(sunrise: 342, sunset: 1035);

  static const width = 390.0;
  static const height = 168.0;
  static const centreX = 195.0;
  static const horizonY = 118.0;
  static const radiusX = 150.0;
  static const dayRadiusY = 96.0;
  static const nightRadiusY = 36.0;

  /// A drag this far below the horizon still counts as the day arc.
  static const dragSlack = 6.0;

  /// Minutes from midnight.
  final int sunrise;
  final int sunset;

  int get dayLength => sunset - sunrise;
  int get nightLength => 1440 - dayLength;

  static double wrap(double minute) => ((minute % 1440) + 1440) % 1440;

  bool isDay(double minute) {
    final t = wrap(minute);
    return t >= sunrise && t <= sunset;
  }

  /// The sun's place at [minute].
  SunPosition positionAt(double minute) {
    final t = wrap(minute);
    if (t >= sunrise && t <= sunset) {
      final a = math.pi * (t - sunrise) / dayLength;
      return SunPosition(
        PathPoint(
          centreX - radiusX * math.cos(a),
          horizonY - dayRadiusY * math.sin(a),
        ),
        math.sin(a),
      );
    }
    final tt = t < sunrise ? t + 1440 : t;
    final a = math.pi * (tt - sunset) / nightLength;
    return SunPosition(
      PathPoint(
        centreX + radiusX * math.cos(a),
        horizonY + nightRadiusY * math.sin(a),
      ),
      -math.sin(a),
    );
  }

  /// The minute under a touch at ([x], [y]) in the design box: above the
  /// horizon (with a little slack) reads the day arc, below it the night arc.
  double timeAt(double x, double y) {
    final c = ((centreX - x) / radiusX).clamp(-1.0, 1.0);
    if (y <= horizonY + dragSlack) {
      return sunrise + math.acos(c) / math.pi * dayLength;
    }
    return wrap(sunset + math.acos(-c) / math.pi * nightLength);
  }

  /// The travelled part of the arcs at [minute]. A new day starts at midnight:
  /// before sunrise only the night arc since sunset is drawn.
  SunTrail trailAt(double minute) {
    final t = wrap(minute);
    if (t >= sunrise && t <= sunset) {
      return SunTrail(day: (t - sunrise) / dayLength, night: 0);
    }
    final tt = t < sunrise ? t + 1440 : t;
    return SunTrail(
      day: t > sunset ? 1 : 0,
      night: (tt - sunset) / nightLength,
    );
  }

  /// Sun core and disc colours by [altitude]: amber at the horizon, near white
  /// high up.
  static ({SkyRgb core, SkyRgb disc}) sunColours(double altitude) {
    final warm = math.min(1.0, math.max(0.0, altitude) * 2.4);
    return (
      core: SkyRgb.hex('#FFB062').mix(SkyRgb.hex('#FFF4DC'), warm),
      disc: SkyRgb.hex('#FFC27E').mix(SkyRgb.hex('#FFF8EA'), warm),
    );
  }

  /// The sun is drawn faint while it is on the night arc.
  static double sunOpacity(double altitude) => altitude >= 0 ? 1 : 0.28;

  /// The signed minutes from [from] to [to] the short way round the clock.
  static double shortestDelta(double from, double to) {
    var d = wrap(to) - wrap(from);
    if (d > 720) d -= 1440;
    if (d < -720) d += 1440;
    return d;
  }

  /// How long a glide along the arc takes (spec §3.6).
  static Duration glideDuration(double from, double to) {
    final minutes = shortestDelta(from, to).abs();
    return Duration(
      milliseconds: math.min(1200, (380 + 0.9 * minutes).round()),
    );
  }

  /// Ease-in-out cubic, the glide's curve.
  static double glideEase(double f) =>
      f < 0.5 ? 4 * f * f * f : 1 - math.pow(-2 * f + 2, 3) / 2;
}
