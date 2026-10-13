import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/notifications/notification_sync.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/notification_channels.dart';
import '../../domain/notification_plan.dart';
import '../../domain/prayer.dart';
import '../components/app_widgets.dart';

/// The bundled chime, as Settings previews it. The notification channel plays
/// the same file from android/app/src/main/res/raw/reminder_chime.wav.
const kReminderChimeAsset = 'assets/audio/chime/reminder_chime.wav';

/// How every Jama’ah reminder sounds: the sound, vibration, and a test.
/// Which prayers have a reminder, and how early, stays on each mosque.
class JamaahReminderSoundRows extends ConsumerStatefulWidget {
  const JamaahReminderSoundRows({super.key});

  @override
  ConsumerState<JamaahReminderSoundRows> createState() =>
      _JamaahReminderSoundRowsState();
}

class _JamaahReminderSoundRowsState
    extends ConsumerState<JamaahReminderSoundRows> {
  late final AudioPreview _preview;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(audioPreviewProvider);
  }

  JamaahReminderSettings get _current =>
      ref.read(appSettingsProvider).value?.jamaahReminders ??
      const JamaahReminderSettings();

  Future<void> _save(JamaahReminderSettings value) =>
      ref.read(settingsRepositoryProvider).saveJamaahReminders(value);

  Future<void> _chooseSound(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final current = _current.sound;
    final chosen = await showModalBottomSheet<ReminderSound>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) =>
          _SoundSheet(current: current, preview: _preview, l10n: l10n),
    );
    unawaited(_preview.stop());
    if (chosen == null || chosen == current) return;
    await _save(_current.copyWith(sound: chosen));
  }

  Future<void> _sendTest() async {
    final l10n = ref.read(notificationL10nProvider);
    final settings = _current;
    final active = ref.read(activeMosqueProvider);
    final planned = PlannedNotification(
      // Outside every id the planner can produce for centuries.
      id: 999980,
      kind: NotificationKind.iqama,
      prayer: Prayer.fajr,
      at: DateTime.now().toUtc(),
      soundMode: null,
      mosqueId: active?.id ?? '',
      minutesBefore: 10,
      vibrate: settings.vibrate,
      reminderSound: settings.sound,
    );
    await ref.read(notificationPermissionRequestProvider)();
    final text = notificationText(
      l10n,
      planned,
      mosqueName: (_) => active?.name,
    );
    await ref
        .read(notificationGatewayProvider)
        .showNow(
          ScheduledItem(
            planned: planned,
            channel: channelFor(planned),
            title: text.title,
            body: text.body,
            stopLabel: l10n.adhanStop,
          ),
        );
    if (mounted) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final reminders =
        ref.watch(appSettingsProvider).value?.jamaahReminders ??
        SettingsRepository.defaults.jamaahReminders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppRows(
          children: [
            AppRow(
              leading: null,
              onTap: () => _chooseSound(context),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(l10n.settingsReminderSound),
                  Text(
                    reminderSoundName(l10n, reminders.sound),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: ink.muted),
                  ),
                ],
              ),
              trailing: Icon(Icons.chevron_right, color: ink.muted),
            ),
            SwitchListTile(
              title: Text(l10n.settingsReminderVibrate),
              value: reminders.vibrate,
              onChanged: (on) => _save(reminders.copyWith(vibrate: on)),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpace.md,
          children: [
            OutlinedButton(
              onPressed: _sendTest,
              child: Text(l10n.settingsReminderTest),
            ),
            if (_sent)
              Text(
                l10n.settingsReminderTestSent,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: ink.muted),
              ),
          ],
        ),
      ],
    );
  }
}

class _SoundSheet extends StatefulWidget {
  const _SoundSheet({
    required this.current,
    required this.preview,
    required this.l10n,
  });

  final ReminderSound current;
  final AudioPreview preview;
  final AppLocalizations l10n;

  @override
  State<_SoundSheet> createState() => _SoundSheetState();
}

class _SoundSheetState extends State<_SoundSheet> {
  bool _playing = false;

  Future<void> _toggle() async {
    if (_playing) {
      await widget.preview.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    unawaited(
      widget.preview.play(kReminderChimeAsset).whenComplete(() {
        if (mounted) setState(() => _playing = false);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    String hint(ReminderSound s) => switch (s) {
      ReminderSound.chime => l10n.reminderSoundChimeHint,
      ReminderSound.standard => l10n.reminderSoundStandardHint,
      ReminderSound.silent => l10n.reminderSoundSilentHint,
    };
    return SafeArea(
      child: SingleChildScrollView(
        child: RadioGroup<ReminderSound>(
          groupValue: widget.current,
          onChanged: (s) => Navigator.of(context).pop(s),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in ReminderSound.values)
                RadioListTile<ReminderSound>(
                  value: s,
                  title: Text(reminderSoundName(l10n, s)),
                  subtitle: Text(hint(s)),
                  secondary: s == ReminderSound.chime
                      ? TextButton(
                          onPressed: _toggle,
                          child: Text(
                            _playing
                                ? l10n.alertStopPreview
                                : l10n.alertPreview,
                          ),
                        )
                      : null,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
