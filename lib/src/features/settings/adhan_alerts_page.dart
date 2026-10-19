import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/prayer.dart';
import 'adhan_recordings_page.dart';
import 'jamaah_reminder_settings.dart';
import 'prayer_alert_page.dart';
import 'settings_kit.dart';
import 'settings_page.dart';

/// "Short Adhan · 5 of 6 on": what the hub row says.
String adhanAlertsSummary(AppLocalizations l10n, AdhanAlertSettings alerts) {
  final on = Prayer.adhanPrayers.where((p) => alerts.alertFor(p).enabled);
  return l10n.settingsAlertsSummary(
    soundModeName(l10n, alerts.defaultSoundMode),
    on.length,
    Prayer.adhanPrayers.length,
  );
}

/// What reaches the user at each Adhan (spec §4.9): the default sound, each
/// prayer, the recordings, full screen, and ringing on silent.
class AdhanAlertsPage extends ConsumerWidget {
  const AdhanAlertsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final alerts =
        ref.watch(appSettingsProvider).value?.adhanAlerts ??
        SettingsRepository.defaults.adhanAlerts;

    return SettingsScaffold(
      title: l10n.settingsAdhanSection,
      lead: l10n.settingsAlertsLead,
      children: [
        SettingsHeading(l10n.settingsDefaultSound, top: 4),
        RadioList<AdhanSoundMode>(
          options: [
            for (final mode in AdhanSoundMode.values)
              RadioOption(
                mode,
                soundModeName(l10n, mode),
                description: soundModeHint(l10n, mode),
              ),
          ],
          selected: alerts.defaultSoundMode,
          onChanged: (mode) {
            if (mode == alerts.defaultSoundMode) return;
            unawaited(updateAdhanAlerts(ref, (a) => a.withSoundMode(mode)));
          },
        ),
        SettingsNote(l10n.settingsDefaultSoundHint),
        SettingsHeading(l10n.alertsEachPrayer),
        for (final (i, prayer) in Prayer.adhanPrayers.indexed)
          SettingsLinkRow(
            title: prayerName(l10n, prayer),
            value: alertSummary(l10n, alerts, prayer),
            muted: prayer == Prayer.sunrise,
            divider: i < Prayer.adhanPrayers.length - 1,
            onTap: () => openPrayerAlert(context, prayer),
          ),
        SettingsNote(l10n.alertsAlsoFromToday),
        SettingsHeading(l10n.alertsRecordings),
        SettingsLinkRow(
          title: l10n.settingsFullRecording,
          value: recordingName(alerts),
          onTap: () => openAdhanRecordings(context),
        ),
        SettingsLinkRow(
          title: l10n.settingsShortAdhan,
          value: shortAdhanName(alerts.shortAdhan),
          onTap: () => _chooseShortAdhan(context, ref, alerts),
          divider: false,
        ),
        SettingsHeading(l10n.alertsSilentSection),
        _FullScreenRow(alerts: alerts),
        for (final (i, (target, title)) in [
          (RingTarget.adhan, l10n.settingsAdhanRingInSilent),
          (RingTarget.preAdhan, l10n.settingsPreAdhanRingInSilent),
        ].indexed)
          SettingsSwitchRow(
            title: title,
            hint: alerts.ringInSilentFor(target) == RingCoverage.some
                ? l10n.ringInSilentSome
                : l10n.alertRingInSilentHint,
            // A mix reads as off: one tap rings them all.
            value: alerts.ringInSilentFor(target) == RingCoverage.all,
            divider: i == 0,
            onChanged: (on) => updateAdhanAlerts(
              ref,
              (a) => a.withRingInSilentForAll(target, on: on),
            ),
          ),
      ],
    );
  }

  Future<void> _chooseShortAdhan(
    BuildContext context,
    WidgetRef ref,
    AdhanAlertSettings alerts,
  ) async {
    final l10n = AppLocalizations.of(context);
    final preview = ref.read(audioPreviewProvider);
    final chosen = await showSoundChoiceSheet<ShortAdhan>(
      context,
      current: alerts.shortAdhan,
      preview: preview,
      choices: [
        for (final clip in ShortAdhan.values)
          SoundChoice(
            value: clip,
            title: clip.label,
            hint: l10n.shortAdhanClipHint,
            asset: clip.asset,
          ),
      ],
    );
    unawaited(preview.stop());
    if (chosen == null || chosen == alerts.shortAdhan) return;
    await updateAdhanAlerts(ref, (all) => all.copyWith(shortAdhan: chosen));
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
    final on = widget.alerts.fullScreen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSwitchRow(
          title: l10n.settingsFullScreen,
          hint: l10n.settingsFullScreenHint,
          value: on,
          onChanged: (value) async {
            await updateAdhanAlerts(ref, (a) => a.copyWith(fullScreen: value));
            if (value) {
              await ref.read(notificationPermissionRequestProvider)();
              await _check();
            }
          },
        ),
        if (on && _allowed == false) ...[
          SettingsNote(l10n.settingsFullScreenDenied, top: 0),
          const SizedBox(height: 8),
          SettingsButton(
            label: l10n.settingsFullScreenAllow,
            onPressed: () => ref
                .read(localNotificationsGatewayProvider)
                .openFullScreenSettings(),
          ),
        ],
      ],
    );
  }
}
