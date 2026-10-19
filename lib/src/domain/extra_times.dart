import 'prayer.dart';
import 'prayer_times_calculator.dart';
import 'time_model.dart';
import 'today.dart';

/// Times beside the five prayers (2026-10-14). Shown on Today when the user
/// asks; never an Iqama, never the next prayer, never a countdown.
enum ExtraTime { imsak, duha, qiyam }

const kMinImsakMinutes = 0;
const kMaxImsakMinutes = 20;
const kMinDuhaMinutes = 10;
const kMaxDuhaMinutes = 30;

int clampImsakMinutes(int m) => m.clamp(kMinImsakMinutes, kMaxImsakMinutes);
int clampDuhaMinutes(int m) => m.clamp(kMinDuhaMinutes, kMaxDuhaMinutes);

/// How the extra times are worked out, and which are shown and alerted.
class ExtraTimesSettings {
  const ExtraTimesSettings({
    this.imsakMinutes = 10,
    this.duhaMinutes = 15,
    this.shown = const {},
    this.alerts = const {},
  });

  /// Imsak is this many minutes before Fajr.
  final int imsakMinutes;

  /// Duha starts this many minutes after sunrise.
  final int duhaMinutes;

  /// Listed on Today.
  final Set<ExtraTime> shown;

  /// Each gets a notification at its time.
  final Set<ExtraTime> alerts;

  ExtraTimesSettings copyWith({
    int? imsakMinutes,
    int? duhaMinutes,
    Set<ExtraTime>? shown,
    Set<ExtraTime>? alerts,
  }) => ExtraTimesSettings(
    imsakMinutes: imsakMinutes ?? this.imsakMinutes,
    duhaMinutes: duhaMinutes ?? this.duhaMinutes,
    shown: shown ?? this.shown,
    alerts: alerts ?? this.alerts,
  );

  @override
  bool operator ==(Object other) =>
      other is ExtraTimesSettings &&
      other.imsakMinutes == imsakMinutes &&
      other.duhaMinutes == duhaMinutes &&
      _sameSet(other.shown, shown) &&
      _sameSet(other.alerts, alerts);

  @override
  int get hashCode => Object.hash(
    imsakMinutes,
    duhaMinutes,
    Object.hashAllUnordered(shown),
    Object.hashAllUnordered(alerts),
  );
}

bool _sameSet(Set<ExtraTime> a, Set<ExtraTime> b) =>
    a.length == b.length && a.containsAll(b);

/// One extra time on the place's wall clock, and the instant it falls on.
class ExtraTimeAt {
  const ExtraTimeAt({
    required this.time,
    required this.day,
    required this.at,
    required this.utc,
  });

  final ExtraTime time;

  /// The place's date it falls on: the Qiyam of an evening is often the next.
  final LocalDay day;
  final LocalTime at;
  final DateTime utc;
}

/// Imsak before [day]'s Fajr, Duha after its sunrise, and the Qiyam of the
/// night that begins on its evening.
///
/// Measured between instants, so a night with a clock change is counted at
/// its real length. A time whose inputs are missing is left out, never
/// guessed.
List<ExtraTimeAt> extraTimesFor({
  required PrayerTimesCalculator calculator,
  required LocalDay day,
  required ExtraTimesSettings settings,
}) {
  final zone = calculator.zone;
  final times = calculator.forDay(day).times;
  DateTime? instant(LocalDay d, int? minutes) => minutes == null
      ? null
      : zone.utcInstantOf(day: d, time: LocalTime(minutes));
  ExtraTimeAt at(ExtraTime time, DateTime utc) {
    final ms = utc.millisecondsSinceEpoch;
    final whole = DateTime.fromMillisecondsSinceEpoch(
      ms - ms % 60000,
      isUtc: true,
    );
    final local = LocalMoment.inZone(zone: zone, utcInstant: whole);
    return ExtraTimeAt(
      time: time,
      day: local.day,
      at: LocalTime(local.minutesOfDay),
      utc: whole,
    );
  }

  final out = <ExtraTimeAt>[];
  if (instant(day, times[Prayer.fajr]) case final fajr?) {
    out.add(
      at(
        ExtraTime.imsak,
        fajr.subtract(Duration(minutes: settings.imsakMinutes)),
      ),
    );
  }
  if (instant(day, times[Prayer.sunrise]) case final sunrise?) {
    out.add(
      at(ExtraTime.duha, sunrise.add(Duration(minutes: settings.duhaMinutes))),
    );
  }
  final maghrib = instant(day, times[Prayer.maghrib]);
  final next = day.addDays(1);
  final fajr = instant(next, calculator.forDay(next).times[Prayer.fajr]);
  if (maghrib != null && fajr != null && fajr.isAfter(maghrib)) {
    out.add(
      at(ExtraTime.qiyam, maghrib.add(fajr.difference(maghrib) * 2 ~/ 3)),
    );
  }
  return out;
}

/// What Today lists: Imsak and Duha of [moment]'s day, and the Qiyam of the
/// night in progress (before Fajr, last evening's) or the one ahead. Only the
/// [ExtraTimesSettings.shown] ones, in time order.
List<ExtraTimeAt> extraTimesForToday({
  required PrayerTimesCalculator calculator,
  required LocalMoment moment,
  required ExtraTimesSettings settings,
}) {
  final today = extraTimesFor(
    calculator: calculator,
    day: moment.day,
    settings: settings,
  );
  final fajr = calculator.forDay(moment.day).times[Prayer.fajr];
  final beforeFajr = fajr != null && moment.minutesOfDay < fajr;
  final night = beforeFajr
      ? extraTimesFor(
          calculator: calculator,
          day: moment.day.addDays(-1),
          settings: settings,
        )
      : today;
  return [
      for (final e in today)
        if (e.time != ExtraTime.qiyam) e,
      for (final e in night)
        if (e.time == ExtraTime.qiyam) e,
    ].where((e) => settings.shown.contains(e.time)).toList()
    ..sort((a, b) => a.utc.compareTo(b.utc));
}
