import '../../domain/prayer.dart';
import '../../domain/prayer_times_parameters.dart';
import 'generated/app_localizations.dart';

/// The name of one of the six daily times, in the app's current locale.
///
/// The switch is exhaustive on [Prayer], so adding a time to the enum fails the
/// build here until it also has a label.
String prayerName(AppLocalizations l10n, Prayer prayer) => switch (prayer) {
  Prayer.fajr => l10n.prayerFajr,
  Prayer.sunrise => l10n.prayerSunrise,
  Prayer.dhuhr => l10n.prayerDhuhr,
  Prayer.asr => l10n.prayerAsr,
  Prayer.maghrib => l10n.prayerMaghrib,
  Prayer.isha => l10n.prayerIsha,
};

/// The night rule's name as the Settings screen spells it.
String highLatitudeRuleName(
  AppLocalizations l10n,
  HighLatitudeRule rule,
) => switch (rule) {
  HighLatitudeRule.middleOfTheNight => l10n.ruleMiddleOfTheNight,
  HighLatitudeRule.seventhOfTheNight => l10n.ruleSeventhOfTheNight,
  HighLatitudeRule.twilightAngle => l10n.ruleTwilightAngle,
};

/// "Fajr and Isha", in order, for the prayers the rule moved.
///
/// The rule can only ever move these two, so a longer list needs no serial comma.
String movedPrayerNames(AppLocalizations l10n, Set<Prayer> moved) {
  final names = [
    for (final prayer in const [Prayer.fajr, Prayer.isha])
      if (moved.contains(prayer)) prayerName(l10n, prayer),
  ];
  return switch (names.length) {
    2 => l10n.twoNames(names.first, names.last),
    _ => names.first,
  };
}

/// "just now", "12 min ago", "6 h ago", "2 d ago".
String agoLabel(AppLocalizations l10n, DateTime then, DateTime now) {
  final minutes = now.difference(then).inMinutes;
  if (minutes < 1) return l10n.agoJustNow;
  if (minutes < 60) return l10n.agoMinutes(minutes);
  if (minutes < 48 * 60) return l10n.agoHours(minutes ~/ 60);
  return l10n.agoDays(minutes ~/ (24 * 60));
}
