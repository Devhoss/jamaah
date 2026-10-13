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
import '../../domain/adhan_recordings.dart';
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
    final chosen = await showSoundChoiceSheet<ReminderSound>(
      context,
      current: current,
      preview: _preview,
      choices: [
        SoundChoice(
          value: ReminderSound.chime,
          title: l10n.reminderSoundChime,
          hint: l10n.reminderSoundChimeHint,
          asset: kReminderChimeAsset,
        ),
        SoundChoice(
          value: ReminderSound.hayya,
          title: l10n.soundHayya,
          hint: l10n.reminderSoundHayyaHint,
          asset: kHayyaAsset,
        ),
        SoundChoice(
          value: ReminderSound.standard,
          title: l10n.soundModeStandard,
          hint: l10n.reminderSoundStandardHint,
        ),
        SoundChoice(
          value: ReminderSound.silent,
          title: l10n.soundModeSilent,
          hint: l10n.reminderSoundSilentHint,
        ),
      ],
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

/// One choice in a sound sheet ([showSoundChoiceSheet]).
class SoundChoice<T> {
  const SoundChoice({
    required this.value,
    required this.title,
    required this.hint,
    this.asset,
  });

  final T value;
  final String title;
  final String hint;

  /// A bundled sound to preview, when the choice has one of its own.
  final String? asset;
}

/// A bottom sheet of sounds to choose from, each with its own preview when it
/// has a sound of its own. Choosing closes the sheet with the choice; the
/// caller stops any preview after.
Future<T?> showSoundChoiceSheet<T>(
  BuildContext context, {
  required T current,
  required List<SoundChoice<T>> choices,
  required AudioPreview preview,
}) => showModalBottomSheet<T>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (_) => _SoundChoiceSheet<T>(
    current: current,
    choices: choices,
    preview: preview,
  ),
);

class _SoundChoiceSheet<T> extends StatefulWidget {
  const _SoundChoiceSheet({
    required this.current,
    required this.choices,
    required this.preview,
  });

  final T current;
  final List<SoundChoice<T>> choices;
  final AudioPreview preview;

  @override
  State<_SoundChoiceSheet<T>> createState() => _SoundChoiceSheetState<T>();
}

class _SoundChoiceSheetState<T> extends State<_SoundChoiceSheet<T>> {
  String? _playing;

  Future<void> _toggle(String asset) async {
    if (_playing == asset) {
      await widget.preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = asset);
    unawaited(
      widget.preview.play(asset).whenComplete(() {
        if (mounted && _playing == asset) setState(() => _playing = null);
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        child: RadioGroup<T>(
          groupValue: widget.current,
          onChanged: (v) => Navigator.of(context).pop(v),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final c in widget.choices)
                RadioListTile<T>(
                  value: c.value,
                  title: Text(c.title),
                  subtitle: Text(c.hint),
                  secondary: switch (c.asset) {
                    final asset? => TextButton(
                      onPressed: () => _toggle(asset),
                      child: Text(
                        _playing == asset
                            ? l10n.alertStopPreview
                            : l10n.alertPreview,
                      ),
                    ),
                    null => null,
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
