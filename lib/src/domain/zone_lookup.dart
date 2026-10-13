import 'package:lat_lng_to_timezone/lat_lng_to_timezone.dart';
import 'package:timezone/timezone.dart' as tz;

/// The IANA time zone at a point on Earth, from a map bundled in the app
/// (package lat_lng_to_timezone, MIT), so no network is needed (2026-10-14).
///
/// A place read from the device takes its zone from where it is, not from
/// the phone's clock setting: someone who lands without changing the phone's
/// zone still gets the place's own times. Open sea maps to the nearest zone.
/// Null when the map's answer is not in the app's time zone database.
String? zoneAt({required double latitude, required double longitude}) {
  try {
    final name = latLngToTimezoneString(latitude, longitude);
    tz.getLocation(name);
    return name;
  } on Object {
    return null;
  }
}

/// `+3`, `+5:30`, `-4`: a UTC offset as people write it.
String utcOffsetLabel(int minutes) {
  final sign = minutes < 0 ? '-' : '+';
  final m = minutes.abs();
  final h = m ~/ 60;
  final rest = m % 60;
  return rest == 0 ? '$sign$h' : '$sign$h:${rest.toString().padLeft(2, '0')}';
}
