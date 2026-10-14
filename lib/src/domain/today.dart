import 'mosque.dart';
import 'prayer.dart';
import 'prayer_times_calculator.dart';
import 'time_model.dart';
import 'zone_offsets.dart';

/// The five daily prayers in the order their times arrive.
///
/// Sunrise is deliberately absent: it is a time on the list, never a prayer to
/// count down to (AGENTS.md gives it only an optional Adhan alert). The set is the
/// same as [Prayer.iqamaPrayers] because both are "the five prayers".
const _dailyOrder = Prayer.iqamaPrayers;

/// An instant as the saved place's own wall clock sees it.
///
/// Built from a UTC instant plus the place's zone, so "today" is the day at the
/// place the times are calculated for — never the day on the device, which can be
/// a different calendar date.
class LocalMoment {
  const LocalMoment._({
    required this.zone,
    required this.utcInstant,
    required this.day,
    required this.minutesOfDay,
  });

  factory LocalMoment.inZone({
    required ZoneOffsets zone,
    required DateTime utcInstant,
  }) {
    final utc = utcInstant.toUtc();
    final local = utc.add(Duration(minutes: zone.offsetMinutesAt(utc)));
    return LocalMoment._(
      zone: zone,
      utcInstant: utc,
      day: LocalDay(local.year, local.month, local.day),
      minutesOfDay: local.hour * 60 + local.minute,
    );
  }

  final ZoneOffsets zone;
  final DateTime utcInstant;

  /// The calendar date at the place.
  final LocalDay day;

  /// Minutes from that date's midnight, on the place's wall clock.
  final int minutesOfDay;
}

/// The prayer the countdown points at.
class NextPrayer {
  const NextPrayer({
    required this.prayer,
    required this.on,
    required this.at,
    required this.minutesUntil,
    required this.isTomorrow,
  });

  final Prayer prayer;

  /// The date the prayer falls on at the place — tomorrow once Isha has passed.
  final LocalDay on;
  final LocalTime at;

  /// Real minutes from the moment to [at]. Counted between instants rather than
  /// between wall-clock numbers, so a day with a clock change is genuinely 23 or
  /// 25 hours long and the countdown says so.
  final int minutesUntil;

  final bool isTomorrow;
}

/// The prayer whose time has already arrived.
class PrayerInForce {
  const PrayerInForce({
    required this.prayer,
    required this.startedOn,
    required this.at,
  });

  final Prayer prayer;

  /// Between midnight and Fajr this is yesterday's date: the prayer in force is the
  /// Isha that began yesterday evening.
  final LocalDay startedOn;
  final LocalTime at;
}

/// What the Today screen shows for one place at one instant.
class TodayReading {
  const TodayReading({
    required this.day,
    required this.moment,
    this.next,
    this.inForce,
  });

  /// The place's own day, with its times.
  final PrayerDay day;

  /// The instant this was read at, so a caller can turn a wall-clock time into a
  /// countdown without re-resolving the zone.
  final LocalMoment moment;

  /// Null when there is nothing to count down to — no times for this day at all.
  final NextPrayer? next;

  /// Null in the same case, and before the first time of a day whose previous
  /// evening cannot be resolved. Also null between sunrise and Dhuhr: Fajr's window
  /// closes at sunrise, so that gap belongs to no prayer.
  final PrayerInForce? inForce;

  bool get areTimesAvailable => day.times.isNotEmpty;

  /// Non-empty exactly when the high-latitude rule moved a time, which is the only
  /// time the UI adds the quiet note about it.
  Set<Prayer> get prayersMovedByRule => day.highLatitudeMovedPrayers;

  /// Set when the place has no sunrise or sunset today and the times came from a
  /// latitude nearer the equator.
  double? get estimatedFromLatitude => day.estimatedFromLatitude;
}

/// Reads the place's day around [moment].
///
/// Pure and clock-injected: the app hands in the instant, so every DST, midnight
/// and next-day case here is testable without waiting for one.
TodayReading readToday({
  required PrayerTimesCalculator calculator,
  required LocalMoment moment,
}) {
  final today = calculator.forDay(moment.day);
  return TodayReading(
    day: today,
    moment: moment,
    next: _nextPrayer(calculator: calculator, today: today, moment: moment),
    inForce: _prayerInForce(
      calculator: calculator,
      today: today,
      moment: moment,
    ),
  );
}

NextPrayer? _nextPrayer({
  required PrayerTimesCalculator calculator,
  required PrayerDay today,
  required LocalMoment moment,
}) {
  if (today.times.isEmpty) return null;

  for (final prayer in _dailyOrder) {
    final minutes = today.times[prayer];
    if (minutes == null || minutes <= moment.minutesOfDay) continue;
    final at = LocalTime(minutes);
    return NextPrayer(
      prayer: prayer,
      on: today.day,
      at: at,
      minutesUntil: _minutesUntil(moment, today.day, at),
      isTomorrow: false,
    );
  }

  // After Isha the next prayer is tomorrow's Fajr, whose times are their own day's.
  final tomorrow = calculator.forDay(today.day.addDays(1));
  final fajr = tomorrow.times[Prayer.fajr];
  if (fajr == null) return null;
  final at = LocalTime(fajr);
  return NextPrayer(
    prayer: Prayer.fajr,
    on: tomorrow.day,
    at: at,
    minutesUntil: _minutesUntil(moment, tomorrow.day, at),
    isTomorrow: true,
  );
}

PrayerInForce? _prayerInForce({
  required PrayerTimesCalculator calculator,
  required PrayerDay today,
  required LocalMoment moment,
}) {
  if (today.times.isEmpty) return null;

  Prayer? started;
  int? startedAt;
  for (final prayer in _dailyOrder) {
    final minutes = today.times[prayer];
    if (minutes == null || minutes > moment.minutesOfDay) continue;
    started = prayer;
    startedAt = minutes;
  }
  if (started != null) {
    // Sunrise is not a prayer, but it does end Fajr's window. Between it and Dhuhr
    // nothing is in force, so the screen highlights no row rather than claiming a
    // prayer is still current hours after its time has gone.
    final sunrise = today.times[Prayer.sunrise];
    if (started == Prayer.fajr && sunrise != null && sunrise <= moment.minutesOfDay) {
      return null;
    }
    return PrayerInForce(
      prayer: started,
      startedOn: today.day,
      at: LocalTime(startedAt!),
    );
  }

  final yesterday = calculator.forDay(today.day.addDays(-1));
  final isha = yesterday.times[Prayer.isha];
  if (isha == null) return null;
  return PrayerInForce(
    prayer: Prayer.isha,
    startedOn: yesterday.day,
    at: LocalTime(isha),
  );
}

int _minutesUntil(LocalMoment moment, LocalDay day, LocalTime time) =>
    moment.zone
        .utcInstantOf(day: day, time: time)
        .difference(moment.utcInstant)
        .inMinutes;

/// The active mosque's Iqama, as the Today card can honestly state it.
///
/// Three answers that are not variations of one another: a time still ahead, a day
/// whose entered times are all behind the clock, and a mosque with nothing entered
/// at all. The last two need different responses from the app, so the type keeps
/// them apart rather than letting both collapse into "nothing to show".
sealed class NextIqama {
  const NextIqama();
}

/// The earliest Iqama still ahead of the moment, whichever of the five it is.
final class IqamaUpcoming extends NextIqama {
  const IqamaUpcoming({
    required this.prayer,
    required this.mosqueName,
    required this.on,
    required this.at,
    required this.minutesUntil,
    required this.isTomorrow,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
    this.isJumuah = false,
    this.jumuahNotSet = false,
  });

  final Prayer prayer;
  final String mosqueName;

  /// Friday's Dhuhr: named Jumu'ah (2026-10-14).
  final bool isJumuah;

  /// Friday, but the mosque has no Jumu'ah time: [at] is Dhuhr's own Iqama,
  /// and the card says so.
  final bool jumuahNotSet;

  /// The day the Iqama falls on — tomorrow once the day's times have run out.
  final LocalDay on;
  final LocalTime at;

  /// Real minutes from the moment to [at], so a day that changes its clocks is
  /// counted at the length it really has.
  final int minutesUntil;

  final bool isTomorrow;

  /// The reminder *settings*. Nothing here implies a notification was scheduled;
  /// the notifications step owns that.
  final bool reminderEnabled;
  final int reminderMinutesBefore;
}

/// The mosque has Iqama times, but none is still ahead today and no Fajr time is
/// entered for tomorrow either.
final class IqamaNoneLeftToday extends NextIqama {
  const IqamaNoneLeftToday({required this.mosqueName});

  /// The mosque the finished day belongs to, so the card can name it rather than
  /// leave the sentence standing on its own.
  final String mosqueName;
}

/// Nothing entered: no active mosque, or one whose schedule is still all "Not
/// configured". The app never shows a time the user has not given it (AGENTS.md).
final class IqamaNotConfigured extends NextIqama {
  const IqamaNotConfigured();
}

/// Reads the mosque's Iqama times around [TodayReading.moment].
///
/// The next Iqama is the earliest one the user has entered that is still ahead —
/// which can belong to a prayer whose Adhan is already behind the clock, because a
/// jama'ah is its mosque's own time and has nothing to wait for the Adhan. Only when
/// the day's entered times have all run out does the card reach for tomorrow's Fajr,
/// and it reads that day's schedule to do so.
///
/// Nothing here consults the calculated Adhan times: an Iqama is the user's own data
/// (AGENTS.md), so it is never a guess and never borrowed from another prayer.
NextIqama readNextIqama({
  required Mosque? mosque,
  required TodayReading today,
}) {
  if (mosque == null) return const IqamaNotConfigured();
  final moment = today.moment;
  final tomorrow = moment.day.addDays(1);
  final todaySchedule = mosque.scheduleFor(moment.day);
  final tomorrowSchedule = mosque.scheduleFor(tomorrow);

  IqamaUpcoming? earliest;
  for (final prayer in Prayer.iqamaPrayers) {
    // On a Friday, Dhuhr's is Jumu'ah's (or Dhuhr's own while it has none).
    final resolved = todaySchedule?.iqamaOn(moment.day, prayer);
    final entry = resolved?.entry;
    final at = entry?.iqama;
    if (resolved == null || entry == null || at == null) continue;
    final until = _minutesUntil(moment, moment.day, at);
    // Measured in real minutes rather than on the wall clock, so an hour the day
    // has already lived through on a clock-changing morning is not offered again.
    if (until <= 0) continue;
    if (earliest == null || until < earliest.minutesUntil) {
      earliest = IqamaUpcoming(
        prayer: prayer,
        mosqueName: mosque.name,
        on: moment.day,
        at: at,
        minutesUntil: until,
        isTomorrow: false,
        reminderEnabled: entry.reminderEnabled,
        reminderMinutesBefore: entry.reminderMinutesBefore,
        isJumuah: resolved.isJumuah,
        jumuahNotSet: resolved.jumuahNotSet,
      );
    }
  }
  if (earliest != null) return earliest;

  final fajrEntry = tomorrowSchedule?.iqamaFor(Prayer.fajr);
  final fajrAt = fajrEntry?.iqama;
  if (fajrEntry != null && fajrAt != null) {
    return IqamaUpcoming(
      prayer: Prayer.fajr,
      mosqueName: mosque.name,
      on: tomorrow,
      at: fajrAt,
      minutesUntil: _minutesUntil(moment, tomorrow, fajrAt),
      isTomorrow: true,
      reminderEnabled: fajrEntry.reminderEnabled,
      reminderMinutesBefore: fajrEntry.reminderMinutesBefore,
    );
  }

  final anythingEntered =
      (todaySchedule?.configuredCount ?? 0) > 0 ||
      (todaySchedule?.jumuah.isConfigured ?? false) ||
      (tomorrowSchedule?.configuredCount ?? 0) > 0;
  return anythingEntered
      ? IqamaNoneLeftToday(mosqueName: mosque.name)
      : const IqamaNotConfigured();
}
