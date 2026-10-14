import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/time_model.dart';

/// Opens the sheet for entering all five Iqama times at once, as minutes after
/// the Adhan, the way Kuwaiti mosques publish them (2026-10-14).
Future<void> showEnterAllFive(
  BuildContext context, {
  required Mosque mosque,
  required Schedule? schedule,
  required Map<Prayer, int> adhanToday,
  Map<Prayer, int> adhanTomorrow = const {},
  int nowMinutes = 0,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => EnterAllFiveSheet(
    mosque: mosque,
    schedule: schedule,
    adhanToday: adhanToday,
    adhanTomorrow: adhanTomorrow,
    nowMinutes: nowMinutes,
  ),
);

/// Five number fields, Fajr to Isha, each with today's Adhan and the Iqama it
/// gives. Save stores the filled ones; an empty field leaves its prayer as it
/// is (clearing is done in that prayer's own editor).
class EnterAllFiveSheet extends ConsumerStatefulWidget {
  const EnterAllFiveSheet({
    required this.mosque,
    required this.schedule,
    required this.adhanToday,
    this.adhanTomorrow = const {},
    this.nowMinutes = 0,
    super.key,
  });

  final Mosque mosque;
  final Schedule? schedule;

  /// Today's Adhan times at the current place; empty without a place.
  final Map<Prayer, int> adhanToday;

  /// Tomorrow's Adhan times and the place's time now, so each line names the
  /// next Iqama, today's or tomorrow's.
  final Map<Prayer, int> adhanTomorrow;
  final int nowMinutes;

  @override
  ConsumerState<EnterAllFiveSheet> createState() => _EnterAllFiveSheetState();
}

class _EnterAllFiveSheetState extends ConsumerState<EnterAllFiveSheet> {
  late final _fields = {
    for (final p in Prayer.iqamaPrayers)
      p: TextEditingController(
        text: widget.schedule?.iqamaFor(p).afterAdhanMinutes?.toString() ?? '',
      ),
  };
  bool _saving = false;

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  int? _valueOf(Prayer p) => int.tryParse(_fields[p]!.text.trim());

  ({LocalTime adhan, LocalTime iqama, bool tomorrow})? _next(Prayer p) {
    final n = _valueOf(p);
    if (n == null || !_valid(p)) return null;
    return nextIqamaAfterAdhan(
      minutes: n,
      nowMinutes: widget.nowMinutes,
      adhanToday: widget.adhanToday[p],
      adhanTomorrow: widget.adhanTomorrow[p],
    );
  }

  bool _valid(Prayer p) {
    final text = _fields[p]!.text.trim();
    if (text.isEmpty) return true;
    final n = int.tryParse(text);
    return n != null &&
        n >= kMinAfterAdhanMinutes &&
        n <= kMaxAfterAdhanMinutes;
  }

  bool get _canSave =>
      !_saving &&
      Prayer.iqamaPrayers.every(_valid) &&
      Prayer.iqamaPrayers.any((p) => _fields[p]!.text.trim().isNotEmpty);

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(mosqueRepositoryProvider).setAfterAdhanForAll(
      widget.mosque.id,
      {
        for (final p in Prayer.iqamaPrayers) p: ?_valueOf(p),
      },
    );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final clock = ClockFormat.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            0,
            AppSpace.xxl,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.enterAllFiveTitle,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.enterAllFiveHint,
                style: theme.textTheme.bodyMedium?.copyWith(color: ink.muted),
              ),
              const SizedBox(height: AppSpace.lg),
              for (final p in Prayer.iqamaPrayers) ...[
                _Field(
                  name: prayerName(l10n, p),
                  controller: _fields[p]!,
                  error: _valid(p) ? null : l10n.iqamaMinutesInvalid,
                  result: switch ((widget.adhanToday[p], _next(p))) {
                    (_, (:final adhan, :final iqama, :final tomorrow)?) =>
                      (tomorrow
                      ? l10n.iqamaAfterAdhanPreviewTomorrow
                      : l10n.iqamaAfterAdhanPreview)(
                        clock.time(adhan),
                        _valueOf(p)!,
                        clock.time(iqama),
                      ),
                    (final adhan?, _) => l10n.rowAdhanTime(
                      clock.time(LocalTime(adhan)),
                    ),
                    _ => null,
                  },
                  onChanged: () => setState(() {}),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSave ? _save : null,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.name,
    required this.controller,
    required this.error,
    required this.result,
    required this.onChanged,
  });

  final String name;
  final TextEditingController controller;
  final String? error;
  final String? result;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    decoration: InputDecoration(
      labelText: name,
      errorText: error,
      helperText: error == null ? result : null,
    ),
    onChanged: (_) => onChanged(),
  );
}
