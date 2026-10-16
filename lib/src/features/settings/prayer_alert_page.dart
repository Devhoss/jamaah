import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/adhan_screen.dart';
import '../../app/audio_preview.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../data/notifications/notification_sync.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/notification_channels.dart';
import '../../domain/notification_plan.dart';
import '../../domain/prayer.dart';
import 'adhan_recordings_page.dart';
import 'settings_kit.dart';
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
    final alerts = ref.read(appSettingsProvider).value?.adhanAlerts;
    final asset = previewAssetFor(
      mode,
      fullSource: alerts?.recordingSourceFor(_prayer).source,
      shortAdhan: alerts?.shortAdhan ?? ShortAdhan.naghshbandi,
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
      ringInSilent: alert.ringInSilent && mode != AdhanSoundMode.silent,
      fullScreen: alerts.fullScreen,
      recordingAsset: switch (mode) {
        AdhanSoundMode.full => adhanRecordingById(alerts.fullRecording).asset,
        AdhanSoundMode.short => alerts.shortAdhan.asset,
        _ => null,
      },
      shortAdhan: alerts.shortAdhan,
    );
    await ref.read(notificationPermissionRequestProvider)();
    final calculator = ref.read(prayerTimesCalculatorProvider);
    final zone = ref.read(placeZoneProvider);
    final settings =
        ref.read(appSettingsProvider).value ?? SettingsRepository.defaults;
    final use24Hour = mounted && MediaQuery.alwaysUse24HourFormatOf(context);
    final item = ScheduledItem(
      planned: planned,
      channel: channelFor(planned),
      title: l10n.notifTestTitle(prayerName(l10n, _prayer)),
      body: l10n.notifTestBody,
      stopLabel: l10n.adhanStop,
      // The test full-screen page looks like the real one: this prayer's sky.
      screen: planned.fullScreen && calculator != null && zone != null
          ? adhanScreenPayload(
              planned: planned,
              calculator: calculator,
              zone: zone,
              l10n: l10n,
              mosque: ref.read(activeMosqueProvider),
              theme: settings.themeMode.name,
              hijriAdjustDays: settings.hijriAdjustDays,
              clockTime: (t) => plainClockTime(
                t,
                use24Hour: use24Hour,
                languageCode: l10n.localeName,
              ),
            )
          : null,
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
    final alerts =
        ref.watch(appSettingsProvider).value?.adhanAlerts ??
        SettingsRepository.defaults.adhanAlerts;
    final alert = alerts.alertFor(_prayer);
    final effective = alerts.soundModeFor(_prayer);
    // Any sound can ring on silent; only Silent has nothing to ring.
    final plays = effective != AdhanSoundMode.silent;
    final before = alert.preAdhanMinutes;
    final customSelected =
        _customOpen || (before != null && !_reminderPresets.contains(before));

    return SettingsScaffold(
      title: l10n.alertPageTitle(prayerName(l10n, _prayer)),
      lead: _prayer == Prayer.sunrise ? l10n.alertSunriseHint : null,
      children: [
        SettingsSwitchRow(
          title: l10n.alertAdhanSwitch,
          hint: l10n.alertAdhanSwitchHint,
          value: alert.enabled,
          divider: false,
          onChanged: (on) async {
            await _change((a) => a.copyWith(enabled: on));
            if (on) {
              await ref.read(notificationPermissionRequestProvider)();
            }
          },
        ),
        SettingsHeading(l10n.alertSoundHeader),
        // This prayer's own Full Adhan recording (2026-10-15).
        SettingsLinkRow(
          title: l10n.prayerRecording,
          value: alert.recording == null
              ? l10n.prayerRecordingSame(recordingName(alerts))
              : alerts.recordingSourceFor(_prayer).name,
          onTap: () => openAdhanRecordings(context, prayer: _prayer),
        ),
        RadioList<AdhanSoundMode?>(
          options: [
            RadioOption(
              null,
              l10n.alertUseDefault(
                soundModeName(l10n, alerts.defaultSoundMode),
              ),
            ),
            for (final mode in AdhanSoundMode.values)
              RadioOption(
                mode,
                soundModeName(l10n, mode),
                description: soundModeHint(l10n, mode),
                trailing: previewAssetFor(mode) == null
                    ? null
                    : SettingsTextButton(
                        label: _previewing == mode
                            ? l10n.alertStopPreview
                            : l10n.alertPreview,
                        onPressed: () => _togglePreview(mode),
                      ),
              ),
          ],
          selected: alert.soundModeOverride,
          onChanged: (mode) => _change(
            (a) => mode == null
                ? a.copyWith(clearOverride: true)
                : a.copyWith(soundModeOverride: mode),
          ),
        ),
        const SizedBox(height: 8),
        SettingsSwitchRow(
          title: l10n.alertVibrate,
          value: alert.vibrate,
          onChanged: (on) => _change((a) => a.copyWith(vibrate: on)),
        ),
        SettingsSwitchRow(
          title: l10n.alertRingInSilent,
          hint: plays
              ? l10n.alertRingInSilentHint
              : l10n.alertRingInSilentNeedsSound,
          value: plays && alert.ringInSilent,
          divider: false,
          onChanged: plays
              ? (on) => _change((a) => a.copyWith(ringInSilent: on))
              : null,
        ),
        SettingsHeading(l10n.alertReminderHeader),
        SettingsNote(l10n.alertReminderHint, top: 0),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            SettingsChip(
              label: l10n.alertReminderNone,
              selected: before == null && !_customOpen,
              onTap: () {
                setState(() => _customOpen = false);
                _change((a) => a.copyWith(clearPreAdhan: true));
              },
            ),
            for (final minutes in _reminderPresets)
              SettingsChip(
                label: l10n.reminderMinutesChip(minutes),
                selected: !_customOpen && before == minutes,
                onTap: () async {
                  setState(() => _customOpen = false);
                  await _change((a) => a.copyWith(preAdhanMinutes: minutes));
                  await ref.read(notificationPermissionRequestProvider)();
                },
              ),
            SettingsChip(
              label: l10n.reminderCustom,
              selected: customSelected,
              onTap: () => setState(() {
                _customOpen = true;
                _custom.text = before?.toString() ?? '';
              }),
            ),
          ],
        ),
        if (before != null) ...[
          const SizedBox(height: 8),
          SettingsSwitchRow(
            title: l10n.alertPreAdhanRingInSilent,
            hint: l10n.alertRingInSilentHint,
            value: alert.preAdhanRingInSilent,
            divider: false,
            onChanged: (on) =>
                _change((a) => a.copyWith(preAdhanRingInSilent: on)),
          ),
        ],
        if (customSelected) ...[
          const SizedBox(height: 12),
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
          const SizedBox(height: 8),
          SettingsButton(
            label: l10n.save,
            filled: true,
            onPressed:
                ReminderInterval.parseCustom(_custom.text)
                    is ReminderMinutesValid
                ? _saveCustom
                : null,
          ),
        ],
        const SizedBox(height: 24),
        SettingsButton(
          label: l10n.alertTryIt,
          onPressed: () => _sendTest(alerts),
        ),
        if (_sent)
          Semantics(
            liveRegion: true,
            child: SettingsNote(l10n.alertTrySent),
          ),
      ],
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
