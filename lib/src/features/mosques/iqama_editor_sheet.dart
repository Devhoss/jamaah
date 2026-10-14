import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/time_model.dart';

/// Asks the user for a time of day, starting the dial at [initial] when given.
/// Null means they backed out.
typedef IqamaTimePicker = Future<LocalTime?> Function(
  BuildContext context,
  LocalTime? initial,
);

/// The device's own time picker, which follows the system 12/24-hour setting.
///
/// A provider so a widget test can answer it without driving the platform dial.
final iqamaTimePickerProvider = Provider<IqamaTimePicker>(
  (ref) => _materialTimePicker,
);

Future<LocalTime?> _materialTimePicker(
  BuildContext context,
  LocalTime? initial,
) async {
  // With nothing to start from the dial opens at the current time. Either way it
  // is where a picker starts, not a value: nothing is stored until the user
  // confirms a time.
  final picked = await showTimePicker(
    context: context,
    initialTime: initial == null
        ? TimeOfDay.now()
        : TimeOfDay(hour: initial.hour, minute: initial.minute),
  );
  return picked == null ? null : LocalTime.of(picked.hour, picked.minute);
}

/// Opens the editor for one prayer of one mosque.
Future<void> showIqamaEditor(
  BuildContext context, {
  required Mosque mosque,
  required Prayer prayer,
  required PrayerIqama current,
  LocalTime? adhan,
  LocalTime? adhanTomorrow,
  int? nowMinutes,
  bool jumuah = false,
}) {
  assert(prayer.canHaveIqama, 'Sunrise has no Iqama (AGENTS.md)');
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => IqamaEditorSheet(
      mosque: mosque,
      prayer: prayer,
      current: current,
      adhan: adhan,
      adhanTomorrow: adhanTomorrow,
      nowMinutes: nowMinutes,
      jumuah: jumuah,
    ),
  );
}

/// The editor itself: one prayer, one mosque, named at the top so the user always
/// knows which schedule they are changing.
///
/// Nothing is written until Save. Cancel, the scrim and the back gesture all
/// discard; Clear returns the prayer to "Not configured".
class IqamaEditorSheet extends ConsumerStatefulWidget {
  const IqamaEditorSheet({
    required this.mosque,
    required this.prayer,
    required this.current,
    this.adhan,
    this.adhanTomorrow,
    this.nowMinutes,
    this.jumuah = false,
    super.key,
  });

  final Mosque mosque;
  final Prayer prayer;
  final PrayerIqama current;

  /// The day's Adhan time for [prayer], when there is a place to read it from.
  ///
  /// Only ever the picker's starting point for an Iqama not entered yet, so the
  /// user nudges minutes instead of scrolling from the current time. It is never
  /// shown as the Iqama and never saved without the user confirming a time
  /// (AGENTS.md: Iqama is never derived from Adhan).
  final LocalTime? adhan;

  /// Tomorrow's Adhan and the place's time now, so the preview of "minutes
  /// after the Adhan" names the next Iqama, today's or tomorrow's.
  final LocalTime? adhanTomorrow;
  final int? nowMinutes;

  /// Editing the mosque's Jumu'ah (2026-10-14): [prayer] is Dhuhr, and the
  /// time is saved as Jumu'ah's, never Dhuhr's.
  final bool jumuah;

  @override
  ConsumerState<IqamaEditorSheet> createState() => _IqamaEditorSheetState();
}

/// How the Iqama is entered: as the mosque publishes it, minutes after the
/// Adhan (the default for a new entry), or as a fixed time (2026-10-14).
enum _Mode { afterAdhan, fixed }

class _IqamaEditorSheetState extends ConsumerState<IqamaEditorSheet> {
  late LocalTime? _time = widget.current.iqama;
  late _Mode _mode = widget.current.iqama != null ? _Mode.fixed : _Mode.afterAdhan;
  late final _afterField = TextEditingController(
    text: widget.current.afterAdhanMinutes?.toString() ?? '',
  );
  late bool _reminderOn = widget.current.hasReminder;
  late int _presetMinutes = widget.current.reminderMinutesBefore;
  late bool _custom = !ReminderInterval.presets.contains(
    widget.current.reminderMinutesBefore,
  );
  late final _customField = TextEditingController(
    text: _custom ? '${widget.current.reminderMinutesBefore}' : '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _customField.dispose();
    _afterField.dispose();
    super.dispose();
  }

  /// The minutes typed, or null while they are not a whole number in range.
  int? get _afterMinutes {
    final n = int.tryParse(_afterField.text.trim());
    return n != null && n >= kMinAfterAdhanMinutes && n <= kMaxAfterAdhanMinutes
        ? n
        : null;
  }

  /// Something to save: a picked time, or valid minutes.
  bool get _hasEntry =>
      _mode == _Mode.fixed ? _time != null : _afterMinutes != null;

  /// The next Iqama the minutes give: today's while it is still ahead,
  /// otherwise tomorrow's (null without an Adhan to count from).
  ({LocalTime adhan, LocalTime iqama, bool tomorrow})? get _next =>
      switch (_afterMinutes) {
        final after? => nextIqamaAfterAdhan(
          minutes: after,
          nowMinutes: widget.nowMinutes ?? 0,
          adhanToday: widget.adhan?.minutes,
          adhanTomorrow: widget.adhanTomorrow?.minutes,
        ),
        null => null,
      };

  /// The Iqama for the summary: the picked time, or the next one the minutes
  /// give.
  LocalTime? get _iqamaToday => switch (_mode) {
    _Mode.fixed => _time,
    _Mode.afterAdhan => _next?.iqama,
  };

  ReminderMinutesInput get _customInput =>
      ReminderInterval.parseCustom(_customField.text);

  /// The interval the summary and Save use, or null while Custom is invalid.
  int? get _minutes {
    if (!_custom) return _presetMinutes;
    final input = _customInput;
    return input is ReminderMinutesValid ? input.minutes : null;
  }

  bool get _canSave =>
      !_saving && _hasEntry && (!_reminderOn || _minutes != null);

  Future<void> _pickTime() async {
    final picked = await ref.read(iqamaTimePickerProvider)(
      context,
      _time ?? widget.adhan,
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repository = ref.read(mosqueRepositoryProvider);
    // A reminder that is off keeps the last interval the user chose, so
    // switching it back on later does not reset their choice.
    final minutes = _minutes ?? widget.current.reminderMinutesBefore;
    final fixed = _mode == _Mode.fixed ? _time : null;
    final after = _mode == _Mode.afterAdhan ? _afterMinutes : null;
    if (widget.jumuah) {
      await repository.setJumuah(
        widget.mosque.id,
        fixed,
        afterAdhanMinutes: after,
        reminderEnabled: _reminderOn,
        reminderMinutesBefore: minutes,
      );
      if (_reminderOn) await ref.read(notificationPermissionRequestProvider)();
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await repository
        .setIqama(
          widget.mosque.id,
          widget.prayer,
          fixed,
          afterAdhanMinutes: after,
          reminderEnabled: _reminderOn,
          // A reminder that is off keeps the last interval the user chose, so
          // switching it back on later does not reset their choice.
          reminderMinutesBefore:
              _minutes ?? widget.current.reminderMinutesBefore,
        );
    if (_reminderOn) await ref.read(notificationPermissionRequestProvider)();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _clear() async {
    setState(() => _saving = true);
    if (widget.jumuah) {
      await ref
          .read(mosqueRepositoryProvider)
          .setJumuah(
            widget.mosque.id,
            null,
            reminderMinutesBefore: widget.current.reminderMinutesBefore,
          );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    await ref
        .read(mosqueRepositoryProvider)
        .setIqama(
          widget.mosque.id,
          widget.prayer,
          null,
          reminderMinutesBefore: widget.current.reminderMinutesBefore,
        );
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final clock = ClockFormat.of(context);
    final prayerLabel = widget.jumuah
        ? l10n.prayerJumuah
        : prayerName(l10n, widget.prayer);

    return SafeArea(
      child: Padding(
        // Lift the sheet above the keyboard while the Custom field is focused.
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
                l10n.iqamaEditorTitle(prayerLabel),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.iqamaEditorEditing(widget.mosque.name),
                style: theme.textTheme.bodyMedium?.copyWith(color: ink.muted),
              ),
              const SizedBox(height: AppSpace.lg),
              SegmentedButton<_Mode>(
                segments: [
                  ButtonSegment(
                    value: _Mode.afterAdhan,
                    label: Text(l10n.iqamaModeAfterAdhan),
                  ),
                  ButtonSegment(
                    value: _Mode.fixed,
                    label: Text(l10n.iqamaModeFixed),
                  ),
                ],
                selected: {_mode},
                showSelectedIcon: false,
                onSelectionChanged: _saving
                    ? null
                    : (s) => setState(() => _mode = s.single),
              ),
              const SizedBox(height: AppSpace.md),
              if (_mode == _Mode.fixed)
                _TimeField(
                  label: l10n.iqamaTimeLabel,
                  value: _time == null ? null : clock.time(_time!),
                  placeholder: widget.adhan == null
                      ? l10n.iqamaChooseTime
                      : l10n.iqamaStartsAtAdhan(clock.time(widget.adhan!)),
                  onTap: _saving ? null : _pickTime,
                )
              else ...[
                TextField(
                  controller: _afterField,
                  autofocus: _afterField.text.isEmpty,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.iqamaMinutesLabel,
                    errorText:
                        _afterField.text.isNotEmpty && _afterMinutes == null
                        ? l10n.iqamaMinutesInvalid
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpace.xs),
                Text(
                  switch ((_next, _afterMinutes)) {
                    (final next?, final after?) => next.tomorrow
                        ? l10n.iqamaAfterAdhanPreviewTomorrow(
                            clock.time(next.adhan),
                            after,
                            clock.time(next.iqama),
                          )
                        : l10n.iqamaAfterAdhanPreview(
                            clock.time(next.adhan),
                            after,
                            clock.time(next.iqama),
                          ),
                    _ when widget.adhan == null => l10n.iqamaNeedsAdhan,
                    _ => '',
                  },
                  style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
                ),
              ],
              const SizedBox(height: AppSpace.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.remindMeBefore),
                subtitle: !_hasEntry ? Text(l10n.reminderNeedsTime) : null,
                value: _hasEntry && _reminderOn,
                // A reminder can only exist alongside an Iqama time (AGENTS.md).
                onChanged: !_hasEntry || _saving
                    ? null
                    : (on) => setState(() => _reminderOn = on),
              ),
              if (_hasEntry && _reminderOn) ...[
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    for (final minutes in ReminderInterval.presets)
                      ChoiceChip(
                        label: Text(l10n.reminderMinutesChip(minutes)),
                        selected: !_custom && _presetMinutes == minutes,
                        onSelected: (_) => setState(() {
                          _custom = false;
                          _presetMinutes = minutes;
                        }),
                      ),
                    ChoiceChip(
                      label: Text(l10n.reminderCustom),
                      selected: _custom,
                      onSelected: (_) => setState(() => _custom = true),
                    ),
                  ],
                ),
                if (_custom) ...[
                  const SizedBox(height: AppSpace.md),
                  TextField(
                    controller: _customField,
                    autofocus: _customField.text.isEmpty,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.reminderCustomLabel,
                      errorText: _customError(l10n),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ],
              ],
              const SizedBox(height: AppSpace.lg),
              _Summary(text: _summary(l10n, clock, prayerLabel), ink: ink),
              const SizedBox(height: AppSpace.lg),
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
              if (widget.current.isConfigured) ...[
                const SizedBox(height: AppSpace.sm),
                TextButton(
                  onPressed: _saving ? null : _clear,
                  child: Text(l10n.clearIqamaTime),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Shown only once the user has typed something, so an empty field that has just
  /// appeared is not already an error.
  String? _customError(AppLocalizations l10n) {
    if (_customField.text.isEmpty) return null;
    return switch (_customInput) {
      ReminderMinutesValid() => null,
      ReminderMinutesEmpty() => l10n.reminderCustomEmpty,
      ReminderMinutesNotWhole() => l10n.reminderCustomNotWhole,
      ReminderMinutesOutOfRange() => l10n.reminderCustomOutOfRange,
    };
  }

  String _summary(AppLocalizations l10n, ClockFormat clock, String prayer) {
    final time = _iqamaToday;
    if (time == null) {
      return _hasEntry ? l10n.iqamaNeedsAdhan : l10n.summaryNoTime;
    }
    final minutes = _minutes;
    if (_reminderOn && minutes == null) {
      // Custom is open but not valid yet: say what the field needs instead of a
      // reminder time worked out from a number the user has not finished typing.
      return l10n.reminderCustomEmpty;
    }
    final summary = IqamaSummary.of(
      prayer: widget.prayer,
      iqama: time,
      reminderEnabled: _reminderOn,
      reminderMinutesBefore: minutes ?? widget.current.reminderMinutesBefore,
    );
    final at = summary.reminderAt;
    if (at == null) return l10n.summaryReminderOff(prayer, clock.time(time));
    return summary.reminderIsPreviousDay
        ? l10n.summaryReminderBeforeMidnight(
            prayer,
            clock.time(time),
            clock.time(at),
          )
        : l10n.summaryReminderAt(prayer, clock.time(time), clock.time(at));
  }
}

/// The prototype's large time input: one tap opens the device's picker.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    return Semantics(
      button: true,
      label: label,
      value: value ?? placeholder,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpace.touchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.md,
          ),
          decoration: BoxDecoration(
            border: Border.all(color: theme.dividerColor),
            borderRadius: BorderRadius.circular(AppRadius.input),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
                  style: value == null
                      ? theme.textTheme.bodyLarge?.copyWith(color: ink.muted)
                      : theme.textTheme.headlineMedium?.copyWith(
                          fontSize: AppType.timeInputSize,
                          fontWeight: FontWeight.w600,
                        ),
                ),
              ),
              Icon(Icons.schedule, color: ink.muted),
            ],
          ),
        ),
      ),
    );
  }
}

/// The live line under the controls, in the prototype's sage summary box.
class _Summary extends StatelessWidget {
  const _Summary({required this.text, required this.ink});

  final String text;
  final AppInk ink;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: ink.sage,
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }
}
