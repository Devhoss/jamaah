import '../../domain/prayer.dart';
import '../../domain/sky/sun_path_geometry.dart';
import '../../domain/today.dart';

/// What the hero's small line above the time says (spec §4.1).
enum HeroKicker {
  /// "NEXT PRAYER · ADHAN"
  nextPrayer,

  /// "NEXT PRAYER · TOMORROW"
  nextPrayerTomorrow,

  /// "ASR · IQAMA IN 15 MIN": between a prayer's Adhan and its Iqama at the
  /// active mosque (owner, 2026-10-15).
  heldForIqama,

  /// "ADHAN": a prayer picked from its row.
  adhan,

  /// "IN FORCE AT 4:12 PM": the view was dragged to a time.
  inForceAt,

  /// "SUNRISE · NOT A PRAYER"
  sunrise,
}

/// The prayer the hero and the ticket are about, and how to introduce it.
class TodaySelection {
  const TodaySelection(this.prayer, this.kicker);

  final Prayer prayer;
  final HeroKicker kicker;

  @override
  bool operator ==(Object other) =>
      other is TodaySelection &&
      other.prayer == prayer &&
      other.kicker == kicker;

  @override
  int get hashCode => Object.hash(prayer, kicker);

  @override
  String toString() => 'TodaySelection(${prayer.name}, ${kicker.name})';
}

/// Where Today is looking: at rest (now), dragged to a minute, or pinned to a
/// prayer picked from its row. Plain Dart, so the selection rules are tested
/// without a widget.
class TodayView {
  const TodayView({this.viewMinute, this.pinned});

  static const atRest = TodayView();

  /// Null at rest: the sky follows the clock.
  final double? viewMinute;

  /// The prayer whose row was tapped, while the view is on it.
  final Prayer? pinned;

  bool get moved => viewMinute != null;

  /// A drag along the arc: any minute, nothing pinned.
  TodayView scrubTo(double minute) =>
      TodayView(viewMinute: SunPathGeometry.wrap(minute));

  /// A row tap: the sun goes to that prayer's time and the prayer is held.
  TodayView pinTo(Prayer prayer, int minute) =>
      TodayView(viewMinute: minute.toDouble(), pinned: prayer);

  /// The minute the sky and the sun show.
  double minuteShown(double now) => viewMinute ?? now;

  /// The prayer the hero is about.
  ///
  /// At rest it is the next Adhan, unless [held] names the prayer in force
  /// whose Iqama at the active mosque is still ahead. Moved, it is the pinned
  /// prayer, or whichever time is in force at the viewed minute (Sunrise
  /// included, introduced as "not a prayer"). Null when the day has no times.
  TodaySelection? select({
    required Map<Prayer, int> times,
    NextPrayer? next,
    Prayer? held,
  }) {
    if (!moved) {
      if (held != null) return TodaySelection(held, HeroKicker.heldForIqama);
      if (next == null) return null;
      return TodaySelection(
        next.prayer,
        next.isTomorrow ? HeroKicker.nextPrayerTomorrow : HeroKicker.nextPrayer,
      );
    }
    final pin = pinned;
    if (pin != null) {
      return TodaySelection(
        pin,
        pin == Prayer.sunrise ? HeroKicker.sunrise : HeroKicker.adhan,
      );
    }
    final p = inForceAt(times, viewMinute!);
    if (p == null) return null;
    return TodaySelection(
      p,
      p == Prayer.sunrise ? HeroKicker.sunrise : HeroKicker.inForceAt,
    );
  }

  /// The last of the six times at or before [minute]; before the day's first
  /// time it is still last night's Isha.
  static Prayer? inForceAt(Map<Prayer, int> times, double minute) {
    if (times.isEmpty) return null;
    Prayer? found;
    for (final p in Prayer.adhanPrayers) {
      final t = times[p];
      if (t != null && t <= minute) found = p;
    }
    return found ?? (times.containsKey(Prayer.isha) ? Prayer.isha : null);
  }

  /// The prayer to hold at rest: the one in force, while the active mosque's
  /// next Iqama is that prayer's and still today (spec §4.1, 2026-10-15).
  ///
  /// No hold while Iqama reminders are paused for travel or while travel mode
  /// follows the location: the user is away from the mosque.
  static Prayer? heldPrayer({
    required TodayReading today,
    required NextIqama? iqama,
    required bool awayFromMosque,
  }) {
    if (awayFromMosque) return null;
    final inForce = today.inForce;
    if (inForce == null || iqama is! IqamaUpcoming) return null;
    if (iqama.prayer != inForce.prayer || iqama.on != today.moment.day) {
      return null;
    }
    return inForce.prayer;
  }
}

/// A glide of the viewed minute, the short way round the clock (spec §3.6).
class SkyGlide {
  SkyGlide({required this.from, required double to})
    : delta = SunPathGeometry.shortestDelta(from, to),
      duration = SunPathGeometry.glideDuration(from, to);

  final double from;
  final double delta;
  final Duration duration;

  /// The minute at [f] (0..1) of the way, eased in and out.
  double at(double f) =>
      SunPathGeometry.wrap(from + delta * SunPathGeometry.glideEase(f));
}
