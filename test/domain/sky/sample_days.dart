import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// Real computed days for the sky tests: Kuwait in winter and summer, London in
/// summer (a long dusk), and Oslo in summer (Isha past midnight).
class SampleDay {
  const SampleDay(this.name, this.day);

  final String name;
  final PrayerDay day;
}

List<SampleDay> sampleDays() {
  loadTimeZoneDatabase();
  PrayerDay compute(
    String zone,
    CalculationMethod method,
    double lat,
    double lng,
    LocalDay day,
  ) => PrayerTimesCalculator(
    latitude: lat,
    longitude: lng,
    zone: zoneOffsetsFor(zone),
    method: method,
  ).forDay(day);

  return [
    SampleDay(
      'Kuwait winter',
      compute(
        'Asia/Kuwait',
        CalculationMethod.kuwait,
        29.3759,
        47.9774,
        const LocalDay(2026, 1, 15),
      ),
    ),
    SampleDay(
      'Kuwait summer',
      compute(
        'Asia/Kuwait',
        CalculationMethod.kuwait,
        29.3759,
        47.9774,
        const LocalDay(2026, 6, 21),
      ),
    ),
    SampleDay(
      'London summer',
      compute(
        'Europe/London',
        CalculationMethod.muslimWorldLeague,
        51.5074,
        -0.1278,
        const LocalDay(2026, 6, 21),
      ),
    ),
    SampleDay(
      'Oslo summer',
      compute(
        'Europe/Oslo',
        CalculationMethod.muslimWorldLeague,
        59.9139,
        10.7522,
        const LocalDay(2026, 6, 21),
      ),
    ),
  ];
}
