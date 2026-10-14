import 'discovery.dart' show distanceMeters;
import 'placeholder_places.dart';

/// A name for a point found by the phone, with no network (2026-10-14): the
/// nearest city in the bundled list when one is within [withinKm], otherwise
/// the city in the name of [ianaZone] ("Africa/Cairo" → "Cairo"). Null when
/// neither gives a name. Only ever said as "near …", never as an address.
String? nearName({
  required double latitude,
  required double longitude,
  required String ianaZone,
  double withinKm = 75,
}) {
  String? best;
  var bestMeters = withinKm * 1000;
  for (final city in placeholderPlaces) {
    final m = distanceMeters(
      fromLatitude: latitude,
      fromLongitude: longitude,
      toLatitude: city.latitude,
      toLongitude: city.longitude,
    );
    if (m <= bestMeters) {
      bestMeters = m;
      best = city.displayName.split(',').first.trim();
    }
  }
  if (best != null) return best;
  final parts = ianaZone.split('/');
  if (parts.length < 2 || ianaZone.startsWith('device/')) return null;
  return parts.last.replaceAll('_', ' ');
}
