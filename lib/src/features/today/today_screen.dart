import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_parameters.dart';
import '../../domain/time_model.dart';
import '../../domain/today.dart';
import '../components/app_widgets.dart';
import '../location/location_controller.dart';
import '../location/location_sheet.dart';
import '../location/place_copy.dart';

/// The day at the place the user saved.
///
/// Everything on this screen is a reading of the domain's `TodayReading`, which is
/// built from the saved place's own zone and the injected clock — so "today" here is
/// the place's date, never the device's, and it rolls over at the place's midnight
/// while the app is in the foreground.
///
/// The screen owns no state of its own: settings, mosques and the clock all arrive
/// through providers, which is what lets each state below be driven from a test.
class TodayScreen extends ConsumerWidget {
  const TodayScreen({this.onOpenMosques, super.key});

  /// Where the mosque prompts lead. The shell owns the destination, so the screen
  /// only asks for it; without a shell the prompts simply are not tappable.
  final VoidCallback? onOpenMosques;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);

    if (settings.hasError) {
      // The stream can fail while the data on the device is intact, so this is an
      // invitation to try again rather than a failure laid at the user's door.
      return _TodayNotice(
        title: l10n.todayErrorTitle,
        body: l10n.todayErrorBody,
        actionLabel: l10n.locationTryAgain,
        onAction: () => ref.invalidate(appSettingsProvider),
      );
    }

    if (!settings.hasValue) {
      return Center(
        child: Text(l10n.todayLoading, style: Theme.of(context).textTheme.bodySmall),
      );
    }

    final place = ref.watch(currentPlaceProvider);
    if (place == null) return const _NeedsPlace();

    // A saved place always resolves to a zone and a calculator, so a reading always
    // exists; the state without a place is the prompt above.
    final today = ref.watch(todayProvider)!;
    final schedule = ref.watch(activeMosqueScheduleProvider);
    final hasTimes = today.areTimesAvailable;
    // One clock format for the whole screen, so the card and the rows cannot disagree.
    final clock = ClockFormat.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.lg,
        AppSpace.xxl,
        AppSpace.xxl,
      ),
      children: [
        _DayHeader(day: today.day.day),
        const SizedBox(height: AppSpace.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: placeLabel(l10n, place),
            icon: Icons.place_outlined,
            onTap: () => showLocationSheet(context),
          ),
        ),
        if (hasTimes) ...[
          _HeroCard(
            today: today,
            iqama: ref.watch(nextIqamaProvider),
            clock: clock,
          ),
          _MosquePrompt(
            mosque: ref.watch(activeMosqueProvider),
            schedule: schedule,
            onOpenMosques: onOpenMosques,
          ),
          AppSectionHeader(l10n.todaySectionTimes),
          _PrayerRows(today: today, schedule: schedule, clock: clock),
          _TodayNotes(
            today: today,
            rule: settings.requireValue.highLatitudeRule,
          ),
        ] else
          _TimesUnavailable(),
      ],
    );
  }
}

/// `Monday, 12 October` with the Hijri date under it, both read at the place.
///
/// The Hijri line comes from the place's own calendar day, so it cannot slip a day
/// when the device and the place are on different dates.
class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.day});

  final LocalDay day;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    // The place's day carries no time of day, so it is formatted from a plain date
    // rather than the device's clock.
    final date = day.midnightUtc();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          DateLabels.gregorian(date, locale),
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        Text(
          DateLabels.hijri(date, locale),
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// The next prayer, its Adhan time and how long until it — the one loud element.
///
/// The mosque's Iqama for the same prayer sits underneath, visibly separate and
/// only when the user has entered one (AGENTS.md).
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.today,
    required this.iqama,
    required this.clock,
  });

  final TodayReading today;
  final NextIqama? iqama;
  final ClockFormat clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final next = today.next;
    // Null only when the day has no times at all, which the note below the rows
    // answers; the card then has nothing honest to count down to.
    if (next == null) return const SizedBox(height: AppSpace.lg);

    final label = TextStyle(
      fontSize: 13,
      color: AppColors.onPrimary.withValues(alpha: 0.78),
    );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.hero),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            // Two labels on one line is fine at 1x and a clipped sentence at 3x;
            // a Wrap keeps both readable whatever the text size.
            spacing: AppSpace.sm,
            children: [
              Text(l10n.nextPrayerAdhan, style: label),
              if (next.isTomorrow) Text(l10n.tomorrow, style: label),
            ],
          ),
          Text(
            l10n.prayerAtTime(prayerName(l10n, next.prayer), clock.time(next.at)),
            style: const TextStyle(
              fontSize: AppType.heroTimeSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              height: 1.15,
              color: AppColors.onPrimary,
            ),
          ),
          Text(_countdown(l10n, next.minutesUntil), style: label),
          if (iqama != null) _iqamaBlock(l10n, iqama!),
        ],
      ),
    );
  }

  Widget _iqamaBlock(AppLocalizations l10n, NextIqama iqama) {
    final onPrimary = AppColors.onPrimary;
    final label = TextStyle(fontSize: 13, color: onPrimary.withValues(alpha: 0.78));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: AppSpace.lg,
            bottom: AppSpace.sm,
          ),
          child: Divider(
            height: 1,
            thickness: 1,
            color: onPrimary.withValues(alpha: 0.28),
          ),
        ),
        Text(l10n.nextIqamaLabel(iqama.mosqueName), style: label),
        const SizedBox(height: 2),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            Text(
              l10n.prayerAtTime(prayerName(l10n, iqama.prayer), clock.time(iqama.at)),
              style: TextStyle(
                fontSize: AppType.bodySize + 1,
                fontWeight: FontWeight.w600,
                color: onPrimary,
              ),
            ),
            Text(
              '· ${_countdown(l10n, iqama.minutesUntil)}',
              style: TextStyle(fontSize: AppType.bodySize, color: onPrimary),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          iqama.reminderEnabled
              ? l10n.reminderBeforeIqama(iqama.reminderMinutesBefore)
              : l10n.reminderOffForPrayer,
          style: label,
        ),
        const SizedBox(height: 2),
        Text(l10n.remindersAreSettingsNote, style: label),
      ],
    );
  }
}

String _countdown(AppLocalizations l10n, int minutes) =>
    minutes >= 60
        ? l10n.countdownHours(minutes ~/ 60, minutes % 60)
        : l10n.countdownMinutes(minutes);

/// The quiet ask that gets the user to the mosque step, and only for as long as it
/// is the honest one.
///
/// A mosque that already has Iqama times gets no prompt: the card shows them.
class _MosquePrompt extends StatelessWidget {
  const _MosquePrompt({
    required this.mosque,
    required this.schedule,
    required this.onOpenMosques,
  });

  final Mosque? mosque;
  final Schedule? schedule;
  final VoidCallback? onOpenMosques;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (mosque == null) {
      return AppPrompt(
        onTap: onOpenMosques,
        children: [
          Text(
            l10n.addMosqueTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(l10n.addMosqueBody, style: Theme.of(context).textTheme.bodyMedium),
        ],
      );
    }
    if (schedule != null && schedule!.configuredCount > 0) {
      return const SizedBox(height: AppSpace.sm);
    }

    return AppPrompt(
      onTap: onOpenMosques,
      children: [
        Text(
          l10n.mosqueHasNoIqama(mosque!.name),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

/// The six Adhan times, in the order they arrive.
///
/// Each row keeps its own Iqama line separate from the Adhan time, and only when the
/// active mosque has that time entered — an absent Iqama is silence, never a guess.
class _PrayerRows extends StatelessWidget {
  const _PrayerRows({
    required this.today,
    required this.schedule,
    required this.clock,
  });

  final TodayReading today;
  final Schedule? schedule;
  final ClockFormat clock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final inForce = today.inForce?.prayer;
    final next = today.next?.prayer;

    return AppRows(
      children: [
        for (final prayer in Prayer.adhanPrayers)
          _PrayerRow(
            name: prayerName(l10n, prayer),
            adhan: _time(prayer),
            iqama: _iqama(prayer),
            reminderOn: prayer.canHaveIqama &&
                (schedule?.iqamaFor(prayer).hasReminder ?? false),
            muted: prayer == Prayer.sunrise,
            selected: prayer == inForce,
            isNext: prayer == next,
            ink: ink,
          ),
      ],
    );
  }

  /// Null when the day has no time for this prayer.
  String? _time(Prayer prayer) {
    final minutes = today.day.timeOf(prayer);
    return minutes == null ? null : clock.time(LocalTime(minutes));
  }

  /// The mosque's own Iqama for this prayer, or null when it has not been entered.
  /// Sunrise is never asked for: it has no Iqama (AGENTS.md).
  String? _iqama(Prayer prayer) {
    if (!prayer.canHaveIqama) return null;
    final at = schedule?.iqamaFor(prayer).iqama;
    return at == null ? null : clock.time(at);
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.name,
    required this.adhan,
    required this.iqama,
    required this.reminderOn,
    required this.muted,
    required this.selected,
    required this.isNext,
    required this.ink,
  });

  final String name;
  final String? adhan;
  final String? iqama;

  /// The saved reminder setting for this prayer's Iqama, shown as a bell. Nothing
  /// has been scheduled — the notifications step owns that.
  final bool reminderOn;
  final bool muted;
  final bool selected;
  final bool isNext;
  final AppInk ink;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AppRow(
      muted: muted,
      selected: selected,
      // The slot is always there, so marking one prayer out of six moves nothing.
      leading: Icon(
        Icons.circle,
        size: 8,
        color: isNext ? Theme.of(context).colorScheme.primary : Colors.transparent,
      ),
      title: Wrap(
        // One line per prayer: the Next pill and the mosque's Iqama sit beside the
        // name, so marking one row out of six neither moves nor tallies it. Wrap
        // rather than Row, so a large text size flows onto a second line instead of
        // running off the edge.
        spacing: AppSpace.sm,
        runSpacing: AppSpace.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(name, style: _nameStyle(isNext ? FontWeight.w700 : FontWeight.w500)),
          if (isNext) AppTag(l10n.tagNext),
          if (iqama != null) Text(l10n.rowIqama(iqama!), style: _detailStyle(ink)),
          if (reminderOn)
            Semantics(
              label: l10n.reminderOnSemantics,
              child: Icon(Icons.notifications_none, size: 14, color: ink.muted),
            ),
        ],
      ),
      trailing: adhan != null
          ? Text(adhan!, style: _nameStyle(FontWeight.w500))
          : Text(l10n.noTimeToday, style: _detailStyle(ink)),
    );
  }

  /// Size and weight only: the colour comes from the row, so a muted row mutes the
  /// whole of it.
  static TextStyle _nameStyle(FontWeight weight) => TextStyle(
    fontSize: AppType.rowSize,
    fontWeight: weight,
  );

  /// The small muted reading — an Iqama, or the admission that there is no time.
  static TextStyle _detailStyle(AppInk ink) =>
      TextStyle(fontSize: 12, color: ink.muted);
}

/// The two quiet admissions a day can need, in the prototype's small muted note.
///
/// Only ever shown when the domain says the day is not a plain one: the night rule
/// moving a time, or a latitude with no sunrise to measure from.
class _TodayNotes extends StatelessWidget {
  const _TodayNotes({required this.today, required this.rule});

  final TodayReading today;
  final HighLatitudeRule rule;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moved = today.prayersMovedByRule;
    final estimated = today.estimatedFromLatitude;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (moved.isNotEmpty)
          _Note(
            l10n.highLatitudeNote(
              movedPrayerNames(l10n, moved),
              highLatitudeRuleName(l10n, rule),
            ),
          ),
        if (estimated != null) _Note(l10n.estimatedFromLatitudeNote(_degrees(estimated))),
      ],
    );
  }

  /// `48.5°N` — one decimal is all a fallback latitude is worth, and the hemisphere
  /// letter keeps it out of the sentence.
  static String _degrees(double latitude) =>
      '${latitude.abs().toStringAsFixed(1)}°${latitude >= 0 ? 'N' : 'S'}';
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: AppInk.of(context).muted),
      ),
    );
  }
}

/// A day the sun does not cross here: no times, said plainly, with the place and
/// date still named so the user can see what to change.
class _TimesUnavailable extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppPrompt(
      children: [
        Text(
          l10n.timesUnavailableTitle,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpace.xs),
        Text(l10n.timesUnavailableBody, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

/// The place question, asked where the user actually lands: on Today.
///
/// A device that said no keeps its message on screen after the sheet closes. The
/// route out is the same sheet, which always offers the manual city list, so no
/// permission answer ends the flow (AGENTS.md: never a silent failure).
class _NeedsPlace extends ConsumerWidget {
  const _NeedsPlace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final failure = ref.watch(locationRequestProvider).failure;

    return _TodayNotice(
      title: l10n.todayNeedsPlaceTitle,
      body: failure == null
          ? l10n.todayNeedsPlaceBody
          : placeFailureMessage(l10n, failure),
      actionLabel: l10n.todayChoosePlace,
      onAction: () => showLocationSheet(context),
    );
  }
}

class _TodayNotice extends StatelessWidget {
  const _TodayNotice({
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      children: [
        const SizedBox(height: AppSpace.xxl),
        AppPrompt(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpace.sm),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        FilledButton(onPressed: onAction, child: Text(actionLabel)),
      ],
    );
  }
}
