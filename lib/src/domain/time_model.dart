import 'prayer.dart';

/// A moment on a specific calendar day, in the location's own wall clock.
///
/// Prayer times are decimal-free: we only ever compare whole minutes within a day,
/// so a plain `DateTime` at midnight with no timezone attached is not enough —
/// every time carries the day it belongs to so the next day's Fajr can be found.
class LocalDay {
  const LocalDay(this.year, this.month, this.day);

  final int year;
  final int month;
  final int day;

  static LocalDay fromDateTime(DateTime dateTime) =>
      LocalDay(dateTime.year, dateTime.month, dateTime.day);

  LocalDay addDays(int days) {
    final d = DateTime.utc(year, month, day).add(Duration(days: days));
    return LocalDay(d.year, d.month, d.day);
  }

  bool isAfterDay(LocalDay other) =>
      year > other.year ||
      (year == other.year && month > other.month) ||
      (year == other.year && month == other.month && day > other.day);

  /// Whole days from [this] to [other]; negative when [other] is earlier.
  int daysUntil(LocalDay other) {
    final a = DateTime.utc(year, month, day);
    final b = DateTime.utc(other.year, other.month, other.day);
    return b.difference(a).inDays;
  }

  DateTime midnightUtc() => DateTime.utc(year, month, day);

  @override
  bool operator ==(Object other) =>
      other is LocalDay &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}

/// A wall-clock time of day, stored as minutes from midnight (0..1439).
///
/// Times are NEVER stored as absolute timestamps (AGENTS.md).
class LocalTime {
  const LocalTime(this.minutes);

  /// Minutes from midnight, 0..1439.
  final int minutes;

  static const zero = LocalTime(0);

  static LocalTime of(int hour, int minute) => LocalTime(hour * 60 + minute);

  bool get isConfigured => true;

  /// Adds [extraMinutes], wrapping past midnight. An Iqama of 23:50 plus 20
  /// minutes is 00:10 the next day, so callers that need a real instant must
  /// combine this with a date.
  LocalTime plusMinutes(int extraMinutes) =>
      LocalTime(_wrap(minutes + extraMinutes));

  static int _wrap(int value) => ((value % 1440) + 1440) % 1440;

  int get hour => minutes ~/ 60;
  int get minute => minutes % 60;

  @override
  bool operator ==(Object other) =>
      other is LocalTime && other.minutes == minutes;

  @override
  int get hashCode => minutes;

  @override
  String toString() {
    final h = hour;
    final m = minute;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
  }
}

/// The six prayer times for one day, as local minutes-from-midnight.
class PrayerDay {
  const PrayerDay({
    required this.day,
    required this.times,
    this.unavailable = const {},
    this.highLatitudeMovedPrayers = const {},
    this.estimatedFromLatitude,
    this.timesAreEstimates = false,
  });

  final LocalDay day;

  /// Minutes from midnight for each prayer that could be computed.
  final Map<Prayer, int> times;

  /// Prayers with no computable time at all (polar day or night). The UI must say
  /// so instead of inventing a number.
  final Set<Prayer> unavailable;

  /// Prayers whose time was moved by the high-latitude rule rather than by the
  /// angle-based calculation. Surfaced as a quiet note in the UI.
  final Set<Prayer> highLatitudeMovedPrayers;

  /// Latitude actually used when the requested latitude has no sunrise or sunset
  /// on this day (polar day or night). Null means the location's own astronomy was
  /// used.
  final double? estimatedFromLatitude;

  /// True when no latitude produced a believable day; every time is then missing
  /// and the UI must say the times could not be calculated here.
  final bool timesAreEstimates;

  int? timeOf(Prayer prayer) => times[prayer];

  /// The prayer whose time is next at [nowMinutes] (minutes from midnight today),
  /// falling through to tomorrow's Fajr once every time has passed.
  Prayer nextPrayer(int nowMinutes) {
    for (final p in Prayer.adhanPrayers) {
      final t = times[p];
      if (t != null && t > nowMinutes) return p;
    }
    return Prayer.fajr;
  }

  /// True when [nextPrayer] fell through to tomorrow's Fajr.
  bool isAfterLastPrayer(int nowMinutes) => Prayer.adhanPrayers.every(
    (p) => (times[p] ?? 0) <= nowMinutes,
  );

  /// The prayer currently in force at [nowMinutes].
  Prayer currentPrayer(int nowMinutes) {
    var current = Prayer.isha;
    for (final p in Prayer.adhanPrayers) {
      final t = times[p];
      if (t != null && t <= nowMinutes) current = p;
    }
    return current;
  }
}
