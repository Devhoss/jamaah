import 'adhan_alerts.dart';
import 'mosque.dart';
import 'prayer.dart';
import 'time_model.dart';

/// What the platform layer must schedule. Pure data: no plugin types, so this can
/// be unit-tested without a device (AGENDS.md quality bar).
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.prayer,
    required this.at,
    required this.soundMode,
    required this.mosqueId,
  });

  /// Stable id: same notification re-planned replaces itself instead of
  /// duplicating (kind + prayer + day, not a running counter).
  final int id;
  final NotificationKind kind;
  final Prayer prayer;

  /// UTC instant the notification should fire.
  final DateTime at;

  /// Null for Iqama reminders: they always use the standard notification sound.
  final AdhanSoundMode? soundMode;

  /// Which mosque this belongs to; empty for Adhan alerts (which are global).
  final String mosqueId;

  /// True when the reminder has already fired and must not be re-scheduled.
  bool isInPast(DateTime now) => at.isBefore(now);
}

enum NotificationKind { adhan, iqama }

/// Inputs needed to plan a rolling window of notifications.
class NotificationPlanInput {
  const NotificationPlanInput({
    required this.today,
    required this.now,
    required this.prayerTimeOf,
    required this.zoneOffsetFor,
    required this.adhanAlerts,
    this.activeMosque,
    this.windowDays = 7,
  });

  final LocalDay today;

  /// "Now" in the device's own clock; used to drop already-fired reminders.
  final DateTime now;

  /// Prayer times by day, keyed by [LocalDay].
  final Map<LocalDay, Map<Prayer, int>> prayerTimeOf;

  /// UTC offset in minutes for a given day. A function, not a map, so a caller can
  /// never accidentally leave a day of the window at offset 0 and have every
  /// reminder silently land three hours early. DST changes inside the window are
  /// resolved here.
  final int Function(LocalDay day) zoneOffsetFor;

  final AdhanAlertSettings adhanAlerts;
  final Mosque? activeMosque;
  final int windowDays;
}

/// Builds the rolling notification window.
///
/// Two independent streams:
///  - Adhan alerts: global settings, any of the six prayers.
///  - Iqama reminders: the active mosque's schedule, only prayers that have a
///    configured Iqama time and an enabled reminder.
class NotificationPlanner {
  const NotificationPlanner();

  List<PlannedNotification> plan(NotificationPlanInput input) {
    final out = <PlannedNotification>[];

    for (var offset = 0; offset < input.windowDays; offset++) {
      final day = input.today.addDays(offset);
      final zoneOffset = input.zoneOffsetFor(day);
      final times = input.prayerTimeOf[day] ?? const {};

      out.addAll(_adhanNotifications(input, day, zoneOffset, times));
      out.addAll(_iqamaNotifications(input, day, zoneOffset));
    }

    return out..sort((a, b) => a.at.compareTo(b.at));
  }

  List<PlannedNotification> _adhanNotifications(
    NotificationPlanInput input,
    LocalDay day,
    int zoneOffset,
    Map<Prayer, int> times,
  ) {
    final out = <PlannedNotification>[];
    for (final prayer in Prayer.adhanPrayers) {
      final minutes = times[prayer];
      if (minutes == null) continue;
      final alert = input.adhanAlerts.alertFor(prayer);
      if (!alert.enabled) continue;
      out.add(
        PlannedNotification(
          id: notificationId(NotificationKind.adhan, prayer, day),
          kind: NotificationKind.adhan,
          prayer: prayer,
          at: instantFor(day, minutes, zoneOffset),
          soundMode: input.adhanAlerts.soundModeFor(prayer),
          mosqueId: '',
        ),
      );
    }
    return out;
  }

  List<PlannedNotification> _iqamaNotifications(
    NotificationPlanInput input,
    LocalDay day,
    int zoneOffset,
  ) {
    final mosque = input.activeMosque;
    if (mosque == null) return const [];
    final schedule = mosque.scheduleFor(day);
    if (schedule == null) return const [];

    final adhanTimes = input.prayerTimeOf[day] ?? const {};
    final out = <PlannedNotification>[];
    for (final prayer in Prayer.iqamaPrayers) {
      final iqama = schedule.iqamaFor(prayer);
      if (!iqama.hasReminder) continue;

      // An Iqama can sit after midnight: an Isha Iqama of 00:30 follows the 19:45
      // Adhan, so it belongs to the *next* calendar day. Deciding by comparing with
      // the Adhan is the only signal we have.
      final adhan = adhanTimes[prayer];
      final targetDay = (adhan != null && iqama.iqama!.minutes < adhan)
          ? day.addDays(1)
          : day;
      final offset = input.zoneOffsetFor(targetDay);

      final reminderAt = iqama.iqama!.plusMinutes(-iqama.reminderMinutesBefore);
      out.add(
        PlannedNotification(
          id: notificationId(NotificationKind.iqama, prayer, day),
          kind: NotificationKind.iqama,
          prayer: prayer,
          at: instantFor(targetDay, reminderAt.minutes, offset),
          soundMode: null,
          mosqueId: mosque.id,
        ),
      );
    }
    return out;
  }

  /// Instant for a wall-clock time on [day], in the given zone.
  static DateTime instantFor(LocalDay day, int minutesFromMidnight, int zoneOffsetMinutes) {
    final wrapped = ((minutesFromMidnight % 1440) + 1440) % 1440;
    return DateTime.fromMillisecondsSinceEpoch(
      day.midnightUtc().millisecondsSinceEpoch +
          (wrapped - zoneOffsetMinutes) * 60000,
      isUtc: true,
    );
  }
}

/// Stable notification id, independent of list order or app restarts.
///
/// Collisions would silently drop a reminder, so the hash spreads across a wide
/// id space. 32-bit int keeps it inside Android's and PendingIntent's limits.
int notificationId(NotificationKind kind, Prayer prayer, LocalDay day) {
  // Distinct, small, pray-specific salts.
  const prayerSalt = {
    Prayer.fajr: 1,
    Prayer.sunrise: 2,
    Prayer.dhuhr: 3,
    Prayer.asr: 4,
    Prayer.maghrib: 5,
    Prayer.isha: 6,
  };
  final kindSalt = kind == NotificationKind.adhan ? 0x1000 : 0x2000;
  var hash = 17;
  hash = 31 * hash + prayerSalt[prayer]!;
  hash = 31 * hash + kindSalt;
  hash = 31 * hash + day.year;
  hash = 31 * hash + day.month;
  hash = 31 * hash + day.day;
  return hash & 0x7FFFFFFF;
}
