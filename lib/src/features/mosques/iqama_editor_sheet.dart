import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/time_model.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';

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
  final s = HorizonTheme.of(context).surfaces;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: s.surface,
    barrierColor: s.scrim,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(HorizonShape.sheetRadius),
      ),
    ),
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

  /// The fixed-time field, which opens the picker.
  static const timeFieldKey = ValueKey('iqama-time-field');

  @override
  ConsumerState<IqamaEditorSheet> createState() => _IqamaEditorSheetState();
}

/// How the Iqama is entered: as the mosque publishes it, minutes after the
/// Adhan (the default for a new entry), or as a fixed time (2026-10-14).
enum _Mode { afterAdhan, fixed, followDhuhr }

class _IqamaEditorSheetState extends ConsumerState<IqamaEditorSheet> {
  late LocalTime? _time = widget.current.iqama;
  late _Mode _mode = widget.jumuah
      ? (widget.current.afterAdhanMinutes == 0
            ? _Mode.followDhuhr
            : _Mode.fixed)
      : widget.current.iqama != null
      ? _Mode.fixed
      : _Mode.afterAdhan;
  late final _afterField = TextEditingController(
    text: widget.current.afterAdhanMinutes?.toString() ?? '',
  );
  // A prayer set for the first time starts with its reminder on, at the
  // stored interval (10 min unless changed): spec §4.5. One already set keeps
  // what the user chose.
  late bool _reminderOn =
      widget.jumuah ||
      (widget.current.isConfigured ? widget.current.hasReminder : true);
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
  bool get _hasEntry => widget.jumuah
      ? (_mode == _Mode.followDhuhr || _time != null)
      : _mode == _Mode.fixed
      ? _time != null
      : _afterMinutes != null;

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
    _Mode.followDhuhr => widget.adhan,
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
      // The day's Dhuhr Adhan is only a starting point for a new Jumu'ah
      // Khutbah time. It is not saved unless the user confirms the picker.
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
        followsDhuhrAdhan: _mode == _Mode.followDhuhr,
        reminderMinutesBefore: minutes,
      );
      await ref.read(notificationPermissionRequestProvider)();
      _done();
      return;
    }
    await repository.setIqama(
      widget.mosque.id,
      widget.prayer,
      fixed,
      afterAdhanMinutes: after,
      reminderEnabled: _reminderOn,
      // A reminder that is off keeps the last interval the user chose, so
      // switching it back on later does not reset their choice.
      reminderMinutesBefore: _minutes ?? widget.current.reminderMinutesBefore,
    );
    if (_reminderOn) await ref.read(notificationPermissionRequestProvider)();
    _done();
  }

  /// Closes the sheet and says what was saved.
  void _done() {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context);
    showHorizonSnackBar(
      context,
      widget.jumuah
          ? l10n.jumuahSaved
          : l10n.iqamaSaved(prayerName(l10n, widget.prayer)),
    );
    Navigator.of(context).pop();
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
    final clock = ClockFormat.of(context);
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final prayerLabel = widget.jumuah
        ? l10n.prayerJumuah
        : prayerName(l10n, widget.prayer);
    final muted = type.meta.copyWith(color: s.onSurfaceMuted, height: 1.45);
    final adhan = widget.adhan;
    final sub = widget.jumuah
        ? l10n.iqamaEditorSubFriday(widget.mosque.name)
        : adhan == null
        ? l10n.iqamaEditorEditing(widget.mosque.name)
        : l10n.iqamaEditorSub(widget.mosque.name, clock.time(adhan));

    return SafeArea(
      child: Padding(
        // Lift the sheet above the keyboard while a number is being typed.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  widget.jumuah
                      ? l10n.jumuahEditorTitle
                      : l10n.iqamaEditorTitle(prayerLabel),
                  style: type.prayerName.copyWith(color: s.onSurface),
                ),
              ),
              const SizedBox(height: 2),
              Text(sub, style: type.body.copyWith(color: s.onSurfaceMuted)),
              const SizedBox(height: 16),
              if (widget.jumuah || _mode != _Mode.followDhuhr)
                Segmented<_Mode>(
                  options: widget.jumuah
                      ? [
                          SegmentOption(
                            _Mode.followDhuhr,
                            l10n.jumuahFollowDhuhr,
                            description: l10n.jumuahFollowDhuhrDescription,
                          ),
                          SegmentOption(
                            _Mode.fixed,
                            l10n.iqamaModeFixed,
                            description: l10n.jumuahFixedModeDescription,
                          ),
                        ]
                      : [
                          SegmentOption(
                            _Mode.afterAdhan,
                            l10n.iqamaModeAfterAdhan,
                            description: l10n.iqamaModeAfterDesc,
                          ),
                          SegmentOption(
                            _Mode.fixed,
                            l10n.iqamaModeFixed,
                            description: l10n.iqamaModeFixedDesc,
                          ),
                        ],
                  selected: _mode,
                  onChanged: _saving ? null : (m) => setState(() => _mode = m),
                ),
              const SizedBox(height: 18),
              if (_mode == _Mode.fixed)
                ..._fixedInputs(l10n, clock, s, type, muted)
              else if (!widget.jumuah)
                ..._minutesInputs(l10n, clock, s, type, muted),
              if (widget.jumuah && _mode == _Mode.followDhuhr)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    widget.adhan == null
                        ? l10n.iqamaNeedsAdhan
                        : l10n.jumuahFollowDhuhrPreview(
                            clock.time(widget.adhan!),
                          ),
                    style: muted,
                  ),
                ),
              if (widget.jumuah) ...[
                const SizedBox(height: 18),
                Text(
                  l10n.jumuahArrivalLeadTitle,
                  style: type.row.copyWith(color: s.onSurface),
                ),
                const SizedBox(height: 8),
                _leadMinutesInputs(l10n),
              ],
              const SizedBox(height: 18),
              Divider(color: s.divider, height: 1),
              const SizedBox(height: 10),
              if (!widget.jumuah) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.iqamaReminderTitle,
                            style: type.row.copyWith(color: s.onSurface),
                          ),
                          Text(
                            _hasEntry
                                ? l10n.iqamaReminderHint
                                : l10n.reminderNeedsTime,
                            style: type.meta.copyWith(color: s.onSurfaceMuted),
                          ),
                        ],
                      ),
                    ),
                    AppSwitch(
                      value: _hasEntry && _reminderOn,
                      // A reminder can only exist alongside an Iqama time
                      // (AGENTS.md).
                      onChanged: !_hasEntry || _saving
                          ? null
                          : (on) => setState(() => _reminderOn = on),
                      semanticLabel: _hasEntry
                          ? l10n.iqamaReminderTitle
                          : l10n.reminderSwitchNeedsIqama(prayerLabel),
                    ),
                  ],
                ),
                if (_hasEntry && _reminderOn) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final minutes in ReminderInterval.presets)
                        _Chip(
                          label: l10n.reminderMinutesChip(minutes),
                          selected: !_custom && _presetMinutes == minutes,
                          onTap: () => setState(() {
                            _custom = false;
                            _presetMinutes = minutes;
                          }),
                        ),
                      _Chip(
                        label: l10n.reminderCustom,
                        selected: _custom,
                        onTap: () => setState(() => _custom = true),
                      ),
                    ],
                  ),
                  if (_custom) ...[
                    const SizedBox(height: 12),
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
              ],
              const SizedBox(height: 14),
              Semantics(
                liveRegion: true,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.well,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    _summary(l10n, clock, prayerLabel),
                    style: type.body.copyWith(fontSize: 14, color: s.onSurface),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: l10n.cancel,
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SheetButton(
                      label: l10n.save,
                      filled: true,
                      onPressed: _canSave ? _save : null,
                    ),
                  ),
                ],
              ),
              if (widget.current.isConfigured) ...[
                const SizedBox(height: 6),
                Center(
                  child: PillButton(
                    label: l10n.clearThisIqama,
                    ink: s.danger,
                    onInk: s.surface,
                    line: s.divider,
                    danger: s.danger,
                    onPressed: _saving ? null : _clear,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// "Minutes after Adhan": a big number with − and +, quick chips, and what
  /// it means today. Empty shows "—" until the user chooses.
  List<Widget> _minutesInputs(
    AppLocalizations l10n,
    ClockFormat clock,
    HorizonSurfaces s,
    HorizonType type,
    TextStyle muted,
  ) {
    void step(int by) {
      final now = _afterMinutes ?? (by > 0 ? 9 : 11);
      final next = (now + by).clamp(
        kMinAfterAdhanMinutes,
        kMaxAfterAdhanMinutes,
      );
      setState(() => _afterField.text = '$next');
    }

    final preview = switch ((_next, _afterMinutes)) {
      (final next?, final after?) =>
        widget.jumuah
            ? null
            : next.tomorrow
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
      (_, null) => l10n.iqamaMinutesEmpty,
      _ when widget.adhan == null => l10n.iqamaNeedsAdhan,
      _ => null,
    };

    return [
      Row(
        children: [
          _RoundStep(
            icon: LineIcons.minus,
            label: l10n.iqamaFewerMinutes,
            onTap: _saving ? null : () => step(-1),
          ),
          Expanded(
            child: TextField(
              controller: _afterField,
              autofocus: false,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: type.display.copyWith(
                fontSize: 44,
                color: s.onSurface,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
              decoration: InputDecoration(
                labelText: l10n.iqamaMinutesLabel,
                floatingLabelAlignment: FloatingLabelAlignment.center,
                hintText: '—',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorText: _afterField.text.isNotEmpty && _afterMinutes == null
                    ? l10n.iqamaMinutesInvalid
                    : null,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _RoundStep(
            icon: LineIcons.plus,
            label: l10n.iqamaMoreMinutes,
            onTap: _saving ? null : () => step(1),
          ),
        ],
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.center,
        children: [
          for (final n in const [5, 10, 15, 20, 25, 30])
            _Chip(
              label: l10n.reminderMinutesChip(n),
              selected: _afterMinutes == n,
              onTap: _saving
                  ? null
                  : () => setState(() => _afterField.text = '$n'),
            ),
        ],
      ),
      if (preview != null) ...[
        const SizedBox(height: 10),
        Text(preview, style: muted),
      ],
    ];
  }

  Widget _leadMinutesInputs(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final minutes in ReminderInterval.presets)
            _Chip(
              label: l10n.reminderMinutesChip(minutes),
              selected: !_custom && _presetMinutes == minutes,
              onTap: _saving
                  ? null
                  : () => setState(() {
                      _custom = false;
                      _presetMinutes = minutes;
                    }),
            ),
          _Chip(
            label: l10n.reminderCustom,
            selected: _custom,
            onTap: _saving ? null : () => setState(() => _custom = true),
          ),
        ],
      ),
      if (_custom) ...[
        const SizedBox(height: 12),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _customField,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: l10n.jumuahArrivalLeadTitle,
              errorText: _customError(l10n),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ),
      ],
    ],
  );

  /// "Fixed time": empty, a dashed button that opens the picker at the Adhan
  /// (nothing saved until a time is chosen); set, the time with steppers.
  List<Widget> _fixedInputs(
    AppLocalizations l10n,
    ClockFormat clock,
    HorizonSurfaces s,
    HorizonType type,
    TextStyle muted,
  ) {
    final time = _time;
    final adhan = widget.adhan;
    void nudge(int by) => setState(() => _time = _time!.plusMinutes(by));

    return [
      _TimeField(
        key: IqamaEditorSheet.timeFieldKey,
        label: widget.jumuah ? l10n.jumuahKhutbahTime : l10n.iqamaTimeLabel,
        value: time == null ? null : clock.time(time),
        placeholder: widget.jumuah
            ? l10n.jumuahChooseKhutbahTime
            : adhan == null
            ? l10n.iqamaChooseTime
            : l10n.iqamaStartsAtAdhan(clock.time(adhan)),
        onTap: _saving ? null : _pickTime,
      ),
      if (time != null) ...[
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: [
            for (final by in const [-5, -1, 1, 5])
              Semantics(
                label: by < 0 ? l10n.iqamaEarlier(-by) : l10n.iqamaLater(by),
                excludeSemantics: true,
                child: _Chip(
                  label: by < 0 ? '−${-by}' : '+$by',
                  selected: false,
                  onTap: _saving ? null : () => nudge(by),
                ),
              ),
          ],
        ),
      ],
      const SizedBox(height: 10),
      Text(
        widget.jumuah
            ? l10n.jumuahKhutbahTimeNote
            : time == null
            ? l10n.iqamaFixedEmptyNote
            : l10n.iqamaFixedNote,
        style: muted,
      ),
    ];
  }

  /// Shown only once the user has typed something, so an empty field that has just
  /// appeared is not already an error.
  String? _customError(AppLocalizations l10n) {
    if (_customField.text.isEmpty) return null;
    return switch (_customInput) {
      ReminderMinutesValid() => null,
      ReminderMinutesEmpty() =>
        widget.jumuah
            ? l10n.jumuahReminderCustomEmpty
            : l10n.reminderCustomEmpty,
      ReminderMinutesNotWhole() => l10n.reminderCustomNotWhole,
      ReminderMinutesOutOfRange() => l10n.reminderCustomOutOfRange,
    };
  }

  String _summary(AppLocalizations l10n, ClockFormat clock, String prayer) {
    final time = _iqamaToday;
    if (widget.jumuah) {
      if (time == null) return l10n.summaryNoTime;
      final minutes = _minutes;
      if (minutes == null) return l10n.jumuahReminderCustomEmpty;
      return l10n.jumuahReminderPreview(
        clock.time(time),
        minutes,
        clock.time(time.plusMinutes(-minutes)),
      );
    }
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

/// The time of a fixed Iqama: one tap opens the device's picker. Empty, it is
/// a dashed button that names the Adhan it will start at.
class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.onTap,
    super.key,
  });

  final String label;
  final String? value;
  final String placeholder;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final empty = value == null;
    final field = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: empty
          ? null
          : BoxDecoration(
              color: s.well,
              borderRadius: BorderRadius.circular(14),
            ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              value ?? placeholder,
              textAlign: empty ? TextAlign.start : TextAlign.center,
              style: empty
                  ? type.row.copyWith(
                      fontWeight: FontWeight.w500,
                      color: s.onSurface,
                    )
                  : type.display.copyWith(
                      fontSize: 34,
                      color: s.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
            ),
          ),
          LineIcon(LineIcons.clock, size: 20, color: s.onSurfaceMuted),
        ],
      ),
    );
    return Semantics(
      button: true,
      label: label,
      value: value ?? placeholder,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: empty
            ? CustomPaint(
                painter: DashedOutline(color: s.onSurfaceMuted, radius: 14),
                child: field,
              )
            : field,
      ),
    );
  }
}

/// A choice chip on the surface: `accent` when selected, outlined otherwise.
class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? s.accent : Colors.transparent,
        shape: StadiumBorder(
          side: selected ? BorderSide.none : BorderSide(color: s.divider),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: type.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? s.onAccent : s.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// − or + beside the minutes.
class _RoundStep extends StatelessWidget {
  const _RoundStep({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final LineIconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: CircleBorder(side: BorderSide(color: s.divider, width: 1.5)),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox.square(
            dimension: 52,
            child: Center(
              child: LineIcon(
                icon,
                size: 22,
                strokeWidth: 2,
                color: s.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cancel and Save: 52 tall, rounded 14. Save waits for a value.
class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final enabled = onPressed != null;
    final bg = filled ? (enabled ? s.accent : s.well) : Colors.transparent;
    final fg = filled ? (enabled ? s.onAccent : s.onSurfaceMuted) : s.onSurface;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
      side: filled ? BorderSide.none : BorderSide(color: s.divider, width: 1.5),
    );
    return SizedBox(
      height: 52,
      child: filled
          ? FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                disabledBackgroundColor: s.well,
                disabledForegroundColor: s.onSurfaceMuted,
                shape: shape,
                textStyle: type.row.copyWith(fontWeight: FontWeight.w500),
              ),
              child: Text(label),
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                backgroundColor: bg,
                foregroundColor: fg,
                side: BorderSide(color: s.divider, width: 1.5),
                shape: shape,
                textStyle: type.row.copyWith(fontWeight: FontWeight.w500),
              ),
              child: Text(label),
            ),
    );
  }
}
