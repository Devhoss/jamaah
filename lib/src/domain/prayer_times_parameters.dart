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
/// Expanded on 2026-10-13 at the user's request from the five AGENTS.md first
/// named. Stored by [name], so the original five keep their stored values.
/// [auto] is resolved from the place's time zone ([autoMethodFor]); [custom]
/// uses the user's own angles ([CustomAngles]).
enum CalculationMethod {
  auto,
  custom,
  egyptian,
  isna,
  moonsightingCommittee,
  muslimWorldLeague,
  ummAlQura,
  karachi,
  jakim,
  singapore,
  indonesia,
  turkiye,
  france,
  kuwait,
  qatar,
  dubai,
  gulfRegion,
  jordan,
  algeria,
  morocco,
  tunisia,
  russia,
  portugal,
  tehran,
  jafari;

  String get storageKey => name;

  static CalculationMethod fromStorageKey(String? key) => values.firstWhere(
    (m) => m.name == key,
    orElse: () => CalculationMethod.muslimWorldLeague,
  );

  /// The method to calculate with: [auto] becomes the one for [ianaZone].
  CalculationMethod resolvedFor(String ianaZone) =>
      this == auto ? autoMethodFor(ianaZone) : this;
}

/// The user's own angles for [CalculationMethod.custom].
class CustomAngles {
  const CustomAngles({
    this.fajrAngle = 18,
    this.ishaAngle = 17,
    this.ishaMinutesAfterMaghrib,
  });

  static const minAngle = 10.0;
  static const maxAngle = 22.0;

  final double fajrAngle;
  final double ishaAngle;

  /// When set, Isha is this many minutes after Maghrib instead of an angle.
  final int? ishaMinutesAfterMaghrib;

  static bool validAngle(double a) => a >= minAngle && a <= maxAngle;

  @override
  bool operator ==(Object other) =>
      other is CustomAngles &&
      other.fajrAngle == fajrAngle &&
      other.ishaAngle == ishaAngle &&
      other.ishaMinutesAfterMaghrib == ishaMinutesAfterMaghrib;

  @override
  int get hashCode =>
      Object.hash(fajrAngle, ishaAngle, ishaMinutesAfterMaghrib);
}

/// The method commonly used where [ianaZone] is, for "Auto detect". The zone
/// is what the app knows about a place without a network lookup; anything not
/// listed falls back to the Muslim World League.
CalculationMethod autoMethodFor(String ianaZone) {
  const byZone = <String, CalculationMethod>{
    'Africa/Cairo': CalculationMethod.egyptian,
    'Africa/Khartoum': CalculationMethod.egyptian,
    'Africa/Tripoli': CalculationMethod.egyptian,
    'Asia/Damascus': CalculationMethod.egyptian,
    'Asia/Beirut': CalculationMethod.egyptian,
    'Asia/Riyadh': CalculationMethod.ummAlQura,
    'Asia/Aden': CalculationMethod.ummAlQura,
    'Asia/Kuwait': CalculationMethod.kuwait,
    'Asia/Qatar': CalculationMethod.qatar,
    'Asia/Bahrain': CalculationMethod.gulfRegion,
    'Asia/Muscat': CalculationMethod.gulfRegion,
    'Asia/Dubai': CalculationMethod.dubai,
    'Asia/Amman': CalculationMethod.jordan,
    'Asia/Karachi': CalculationMethod.karachi,
    'Asia/Kolkata': CalculationMethod.karachi,
    'Asia/Calcutta': CalculationMethod.karachi,
    'Asia/Dhaka': CalculationMethod.karachi,
    'Asia/Kabul': CalculationMethod.karachi,
    'Asia/Kuala_Lumpur': CalculationMethod.jakim,
    'Asia/Kuching': CalculationMethod.jakim,
    'Asia/Singapore': CalculationMethod.singapore,
    'Asia/Jakarta': CalculationMethod.indonesia,
    'Asia/Makassar': CalculationMethod.indonesia,
    'Asia/Jayapura': CalculationMethod.indonesia,
    'Asia/Pontianak': CalculationMethod.indonesia,
    'Europe/Istanbul': CalculationMethod.turkiye,
    'Europe/Paris': CalculationMethod.france,
    'Africa/Algiers': CalculationMethod.algeria,
    'Africa/Casablanca': CalculationMethod.morocco,
    'Africa/Tunis': CalculationMethod.tunisia,
    'Europe/Moscow': CalculationMethod.russia,
    'Europe/Lisbon': CalculationMethod.portugal,
    'Asia/Tehran': CalculationMethod.tehran,
  };
  final known = byZone[ianaZone];
  if (known != null) return known;
  // The US and Canada (ISNA); the rest of the Americas keeps the fallback.
  const northAmerica = {
    'America/New_York',
    'America/Chicago',
    'America/Denver',
    'America/Los_Angeles',
    'America/Phoenix',
    'America/Anchorage',
    'America/Detroit',
    'America/Toronto',
    'America/Vancouver',
    'America/Edmonton',
    'America/Winnipeg',
    'America/Halifax',
    'America/Regina',
    'America/St_Johns',
    'Pacific/Honolulu',
  };
  if (northAmerica.contains(ianaZone) ||
      ianaZone.startsWith('America/Indiana/') ||
      ianaZone.startsWith('America/Kentucky/')) {
    return CalculationMethod.isna;
  }
  return CalculationMethod.muslimWorldLeague;
}

/// What a method does, for the list in Settings: its Fajr angle, and its Isha
/// angle or minutes after Maghrib. Read from the very parameters the calculator
/// uses, so the list can never disagree with the times.
({double fajrAngle, double? ishaAngle, int? ishaMinutes}) methodAngles(
  CalculationMethod method, {
  CustomAngles custom = const CustomAngles(),
}) {
  final p = _parameters(method, custom: custom);
  final interval = p.ishaInterval;
  final byInterval = interval != null && interval > 0;
  return (
    fajrAngle: p.fajrAngle,
    ishaAngle: byInterval ? null : p.ishaAngle,
    ishaMinutes: byInterval ? interval : null,
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

adhan.CalculationParameters _parameters(
  CalculationMethod method, {
  CustomAngles custom = const CustomAngles(),
  bool ramadan = false,
}) => switch (method) {
  // Resolved by the caller (CalculationMethod.resolvedFor); MWL if it is not.
  CalculationMethod.auto ||
  CalculationMethod.muslimWorldLeague =>
    adhan.CalculationMethodParameters.muslimWorldLeague(),
  CalculationMethod.custom => adhan.CalculationParameters(
    method: adhan.CalculationMethod.other,
    fajrAngle: custom.fajrAngle,
    ishaAngle: custom.ishaMinutesAfterMaghrib == null ? custom.ishaAngle : 0,
    ishaInterval: custom.ishaMinutesAfterMaghrib ?? 0,
  ),
  CalculationMethod.egyptian => adhan.CalculationMethodParameters.egyptian(),
  CalculationMethod.isna => adhan.CalculationMethodParameters.northAmerica(),
  CalculationMethod.moonsightingCommittee =>
    adhan.CalculationMethodParameters.moonsightingCommittee(),
  // Isha 90 minutes after Maghrib, 120 during Ramadan.
  CalculationMethod.ummAlQura =>
    adhan.CalculationMethodParameters.ummAlQura()
      ..ishaInterval = ramadan ? 120 : 90,
  CalculationMethod.karachi => adhan.CalculationMethodParameters.karachi(),
  // JAKIM's published standard: Fajr 20°, Isha 18°. Not built into adhan_dart.
  CalculationMethod.jakim =>
    adhan.CalculationParameters(
        method: adhan.CalculationMethod.other,
        fajrAngle: 20,
        ishaAngle: 18,
      )
      ..methodAdjustments = {adhan.Prayer.dhuhr: 1},
  CalculationMethod.singapore => adhan.CalculationMethodParameters.singapore(),
  CalculationMethod.indonesia =>
    adhan.CalculationMethodParameters.indonesian(),
  CalculationMethod.turkiye => adhan.CalculationMethodParameters.turkiye(),
  CalculationMethod.france => adhan.CalculationMethodParameters.france(),
  CalculationMethod.kuwait => adhan.CalculationMethodParameters.kuwait(),
  CalculationMethod.qatar => adhan.CalculationMethodParameters.qatar(),
  CalculationMethod.dubai => adhan.CalculationMethodParameters.dubai(),
  CalculationMethod.gulfRegion =>
    adhan.CalculationMethodParameters.gulfRegion(),
  CalculationMethod.jordan => adhan.CalculationMethodParameters.jordan(),
  CalculationMethod.algeria => adhan.CalculationMethodParameters.algerian(),
  CalculationMethod.morocco => adhan.CalculationMethodParameters.morocco(),
  CalculationMethod.tunisia => adhan.CalculationMethodParameters.tunisia(),
  CalculationMethod.russia => adhan.CalculationMethodParameters.russia(),
  CalculationMethod.portugal => adhan.CalculationMethodParameters.portugal(),
  CalculationMethod.tehran => adhan.CalculationMethodParameters.tehran(),
  CalculationMethod.jafari => adhan.CalculationMethodParameters.jafari(),
};

/// Parameters adhan_dart expects, built from our own small setting types.
adhan.CalculationParameters calculationParametersFor({
  required CalculationMethod method,
  required Madhab madhab,
  CustomAngles customAngles = const CustomAngles(),
  bool ramadan = false,
  HighLatitudeRule highLatitudeRule = HighLatitudeRule.middleOfTheNight,
  Map<Prayer, int> minuteOffsets = const {},
  adhan.PolarCircleResolution polarCircleResolution =
      adhan.PolarCircleResolution.unresolved,
}) => _parameters(
  method,
  custom: customAngles,
  ramadan: ramadan,
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


