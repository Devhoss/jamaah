import 'dart:math' as math;

/// Where the Kaaba is. Constant for every calculation.
const double kKaabaLatitude = 21.4225241;
const double kKaabaLongitude = 39.8261818;

const double _earthRadiusKm = 6371.0088;

/// Great-circle initial bearing from the given location to the Kaaba, in degrees
/// clockwise from true north (0 = north, 90 = east).
///
/// Unit-tested against known cities (London 118.99°, New York 58.48°,
/// Cairo 136.14°, Jakarta 295.15°).
double qiblaBearingFor({required double latitude, required double longitude}) {
  final phi1 = _radians(latitude);
  final phi2 = _radians(kKaabaLatitude);
  final deltaLambda = _radians(kKaabaLongitude - longitude);

  final y = math.sin(deltaLambda) * math.cos(phi2);
  final x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(deltaLambda);

  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// How many degrees to turn to face the qibla: positive means clockwise.
///
/// Always within ±180, so the compass never sends the user the long way round.
int angleDifference(int headingDegrees, int targetDegrees) {
  final diff = (targetDegrees - headingDegrees) % 360;
  if (diff > 180) return diff - 360;
  if (diff < -180) return diff + 360;
  return diff;
}

/// True when the user is already facing the qibla within [toleranceDegrees].
bool isAligned(
  int headingDegrees,
  int qiblaDegrees, {
  int toleranceDegrees = 3,
}) {
  final diff = (qiblaDegrees - headingDegrees) % 360;
  final magnitude = diff > 180 ? 360 - diff : diff;
  return magnitude <= toleranceDegrees;
}

/// The heading against true north, from a compass that reads magnetic north.
///
/// Qibla bearings are from true north, and an Android compass reads magnetic
/// north: [declination] (east positive, from the platform's World Magnetic
/// Model) is what lies between them, up to several degrees in most places.
double trueHeading(double magneticHeading, double declination) =>
    ((magneticHeading + declination) % 360 + 360) % 360;

/// Great-circle distance to the Kaaba in kilometres (haversine).
double distanceKm({required double latitude, required double longitude}) {
  final phi1 = _radians(latitude);
  final phi2 = _radians(kKaabaLatitude);
  final dPhi = phi2 - phi1;
  final dLambda = _radians(kKaabaLongitude - longitude);

  final a =
      math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) * math.cos(phi2) * math.sin(dLambda / 2) * math.sin(dLambda / 2);
  return 2 * _earthRadiusKm * math.asin(math.sqrt(a));
}

/// Bearing rounded to whole degrees, which is all the UI shows.
int qiblaBearingRounded({required double latitude, required double longitude}) =>
    qiblaBearingFor(latitude: latitude, longitude: longitude).round();

double _radians(double degrees) => degrees * math.pi / 180;
