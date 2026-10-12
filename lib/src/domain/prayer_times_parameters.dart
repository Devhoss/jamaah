import 'package:adhan_dart/adhan_dart.dart' as adhan;

import 'prayer.dart';
import 'qibla.dart' as qibla;

/// Great-circle initial bearing from the given location toward Makkah, in degrees
/// clockwise from true north.
///
/// Delegates to the same great-circle formula the Qibla screen uses.
double bearingFor({required double lat, required double lng}) =>
    qibla.qiblaBearingFor(latitude: lat, longitude: lng);
/// Calculation methods offered in Settings, mapped to adhan_dart's parameters.
///
/// AGENDS.md names MWL, ISNA, Egypt, Kuwait and Umm al-Qura; adhan_dart supplies
/// all five, so no parameter tweaking is needed.
enum CalculationMethod {
  muslimWorldLeague,
  isna,
  egyptian,
  kuwait,
  ummAlQura;

  String get storageKey => name;

  static CalculationMethod fromStorageKey(String? key) => values.firstWhere(
    (m) => m.name == key,
    orElse: () => CalculationMethod.muslimWorldLeague,
  );
}

/// Asr shadow-length school.
enum Madhab { standard, hanafi }

/// High-latitude rule used when the sun never gets far enough below the horizon.
enum HighLatitudeRule {
  middleOfTheNight,
  seventhOfTheNight,
  twilightAngle;

  String get storageKey => name;

  static HighLatitudeRule fromStorageKey(String? key) => values.firstWhere(
    (r) => r.name == key,
    orElse: () => HighLatitudeRule.middleOfTheNight,
  );
}

adhan.CalculationParameters _parameters(CalculationMethod method) => switch (method) {
  CalculationMethod.muslimWorldLeague =>
    adhan.CalculationMethodParameters.muslimWorldLeague(),
  CalculationMethod.isna => adhan.CalculationMethodParameters.northAmerica(),
  CalculationMethod.egyptian => adhan.CalculationMethodParameters.egyptian(),
  CalculationMethod.kuwait => adhan.CalculationMethodParameters.kuwait(),
  CalculationMethod.ummAlQura => adhan.CalculationMethodParameters.ummAlQura(),
};

/// Parameters adhan_dart expects, built from our own small setting types.
adhan.CalculationParameters calculationParametersFor({
  required CalculationMethod method,
  required Madhab madhab,
  HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfTheNight,
  Map<Prayer, int> minuteOffsets = const {},
  adhan.PolarCircleResolution polarCircleResolution =
      adhan.PolarCircleResolution.unresolved,
}) => _parameters(
  method,
).copyWith(
  madhab: switch (madhab) {
    Madhab.standard => adhan.Madhab.shafi,
    Madhab.hanafi => adhan.Madhab.hanafi,
  },
  highLatitudeRule: switch (highLatitudeRule) {
    HighLatitudeRule.middleOfTheNight =>
      adhan.HighLatitudeRule.middleOfTheNight,
    HighLatitudeRule.seventhOfTheNight =>
      adhan.HighLatitudeRule.seventhOfTheNight,
    HighLatitudeRule.twilightAngle => adhan.HighLatitudeRule.twilightAngle,
  },
  polarCircleResolution: polarCircleResolution,
  adjustments: {
    for (final p in Prayer.adhanPrayers)
      // adhan_dart keys adjustments with its own Prayer enum; ours shares the
      // same six names and drops fajrAfter/ishaBefore.
      p.adhanPrayer: minuteOffsets[p] ?? 0,
  },
);


