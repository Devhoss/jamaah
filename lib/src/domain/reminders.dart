import 'mosque.dart';
import 'prayer.dart';
import 'time_model.dart';

/// The result of resolving an Iqama-based reminder for one day.
///
/// Two independent facts, deliberately separate: an Iqama time can exist without a
/// reminder (the user entered the time and left the reminder off), and a reminder
/// can never exist without a time (AGENS.md).
class ReminderOccurrence {
  const ReminderOccurrence({
    required this.prayer,
    this.iqama,
    this.reminderEnabled = false,
    required this.reminderMinutesBefore,
  });

  final Prayer prayer;

  /// The Iqama time itself, in minutes from midnight. Null when unconfigured.
  final LocalTime? iqama;

  final bool reminderEnabled;

  final int reminderMinutesBefore;

  bool get hasIqama => iqama != null;

  /// True only when a notification should actually be scheduled.
  bool get fires => hasIqama && reminderEnabled;

  /// Minutes from midnight at which the reminder fires, wrapping past midnight.
  /// Null when the Iqama is not configured.
  int? get atMinutes =>
      iqama == null ? null : LocalTime(iqama!.minutes - reminderMinutesBefore).minutes;

  /// The Iqama instant on the day whose [iqama] belongs to [day], wrapping when
  /// the Iqama itself is after midnight (e.g. 00:30 for Isha).
  DateTime iqamaInstant(LocalDay day, int utcOffsetMinutes) =>
      DateTime.fromMillisecondsSinceEpoch(
        day.midnightUtc().millisecondsSinceEpoch +
            (iqama!.minutes - utcOffsetMinutes) * 60000,
        isUtc: true,
      );

  /// The reminder instant on the day whose [iqama] belongs to [day].
  DateTime reminderInstant(LocalDay day, int utcOffsetMinutes) =>
      DateTime.fromMillisecondsSinceEpoch(
        iqamaInstant(day, utcOffsetMinutes).millisecondsSinceEpoch -
            reminderMinutesBefore * 60000,
        isUtc: true,
      );

  @override
  bool operator ==(Object other) =>
      other is ReminderOccurrence &&
      other.prayer == prayer &&
      other.iqama == iqama &&
      other.reminderMinutesBefore == reminderMinutesBefore;

  @override
  int get hashCode => Object.hash(prayer, iqama, reminderMinutesBefore);
}

/// Resolves Iqama reminders for a mosque on a given day.
///
/// Sunni prayers keep their Iqama and their date: an Isha Iqama of 00:30 belongs
/// to the date whose Isha Adhan precedes it, and its reminder (23:50 the previous
/// day) still points at the same instant.
class ReminderResolver {
  const ReminderResolver(this.dayUtcOffsetMinutes);

  /// The zone's UTC offset in minutes for the day being resolved.
  final int dayUtcOffsetMinutes;

  List<ReminderOccurrence> resolve(Schedule schedule) {
    final out = <ReminderOccurrence>[];
    for (final prayer in Prayer.iqamaPrayers) {
      final iqama = schedule.iqamaFor(prayer);
      out.add(
        ReminderOccurrence(
          prayer: prayer,
          iqama: iqama.iqama,
          reminderEnabled: iqama.reminderEnabled,
          reminderMinutesBefore: iqama.reminderMinutesBefore,
        ),
      );
    }
    return out;
  }

  ReminderOccurrence? nextReminder(
    Schedule schedule,
    int nowMinutes, {
    LocalDay? day,
  }) {
    for (final occurrence in resolve(schedule)) {
      if (!occurrence.fires) continue;
      final at = occurrence.atMinutes;
      if (at == null) continue;
      if (at > nowMinutes) return occurrence;
    }
    return null;
  }
}

/// Formats a reminder as "Reminder at 05:33", matching the prototype's summary.
String formatReminder(int atMinutes) {
  final wrapped = ((atMinutes % 1440) + 1440) % 1440;
  final h = wrapped ~/ 60;
  final m = wrapped % 60;
  final suffix = h < 12 ? 'AM' : 'PM';
  final h12 = h % 12 == 0 ? 12 : h % 12;
  return '$h12:${m.toString().padLeft(2, '0')} $suffix';
}
