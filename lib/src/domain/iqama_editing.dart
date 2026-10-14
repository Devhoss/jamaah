import 'mosque.dart';
import 'prayer.dart';
import 'time_model.dart';

/// The next Iqama an entry of [minutes] after the Adhan gives, from
/// [nowMinutes] on the place's clock: today's if it is still ahead, otherwise
/// tomorrow's, counted from tomorrow's own Adhan. [tomorrow] is true when it
/// falls on tomorrow's date. Null without an Adhan to count from. Only for
/// showing the user what their minutes mean (2026-10-14).
({LocalTime adhan, LocalTime iqama, bool tomorrow})? nextIqamaAfterAdhan({
  required int minutes,
  required int nowMinutes,
  required int? adhanToday,
  required int? adhanTomorrow,
}) {
  if (adhanToday != null && adhanToday + minutes > nowMinutes) {
    final at = adhanToday + minutes;
    return (
      adhan: LocalTime(adhanToday),
      iqama: LocalTime(at % 1440),
      tomorrow: at >= 1440,
    );
  }
  if (adhanTomorrow == null) return null;
  return (
    adhan: LocalTime(adhanTomorrow),
    iqama: LocalTime((adhanTomorrow + minutes) % 1440),
    tomorrow: true,
  );
}

/// The reminder interval choices the Iqama editor offers.
abstract final class ReminderInterval {
  /// The chips shown before "Custom", as in the prototype.
  static const presets = <int>[5, 10, 15];

  static const minMinutes = 1;
  static const maxMinutes = 120;

  static bool isValid(int minutes) =>
      minutes >= minMinutes && minutes <= maxMinutes;

  /// Reads the Custom field. Only plain digits count: the number keyboard offers
  /// nothing else, and anything else is a typo rather than an intent.
  static ReminderMinutesInput parseCustom(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const ReminderMinutesEmpty();
    if (!RegExp(r'^[0-9]+$').hasMatch(text)) {
      return const ReminderMinutesNotWhole();
    }
    // Long digit strings are out of range rather than an overflow.
    final minutes = text.length > 4 ? maxMinutes + 1 : int.parse(text);
    if (!isValid(minutes)) return const ReminderMinutesOutOfRange();
    return ReminderMinutesValid(minutes);
  }
}

/// What the Custom reminder field holds. Each refusal is its own case so the
/// editor can say exactly what is wrong.
sealed class ReminderMinutesInput {
  const ReminderMinutesInput();
}

final class ReminderMinutesValid extends ReminderMinutesInput {
  const ReminderMinutesValid(this.minutes);

  final int minutes;

  @override
  bool operator ==(Object other) =>
      other is ReminderMinutesValid && other.minutes == minutes;

  @override
  int get hashCode => minutes;
}

final class ReminderMinutesEmpty extends ReminderMinutesInput {
  const ReminderMinutesEmpty();
}

final class ReminderMinutesNotWhole extends ReminderMinutesInput {
  const ReminderMinutesNotWhole();
}

final class ReminderMinutesOutOfRange extends ReminderMinutesInput {
  const ReminderMinutesOutOfRange();
}

/// The live summary under the Iqama editor, such as
/// "Maghrib · 6:30 PM Iqama · Reminder at 6:20 PM". The screen formats it; this
/// decides what is true.
class IqamaSummary {
  const IqamaSummary._({
    required this.prayer,
    required this.iqama,
    required this.reminderAt,
    required this.reminderIsPreviousDay,
  });

  factory IqamaSummary.of({
    required Prayer prayer,
    required LocalTime? iqama,
    required bool reminderEnabled,
    required int reminderMinutesBefore,
  }) {
    if (!prayer.canHaveIqama) {
      throw ArgumentError.value(prayer, 'prayer', 'has no Iqama');
    }
    if (iqama == null || !reminderEnabled) {
      return IqamaSummary._(
        prayer: prayer,
        iqama: iqama,
        reminderAt: null,
        reminderIsPreviousDay: false,
      );
    }
    final raw = iqama.minutes - reminderMinutesBefore;
    return IqamaSummary._(
      prayer: prayer,
      iqama: iqama,
      reminderAt: iqama.plusMinutes(-reminderMinutesBefore),
      reminderIsPreviousDay: raw < 0,
    );
  }

  final Prayer prayer;

  /// Null while no time is chosen.
  final LocalTime? iqama;

  /// Null when there is no reminder: switched off, or no Iqama time to remind of.
  final LocalTime? reminderAt;

  /// True when the reminder lands before midnight of the Iqama's own calendar
  /// day, e.g. an Iqama at 12:05 AM with a 10-minute reminder fires at 11:55 PM
  /// the day before. The UI must say so rather than imply the same day.
  final bool reminderIsPreviousDay;
}

/// How far a mosque's Iqama times are set on a day, for the saved list:
/// "Iqama set", "n of 5 Iqama set" or "Iqama not configured".
sealed class IqamaStatus {
  const IqamaStatus();
}

final class IqamaStatusAll extends IqamaStatus {
  const IqamaStatusAll();

  @override
  bool operator ==(Object other) => other is IqamaStatusAll;

  @override
  int get hashCode => 1;
}

final class IqamaStatusPartial extends IqamaStatus {
  const IqamaStatusPartial({required this.configured, required this.of});

  final int configured;
  final int of;

  @override
  bool operator ==(Object other) =>
      other is IqamaStatusPartial &&
      other.configured == configured &&
      other.of == of;

  @override
  int get hashCode => Object.hash(configured, of);
}

final class IqamaStatusNone extends IqamaStatus {
  const IqamaStatusNone();

  @override
  bool operator ==(Object other) => other is IqamaStatusNone;

  @override
  int get hashCode => 0;
}

/// The status of the schedule in force on [day]. A mosque with nothing in force
/// (only a future schedule) has nothing set that day.
IqamaStatus mosqueIqamaStatus(Mosque mosque, LocalDay day) {
  final schedule = mosque.scheduleFor(day);
  final configured = schedule?.configuredCount ?? 0;
  final total = Prayer.iqamaPrayers.length;
  if (configured == 0) return const IqamaStatusNone();
  if (configured == total) return const IqamaStatusAll();
  return IqamaStatusPartial(configured: configured, of: total);
}

/// Normalises what the user typed for a mosque's name and address.
abstract final class MosqueDetailsInput {
  /// The trimmed name, or null when it is blank: a mosque needs a name.
  static String? name(String raw) {
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// The trimmed address; blank is allowed.
  static String address(String raw) => raw.trim();
}
