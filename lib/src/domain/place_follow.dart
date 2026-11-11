import 'discovery.dart';
import 'place.dart';

/// How far the phone must have moved before a [FollowDecision.offer] is stood
/// for a hand-picked place. Prayer times shift about 2.5 seconds per km
/// east-west at Cairo's latitude, so the gate is about distance, not minutes.
const followThresholdKm = 10.0;

/// What a follow check does with a fresh fix from the device (2026-11-02:
/// following is automatic, never a travel option).
enum FollowDecision {
  /// The saved place still stands: only the "updated" time moves on.
  /// Only ever applies to a pinned (hand-picked) place; a device place
  /// always takes the fresh fix (below), so its name and coordinates can
  /// never go stale behind a small move.
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
/// A place the device supplied moves with the phone: the fresh fix always
/// replaces it, so the saved name, coordinates and zone track the phone on
/// every check, however small the move. Only a pinned (hand-picked) place is
/// gated by [followThresholdKm]: it is never replaced silently, and a fix
/// that would move it [FollowDecision.offer]s instead — also on a time-zone
/// change, because a zone move is a strong signal that the pinned place no
/// longer matches reality. A pinned place that has not moved stays
/// ([FollowDecision.keep]).
FollowDecision decideFollow({required Place? saved, required Place fix}) {
  if (saved == null) return FollowDecision.replace;
  if (saved.fromDevice) return FollowDecision.replace;
  // A pinned place only offers when the fix is somewhere else: another zone,
  // or more than followThresholdKm away on the same zone.
  if (saved.ianaZone != fix.ianaZone) return FollowDecision.offer;
  final km =
      distanceMeters(
        fromLatitude: saved.latitude,
        fromLongitude: saved.longitude,
        toLatitude: fix.latitude,
        toLongitude: fix.longitude,
      ) /
      1000;
  if (km > followThresholdKm) return FollowDecision.offer;
  return FollowDecision.keep;
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
