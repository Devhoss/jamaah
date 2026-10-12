import 'package:adhan_dart/adhan_dart.dart' as adhan;

/// The six daily times the app reasons about.
///
/// [sunrise] is shown but is not a prayer: it can carry an Adhan alert only, never
/// an Iqama or an Iqama reminder (AGENTS.md).
enum Prayer {
  fajr,
  sunrise,
  dhuhr,
  asr,
  maghrib,
  isha;

  /// Prayers that can be configured per mosque with an Iqama time.
  static const iqamaPrayers = <Prayer>[
    Prayer.fajr,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  /// Prayers that can carry a global Adhan alert (sunrise included, default off).
  static const adhanPrayers = <Prayer>[
    Prayer.fajr,
    Prayer.sunrise,
    Prayer.dhuhr,
    Prayer.asr,
    Prayer.maghrib,
    Prayer.isha,
  ];

  bool get canHaveIqama => this != Prayer.sunrise;

  /// The matching value in adhan_dart's own enum, used only at the boundary.
  adhan.Prayer get adhanPrayer => switch (this) {
    Prayer.fajr => adhan.Prayer.fajr,
    Prayer.sunrise => adhan.Prayer.sunrise,
    Prayer.dhuhr => adhan.Prayer.dhuhr,
    Prayer.asr => adhan.Prayer.asr,
    Prayer.maghrib => adhan.Prayer.maghrib,
    Prayer.isha => adhan.Prayer.isha,
  };
}
