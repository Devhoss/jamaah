import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import '../../domain/extra_times.dart';
import '../../domain/hijri.dart';
import '../../domain/prayer_times_parameters.dart';
import '../components/horizon_controls.dart';
import '../location/place_copy.dart';
import 'extra_times_page.dart';
import 'prayer_time_settings.dart';
import 'settings_kit.dart';

/// "Prayer times · Kuwait · Asr Standard": what the hub row says.
String prayerTimesSummary(
  AppLocalizations l10n,
  AppSettingsSnapshot settings,
) => l10n.settingsPrayerTimesSummary(
  methodName(l10n, settings.calculationMethod),
  asrName(l10n, settings.madhab),
);

/// How the day's times are worked out (spec §4.9): the method, Asr, the
/// Hijri date, the extra times on Today, and, folded away, the rules for far
/// north or south and the minute adjustments.
class PrayerTimesPage extends ConsumerWidget {
  const PrayerTimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final place = ref.watch(currentPlaceProvider);
    final method = settings.calculationMethod;
    final repo = ref.read(settingsRepositoryProvider);
    final extra = settings.extraTimes;

    final methodValue = method == CalculationMethod.auto && place != null
        ? l10n.methodAutoResolved(
            methodName(
              l10n,
              method.resolvedForPlace(place.ianaZone, place.countryCode),
            ),
            placeLabel(l10n, place),
          )
        : methodName(l10n, method);

    String hijriLabel(int days) => switch (days) {
      0 => l10n.hijriAsCalculated,
      > 0 => l10n.hijriLater(days),
      _ => l10n.hijriEarlier(-days),
    };

    Future<void> setShown(ExtraTime t, bool on) => repo.saveExtraTimes(
      extra.copyWith(shown: {...extra.shown}..toggle(t, on)),
    );

    return SettingsScaffold(
      title: l10n.settingsPrayerTimesSection,
      lead: l10n.settingsPrayerTimesLead,
      children: [
        SettingsLinkRow(
          title: l10n.settingsMethod,
          value: methodValue,
          onTap: () => pushSettingsPage(context, const MethodListPage()),
        ),
        SettingsHeading(l10n.settingsAsr),
        Segmented<Madhab>(
          options: [
            SegmentOption(
              Madhab.standard,
              l10n.asrStandard,
              description: l10n.asrStandardHint,
            ),
            SegmentOption(
              Madhab.hanafi,
              l10n.asrHanafi,
              description: l10n.asrHanafiHint,
            ),
          ],
          selected: settings.madhab,
          onChanged: (m) => repo.setPrayerTimesPreferences(madhab: m),
        ),
        SettingsHeading(l10n.settingsHijri),
        // ±2 days, each with the date it gives (owner, 2026-10-16).
        RadioList<int>(
          options: [
            for (var d = -kMaxHijriAdjustDays; d <= kMaxHijriAdjustDays; d++)
              RadioOption(
                d,
                hijriLabel(d),
                description: hijriToday(context, ref, d),
              ),
          ],
          selected: settings.hijriAdjustDays,
          onChanged: repo.setHijriAdjustDays,
        ),
        SettingsNote(l10n.hijriAdjustNote),
        SettingsHeading(l10n.extraOnTodaySection),
        for (final t in ExtraTime.values)
          SettingsSwitchRow(
            title: extraTimeName(l10n, t),
            hint: extraRuleLine(l10n, extra, t),
            value: extra.shown.contains(t),
            onChanged: (on) => setShown(t, on),
          ),
        SettingsLinkRow(
          title: l10n.extraAlertsAndTiming,
          value: extraAlertsSummary(l10n, extra),
          onTap: () => openExtraTimes(context),
          divider: false,
        ),
        const SizedBox(height: 8),
        SettingsDisclosure(
          title: l10n.settingsAdvanced,
          children: [
            SettingsLinkRow(
              title: l10n.settingsHighLatitude,
              value: ruleTitle(l10n, settings.highLatitudeRule),
              onTap: () => pushSettingsPage(context, const HighLatitudePage()),
            ),
            SettingsLinkRow(
              title: l10n.settingsAdjustments,
              value: adjustmentsSummary(l10n, settings.minuteOffsets),
              onTap: () => pushSettingsPage(context, const AdjustmentsPage()),
              divider: false,
            ),
          ],
        ),
      ],
    );
  }
}

/// Today's Hijri date with [adjustDays], as Today shows it.
String hijriToday(BuildContext context, WidgetRef ref, int adjustDays) {
  final today = ref.read(todayProvider)?.day.day;
  final date = today == null
      ? DateTime.now()
      : DateTime(today.year, today.month, today.day);
  return DateLabels.hijri(
    date,
    Localizations.localeOf(context).toLanguageTag(),
    adjustDays: adjustDays,
  );
}

/// The rule for places far north or south, each with what it does.
class HighLatitudePage extends ConsumerWidget {
  const HighLatitudePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    return SettingsScaffold(
      title: l10n.settingsHighLatitude,
      lead: l10n.highLatitudeLead,
      children: [
        RadioList<HighLatitudeRule>(
          options: [
            for (final r in HighLatitudeRule.values)
              RadioOption(
                r,
                ruleTitle(l10n, r),
                description: ruleHint(l10n, r),
              ),
          ],
          selected: settings.highLatitudeRule,
          onChanged: (r) => ref
              .read(settingsRepositoryProvider)
              .setPrayerTimesPreferences(highLatitudeRule: r),
        ),
        SettingsNote(l10n.highLatitudeSettingsNote, top: 14),
      ],
    );
  }
}
