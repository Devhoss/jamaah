import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/custom_sound_actions.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/custom_sounds.dart';
import '../../domain/prayer.dart';
import '../components/app_widgets.dart';
import 'settings_page.dart';

/// Opens the recording list: for every prayer, or ([prayer]) for one prayer's
/// own Full Adhan (2026-10-15).
Future<void> openAdhanRecordings(BuildContext context, {Prayer? prayer}) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdhanRecordingsPage(prayer: prayer),
      ),
    );

/// The value for "same as in Settings" on a prayer's own list.
const _same = '';

/// Chooses the recording "Full Adhan" plays, each one playable here first: the
/// user's own (added from the phone, renamed, deleted) above the bundled ones.
/// Choosing saves at once; the scheduler hands the new recording to every
/// Adhan the app will play.
class AdhanRecordingsPage extends ConsumerStatefulWidget {
  const AdhanRecordingsPage({this.prayer, super.key});

  /// Choosing for this prayer only; null chooses for every prayer.
  final Prayer? prayer;

  @override
  ConsumerState<AdhanRecordingsPage> createState() =>
      _AdhanRecordingsPageState();
}

class _AdhanRecordingsPageState extends ConsumerState<AdhanRecordingsPage> {
  String? _playing;
  late final AudioPreview _preview;

  @override
  void initState() {
    super.initState();
    _preview = ref.read(audioPreviewProvider);
  }

  @override
  void dispose() {
    // A three-minute recording must not outlive the page that started it.
    if (_playing != null) unawaited(_preview.stop());
    super.dispose();
  }

  Future<void> _toggle(String id, String source) async {
    if (_playing == id) {
      await _preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = id);
    unawaited(
      _preview.play(source).whenComplete(() {
        if (mounted && _playing == id) setState(() => _playing = null);
      }),
    );
  }

  Future<void> _choose(String id) => updateAdhanAlerts(ref, (all) {
    final prayer = widget.prayer;
    if (prayer == null) return all.copyWith(fullRecording: id);
    final alert = all.alertFor(prayer);
    return all.withAlert(
      prayer,
      id == _same
          ? alert.copyWith(clearRecording: true)
          : alert.copyWith(recording: id),
    );
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final alerts = settings.adhanAlerts;
    final mine = settings.customSounds;
    final prayer = widget.prayer;
    final chosen = prayer == null
        ? alerts.fullRecording
        : (alerts.alertFor(prayer).recording ?? _same);

    Widget playButton(String id, String name, String source) => IconButton(
      icon: Icon(
        _playing == id ? Icons.stop_circle_outlined : Icons.play_circle_outline,
      ),
      tooltip: _playing == id
          ? l10n.recordingStopLabel(name)
          : l10n.recordingPlayLabel(name),
      onPressed: () => _toggle(id, source),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          prayer == null
              ? l10n.recordingsTitle
              : l10n.recordingsForPrayer(prayerName(l10n, prayer)),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(
            prayer == null ? l10n.recordingsBody : l10n.prayerRecordingHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppInk.of(context).muted,
            ),
          ),
          const SizedBox(height: AppSpace.md),
          RadioGroup<String>(
            groupValue: chosen,
            onChanged: (id) {
              if (id != null) _choose(id);
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (prayer != null) ...[
                  AppRows(
                    children: [
                      RadioListTile<String>(
                        value: _same,
                        title: Text(
                          l10n.prayerRecordingSame(
                            resolveRecording(alerts.fullRecording, mine).name,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                AppSectionHeader(l10n.recordingsYours),
                if (mine.isNotEmpty) ...[
                  AppRows(
                    children: [
                      for (final s in mine)
                        RadioListTile<String>(
                          value: s.id,
                          title: Text(s.name),
                          secondary: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              playButton(s.id, s.name, s.path),
                              _SoundMenu(sound: s),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                ],
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    onPressed: () => addSoundFromPhone(context, ref),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.soundAddFromPhone),
                  ),
                ),
                AppSectionHeader(l10n.recordingsTitle),
                AppRows(
                  children: [
                    for (final r in adhanRecordings)
                      RadioListTile<String>(
                        value: r.id,
                        title: Text(r.name),
                        subtitle: Text(_length(l10n, r.seconds)),
                        secondary: playButton(r.id, r.name, r.asset),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rename or delete one of the user's own sounds.
class _SoundMenu extends ConsumerWidget {
  const _SoundMenu({required this.sound});

  final CustomSound sound;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return PopupMenuButton<String>(
      tooltip: l10n.soundOptions(sound.name),
      onSelected: (action) => switch (action) {
        'rename' => renameSound(context, ref, sound),
        _ => deleteSound(context, ref, sound),
      },
      itemBuilder: (_) => [
        PopupMenuItem(value: 'rename', child: Text(l10n.soundRename)),
        PopupMenuItem(value: 'delete', child: Text(l10n.soundDelete)),
      ],
    );
  }
}

/// "3:25": minutes and seconds, the way every player shows a length.
String _length(AppLocalizations l10n, int seconds) => l10n.recordingLength(
  '${seconds ~/ 60}',
  (seconds % 60).toString().padLeft(2, '0'),
);

/// The name Settings shows for the recording for every prayer.
String recordingName(AdhanAlertSettings alerts) =>
    resolveRecording(alerts.fullRecording, alerts.customRecordings).name;
