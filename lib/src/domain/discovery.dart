import 'dart:math' as math;

import 'mosque.dart';

/// Finding mosques near a point, behind one interface so the provider is a
/// configuration choice (AGENTS.md: Google Places by default, OpenStreetMap for
/// comparison).
abstract interface class MosqueDiscoveryProvider {
  /// Which source the results are labelled with. There is no verification, so
  /// the source is all the app can honestly say about a result.
  MosqueSource get source;

  Future<DiscoveryResult> nearby(DiscoveryQuery query);
}

/// Where to look, and how far.
class DiscoveryQuery {
  const DiscoveryQuery({
    required this.latitude,
    required this.longitude,
    this.radiusMeters = defaultRadiusMeters,
  });

  /// Walking-and-short-drive distance: wide enough to find the mosque the user
  /// actually goes to, small enough that the list stays about that.
  static const defaultRadiusMeters = 5000;

  final double latitude;
  final double longitude;
  final int radiusMeters;

  /// Identifies one exact search, for sharing a request already in flight and
  /// for logs. Nearby-but-different points are matched by distance instead.
  String get cacheKey =>
      '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)},'
      '$radiusMeters';

  @override
  bool operator ==(Object other) =>
      other is DiscoveryQuery && other.cacheKey == cacheKey;

  @override
  int get hashCode => cacheKey.hashCode;
}

/// One search result, mapped from whichever provider served it.
///
/// It is not a saved mosque: saving copies the place id and the name and address
/// the user confirms, so nothing here is treated as verified.
class DiscoveredMosque {
  const DiscoveredMosque({
    required this.placeId,
    required this.source,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  /// The provider's own id: a Google place id, or `osm:node/123` for OSM.
  final String placeId;
  final MosqueSource source;

  /// Null when the provider has no name for it (common on OpenStreetMap). The UI
  /// says so and asks the user to name it before saving.
  final String? name;

  /// Empty when the provider has no address.
  final String address;

  final double latitude;
  final double longitude;

  /// Metres from the point that was searched.
  double distanceFrom(DiscoveryQuery query) => distanceMeters(
    fromLatitude: query.latitude,
    fromLongitude: query.longitude,
    toLatitude: latitude,
    toLongitude: longitude,
  );

  @override
  bool operator ==(Object other) =>
      other is DiscoveredMosque &&
      other.placeId == placeId &&
      other.source == source &&
      other.name == name &&
      other.address == address &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(placeId, source);

  @override
  String toString() => 'DiscoveredMosque($source $placeId "$name")';
}

/// What a search can come back with. Each failure is its own case so the screen
/// can say what happened and what the user can do instead.
sealed class DiscoveryResult {
  const DiscoveryResult();
}

/// Results, nearest first. May be empty: "no mosques found here" is an answer.
final class DiscoveryFound extends DiscoveryResult {
  const DiscoveryFound({required this.source, required this.mosques});

  final MosqueSource source;
  final List<DiscoveredMosque> mosques;
}

/// The Google provider was selected but no key was configured. Nothing was sent.
final class DiscoveryNoKey extends DiscoveryResult {
  const DiscoveryNoKey();
}

/// This session has used its share of requests (protects the free tier).
final class DiscoveryLimitReached extends DiscoveryResult {
  const DiscoveryLimitReached();
}

final class DiscoveryFailed extends DiscoveryResult {
  const DiscoveryFailed(this.reason);

  final DiscoveryFailure reason;
}

enum DiscoveryFailure {
  /// No connection, or the request timed out.
  network,

  /// The provider refused the key (restrictions, API not enabled, billing).
  keyRejected,

  /// The provider's own quota or rate limit.
  rateLimited,

  /// Anything else the provider answered with.
  server,
}

/// Results nearest first, each one once.
List<DiscoveredMosque> nearestFirst(
  Iterable<DiscoveredMosque> mosques,
  DiscoveryQuery query,
) {
  final seen = <String>{};
  final unique = [
    for (final m in mosques)
      if (seen.add(m.placeId)) m,
  ];
  unique.sort((a, b) => a.distanceFrom(query).compareTo(b.distanceFrom(query)));
  return unique;
}

const double _earthRadiusMeters = 6371008.8;

/// Great-circle distance in metres (haversine).
double distanceMeters({
  required double fromLatitude,
  required double fromLongitude,
  required double toLatitude,
  required double toLongitude,
}) {
  final phi1 = _radians(fromLatitude);
  final phi2 = _radians(toLatitude);
  final dPhi = phi2 - phi1;
  final dLambda = _radians(toLongitude - fromLongitude);
  final a =
      math.sin(dPhi / 2) * math.sin(dPhi / 2) +
      math.cos(phi1) *
          math.cos(phi2) *
          math.sin(dLambda / 2) *
          math.sin(dLambda / 2);
  return 2 * _earthRadiusMeters * math.asin(math.sqrt(a));
}

double _radians(double degrees) => degrees * math.pi / 180;
