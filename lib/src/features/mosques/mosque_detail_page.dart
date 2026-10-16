import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/time_model.dart';
import '../../domain/today.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';
import '../sky/sky_page.dart';
import '../sky/sky_palette.dart';
import '../today/today_text.dart';
import 'enter_all_five_sheet.dart';
import 'iqama_editor_sheet.dart';
import 'mosque_copy.dart';
import 'mosque_details_sheet.dart';

/// Opens one saved mosque on top of the tabs.
Future<void> openMosqueDetail(BuildContext context, String mosqueId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MosqueDetailPage(mosqueId: mosqueId),
      ),
    );

/// One mosque and its Iqama schedule (Horizon spec §4.4): the only place
/// Iqama times are edited (AGENTS.md: never in general Settings).
class MosqueDetailPage extends ConsumerWidget {
  const MosqueDetailPage({required this.mosqueId, super.key});

  final String mosqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mosque = ref.watch(mosqueByIdProvider(mosqueId));

    if (mosque == null) {
      // Still loading, or just removed and on its way out.
      return const Scaffold();
    }

    final settings = ref.watch(appSettingsProvider).value;
    final isActive = settings?.activeMosqueId == mosque.id;
    final pausedForAll = settings?.travel.pauseAllIqamaReminders ?? false;
    final day = ref.watch(scheduleDayProvider);
    final schedule = mosque.scheduleFor(day);
    final today = ref.watch(todayProvider);
    final calculator = ref.watch(prayerTimesCalculatorProvider);
    // Tomorrow's Adhan and the time now, for "minutes after the Adhan"
    // previews that name the next Iqama.
    final tomorrowTimes = today == null
        ? const <Prayer, int>{}
        : calculator?.forDay(today.day.day.addDays(1)).times ??
              const <Prayer, int>{};
    final nowMinutes = today?.moment.minutesOfDay;
    final clock = ClockFormat.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final next = today == null
        ? null
        : readNextIqama(
            mosque: mosque,
            today: today,
            adhanTimesOn: (d) => calculator?.forDay(d).times ?? const {},
          );
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final paused = mosque.remindersPaused || pausedForAll;

    return Scaffold(
      body: SkyPage(
        header: (context, p) => _Header(
          mosque: mosque,
          palette: p,
          isActive: isActive,
          count: iqamaCountLine(l10n, schedule),
          next: switch (next) {
            final IqamaUpcoming n => l10n.mosqueNextJamaah(
              n.isJumuah ? l10n.prayerJumuah : prayerName(l10n, n.prayer),
              clock.time(n.at),
              relativeText(l10n, n.minutesUntil),
            ),
            IqamaNoneLeftToday() => l10n.mosqueNoNextJamaah,
            _ => null,
          },
          onMakeActive: () =>
              ref.read(settingsRepositoryProvider).setActiveMosqueId(mosque.id),
        ),
        panel: [
          _PauseRow(
            mosque: mosque,
            pausedForAll: pausedForAll,
            onChanged: (on) => ref
                .read(mosqueRepositoryProvider)
                .setRemindersPaused(mosque.id, paused: on),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 4),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.scheduleSection,
                    style: type.section.copyWith(color: s.onSurface),
                  ),
                ),
                Text(
                  l10n.scheduleTapHint,
                  style: type.meta.copyWith(
                    fontSize: 12,
                    color: s.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          for (final prayer in Prayer.iqamaPrayers)
            _IqamaRow(
              mosque: mosque,
              prayer: prayer,
              entry: schedule?.iqamaFor(prayer) ?? PrayerIqama(prayer: prayer),
              adhan: today?.day.timeOf(prayer),
              adhanTomorrow: tomorrowTimes[prayer],
              nowMinutes: nowMinutes,
              clock: clock,
              paused: paused,
            ),
          // Jumu'ah (2026-10-14): its own time, used on Fridays.
          _IqamaRow(
            mosque: mosque,
            prayer: Prayer.dhuhr,
            entry: schedule?.jumuah ?? const PrayerIqama(prayer: Prayer.dhuhr),
            adhan: today?.day.timeOf(Prayer.dhuhr),
            adhanTomorrow: tomorrowTimes[Prayer.dhuhr],
            nowMinutes: nowMinutes,
            clock: clock,
            paused: paused,
            jumuah: true,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PillButton(
              label: l10n.enterAllFive,
              ink: s.onSurface,
              onInk: s.surface,
              line: s.divider,
              onPressed: () => showEnterAllFive(
                context,
                mosque: mosque,
                schedule: schedule,
                adhanToday: today?.day.times ?? const {},
                adhanTomorrow: tomorrowTimes,
                nowMinutes: nowMinutes ?? 0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            schedule != null && schedule.configuredCount > 0
                ? l10n.scheduleFooter(
                    DateLabels.shortDate(schedule.updatedAt.toLocal(), locale),
                  )
                : l10n.scheduleNothingEntered,
            style: type.meta.copyWith(height: 1.45, color: s.onSurfaceMuted),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: PillButton(
              label: l10n.removeThisMosque,
              ink: s.danger,
              onInk: s.surface,
              line: s.divider,
              danger: s.danger,
              onPressed: () => _confirmRemove(context, ref, mosque, isActive),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
    BuildContext context,
    WidgetRef ref,
    Mosque mosque,
    bool isActive,
  ) async {
    final l10n = AppLocalizations.of(context);
    final s = HorizonTheme.of(context).surfaces;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: s.surface,
        title: Text(l10n.removeMosqueTitle(mosque.name)),
        content: Text(
          isActive ? l10n.removeMosqueBodyActive : l10n.removeMosqueBody,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: s.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.remove),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    // Leave first, so the page never renders a mosque that no longer exists.
    Navigator.of(context).pop();
    await ref.read(mosqueRepositoryProvider).delete(mosque.id);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.mosque,
    required this.palette,
    required this.isActive,
    required this.count,
    required this.next,
    required this.onMakeActive,
  });

  final Mosque mosque;
  final SkyPalette palette;
  final bool isActive;
  final String count;
  final String? next;
  final VoidCallback onMakeActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 0),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: l10n.mosqueBack,
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Transform.flip(
                        // Back points the way the page came from.
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: LineIcon(LineIcons.back, size: 22, color: p.ink),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: PillButton(
                    label: l10n.editDetails,
                    ink: p.ink,
                    onInk: p.deep,
                    line: p.line,
                    onPressed: () => showEditMosqueSheet(context, mosque),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabic ? l10n.mosqueKicker : l10n.mosqueKicker.toUpperCase(),
                style: type.kicker.copyWith(color: p.mute),
              ),
              const SizedBox(height: 2),
              Semantics(
                header: true,
                child: Text(
                  mosque.name,
                  style: type.display.copyWith(fontSize: 40, color: p.ink),
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (isActive)
                    _SkyTag(label: l10n.tagActive, palette: p, filled: true)
                  else
                    PillButton(
                      label: l10n.mosqueMakeActive,
                      ink: p.ink,
                      onInk: p.deep,
                      line: p.line,
                      filled: true,
                      onPressed: onMakeActive,
                    ),
                  _SkyTag(
                    label: mosqueSourceLine(l10n, mosque.source),
                    palette: p,
                  ),
                  Text(
                    count,
                    style: type.meta.copyWith(fontSize: 12, color: p.mute),
                  ),
                ],
              ),
              if (next != null) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    LineIcon(
                      LineIcons.bell,
                      size: 16,
                      strokeWidth: 2,
                      color: p.ink,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        next!,
                        style: type.body.copyWith(fontSize: 14, color: p.ink),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SkyTag extends StatelessWidget {
  const _SkyTag({
    required this.label,
    required this.palette,
    this.filled = false,
  });

  final String label;
  final SkyPalette palette;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 26),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? palette.fill : Colors.transparent,
        borderRadius: BorderRadius.circular(13),
        border: filled ? null : Border.all(color: palette.line),
      ),
      child: Text(
        label,
        style: type.meta.copyWith(
          fontSize: 12,
          fontWeight: filled ? FontWeight.w600 : FontWeight.w400,
          color: filled ? palette.deep : palette.ink,
        ),
      ),
    );
  }
}

class _PauseRow extends StatelessWidget {
  const _PauseRow({
    required this.mosque,
    required this.pausedForAll,
    required this.onChanged,
  });

  final Mosque mosque;
  final bool pausedForAll;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.mosquePauseTitle,
                  style: type.row.copyWith(color: s.onSurface),
                ),
                const SizedBox(height: 2),
                Text(
                  pausedForAll ? l10n.mosquePauseAllOn : l10n.mosquePauseHint,
                  style: type.meta.copyWith(color: s.onSurfaceMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          AppSwitch(
            value: mosque.remindersPaused,
            onChanged: onChanged,
            semanticLabel: l10n.mosquePauseTitle,
          ),
        ],
      ),
    );
  }
}

/// One prayer of the schedule: its Adhan time small and secondary, its Iqama
/// time with how it is set, or "Not configured", and the reminder switch.
class _IqamaRow extends ConsumerWidget {
  const _IqamaRow({
    required this.mosque,
    required this.prayer,
    required this.entry,
    required this.adhan,
    this.adhanTomorrow,
    this.nowMinutes,
    required this.clock,
    required this.paused,
    this.jumuah = false,
  });

  final Mosque mosque;
  final Prayer prayer;
  final PrayerIqama entry;

  /// The Jumu'ah row: [prayer] is Dhuhr, [entry] the mosque's Jumu'ah.
  final bool jumuah;

  /// Minutes from midnight, or null when there is no place or no time today.
  final int? adhan;

  /// Tomorrow's Adhan and the place's time now, for the editor's preview.
  final int? adhanTomorrow;
  final int? nowMinutes;
  final ClockFormat clock;

  /// This mosque's reminders, or all of them, are paused.
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final name = jumuah ? l10n.prayerJumuah : prayerName(l10n, prayer);
    final small = type.meta.copyWith(fontSize: 12, color: s.onSurfaceMuted);
    final iqamaAt = entry.timeOfDay(adhan);

    void edit() => showIqamaEditor(
      context,
      mosque: mosque,
      prayer: prayer,
      current: entry,
      adhan: adhan == null ? null : LocalTime(adhan!),
      adhanTomorrow: adhanTomorrow == null ? null : LocalTime(adhanTomorrow!),
      nowMinutes: nowMinutes,
      jumuah: jumuah,
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Semantics(
              button: true,
              label: entry.isConfigured
                  ? l10n.iqamaRowSet(name)
                  : l10n.iqamaRowUnset(name),
              child: InkWell(
                onTap: edit,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: HorizonShape.twoLineRowMin + 8,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                spacing: 8,
                                crossAxisAlignment: WrapCrossAlignment.end,
                                children: [
                                  Text(
                                    name,
                                    style: type.row.copyWith(
                                      color: s.onSurface,
                                    ),
                                  ),
                                  if (jumuah)
                                    Text(l10n.jumuahRowHint, style: small)
                                  else if (adhan != null)
                                    Text(
                                      l10n.rowAdhanTime(
                                        clock.time(LocalTime(adhan!)),
                                      ),
                                      style: small,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _reminderLine(l10n),
                                style: type.meta.copyWith(
                                  color: s.onSurfaceMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (entry.isConfigured)
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Today's time: a fixed one, or the Adhan plus
                                // the user's minutes (2026-10-14).
                                if (iqamaAt != null)
                                  Text(
                                    clock.time(iqamaAt),
                                    style: type.rowTime.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: s.onSurface,
                                    ),
                                  ),
                                Text(
                                  entry.afterAdhanMinutes != null
                                      ? l10n.rowAdhanPlus(
                                          entry.afterAdhanMinutes!,
                                        )
                                      : l10n.rowFixedTime,
                                  textAlign: TextAlign.end,
                                  style: small.copyWith(fontSize: 11),
                                ),
                              ],
                            ),
                          )
                        else
                          Flexible(
                            child: NotConfiguredPill(l10n.notConfigured),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          AppSwitch(
            value: entry.hasReminder,
            // No Iqama time, no reminder (AGENTS.md); the line under the
            // name says what to do instead.
            onChanged: entry.isConfigured
                ? (on) async {
                    final repository = ref.read(mosqueRepositoryProvider);
                    if (jumuah) {
                      await repository.setJumuahReminderEnabled(
                        mosque.id,
                        enabled: on,
                      );
                    } else {
                      await repository.setReminderEnabled(
                        mosque.id,
                        prayer,
                        enabled: on,
                      );
                    }
                    if (on) {
                      await ref.read(notificationPermissionRequestProvider)();
                    }
                  }
                : null,
            semanticLabel: entry.isConfigured
                ? l10n.reminderSwitchLabel(name)
                : l10n.reminderSwitchNeedsIqama(name),
          ),
        ],
      ),
    );
  }

  String _reminderLine(AppLocalizations l10n) {
    if (!entry.isConfigured) return l10n.rowReminderNeedsIqama;
    final time = entry.timeOfDay(adhan);
    // Minutes after the Adhan with no place to read the Adhan from: the
    // reminder is set, but its time today cannot be said.
    if (time == null) {
      return entry.hasReminder
          ? l10n.reminderBeforeIqama(entry.reminderMinutesBefore)
          : l10n.rowReminderOff;
    }
    final summary = IqamaSummary.of(
      prayer: prayer,
      iqama: time,
      reminderEnabled: entry.reminderEnabled,
      reminderMinutesBefore: entry.reminderMinutesBefore,
    );
    final at = summary.reminderAt;
    if (at == null) return l10n.rowReminderOff;
    if (paused) return l10n.rowPausedReminder(clock.time(at));
    return summary.reminderIsPreviousDay
        ? l10n.rowReminderBeforeMidnight(clock.time(at))
        : l10n.rowReminderAt(clock.time(at));
  }
}
