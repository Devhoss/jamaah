/// Where the Qibla is relative to the way you face, in eight words (spec §4.8),
/// for the in-flight Qibla against the aircraft's nose.
enum QiblaDirection {
  straightAhead,
  aheadRight,
  right,
  behindRight,
  behind,
  behindLeft,
  left,
  aheadLeft;

  /// [degreesClockwise] from the nose (any range; ±180 from `qiblaFromNose`
  /// works): under 15° or over 345° is straight ahead, 15–75 ahead to the
  /// right, 75–105 to the right, 105–165 behind to the right, 165–195 behind,
  /// 195–255 behind to the left, 255–285 to the left, 285–345 ahead to the left.
  static QiblaDirection fromRelative(double degreesClockwise) {
    final d = (degreesClockwise % 360 + 360) % 360;
    if (d < 15 || d > 345) return straightAhead;
    if (d < 75) return aheadRight;
    if (d < 105) return right;
    if (d < 165) return behindRight;
    if (d < 195) return behind;
    if (d < 255) return behindLeft;
    if (d < 285) return left;
    return aheadLeft;
  }
}

/// The eight points of the compass, clockwise from north.
enum CompassPoint {
  north,
  northEast,
  east,
  southEast,
  south,
  southWest,
  west,
  northWest;

  bool get isCardinal => index.isEven;
}

/// A bearing in words for a phone with no compass (spec §4.7): the nearest of
/// the eight points, and, when it is more than 5° off, which way it leans.
///
/// - On a cardinal point it leans [toward] the next cardinal: "South, a
///   little towards the west".
/// - On an intercardinal point it leans [toward] the nearer of its two
///   cardinals, [away] from the other: "South-west, a little more west than
///   south".
class CompassWords {
  const CompassWords(this.point, {this.toward, this.away});

  /// [bearing] in degrees clockwise from true north.
  factory CompassWords.of(double bearing) {
    final b = (bearing % 360 + 360) % 360;
    final index = (b / 45).round() % 8;
    final point = CompassPoint.values[index];
    var d = b - index * 45.0;
    if (d > 180) d -= 360;
    if (d < -180) d += 360;
    if (d.abs() <= 5) return CompassWords(point);
    final clockwise = d > 0;
    if (point.isCardinal) {
      final next = CompassPoint.values[(index + (clockwise ? 2 : 6)) % 8];
      return CompassWords(point, toward: next);
    }
    final after = CompassPoint.values[(index + 1) % 8];
    final before = CompassPoint.values[(index + 7) % 8];
    return clockwise
        ? CompassWords(point, toward: after, away: before)
        : CompassWords(point, toward: before, away: after);
  }

  final CompassPoint point;

  /// The cardinal it leans toward, if it leans.
  final CompassPoint? toward;

  /// For an intercardinal point that leans, the cardinal it leans from.
  final CompassPoint? away;
}
