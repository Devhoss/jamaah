import 'package:flutter/foundation.dart';

import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../domain/mosque.dart';
import '../../domain/prayer.dart';
import '../../domain/time_model.dart';
import 'iqama_ticket.dart';

/// "in 50 min", "in 1h 10m", "5 min ago", "2 h ago": a signed span of whole
/// minutes from now, in the strings Today already uses.
String relativeText(AppLocalizations l10n, int minutes) {
  if (minutes > 0) {
    return minutes < 60
        ? l10n.countdownMinutes(minutes)
        : l10n.countdownHours(minutes ~/ 60, minutes % 60);
  }
  final ago = -minutes;
  if (ago == 0) return l10n.agoJustNow;
  return ago < 60 ? l10n.agoMinutes(ago) : l10n.agoHours(ago ~/ 60);
}

/// What the Iqama ticket says about [prayer] on [day] at [mosque].
///
/// The minutes are the user's; the app only adds them to the day's Adhan
/// (AGENTS.md). With nothing entered the ticket says "Not configured" and
/// never offers a time of its own. [nowMinute] is the place's wall clock,
/// in minutes from that day's midnight.
TicketContent ticketFor({
  required AppLocalizations l10n,
  required ClockFormat clock,
  required Prayer prayer,
  required LocalDay day,
  required Map<Prayer, int> adhanTimes,
  required Mosque? mosque,
  required int nowMinute,
  required VoidCallback onSet,
  required VoidCallback onAdd,
}) {
  if (!prayer.canHaveIqama) return const TicketSunrise();
  if (mosque == null) return TicketNoMosque(onAdd: onAdd);
  final resolved = mosque.scheduleFor(day)?.iqamaOn(day, prayer);
  final entry = resolved?.entry;
  final minutes = entry?.minutesOfDay(adhanTimes[prayer]);
  if (resolved == null || entry == null || minutes == null) {
    return TicketNotConfigured(mosque: mosque.name, onSet: onSet);
  }
  final at = LocalTime(minutes % 1440);
  final time = clock.time(at);
  return TicketSet(
    mosque: mosque.name,
    time: time,
    relative: relativeText(l10n, minutes - nowMinute),
    rule: entry.isAfterAdhan
        ? l10n.ticketRuleAfter(entry.afterAdhanMinutes!)
        : l10n.ticketRuleFixed,
    reminderOn: entry.reminderEnabled,
    reminder: entry.reminderEnabled
        ? l10n.ticketReminder(
            clock.time(at.plusMinutes(-entry.reminderMinutesBefore)),
          )
        : l10n.ticketNoReminder,
    note: resolved.jumuahNotSet ? l10n.ticketJumuahNotSet(time) : null,
  );
}
