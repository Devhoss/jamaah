import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/location_follower.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/place.dart';
import '../../domain/prayer.dart';
import 'adhan_alerts_page.dart';
import 'jamaah_reminder_settings.dart';
import 'preference_pages.dart';
import 'prayer_times_page.dart';
import 'settings_kit.dart';

String shortAdhanName(AppLocalizations l10n, ShortAdhan clip) =>
    switch (clip) {
      ShortAdhan.naghshbandi => l10n.shortAdhanNaghshbandi,
      ShortAdhan.hayya => l10n.soundHayya,
    };

/// Each language by its own name, so it can be found whatever the app is in.
String languageName(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.themeSystem,
      AppLanguage.en => 'English',
      AppLanguage.ar => 'العربية',
    };

String themeModeName(AppLocalizations l10n, AppThemeMode mode) =>
    switch (mode) {
      AppThemeMode.system => l10n.themeSystem,
      AppThemeMode.light => l10n.themeLight,
      AppThemeMode.dark => l10n.themeDark,
    };

String followFailure(AppLocalizations l10n, PlaceFailure failure) =>
    failure == PlaceFailure.denied || failure == PlaceFailure.permanentlyDenied
    ? l10n.followDenied
    : l10n.followUnavailable;

/// Travel mode on or off, from the top bar or Settings. The location dialog
/// may show (following starts now); the outcome is said in a snack bar, since
/// the top-bar button is only an icon.
Future<void> setTravelMode(
  BuildContext context,
  WidgetRef ref,
  bool on,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final l10n = AppLocalizations.of(context);
  final failure = await ref.read(locationFollowerProvider).setTravelMode(on);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          failure != null
              ? followFailure(l10n, failure)
              : on
              ? l10n.travelModeOnSnack
              : l10n.travelModeOffSnack,
        ),
      ),
    );
}

Future<void> openSettings(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));

/// Changes the stored Adhan alerts with [change] and saves them; the scheduler
/// picks the change up from the settings stream.
Future<void> updateAdhanAlerts(
  WidgetRef ref,
  AdhanAlertSettings Function(AdhanAlertSettings current) change,
) async {
  final current =
      ref.read(appSettingsProvider).value?.adhanAlerts ??
      SettingsRepository.defaults.adhanAlerts;
  await ref.read(settingsRepositoryProvider).saveAdhanAlerts(change(current));
}

/// Settings (Horizon spec §4.9): six rows in three groups, each saying what
/// it is set to now. Iqama times are not here: they belong to each mosque.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({this.asTab = false, super.key});

  /// Shown as the fourth tab (Horizon, 2026-10-15): no back arrow.
  final bool asTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final active = ref.watch(activeMosqueProvider);

    void go(Widget page) => pushSettingsPage(context, page);

    return SettingsScaffold(
      title: l10n.settingsTitle,
      onTab: asTab,
      children: [
        SettingsHeading(l10n.settingsGroupEveryDay, top: 4),
        SettingsLinkRow(
          title: l10n.settingsPrayerTimesSection,
          value: prayerTimesSummary(l10n, settings),
          onTap: () => go(const PrayerTimesPage()),
        ),
        SettingsLinkRow(
          title: l10n.settingsAdhanSection,
          value: adhanAlertsSummary(l10n, settings.adhanAlerts),
          onTap: () => go(const AdhanAlertsPage()),
        ),
        SettingsLinkRow(
          title: l10n.settingsIqamaSection,
          value: jamaahRemindersSummary(l10n, settings, active),
          onTap: () => go(const JamaahRemindersPage()),
          divider: false,
        ),
        SettingsHeading(l10n.settingsGroupPreferences),
        SettingsLinkRow(
          title: l10n.settingsTravelSection,
          value: travelSummary(l10n, settings.travel),
          onTap: () => go(const TravelPage()),
        ),
        SettingsLinkRow(
          title: l10n.settingsLanguageLook,
          value: languageLookSummary(l10n, settings),
          onTap: () => go(const LanguageLookPage()),
          divider: false,
        ),
        SettingsHeading(l10n.settingsGroupHelp),
        SettingsLinkRow(
          title: l10n.settingsHelpAbout,
          value: l10n.settingsHelpSummary,
          onTap: () => go(const HelpAboutPage()),
          divider: false,
        ),
        SettingsNote(l10n.settingsHubFooter, top: 18),
      ],
    );
  }
}

/// One line saying what a prayer's alert does.
String alertSummary(
  AppLocalizations l10n,
  AdhanAlertSettings alerts,
  Prayer prayer,
) {
  final alert = alerts.alertFor(prayer);
  final name = soundModeName(l10n, alerts.soundModeFor(prayer));
  // A prayer that follows the default says so (owner, 2026-10-15).
  final sound = alert.soundModeOverride == null
      ? l10n.alertDefaultSuffix(name)
      : name;
  final before = alert.preAdhanMinutes;
  if (alert.enabled && before != null) {
    return l10n.settingsAlertOnWithReminder(sound, before);
  }
  if (alert.enabled) return l10n.settingsAlertOn(sound);
  if (before != null) return l10n.settingsAlertReminderOnly(before);
  return l10n.settingsAlertOff;
}

String soundModeHint(AppLocalizations l10n, AdhanSoundMode mode) =>
    switch (mode) {
      AdhanSoundMode.full => l10n.alertFullHint,
      AdhanSoundMode.short => l10n.alertShortHint,
      AdhanSoundMode.standard => l10n.alertStandardHint,
      AdhanSoundMode.silent => l10n.alertSilentHint,
    };
