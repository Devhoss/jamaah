import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/custom_sound_actions.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/adhan_recordings.dart';
import '../../domain/custom_sounds.dart';
import '../../domain/prayer.dart';
import '../components/line_icon.dart';
import 'settings_kit.dart';
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
    final s = HorizonTheme.of(context).surfaces;
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final alerts = settings.adhanAlerts;
    final mine = settings.customSounds;
    final prayer = widget.prayer;
    final chosen = prayer == null
        ? alerts.fullRecording
        : (alerts.alertFor(prayer).recording ?? _same);

    Widget playButton(String id, String name, String source) => IconButton(
      icon: LineIcon(
        _playing == id ? LineIcons.stop : LineIcons.play,
        size: 20,
        strokeWidth: 2,
        color: s.onSurface,
      ),
      tooltip: _playing == id
          ? l10n.recordingStopLabel(name)
          : l10n.recordingPlayLabel(name),
      onPressed: () => _toggle(id, source),
    );

    return SettingsScaffold(
      title: prayer == null
          ? l10n.recordingsTitle
          : l10n.recordingsForPrayer(prayerName(l10n, prayer)),
      lead: prayer == null ? l10n.recordingsBody : l10n.prayerRecordingHint,
      children: [
        if (prayer != null)
          RadioList<String>(
            options: [
              RadioOption(
                _same,
                l10n.prayerRecordingSame(
                  resolveRecording(alerts.fullRecording, mine).name,
                ),
              ),
            ],
            selected: chosen,
            onChanged: _choose,
          ),
        SettingsHeading(l10n.recordingsYours, top: prayer == null ? 4 : 22),
        if (mine.isNotEmpty) ...[
          RadioList<String>(
            options: [
              for (final m in mine)
                RadioOption(
                  m.id,
                  m.name,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      playButton(m.id, m.name, m.path),
                      _SoundMenu(sound: m),
                    ],
                  ),
                ),
            ],
            selected: chosen,
            onChanged: _choose,
          ),
          const SizedBox(height: 8),
        ],
        SettingsButton(
          label: l10n.soundAddFromPhone,
          onPressed: () => addSoundFromPhone(context, ref),
        ),
        SettingsHeading(l10n.recordingsTitle),
        RadioList<String>(
          options: [
            for (final r in adhanRecordings)
              RadioOption(
                r.id,
                r.name,
                description: _length(l10n, r.seconds),
                trailing: playButton(r.id, r.name, r.asset),
              ),
          ],
          selected: chosen,
          onChanged: _choose,
        ),
      ],
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
    final s = HorizonTheme.of(context).surfaces;
    return PopupMenuButton<String>(
      tooltip: l10n.soundOptions(sound.name),
      color: s.surface,
      icon: LineIcon(LineIcons.more, size: 20, strokeWidth: 2, color: s.onSurface),
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
