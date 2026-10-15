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
