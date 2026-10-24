import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/custom_sound_actions.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/mosque.dart';
import '../mosques/mosque_detail_page.dart';
import 'settings_kit.dart';

/// The bundled chime, as Settings previews it. The notification channel plays
/// the same file from android/app/src/main/res/raw/reminder_chime.wav.
const kReminderChimeAsset = 'assets/audio/chime/reminder_chime.wav';

/// "Masjid al-Nour · Chime": what the hub row says.
String jamaahRemindersSummary(
  AppLocalizations l10n,
  AppSettingsSnapshot settings,
  Mosque? active,
) {
  final r = settings.jamaahReminders;
  final sound = switch (r.customSound) {
    final mine? when r.sound == ReminderSound.custom =>
      l10n.reminderSoundCustomNamed(mine.name),
    _ => reminderSoundName(l10n, r.sound),
  };
  if (settings.travel.pauseAllIqamaReminders) {
    return l10n.settingsSummaryPair(l10n.settingsRemindersPausedShort, sound);
  }
  return l10n.settingsSummaryPair(
    active?.name ?? l10n.settingsNoActiveMosque,
    sound,
  );
}

/// How every Jama’ah reminder sounds (spec §4.9): the sound, vibration,
/// ringing on silent, a test, and pausing them all. Which prayers have a
/// reminder, and how early, stays on each mosque, so this only leads there.
class JamaahRemindersPage extends ConsumerStatefulWidget {
  const JamaahRemindersPage({super.key});

  @override
  ConsumerState<JamaahRemindersPage> createState() =>
      _JamaahRemindersPageState();
}

class _JamaahRemindersPageState extends ConsumerState<JamaahRemindersPage> {
  late final AudioPreview _preview;
  String? _playing;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(audioPreviewProvider);
  }

  @override
  void dispose() {
    // Leaving the page stops a sound it started.
    if (_playing != null) unawaited(_preview.stop());
    super.dispose();
  }

  JamaahReminderSettings get _current =>
      ref.read(appSettingsProvider).value?.jamaahReminders ??
      const JamaahReminderSettings();

  Future<void> _save(JamaahReminderSettings value) =>
      ref.read(settingsRepositoryProvider).saveJamaahReminders(value);

  Future<void> _togglePreview(String asset) async {
    if (_playing == asset) {
      await _preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = asset);
    unawaited(
      _preview.play(asset).whenComplete(() {
        if (mounted && _playing == asset) setState(() => _playing = null);
      }),
    );
  }

  Future<void> _choose(ReminderSound chosen) async {
    if (_playing != null) {
      unawaited(_preview.stop());
      setState(() => _playing = null);
    }
    // Your own sound: a file from the phone, picked now (2026-10-15); picking
    // again replaces it. Nothing picked changes nothing.
    if (chosen == ReminderSound.custom) {
      final sound = await addSoundFromPhone(context, ref);
      if (sound == null) return;
      await _save(
        _current.copyWith(sound: ReminderSound.custom, customSound: sound),
      );
      return;
    }
    if (chosen == _current.sound) return;
    await _save(_current.copyWith(sound: chosen));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final reminders = settings.jamaahReminders;
    final travel = settings.travel;
    final active = ref.watch(activeMosqueProvider);

    Widget? preview(String? asset) => asset == null
        ? null
        : SettingsTextButton(
            label: _playing == asset
                ? l10n.alertStopPreview
                : l10n.alertPreview,
            onPressed: () => _togglePreview(asset),
          );

    final mine = reminders.customSound;
    return SettingsScaffold(
      title: l10n.settingsIqamaSection,
      lead: l10n.settingsRemindersLead,
      children: [
        SettingsNote(l10n.settingsRemindersOnMosque, top: 4),
        const SizedBox(height: 12),
        if (active == null)
          SettingsNote(l10n.settingsIqamaNoMosque, top: 0)
        else
          SettingsButton(
            label: l10n.settingsIqamaOpenActive(active.name),
            onPressed: () => openMosqueDetail(context, active.id),
          ),
        SettingsHeading(l10n.settingsReminderSound),
        RadioList<ReminderSound>(
          options: [
            RadioOption(
              ReminderSound.chime,
              l10n.reminderSoundChime,
              description: l10n.reminderSoundChimeHint,
              trailing: preview(kReminderChimeAsset),
            ),
            for (final choice in [
              (
                ReminderSound.shortAzan,
                ShortAdhan.azanShort,
                l10n.reminderSoundShortAzan,
              ),
              (
                ReminderSound.shortAllahAkbar,
                ShortAdhan.azanAllahAkbar,
                l10n.reminderSoundShortAllahAkbar,
              ),
              (
                ReminderSound.shortAzanOne,
                ShortAdhan.azanShortOne,
                l10n.reminderSoundShortAzanOne,
              ),
              (
                ReminderSound.shortVerseOne,
                ShortAdhan.adhanVerseOne,
                l10n.reminderSoundShortVerseOne,
              ),
              (
                ReminderSound.shortVerseTwo,
                ShortAdhan.adhanVerseTwo,
                l10n.reminderSoundShortVerseTwo,
              ),
            ])
              RadioOption(
                choice.$1,
                choice.$3,
                description: l10n.shortAdhanClipHint,
                trailing: preview(choice.$2.asset),
              ),
            RadioOption(
              ReminderSound.standard,
              l10n.soundModeStandard,
              description: l10n.reminderSoundStandardHint,
            ),
            RadioOption(
              ReminderSound.silent,
              l10n.soundModeSilent,
              description: l10n.reminderSoundSilentHint,
            ),
            RadioOption(
              ReminderSound.custom,
              l10n.reminderSoundCustom,
              description: mine == null
                  ? l10n.reminderSoundCustomHint
                  : l10n.reminderSoundCustomNamed(mine.name),
              trailing: preview(reminders.customSoundPath),
            ),
          ],
          selected: reminders.sound,
          onChanged: _choose,
        ),
        const SizedBox(height: 8),
        SettingsSwitchRow(
          title: l10n.settingsReminderVibrate,
          value: reminders.vibrate,
          onChanged: (on) => _save(reminders.copyWith(vibrate: on)),
        ),
        SettingsSwitchRow(
          title: l10n.alertRingInSilent,
          hint: reminders.sound == ReminderSound.silent
              ? l10n.alertRingInSilentNeedsSound
              : l10n.alertRingInSilentHint,
          value:
              reminders.ringInSilent && reminders.sound != ReminderSound.silent,
          divider: false,
          onChanged: reminders.sound == ReminderSound.silent
              ? null
              : (on) => _save(reminders.copyWith(ringInSilent: on)),
        ),
        const SizedBox(height: 14),
        SettingsSwitchRow(
          title: l10n.settingsPauseAllIqama,
          hint: l10n.settingsPauseAllIqamaHint,
          value: travel.pauseAllIqamaReminders,
          divider: false,
          onChanged: (on) => ref
              .read(settingsRepositoryProvider)
              .saveTravel(travel.copyWith(pauseAllIqamaReminders: on)),
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
}) => showSettingsSheet<T>(
  context,
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
    return SettingsSheetBody(
      children: [
        RadioList<T>(
          options: [
            for (final c in widget.choices)
              RadioOption(
                c.value,
                c.title,
                description: c.hint,
                trailing: switch (c.asset) {
                  final asset? => SettingsTextButton(
                    label: _playing == asset
                        ? l10n.alertStopPreview
                        : l10n.alertPreview,
                    onPressed: () => _toggle(asset),
                  ),
                  null => null,
                },
              ),
          ],
          selected: widget.current,
          onChanged: (v) => Navigator.of(context).pop(v),
        ),
      ],
    );
  }
}
