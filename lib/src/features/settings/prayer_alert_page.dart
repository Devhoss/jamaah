import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/notifications/notification_sync.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/notification_channels.dart';
import '../../domain/notification_plan.dart';
import '../../domain/prayer.dart';
import '../components/app_widgets.dart';
import 'settings_page.dart';

Future<void> openPrayerAlert(BuildContext context, Prayer prayer) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PrayerAlertPage(prayer: prayer)),
    );

/// Everything about one prayer's Adhan alert, and the reminder before it.
///
/// Every change is saved straight away, like a system settings page: there is no
/// Save button to forget, and the schedule follows within the same moment.
class PrayerAlertPage extends ConsumerStatefulWidget {
  const PrayerAlertPage({required this.prayer, super.key});

  final Prayer prayer;

  @override
  ConsumerState<PrayerAlertPage> createState() => _PrayerAlertPageState();
}

/// The reminder chips; Custom covers anything else from 1 to 120 minutes.
const _reminderPresets = <int>[5, 10, 15, 30];

class _PrayerAlertPageState extends ConsumerState<PrayerAlertPage> {
  /// The mode whose preview is playing, if any.
  AdhanSoundMode? _previewing;
  bool _customOpen = false;
  final _custom = TextEditingController();
  bool _sent = false;

  // Kept from initState: dispose must not read providers (the page is
  // already unmounted by then).
  late final AudioPreview _preview;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(audioPreviewProvider);
  }

  @override
  void dispose() {
    _custom.dispose();
    if (_previewing != null) unawaited(_preview.stop());
    super.dispose();
  }

  Prayer get _prayer => widget.prayer;

  Future<void> _change(AdhanAlert Function(AdhanAlert) change) =>
      updateAdhanAlerts(
        ref,
        (all) => all.withAlert(_prayer, change(all.alertFor(_prayer))),
      );

  Future<void> _togglePreview(AdhanSoundMode mode) async {
    final preview = _preview;
    if (_previewing == mode) {
      await preview.stop();
      if (mounted) setState(() => _previewing = null);
      return;
    }
    final asset = previewAssetFor(
      mode,
      fullRecording:
          ref.read(appSettingsProvider).value?.adhanAlerts.fullRecording ??
          kDefaultAdhanRecording,
    );
    if (asset == null) return;
    setState(() => _previewing = mode);
    // Not awaited: it completes when the sound ends, and the page stays usable
    // (and able to stop it) meanwhile.
    unawaited(
      preview.play(asset).whenComplete(() {
        if (mounted && _previewing == mode) setState(() => _previewing = null);
      }),
    );
  }

  Future<void> _sendTest(AdhanAlertSettings alerts) async {
    final l10n = ref.read(notificationL10nProvider);
    final alert = alerts.alertFor(_prayer);
    final mode = alerts.soundModeFor(_prayer);
    final planned = PlannedNotification(
      // Outside every id the planner can produce for centuries.
      id: 999990 + _prayer.index,
      kind: NotificationKind.adhan,
      prayer: _prayer,
      at: DateTime.now().toUtc(),
      soundMode: mode,
      mosqueId: '',
      vibrate: alert.vibrate,
      ringInSilent:
          alert.ringInSilent &&
          (mode == AdhanSoundMode.full || mode == AdhanSoundMode.short),
      fullScreen: alerts.fullScreen,
      recordingAsset: mode == AdhanSoundMode.full
          ? adhanRecordingById(alerts.fullRecording).asset
          : null,
    );
    await ref.read(notificationPermissionRequestProvider)();
    final item = ScheduledItem(
      planned: planned,
      channel: channelFor(planned),
      title: l10n.notifTestTitle(prayerName(l10n, _prayer)),
      body: l10n.notifTestBody,
      stopLabel: l10n.adhanStop,
    );
    final gateway = ref.read(notificationGatewayProvider);
    // The full Adhan and the full-screen Adhan are played by the app itself, so
    // the test goes the same way the real one will.
    if (playsInApp(planned)) {
      await gateway.playAdhanNow(item);
    } else {
      await gateway.showNow(item);
    }
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final alerts =
        ref.watch(appSettingsProvider).value?.adhanAlerts ??
        SettingsRepository.defaults.adhanAlerts;
    final alert = alerts.alertFor(_prayer);
    final effective = alerts.soundModeFor(_prayer);
    final plays =
        effective == AdhanSoundMode.full || effective == AdhanSoundMode.short;
    final small = theme.textTheme.bodySmall?.copyWith(color: ink.muted);
    final before = alert.preAdhanMinutes;
    final customSelected =
        _customOpen || (before != null && !_reminderPresets.contains(before));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.alertPageTitle(prayerName(l10n, _prayer))),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          if (_prayer == Prayer.sunrise) ...[
            Text(l10n.alertSunriseHint, style: small),
            const SizedBox(height: AppSpace.sm),
          ],
          AppRows(
            children: [
              SwitchListTile(
                title: Text(l10n.alertAdhanSwitch),
                subtitle: Text(l10n.alertAdhanSwitchHint),
                value: alert.enabled,
                onChanged: (on) async {
                  await _change((a) => a.copyWith(enabled: on));
                  if (on) {
                    await ref.read(notificationPermissionRequestProvider)();
                  }
                },
              ),
            ],
          ),
          AppSectionHeader(l10n.alertSoundHeader),
          AppRows(
            children: [
              RadioGroup<AdhanSoundMode?>(
                groupValue: alert.soundModeOverride,
                onChanged: (mode) => _change(
                  (a) => mode == null
                      ? a.copyWith(clearOverride: true)
                      : a.copyWith(soundModeOverride: mode),
                ),
                child: Column(
                  children: [
                    RadioListTile<AdhanSoundMode?>(
                      value: null,
                      title: Text(
                        l10n.alertUseDefault(
                          soundModeName(l10n, alerts.defaultSoundMode),
                        ),
                      ),
                    ),
                    for (final mode in AdhanSoundMode.values)
                      RadioListTile<AdhanSoundMode?>(
                        value: mode,
                        title: Text(soundModeName(l10n, mode)),
                        subtitle: Text(soundModeHint(l10n, mode)),
                        secondary: previewAssetFor(mode) == null
                            ? null
                            : TextButton(
                                onPressed: () => _togglePreview(mode),
                                child: Text(
                                  _previewing == mode
                                      ? l10n.alertStopPreview
                                      : l10n.alertPreview,
                                ),
                              ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppRows(
            children: [
              SwitchListTile(
                title: Text(l10n.alertVibrate),
                value: alert.vibrate,
                onChanged: (on) => _change((a) => a.copyWith(vibrate: on)),
              ),
              SwitchListTile(
                title: Text(l10n.alertRingInSilent),
                subtitle: Text(
                  plays
                      ? l10n.alertRingInSilentHint
                      : l10n.alertRingInSilentNeedsAdhan,
                ),
                value: plays && alert.ringInSilent,
                onChanged: plays
                    ? (on) => _change((a) => a.copyWith(ringInSilent: on))
                    : null,
              ),
            ],
          ),
          AppSectionHeader(l10n.alertReminderHeader),
          Text(l10n.alertReminderHint, style: small),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              ChoiceChip(
                label: Text(l10n.alertReminderNone),
                selected: before == null && !_customOpen,
                onSelected: (_) {
                  setState(() => _customOpen = false);
                  _change((a) => a.copyWith(clearPreAdhan: true));
                },
              ),
              for (final minutes in _reminderPresets)
                ChoiceChip(
                  label: Text(l10n.reminderMinutesChip(minutes)),
                  selected: !_customOpen && before == minutes,
                  onSelected: (_) async {
                    setState(() => _customOpen = false);
                    await _change((a) => a.copyWith(preAdhanMinutes: minutes));
                    await ref.read(notificationPermissionRequestProvider)();
                  },
                ),
              ChoiceChip(
                label: Text(l10n.reminderCustom),
                selected: customSelected,
                onSelected: (_) => setState(() {
                  _customOpen = true;
                  _custom.text = before?.toString() ?? '';
                }),
              ),
            ],
          ),
          if (customSelected) ...[
            const SizedBox(height: AppSpace.md),
            TextField(
              controller: _custom,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.reminderCustomLabel,
                errorText: _customError(l10n),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _saveCustom(),
            ),
            const SizedBox(height: AppSpace.sm),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed:
                    ReminderInterval.parseCustom(_custom.text)
                        is ReminderMinutesValid
                    ? _saveCustom
                    : null,
                child: Text(l10n.save),
              ),
            ),
          ],
          const SizedBox(height: AppSpace.xxl),
          OutlinedButton.icon(
            onPressed: () => _sendTest(alerts),
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(l10n.alertTryIt),
          ),
          if (_sent) ...[
            const SizedBox(height: AppSpace.xs),
            Text(l10n.alertTrySent, style: small),
          ],
        ],
      ),
    );
  }

  String? _customError(AppLocalizations l10n) {
    if (_custom.text.isEmpty) return null;
    return switch (ReminderInterval.parseCustom(_custom.text)) {
      ReminderMinutesValid() => null,
      ReminderMinutesEmpty() => l10n.reminderCustomEmpty,
      ReminderMinutesNotWhole() => l10n.reminderCustomNotWhole,
      ReminderMinutesOutOfRange() => l10n.reminderCustomOutOfRange,
    };
  }

  Future<void> _saveCustom() async {
    final input = ReminderInterval.parseCustom(_custom.text);
    if (input is! ReminderMinutesValid) return;
    FocusScope.of(context).unfocus();
    setState(() => _customOpen = false);
    await _change((a) => a.copyWith(preAdhanMinutes: input.minutes));
    await ref.read(notificationPermissionRequestProvider)();
  }
}
