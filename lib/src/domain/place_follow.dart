import 'discovery.dart';
import 'place.dart';

/// How far the phone must have moved before "Follow my location" replaces the
/// saved place. Prayer times shift by about a minute per 15–20 km east-west, so
/// a few kilometres around town changes nothing worth a new place, while a new
/// city does.
const followThresholdKm = 10.0;

/// What "Follow my location" does with a fresh fix from the device.
enum FollowDecision {
  /// The saved place still stands: only the "updated" time moves on.
  keep,

  /// The phone is somewhere else: the fix becomes the saved place, with its zone,
  /// so "today" and every time follow it.
  replace,
}

/// Decides whether [fix] replaces [saved].
///
/// A place the user picked from the list is replaced by the first fix: turning
/// on "Follow my location" asked for exactly that. A device place is replaced
/// when the phone has moved more than [followThresholdKm], or into another time
/// zone (a flight that lands near the border of a zone still changes the clock).
FollowDecision decideFollow({required Place? saved, required Place fix}) {
  if (saved == null || !saved.fromDevice) return FollowDecision.replace;
  if (saved.ianaZone != fix.ianaZone) return FollowDecision.replace;
  final km =
      distanceMeters(
        fromLatitude: saved.latitude,
        fromLongitude: saved.longitude,
        toLatitude: fix.latitude,
        toLongitude: fix.longitude,
      ) /
      1000;
  return km > followThresholdKm ? FollowDecision.replace : FollowDecision.keep;
}
