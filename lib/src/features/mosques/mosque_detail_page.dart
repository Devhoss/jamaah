import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
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
import '../components/app_widgets.dart';
import 'iqama_editor_sheet.dart';
import 'mosque_details_sheet.dart';

/// Opens one saved mosque on top of the tabs.
Future<void> openMosqueDetail(BuildContext context, String mosqueId) =>
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MosqueDetailPage(mosqueId: mosqueId),
      ),
    );

/// One mosque and its Iqama schedule — the only place Iqama times are edited
/// (AGENTS.md: never in general Settings).
class MosqueDetailPage extends ConsumerWidget {
  const MosqueDetailPage({required this.mosqueId, super.key});

  final String mosqueId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final mosque = ref.watch(mosqueByIdProvider(mosqueId));

    if (mosque == null) {
      // Still loading, or just removed and on its way out.
      return Scaffold(appBar: AppBar());
    }

    final settings = ref.watch(appSettingsProvider).value;
    final isActive = settings?.activeMosqueId == mosque.id;
    final pausedForAll = settings?.travel.pauseAllIqamaReminders ?? false;
    final day = ref.watch(scheduleDayProvider);
    final schedule = mosque.scheduleFor(day);
    final today = ref.watch(todayProvider);
    final clock = ClockFormat.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();

    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(mosque.name, style: theme.textTheme.headlineLarge),
          const SizedBox(height: AppSpace.xs),
          Text(
            [
              if (mosque.address.isNotEmpty) mosque.address,
              _sourceLabel(l10n, mosque.source),
            ].join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.lg),
          if (isActive)
            Row(
              children: [
                AppTag(l10n.tagActive),
                const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: Text(
                    l10n.activeMosqueNote,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ink.muted,
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.md,
            runSpacing: AppSpace.sm,
            children: [
              if (!isActive)
                FilledButton(
                  onPressed: () => ref
                      .read(settingsRepositoryProvider)
                      .setActiveMosqueId(mosque.id),
                  child: Text(l10n.setAsActive),
                ),
              OutlinedButton(
                onPressed: () => showEditMosqueSheet(context, mosque),
                child: Text(l10n.editDetails),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          AppRows(
            children: [
              SwitchListTile(
                title: Text(l10n.mosquePauseReminders),
                subtitle: Text(
                  pausedForAll
                      ? l10n.mosquePauseAllOn
                      : l10n.mosquePauseRemindersHint,
                ),
                value: mosque.remindersPaused,
                onChanged: (on) => ref
                    .read(mosqueRepositoryProvider)
                    .setRemindersPaused(mosque.id, paused: on),
              ),
            ],
          ),
          AppSectionHeader(l10n.iqamaScheduleHeader(mosque.name)),
          AppRows(
            children: [
              for (final prayer in Prayer.iqamaPrayers)
                _IqamaRow(
                  mosque: mosque,
                  prayer: prayer,
                  entry:
                      schedule?.iqamaFor(prayer) ?? PrayerIqama(prayer: prayer),
                  adhan: today?.day.timeOf(prayer),
                  clock: clock,
                ),
              // Jumu'ah (2026-10-14): its own time, used on Fridays.
              _IqamaRow(
                mosque: mosque,
                prayer: Prayer.dhuhr,
                entry:
                    schedule?.jumuah ??
                    const PrayerIqama(prayer: Prayer.dhuhr),
                adhan: today?.day.timeOf(Prayer.dhuhr),
                clock: clock,
                jumuah: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            schedule != null && schedule.configuredCount > 0
                ? l10n.scheduleSetByYou(
                    DateLabels.shortDate(schedule.updatedAt.toLocal(), locale),
                  )
                : l10n.scheduleNothingEntered,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.sm),
          Text(
            l10n.iqamaScheduleNote,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.xxl),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              side: BorderSide(color: theme.colorScheme.error),
            ),
            onPressed: () => _confirmRemove(context, ref, mosque, isActive),
            child: Text(l10n.removeMosque),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(dialogContext).colorScheme.error,
            ),
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

/// Where the mosque came from. There is no verification mechanic, so the source
/// is all the app can honestly say (AGENTS.md).
String _sourceLabel(AppLocalizations l10n, MosqueSource source) =>
    switch (source) {
      MosqueSource.manual => l10n.mosqueSourceManual,
      MosqueSource.google => l10n.mosqueSourceGoogle,
      MosqueSource.osm => l10n.mosqueSourceOsm,
    };

/// One prayer of the schedule: its Adhan time small and secondary, its Iqama time
/// or "Not configured", and the quick reminder switch.
class _IqamaRow extends ConsumerWidget {
  const _IqamaRow({
    required this.mosque,
    required this.prayer,
    required this.entry,
    required this.adhan,
    required this.clock,
    this.jumuah = false,
  });

  final Mosque mosque;
  final Prayer prayer;
  final PrayerIqama entry;

  /// The Jumu'ah row: [prayer] is Dhuhr, [entry] the mosque's Jumu'ah.
  final bool jumuah;

  /// Minutes from midnight, or null when there is no place or no time today.
  final int? adhan;
  final ClockFormat clock;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final name = jumuah ? l10n.prayerJumuah : prayerName(l10n, prayer);
    final small = TextStyle(fontSize: 12, color: ink.muted);

    return AppRow(
      leading: null,
      onTap: () => showIqamaEditor(
        context,
        mosque: mosque,
        prayer: prayer,
        current: entry,
        adhan: adhan == null ? null : LocalTime(adhan!),
        jumuah: jumuah,
      ),
      // The Iqama value shares the title's width rather than sitting in the fixed
      // trailing slot, so at a large text size it wraps instead of pushing the row
      // off the edge. Only the switch keeps a fixed size.
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppType.rowSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (jumuah)
                  Text(l10n.jumuahRowHint, style: small)
                else if (adhan != null)
                  Text(
                    l10n.rowAdhanTime(clock.time(LocalTime(adhan!))),
                    style: small,
                  ),
                Text(_reminderLine(l10n), style: small),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(
            child: Align(
              alignment: AlignmentDirectional.centerEnd,
              child: entry.iqama != null
                  ? Text(
                      clock.time(entry.iqama!),
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        fontSize: AppType.rowSize,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  : AppTag(l10n.notConfigured, tone: AppTagTone.warning),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            label: l10n.reminderSwitchLabel(name),
            child: Switch(
              value: entry.hasReminder,
              // No Iqama time, no reminder (AGENTS.md); the line under the name
              // says what to do instead.
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
            ),
          ),
        ],
      ),
    );
  }

  String _reminderLine(AppLocalizations l10n) {
    if (!entry.isConfigured) return l10n.rowReminderNeedsIqama;
    final summary = IqamaSummary.of(
      prayer: prayer,
      iqama: entry.iqama,
      reminderEnabled: entry.reminderEnabled,
      reminderMinutesBefore: entry.reminderMinutesBefore,
    );
    final at = summary.reminderAt;
    if (at == null) return l10n.rowReminderOff;
    return summary.reminderIsPreviousDay
        ? l10n.rowReminderBeforeMidnight(clock.time(at))
        : l10n.rowReminderAt(clock.time(at));
  }
}
