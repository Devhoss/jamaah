import 'discovery.dart';
import 'place.dart';

/// How far the phone must have moved before following moves the saved place.
/// Prayer times shift by about a minute per 15–20 km east-west, so a few
/// kilometres around town changes nothing worth a new place, while a new city
/// does.
const followThresholdKm = 10.0;

/// What a follow check does with a fresh fix from the device (2026-11-02:
/// following is automatic, never a travel option).
enum FollowDecision {
  /// The saved place still stands: only the "updated" time moves on.
  keep,

  /// The phone is somewhere else: the fix becomes the saved place, with its
  /// zone, so "today" and every time follow it. Only for a place the device
  /// supplied, which is where the times were coming from anyway.
  replace,

  /// The saved place was picked by hand, so the app does not move it by
  /// itself. The fix is kept as a [FollowOffer] and Today asks; the user
  /// applies it or drops it.
  offer,
}

/// Decides whether [fix] replaces [saved].
///
/// A place the device supplied moves with the phone: replaced when the phone
/// has moved more than [followThresholdKm], or into another time zone (a
/// flight that lands near the border of a zone still changes the clock).
///
/// A place picked by hand is pinned: never replaced silently. A fix that
/// would replace it [FollowDecision.offer]s instead — also on a time-zone
/// change, because a zone move is a strong signal that the pinned place no
/// longer matches reality.
FollowDecision decideFollow({required Place? saved, required Place fix}) {
  if (saved == null) return FollowDecision.replace;
  final moved = _moved(saved, fix);
  if (!moved) return FollowDecision.keep;
  return saved.fromDevice ? FollowDecision.replace : FollowDecision.offer;
}

/// Whether [fix] is not where [saved] is: another zone, or more than
/// [followThresholdKm] away on the same zone.
bool _moved(Place saved, Place fix) {
  if (saved.ianaZone != fix.ianaZone) return true;
  final km =
      distanceMeters(
        fromLatitude: saved.latitude,
        fromLongitude: saved.longitude,
        toLatitude: fix.latitude,
        toLongitude: fix.longitude,
      ) /
      1000;
  return km > followThresholdKm;
}

/// A follow fix that was not applied because the saved place was pinned
/// (picked by hand). Today offers it; applying it un-pins, dismissing drops
/// it. Kept between checks, so a check that finds nothing new (Keep) or the
/// next replace clears it.
class FollowOffer {
  const FollowOffer({required this.place, required this.at});

  /// The fix itself (always device-derived by construction).
  final Place place;

  /// When the check found it, UTC.
  final DateTime at;

  @override
  bool operator ==(Object other) =>
      other is FollowOffer && other.place == place && other.at == at;

  @override
  int get hashCode => Object.hash(place, at);
}
