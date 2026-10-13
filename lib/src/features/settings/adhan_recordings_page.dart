import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/audio_preview.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_recordings.dart';
import '../components/app_widgets.dart';
import 'settings_page.dart';

Future<void> openAdhanRecordings(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const AdhanRecordingsPage()));

/// Chooses the recording "Full Adhan" plays, each one playable here first.
/// Choosing saves at once; the scheduler hands the new recording to every
/// Adhan the app will play.
class AdhanRecordingsPage extends ConsumerStatefulWidget {
  const AdhanRecordingsPage({super.key});

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

  Future<void> _toggle(AdhanRecording recording) async {
    if (_playing == recording.id) {
      await _preview.stop();
      if (mounted) setState(() => _playing = null);
      return;
    }
    setState(() => _playing = recording.id);
    unawaited(
      _preview.play(recording.asset).whenComplete(() {
        if (mounted && _playing == recording.id) {
          setState(() => _playing = null);
        }
      }),
    );
  }

  Future<void> _choose(String id) =>
      updateAdhanAlerts(ref, (all) => all.copyWith(fullRecording: id));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chosen =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .adhanAlerts
            .fullRecording;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recordingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(
            l10n.recordingsBody,
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
            child: AppRows(
              children: [
                for (final r in adhanRecordings)
                  RadioListTile<String>(
                    value: r.id,
                    title: Text(r.name),
                    subtitle: Text(_length(r.seconds)),
                    secondary: IconButton(
                      icon: Icon(
                        _playing == r.id
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outline,
                      ),
                      tooltip: _playing == r.id
                          ? l10n.recordingStopLabel(r.name)
                          : l10n.recordingPlayLabel(r.name),
                      onPressed: () => _toggle(r),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// "3:25": minutes and seconds, the way every player shows a length.
String _length(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
