import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'prayer.dart';
import 'prayer_times_parameters.dart';
import 'time_model.dart';
import 'zone_offsets.dart';

/// Calculates on-device prayer times for a fixed place.
///
/// adhan_dart returns wall-clock times expressed in **UTC** (its internal
/// representation of solar time at Greenwich), so the wrapper adds the location's
/// zone offset — DST-aware — to obtain local wall-clock times.
///
/// Verified against Aladhan (dev-time oracle only, per AGENTS.md): Cairo
/// 2026-10-12 Egyptian → 05:28 / 06:55 / 12:42 / 16:00 / 18:28 / 19:45, and
/// London, New York, Makkah and Kuwait agree to within a minute (Asr within
/// three, from independent shadow-length rounding).
class PrayerTimesCalculator {
  const PrayerTimesCalculator({
    required this.latitude,
    required this.longitude,
    required this.zone,
    this.method = CalculationMethod.muslimWorldLeague,
    this.madhab = Madhab.standard,
    this.highLatitudeRule = HighLatitudeRule.middleOfTheNight,
    this.minuteOffsets = const {},
    this.polarCircleResolution = adhan.PolarCircleResolution.unresolved,
  });

  final double latitude;
  final double longitude;

  /// Where the user is, for offset lookups.
  final ZoneOffsets zone;

  final CalculationMethod method;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Per-prayer minute offsets applied on top of the method.
  final Map<Prayer, int> minuteOffsets;

  /// How the library should treat polar regions. Left at `unresolved` because the
  /// library's detectors do not fire for the midnight-sun case (see
  /// [_isInternallyConsistent]); this class handles that itself.
  final adhan.PolarCircleResolution polarCircleResolution;

  /// Latitude we fall back to when no sunrise or sunset exists on a day.
  static const double _lowestFallbackLatitude = 45;
  static const double _latitudeStep = 0.5;

  PrayerTimesCalculator copyWith({
    double? latitude,
    double? longitude,
    ZoneOffsets? zone,
    CalculationMethod? method,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? minuteOffsets,
    adhan.PolarCircleResolution? polarCircleResolution,
  }) => PrayerTimesCalculator(
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    zone: zone ?? this.zone,
    method: method ?? this.method,
    madhab: madhab ?? this.madhab,
    highLatitudeRule: highLatitudeRule ?? this.highLatitudeRule,
    minuteOffsets: minuteOffsets ?? this.minuteOffsets,
    polarCircleResolution:
        polarCircleResolution ?? this.polarCircleResolution,
  );

  /// Times for [day] in the location's local wall clock.
  ///
  /// Inside the polar circles on days when the sun never rises or sets, sunrise
  /// and sunset have no astronomical value. The library still returns numbers for
  /// them, so the result is checked for internal consistency; if it fails we move
  /// toward the equator in half-degree steps until it does, and record the
  /// latitude actually used in [PrayerDay.estimatedFromLatitude] so the UI can say
  /// the day's Fajr and Isha are estimates.
  PrayerDay forDay(LocalDay day) {
    var latitude = this.latitude;
    var attempt = _compute(location: latitude, day: day);

    while (!_isInternallyConsistent(attempt) && latitude.abs() > _lowestFallbackLatitude) {
      latitude = _stepTowardEquator(latitude);
      attempt = _compute(location: latitude, day: day);
    }

    final consistent = _isInternallyConsistent(attempt);
    final times = <Prayer, int>{};
    final unavailable = <Prayer>{};
    for (final entry in attempt.entries) {
      final minutes = entry.value.$1;
      if (minutes == null) {
        unavailable.add(entry.key);
      } else {
        times[entry.key] = minutes;
      }
    }

    return PrayerDay(
      day: day,
      times: consistent ? times : const {},
      unavailable: consistent ? unavailable : Prayer.adhanPrayers.toSet(),
      highLatitudeMovedPrayers: _prayersMovedByHighLatitudeRule(
        day,
        latitude,
      ),
      estimatedFromLatitude:
          consistent && latitude != this.latitude ? latitude : null,
      timesAreEstimates: !consistent,
    );
  }

  ({DateTime date, adhan.Coordinates coordinates, adhan.CalculationParameters params})
  _params(LocalDay day) => (
    date: day.midnightUtc(),
    coordinates: adhan.Coordinates(latitude, longitude),
    params: calculationParametersFor(
      method: method,
      madhab: madhab,
      highLatitudeRule: highLatitudeRule,
      minuteOffsets: minuteOffsets,
      polarCircleResolution: polarCircleResolution,
    ),
  );

  Map<Prayer, (int?, DateTime)> _compute({
    required double location,
    required LocalDay day,
  }) {
    final raw = _params(day);
    final times = adhan.PrayerTimes(
      date: raw.date,
      coordinates: adhan.Coordinates(location, longitude),
      calculationParameters: raw.params,
    );
    return {
      for (final entry in <Prayer, DateTime>{
        Prayer.fajr: times.fajr,
        Prayer.sunrise: times.sunrise,
        Prayer.dhuhr: times.dhuhr,
        Prayer.asr: times.asr,
        Prayer.maghrib: times.maghrib,
        Prayer.isha: times.isha,
      }.entries)
        entry.key: (_toLocalMinutes(entry.value), entry.value),
    };
  }

  /// True when the day's times can be believed.
  ///
  /// The chain fajr → sunrise → dhuhr → asr → maghrib must be strictly
  /// increasing. Isha may sit after midnight (summer at high latitudes), so it is
  /// valid either after Maghrib or at/before Fajr.
  bool _isInternallyConsistent(Map<Prayer, (int?, DateTime)> attempt) {
    const chain = [
      Prayer.fajr,
      Prayer.sunrise,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
    ];
    for (var i = 0; i < chain.length - 1; i++) {
      final early = attempt[chain[i]]!.$1;
      final late = attempt[chain[i + 1]]!.$1;
      if (early == null || late == null || early >= late) return false;
    }
    final isha = attempt[Prayer.isha]!.$1;
    final maghrib = attempt[Prayer.maghrib]!.$1;
    final fajr = attempt[Prayer.fajr]!.$1;
    if (isha == null || maghrib == null || fajr == null) return false;
    return isha > maghrib || isha <= fajr;
  }

  double _stepTowardEquator(double latitude) {
    final direction = latitude >= 0 ? -1 : 1;
    final next = latitude + direction * _latitudeStep;
    // Stop at the fallback ring rather than crossing the equator.
    if (direction < 0) {
      return next < -_lowestFallbackLatitude
          ? -_lowestFallbackLatitude
          : next;
    }
    return next > _lowestFallbackLatitude
        ? _lowestFallbackLatitude
        : next;
  }

  /// Converts one of adhan_dart's UTC wall-clock values into minutes from local
  /// midnight, or null when the library could not compute it (NaN).
  int? _toLocalMinutes(DateTime utcWall) {
    if (utcWall.millisecondsSinceEpoch.isNaN) return null;
    return zone.localMinutes(
      DateTime.utc(
        utcWall.year,
        utcWall.month,
        utcWall.day,
        utcWall.hour,
        utcWall.minute,
      ),
    );
  }

  /// Prayers whose time came from the high-latitude rule instead of the
  /// astronomical angle.
  ///
  /// adhan_dart applies the chosen rule silently whenever the sun never reaches the
  /// required depression. We detect this by asking the three rules the same
  /// question: if they agree, the rule is not binding; if they disagree, it is.
  /// AGENTS.md requires the UI to state which rule applies.
  Set<Prayer> _prayersMovedByHighLatitudeRule(LocalDay day, double latitude) {
    final byRule = <Prayer, Set<int>>{};
    for (final rule in HighLatitudeRule.values) {
      final times = adhan.PrayerTimes(
        date: day.midnightUtc(),
        coordinates: adhan.Coordinates(latitude, longitude),
        calculationParameters: calculationParametersFor(
          method: method,
          madhab: madhab,
          highLatitudeRule: rule,
          minuteOffsets: minuteOffsets,
          polarCircleResolution: polarCircleResolution,
        ),
      );
      for (final prayer in [Prayer.fajr, Prayer.isha]) {
        final raw = prayer == Prayer.fajr ? times.fajr : times.isha;
        final minutes = _toLocalMinutes(raw);
        if (minutes == null) continue;
        byRule.putIfAbsent(prayer, () => {}).add(minutes);
      }
    }
    return {
      for (final entry in byRule.entries)
        if (entry.value.length > 1) entry.key,
    };
  }
}
