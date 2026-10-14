import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../flight/in_flight_page.dart';
import '../../app/clock.dart';
import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/extra_times.dart';
import '../../domain/place.dart';
import '../../domain/zone_lookup.dart';
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
  const TodayScreen({this.onOpenMosques, this.onOpenMosque, super.key});

  /// Where the mosque prompts lead. The shell owns the destination, so the screen
  /// only asks for it; without a shell the prompts simply are not tappable.
  final VoidCallback? onOpenMosques;

  /// Opens one mosque, for the "tap to set" prompt: the times are entered on the
  /// mosque itself. Falls back to [onOpenMosques] when not given.
  final ValueChanged<String>? onOpenMosque;

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
        child: Text(
          l10n.todayLoading,
          style: Theme.of(context).textTheme.bodySmall,
        ),
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
        _DayHeader(
          day: today.day.day,
          hijriAdjustDays: settings.requireValue.hijriAdjustDays,
        ),
        const SizedBox(height: AppSpace.md),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: AppChip(
            label: placeLabel(l10n, place),
            icon: Icons.place_outlined,
            onTap: () => showLocationSheet(context),
          ),
        ),
        if (settings.requireValue.travel.followsLocation)
          _FollowLine(
            checkedAt: settings.requireValue.placeCheckedAt,
            failed: settings.requireValue.placeCheckFailed,
            now: ref.watch(minuteClockProvider),
          ),
        if (_zoneNote(ref, l10n, place) case final note?) _Note(note),
        if (settings.requireValue.inFlight case final hold?
            when hold.activeAt(ref.watch(minuteClockProvider)))
          Row(
            children: [
              Expanded(
                child: _Note(
                  l10n.inFlightHeldNote(
                    _phoneClock(context, hold.pausedUntil),
                  ),
                ),
              ),
              TextButton(
                onPressed: () =>
                    ref.read(settingsRepositoryProvider).saveInFlight(null),
                child: Text(l10n.inFlightEnd),
              ),
            ],
          ),
        // In-flight mode lives under travel mode (docs/in-flight-mode.md).
        if (settings.requireValue.travel.travelMode)
          AppPrompt(
            onTap: () => openInFlight(context),
            children: [
              Row(
                children: [
                  const Icon(Icons.flight_takeoff),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Text(
                      l10n.inFlightCardTitle,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.inFlightCardBody,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        if (hasTimes) ...[
          _HeroCard(
            today: today,
            iqama: ref.watch(nextIqamaProvider),
            clock: clock,
          ),
          _MosquePrompt(
            // Until the saved mosques have been read there is nothing honest to
            // say: "Add your mosque" would be wrong for a user who has one.
            loading: !ref.watch(savedMosquesProvider).hasValue,
            mosque: ref.watch(activeMosqueProvider),
            schedule: schedule,
            onOpenMosques: onOpenMosques,
            onOpenMosque: onOpenMosque,
          ),
          // Said where the reminders would otherwise be expected, so a
          // reminder that does not come is never a mystery.
          if (ref.watch(activeMosqueProvider) case final active?)
            if (settings.requireValue.travel.pauseAllIqamaReminders)
              _PausedNote(text: l10n.pausedAllNote)
            else if (active.remindersPaused)
              _PausedNote(text: l10n.pausedMosqueNote(active.name)),
          AppSectionHeader(l10n.todaySectionTimes),
          _PrayerRows(
            today: today,
            schedule: schedule,
            clock: clock,
            extras: ref.watch(todayExtraTimesProvider),
          ),
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
  const _DayHeader({required this.day, required this.hijriAdjustDays});

  final LocalDay day;
  final int hijriAdjustDays;

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
          DateLabels.hijri(date, locale, adjustDays: hijriAdjustDays),
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
              Text(l10n.nextPrayerAdhan, style: _heroLabel),
              if (next.isTomorrow) Text(l10n.tomorrow, style: _heroLabel),
            ],
          ),
          Text(
            l10n.prayerAtTime(
              prayerNameOn(l10n, next.prayer, next.on),
              clock.time(next.at),
            ),
            style: const TextStyle(
              fontSize: AppType.heroTimeSize,
              fontWeight: FontWeight.w600,
              letterSpacing: -1.2,
              height: 1.15,
              color: AppColors.onPrimary,
            ),
          ),
          Text(_countdown(l10n, next.minutesUntil), style: _heroLabel),
          if (iqama != null) _iqamaBlock(context, iqama!),
        ],
      ),
    );
  }

  /// The mosque's own Iqama line, under the divider that keeps it off the Adhan.
  ///
  /// The three readings the domain answers with are said differently here on
  /// purpose. Nothing entered is the prompt below the card's business; a day whose
  /// entered times have all run out is a sentence the user needs to see.
  Widget _iqamaBlock(BuildContext context, NextIqama result) =>
      switch (result) {
        IqamaNotConfigured() => const SizedBox.shrink(),
        IqamaNoneLeftToday(:final mosqueName) => _IqamaDivider(
          children: [
            Text(mosqueName, style: _heroLabel),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context).noIqamaLeftToday,
              style: TextStyle(
                fontSize: AppType.bodySize,
                color: AppColors.onPrimary,
              ),
            ),
          ],
        ),
        final IqamaUpcoming next => _upcomingIqama(context, next),
      };

  Widget _upcomingIqama(BuildContext context, IqamaUpcoming iqama) {
    final l10n = AppLocalizations.of(context);

    return _IqamaDivider(
      children: [
        Text(l10n.nextIqamaLabel(iqama.mosqueName), style: _heroLabel),
        const SizedBox(height: 2),
        Wrap(
          spacing: AppSpace.sm,
          children: [
            Text(
              l10n.prayerAtTime(
                iqama.isJumuah
                    ? l10n.prayerJumuah
                    : prayerName(l10n, iqama.prayer),
                clock.time(iqama.at),
              ),
              style: TextStyle(
                fontSize: AppType.bodySize + 1,
                fontWeight: FontWeight.w600,
                color: AppColors.onPrimary,
              ),
            ),
            Text(
              '· ${_countdown(l10n, iqama.minutesUntil)}',
              style: TextStyle(
                fontSize: AppType.bodySize,
                color: AppColors.onPrimary,
              ),
            ),
            // The day the card counted through, said the same way as the Adhan's.
            if (iqama.isTomorrow) Text(l10n.tomorrow, style: _heroLabel),
          ],
        ),
        if (iqama.jumuahNotSet) Text(l10n.jumuahNotSetNote, style: _heroLabel),
        const SizedBox(height: 2),
        Text(
          iqama.reminderEnabled
              ? l10n.reminderBeforeIqama(iqama.reminderMinutesBefore)
              : l10n.reminderOffForPrayer,
          style: _heroLabel,
        ),
      ],
    );
  }
}

/// The line that separates the mosque's time from the Adhan above it.
class _IqamaDivider extends StatelessWidget {
  const _IqamaDivider({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.onPrimary.withValues(alpha: 0.28),
        ),
      ),
      ...children,
    ],
  );
}

/// The softened small line the hero card uses for everything it does not shout.
final TextStyle _heroLabel = TextStyle(
  fontSize: 13,
  color: AppColors.onPrimary.withValues(alpha: 0.78),
);

String _countdown(AppLocalizations l10n, int minutes) => minutes >= 60
    ? l10n.countdownHours(minutes ~/ 60, minutes % 60)
    : l10n.countdownMinutes(minutes);

/// The quiet ask that gets the user to the mosque step, and only for as long as it
/// is the honest one.
///
/// A mosque that already has Iqama times gets no prompt: the card shows them.
class _MosquePrompt extends StatelessWidget {
  const _MosquePrompt({
    required this.loading,
    required this.mosque,
    required this.schedule,
    required this.onOpenMosques,
    required this.onOpenMosque,
  });

  final bool loading;
  final Mosque? mosque;
  final Schedule? schedule;
  final VoidCallback? onOpenMosques;
  final ValueChanged<String>? onOpenMosque;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (loading) return const SizedBox(height: AppSpace.sm);
    if (mosque == null) {
      return AppPrompt(
        onTap: onOpenMosques,
        children: [
          Text(
            l10n.addMosqueTitle,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.addMosqueBody,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      );
    }
    if (schedule != null && schedule!.configuredCount > 0) {
      return const SizedBox(height: AppSpace.sm);
    }

    final openThisMosque = onOpenMosque;
    return AppPrompt(
      onTap: openThisMosque == null
          ? onOpenMosques
          : () => openThisMosque(mosque!.id),
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
    this.extras = const [],
  });

  final TodayReading today;
  final Schedule? schedule;
  final ClockFormat clock;

  /// Imsak, Duha and the last third of the night, as the user chose to show
  /// them: quiet rows beside the prayers they lead to or follow.
  final List<ExtraTimeAt> extras;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final inForce = today.inForce?.prayer;
    final next = today.next?.prayer;

    List<Widget> extra(ExtraTime time) => [
      for (final e in extras)
        if (e.time == time)
          _ExtraRow(
            name: extraTimeName(l10n, e.time),
            time: clock.time(e.at),
            ink: ink,
          ),
    ];

    return AppRows(
      children: [
        for (final prayer in Prayer.adhanPrayers) ...[
          if (prayer == Prayer.fajr) ...extra(ExtraTime.imsak),
          _PrayerRow(
            name: prayerNameOn(l10n, prayer, today.day.day),
            adhan: _time(prayer),
            iqama: _iqama(prayer),
            reminderOn:
                prayer.canHaveIqama &&
                (schedule?.iqamaOn(today.day.day, prayer).entry.hasReminder ??
                    false),
            muted: prayer == Prayer.sunrise,
            selected: prayer == inForce,
            isNext: prayer == next,
            ink: ink,
          ),
          if (prayer == Prayer.sunrise) ...extra(ExtraTime.duha),
          if (prayer == Prayer.isha) ...extra(ExtraTime.qiyam),
        ],
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
    final at = schedule?.iqamaOn(today.day.day, prayer).entry.iqama;
    return at == null ? null : clock.time(at);
  }
}

/// One extra time: quieter than Sunrise, with no Iqama, no bell and never the
/// next prayer.
class _ExtraRow extends StatelessWidget {
  const _ExtraRow({required this.name, required this.time, required this.ink});

  final String name;
  final String time;
  final AppInk ink;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: AppType.rowSize - 2, color: ink.muted);
    return AppRow(
      muted: true,
      // The same empty slot as the prayers' dot, so the names line up.
      leading: const Icon(Icons.circle, size: 8, color: Colors.transparent),
      title: Text(name, style: style),
      trailing: Text(time, style: style),
    );
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
        color: isNext
            ? Theme.of(context).colorScheme.primary
            : Colors.transparent,
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
          Text(
            name,
            style: _nameStyle(isNext ? FontWeight.w700 : FontWeight.w500),
          ),
          if (isNext) AppTag(l10n.tagNext),
          if (iqama != null)
            Text(l10n.rowIqama(iqama!), style: _detailStyle(ink)),
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
  static TextStyle _nameStyle(FontWeight weight) =>
      TextStyle(fontSize: AppType.rowSize, fontWeight: weight);

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
        if (estimated != null)
          _Note(l10n.estimatedFromLatitudeNote(_degrees(l10n, estimated))),
      ],
    );
  }

  /// `48.5°N` — one decimal is all a fallback latitude is worth, and the hemisphere
  /// letter keeps it out of the sentence.
  static String _degrees(AppLocalizations l10n, double latitude) {
    final value = latitude.abs().toStringAsFixed(1);
    return latitude >= 0
        ? l10n.latitudeNorth(value)
        : l10n.latitudeSouth(value);
  }
}

/// [utc] on the phone's own clock.
String _phoneClock(BuildContext context, DateTime utc) {
  final local = utc.toLocal();
  return ClockFormat.of(context).time(LocalTime.of(local.hour, local.minute));
}

/// When the place's clock and the phone's clock disagree (a phone left on home
/// time after a flight), says which one the times are in, so they are never
/// misread against the clock at the top of the screen.
String? _zoneNote(WidgetRef ref, AppLocalizations l10n, Place place) {
  final phone = ref.watch(phoneUtcOffsetProvider);
  final zone = ref.watch(placeZoneProvider);
  if (phone == null || zone == null) return null;
  final now = ref.watch(minuteClockProvider);
  final placeMinutes = zone.offsetMinutesAt(now);
  if (placeMinutes == phone.inMinutes) return null;
  // Isolated so "UTC+3" keeps its sign in a right-to-left line.
  String utc(int minutes) => '\u2066UTC${utcOffsetLabel(minutes)}\u2069';
  return place.fromDevice && place.userName == null
      ? l10n.zoneNoteHere(utc(placeMinutes), utc(phone.inMinutes))
      : l10n.zoneNotePlace(
          placeLabel(l10n, place),
          utc(placeMinutes),
          utc(phone.inMinutes),
        );
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
        Text(
          l10n.timesUnavailableBody,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
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

/// Travel mode's pause, said where the reminders would otherwise be expected.
class _PausedNote extends StatelessWidget {
  const _PausedNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ink = AppInk.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md),
      child: Row(
        children: [
          Icon(Icons.notifications_paused_outlined, size: 18, color: ink.muted),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: ink.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Follow my location": how fresh the place is, or that it could not be updated.
class _FollowLine extends StatelessWidget {
  const _FollowLine({
    required this.checkedAt,
    required this.failed,
    required this.now,
  });

  final DateTime? checkedAt;
  final bool failed;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final checked = checkedAt;
    if (checked == null && !failed) return const SizedBox.shrink();
    final ago = checked == null ? '' : agoLabel(l10n, checked, now);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.sm),
      child: Row(
        children: [
          Icon(
            failed ? Icons.location_disabled : Icons.my_location,
            size: 16,
            color: ink.muted,
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              failed ? l10n.followingStale(ago) : l10n.followingUpdated(ago),
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: ink.muted),
            ),
          ),
        ],
      ),
    );
  }
}
