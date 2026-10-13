import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/location_follower.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/place.dart';
import '../../domain/prayer.dart';
import '../components/app_widgets.dart';
import '../mosques/mosque_detail_page.dart';
import 'prayer_alert_page.dart';
import 'scheduled_notifications_page.dart';

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

/// Settings for what reaches the user and when (AGENTS.md). Iqama reminders are
/// not configured here: they belong to each mosque, so this only points there.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final alerts = settings.adhanAlerts;
    final travel = settings.travel;
    final active = ref.watch(activeMosqueProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          AppSectionHeader(l10n.settingsAdhanSection),
          AppRows(
            children: [
              AppRow(
                leading: null,
                onTap: () => _chooseDefaultSound(context, ref, alerts),
                // The value sits under the title rather than beside it, so a large text
                // size wraps it instead of pushing the row off the screen.
                title: _TwoLines(
                  first: l10n.settingsDefaultSound,
                  second: soundModeName(l10n, alerts.defaultSoundMode),
                ),
                trailing: Icon(Icons.chevron_right, color: ink.muted),
              ),
              for (final prayer in Prayer.adhanPrayers)
                AppRow(
                  leading: null,
                  muted: prayer == Prayer.sunrise,
                  onTap: () => openPrayerAlert(context, prayer),
                  title: _TwoLines(
                    first: prayerName(l10n, prayer),
                    second: alertSummary(l10n, alerts, prayer),
                  ),
                  trailing: Icon(Icons.chevron_right, color: ink.muted),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          _FullScreenRow(alerts: alerts),
          AppSectionHeader(l10n.settingsIqamaSection),
          Text(l10n.settingsIqamaBody, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpace.sm),
          if (active == null)
            Text(
              l10n.settingsIqamaNoMosque,
              style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
            )
          else
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: OutlinedButton(
                onPressed: () => openMosqueDetail(context, active.id),
                child: Text(l10n.settingsIqamaOpenActive(active.name)),
              ),
            ),
          AppSectionHeader(l10n.settingsTravelSection),
          AppRows(
            children: [
              SwitchListTile(
                title: Text(l10n.settingsFollowLocation),
                subtitle: Text(l10n.settingsFollowLocationHint),
                value: travel.followLocation,
                onChanged: (on) => _setFollow(context, ref, on),
              ),
              SwitchListTile(
                title: Text(l10n.settingsTravelMode),
                subtitle: Text(l10n.settingsTravelModeHint),
                value: travel.travelMode,
                onChanged: (on) => ref
                    .read(settingsRepositoryProvider)
                    .saveTravel(travel.copyWith(travelMode: on)),
              ),
              SwitchListTile(
                title: Text(l10n.settingsPauseIqama),
                subtitle: Text(
                  travel.travelMode
                      ? l10n.settingsPauseIqamaHint
                      : l10n.settingsPauseIqamaNeedsTravel,
                ),
                value: travel.travelMode && travel.pauseIqamaReminders,
                onChanged: travel.travelMode
                    ? (on) => ref
                          .read(settingsRepositoryProvider)
                          .saveTravel(travel.copyWith(pauseIqamaReminders: on))
                    : null,
              ),
            ],
          ),
          AppSectionHeader(l10n.settingsNotificationsSection),
          AppRows(
            children: [
              AppRow(
                leading: null,
                onTap: () => openScheduledNotifications(context),
                title: Text(l10n.scheduledTitle),
                trailing: Icon(Icons.chevron_right, color: ink.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.settingsComingLater,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.aboutBody,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
        ],
      ),
    );
  }

  /// Turning following on is the user's tap, so the location dialog may show
  /// now; if the device says no, following stays off and the reason is shown.
  Future<void> _setFollow(BuildContext context, WidgetRef ref, bool on) async {
    final follower = ref.read(locationFollowerProvider);
    if (!on) {
      await follower.disable();
      return;
    }
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final failure = await follower.enable();
    if (failure == null) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          failure == PlaceFailure.denied ||
                  failure == PlaceFailure.permanentlyDenied
              ? l10n.followDenied
              : l10n.followUnavailable,
        ),
      ),
    );
  }

  Future<void> _chooseDefaultSound(
    BuildContext context,
    WidgetRef ref,
    AdhanAlertSettings alerts,
  ) async {
    final l10n = AppLocalizations.of(context);
    final chosen = await showModalBottomSheet<AdhanSoundMode>(
      context: context,
      showDragHandle: true,
      // Four options with their explanations are taller than the default sheet
      // on a phone, and taller still at a large text size.
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: RadioGroup<AdhanSoundMode>(
            groupValue: alerts.defaultSoundMode,
            onChanged: (mode) => Navigator.of(sheetContext).pop(mode),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final mode in AdhanSoundMode.values)
                  RadioListTile<AdhanSoundMode>(
                    value: mode,
                    title: Text(soundModeName(l10n, mode)),
                    subtitle: Text(soundModeHint(l10n, mode)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (chosen == null || chosen == alerts.defaultSoundMode) return;
    await updateAdhanAlerts(ref, (a) => a.withSoundMode(chosen));
  }
}

/// One line saying what a prayer's alert does.
String alertSummary(
  AppLocalizations l10n,
  AdhanAlertSettings alerts,
  Prayer prayer,
) {
  final alert = alerts.alertFor(prayer);
  final sound = soundModeName(l10n, alerts.soundModeFor(prayer));
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

class _TwoLines extends StatelessWidget {
  const _TwoLines({required this.first, required this.second});

  final String first;
  final String second;

  @override
  Widget build(BuildContext context) {
    final ink = AppInk.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          first,
          style: const TextStyle(
            fontSize: AppType.rowSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(second, style: TextStyle(fontSize: 13, color: ink.muted)),
      ],
    );
  }
}

/// The global full-screen switch, and Android 14's own permission for it.
class _FullScreenRow extends ConsumerStatefulWidget {
  const _FullScreenRow({required this.alerts});

  final AdhanAlertSettings alerts;

  @override
  ConsumerState<_FullScreenRow> createState() => _FullScreenRowState();
}

class _FullScreenRowState extends ConsumerState<_FullScreenRow> {
  bool? _allowed;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Back from the system page: read the permission again.
    _lifecycle = AppLifecycleListener(onResume: _check);
    _check();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final allowed = await ref
        .read(notificationGatewayProvider)
        .canUseFullScreen();
    if (mounted) setState(() => _allowed = allowed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final on = widget.alerts.fullScreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppRows(
          children: [
            SwitchListTile(
              title: Text(l10n.settingsFullScreen),
              subtitle: Text(l10n.settingsFullScreenHint),
              value: on,
              onChanged: (value) async {
                await updateAdhanAlerts(
                  ref,
                  (a) => a.copyWith(fullScreen: value),
                );
                if (value) {
                  await ref.read(notificationPermissionRequestProvider)();
                  await _check();
                }
              },
            ),
          ],
        ),
        if (on && _allowed == false) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.settingsFullScreenDenied,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => ref
                  .read(localNotificationsGatewayProvider)
                  .openFullScreenSettings(),
              child: Text(l10n.settingsFullScreenAllow),
            ),
          ),
        ],
      ],
    );
  }
}
