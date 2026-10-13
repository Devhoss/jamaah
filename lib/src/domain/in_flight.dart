import 'dart:math' as math;

import 'prayer.dart';
import 'prayer_times_calculator.dart';
import 'prayer_times_parameters.dart';
import 'qibla.dart' as qibla;
import 'time_model.dart';
import 'today.dart';
import 'zone_offsets.dart';

/// In-flight mode, phase 1 (2026-10-14; plan in docs/in-flight-mode.md).
///
/// Everything here works from a GPS fix alone: no network, and no reliance on
/// the phone's clock being set to where the aircraft is.

/// One GPS reading aboard.
class InFlightFix {
  const InFlightFix({
    required this.latitude,
    required this.longitude,
    required this.at,
    this.altitudeMeters = 0,
    this.speedMetersPerSecond,
    this.courseDegrees,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;

  /// When the fix was taken, UTC.
  final DateTime at;

  /// Height above sea level. Negative or missing readings count as 0.
  final double altitudeMeters;

  final double? speedMetersPerSecond;

  /// Direction of travel over the ground, clockwise from true north. Only
  /// meaningful while moving.
  final double? courseDegrees;

  final double? accuracyMeters;

  /// Moving fast enough for the course to mean the aircraft's direction:
  /// below about 10 m/s (taxiing slowly, or standing) it does not.
  bool get hasCourse =>
      courseDegrees != null && (speedMetersPerSecond ?? 0) >= 10;
}

/// How far the visible horizon drops below the true one at [altitudeMeters]:
/// about 1.76 arc-minutes × √(height in metres), with standard refraction.
/// Roughly 3° at a cruising altitude of 11 km.
double horizonDipDegrees(double altitudeMeters) =>
    altitudeMeters <= 0 ? 0 : 1.76 * math.sqrt(altitudeMeters) / 60;

/// The sun's altitude above the true horizon, in degrees, at [utc] seen from
/// [latitude], [longitude]. Low-precision solar coordinates (about 0.01°),
/// plenty for prayer times.
double solarAltitude({
  required double latitude,
  required double longitude,
  required DateTime utc,
}) {
  final n =
      utc.toUtc().millisecondsSinceEpoch / Duration.millisecondsPerDay +
      2440587.5 -
      2451545.0;
  final meanLongitude = _norm(280.460 + 0.9856474 * n);
  final meanAnomaly = _rad(_norm(357.528 + 0.9856003 * n));
  final eclipticLongitude = _rad(
    meanLongitude +
        1.915 * math.sin(meanAnomaly) +
        0.020 * math.sin(2 * meanAnomaly),
  );
  final obliquity = _rad(23.439 - 0.0000004 * n);
  final rightAscension = math.atan2(
    math.cos(obliquity) * math.sin(eclipticLongitude),
    math.cos(eclipticLongitude),
  );
  final declination = math.asin(
    math.sin(obliquity) * math.sin(eclipticLongitude),
  );
  final siderealDegrees = _norm(280.46061837 + 360.98564736629 * n);
  final hourAngle = _rad(siderealDegrees + longitude) - rightAscension;
  final phi = _rad(latitude);
  return _deg(
    math.asin(
      math.sin(phi) * math.sin(declination) +
          math.cos(phi) * math.cos(declination) * math.cos(hourAngle),
    ),
  );
}

/// The sun's altitude when its upper edge touches the horizon, with
/// refraction: the usual definition of sunrise and sunset.
const _sunriseAltitude = -0.833;

/// How much later the sun sets (or earlier it rises, as a negative duration
/// for sunrise) at [altitudeMeters] than on the ground at the same point,
/// around the ground event at [groundEvent]. Null when it cannot be found
/// (polar day or night).
Duration? altitudeShift({
  required double latitude,
  required double longitude,
  required DateTime groundEvent,
  required double altitudeMeters,
  required bool setting,
}) {
  if (altitudeMeters <= 0) return Duration.zero;
  double alt(DateTime t) =>
      solarAltitude(latitude: latitude, longitude: longitude, utc: t);
  DateTime? crossing(double target) {
    // Search from an hour before to three hours after (sunset) or the mirror
    // (sunrise): at altitude the event is later for sunset, earlier for
    // sunrise, by minutes to about an hour near the poles.
    var a = setting
        ? groundEvent.subtract(const Duration(hours: 1))
        : groundEvent.subtract(const Duration(hours: 3));
    var b = setting
        ? groundEvent.add(const Duration(hours: 3))
        : groundEvent.add(const Duration(hours: 1));
    double f(DateTime t) => alt(t) - target;
    var fa = f(a);
    final fb = f(b);
    if (fa.sign == fb.sign) return null;
    for (var i = 0; i < 40; i++) {
      final mid = a.add(
        Duration(microseconds: b.difference(a).inMicroseconds ~/ 2),
      );
      final fm = f(mid);
      if (fm.sign == fa.sign) {
        a = mid;
        fa = fm;
      } else {
        b = mid;
      }
    }
    return a;
  }

  final ground = crossing(_sunriseAltitude);
  final aloft = crossing(_sunriseAltitude - horizonDipDegrees(altitudeMeters));
  if (ground == null || aloft == null) return null;
  return aloft.difference(ground);
}

/// The prayer times aboard, for where the aircraft is now.
class InFlightTimes {
  const InFlightTimes({
    required this.times,
    required this.current,
    required this.next,
    required this.nextAt,
    required this.sunsetShift,
    required this.sunriseShift,
  });

  /// Today's times at the fix (UTC instants), with sunrise and Maghrib as
  /// seen from the aircraft, and tomorrow's Fajr after Isha.
  final Map<Prayer, DateTime> times;

  /// The prayer whose time it is now; null between sunrise and Dhuhr, or
  /// before Fajr.
  final Prayer? current;

  /// The next time to come, and when (UTC).
  final Prayer? next;
  final DateTime? nextAt;

  /// How much later the sun sets / earlier it rises than on the ground below.
  final Duration? sunsetShift;
  final Duration? sunriseShift;
}

/// The times at [fix], seen from the aircraft (2026-10-14 decision: sunrise
/// and Maghrib follow the sun at the aircraft's altitude; Fajr and Isha keep
/// the method's angles, and an Isha set as minutes after Maghrib moves with
/// Maghrib; Dhuhr and Asr do not depend on altitude).
///
/// [calculator] is built for the fix's position and [zone] is the zone there;
/// the phone's own clock plays no part.
InFlightTimes inFlightTimes({
  required PrayerTimesCalculator calculator,
  required ZoneOffsets zone,
  required InFlightFix fix,
  required DateTime now,
}) {
  final today = LocalMoment.inZone(zone: zone, utcInstant: now).day;
  Map<Prayer, DateTime> instants(LocalDay day) => {
    for (final MapEntry(key: prayer, value: minutes)
        in calculator.forDay(day).times.entries)
      prayer: zone.utcInstantOf(day: day, time: LocalTime(minutes)),
  };

  final times = instants(today);
  final altitude = math.max(0.0, fix.altitudeMeters);
  Duration? shift(Prayer prayer, {required bool setting}) =>
      times[prayer] == null
      ? null
      : altitudeShift(
          latitude: fix.latitude,
          longitude: fix.longitude,
          groundEvent: times[prayer]!,
          altitudeMeters: altitude,
          setting: setting,
        );
  final sunsetShift = shift(Prayer.maghrib, setting: true);
  final sunriseShift = shift(Prayer.sunrise, setting: false);
  if (sunsetShift != null) {
    times[Prayer.maghrib] = times[Prayer.maghrib]!.add(sunsetShift);
    if (_ishaFollowsMaghrib(calculator) && times[Prayer.isha] != null) {
      times[Prayer.isha] = times[Prayer.isha]!.add(sunsetShift);
    }
  }
  if (sunriseShift != null) {
    times[Prayer.sunrise] = times[Prayer.sunrise]!.add(sunriseShift);
  }

  // Order of the day; after Isha, tomorrow's Fajr is next.
  Prayer? current;
  Prayer? next;
  DateTime? nextAt;
  for (final prayer in Prayer.adhanPrayers) {
    final at = times[prayer];
    if (at == null) continue;
    if (!at.isAfter(now)) {
      current = prayer == Prayer.sunrise ? null : prayer;
    } else {
      next = prayer;
      nextAt = at;
      break;
    }
  }
  if (next == null) {
    final tomorrowFajr = instants(today.addDays(1))[Prayer.fajr];
    if (tomorrowFajr != null) {
      next = Prayer.fajr;
      nextAt = tomorrowFajr;
    }
  }
  return InFlightTimes(
    times: times,
    current: current,
    next: next,
    nextAt: nextAt,
    sunsetShift: sunsetShift,
    sunriseShift: sunriseShift == null ? null : -sunriseShift,
  );
}

bool _ishaFollowsMaghrib(PrayerTimesCalculator c) =>
    methodAngles(c.method, custom: c.customAngles).ishaMinutes != null;

/// Where the Qibla is relative to the aircraft's nose: degrees clockwise
/// (positive, to the right) or anticlockwise (negative, to the left), within
/// ±180. [heading] is the direction the aircraft points, from GPS course or
/// typed in from the seat-back map.
double qiblaFromNose({
  required double latitude,
  required double longitude,
  required double heading,
}) {
  final bearing = qibla.qiblaBearingFor(
    latitude: latitude,
    longitude: longitude,
  );
  final d = ((bearing - heading) % 360 + 360) % 360;
  return d > 180 ? d - 360 : d;
}

double _norm(double degrees) => (degrees % 360 + 360) % 360;
double _rad(double degrees) => degrees * math.pi / 180;
double _deg(double radians) => radians * 180 / math.pi;
