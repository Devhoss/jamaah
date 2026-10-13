import 'adhan_alerts.dart';
import 'adhan_recordings.dart';
import 'mosque.dart';
import 'prayer.dart';
import 'time_model.dart';

/// What the platform layer must schedule. Pure data: no plugin types, so this can
/// be unit-tested without a device (AGENTS.md quality bar).
class PlannedNotification {
  const PlannedNotification({
    required this.id,
    required this.kind,
    required this.prayer,
    required this.at,
    required this.soundMode,
    required this.mosqueId,
    this.vibrate = true,
    this.ringInSilent = false,
    this.fullScreen = false,
    this.minutesBefore,
    this.recordingAsset,
    this.reminderSound,
  });

  /// Stable id: same notification re-planned replaces itself instead of
  /// duplicating (kind + prayer + day, not a running counter).
  final int id;
  final NotificationKind kind;
  final Prayer prayer;

  /// UTC instant the notification should fire.
  final DateTime at;

  /// The Adhan's sound mode. Null for reminders (before an Adhan or an Iqama):
  /// they always use the standard notification sound.
  final AdhanSoundMode? soundMode;

  /// Which mosque this belongs to; empty for Adhan alerts (which are global).
  final String mosqueId;

  final bool vibrate;

  /// Adhan only: play through the alarm volume even when the phone is on silent.
  final bool ringInSilent;

  /// Adhan only: show the full-screen page when the phone is idle.
  final bool fullScreen;

  /// For reminders: how many minutes ahead of the Adhan or Iqama this fires.
  final int? minutesBefore;

  /// Full Adhan only: the bundled recording the app plays.
  final String? recordingAsset;

  /// Jama’ah (Iqama) reminders only: what they play.
  final ReminderSound? reminderSound;

  /// True when the reminder has already fired and must not be re-scheduled.
  bool isInPast(DateTime now) => at.isBefore(now);
}

/// The three independent notifications the app can plan. Adhan alerts and the
/// reminder before them come from the global per-prayer settings; Iqama
/// reminders come from the active mosque (AGENTS.md).
enum NotificationKind { adhan, preAdhan, iqama }

/// Inputs needed to plan a rolling window of notifications.
class NotificationPlanInput {
  const NotificationPlanInput({
    required this.today,
    required this.now,
    required this.prayerTimeOf,
    required this.zoneOffsetFor,
    required this.adhanAlerts,
    this.activeMosque,
    this.iqamaRemindersPaused = false,
    this.jamaahReminders = const JamaahReminderSettings(),
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

  /// Travel mode's manual pause: no Iqama reminders are planned. Adhan alerts
  /// and the reminders before them are not affected.
  final bool iqamaRemindersPaused;

  /// How the Iqama reminders sound and whether they vibrate.
  final JamaahReminderSettings jamaahReminders;

  final int windowDays;
}

/// Builds the rolling notification window.
///
/// Three independent streams:
///  - Adhan alerts: global settings, any of the six prayers.
///  - Reminders before an Adhan: also global, per prayer, on or off on their own.
///  - Iqama reminders: the active mosque's schedule, only prayers that have a
///    configured Iqama time and an enabled reminder, and none while travel mode
///    has them paused.
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
      final adhanAt = instantFor(day, minutes, zoneOffset);
      if (alert.enabled) {
        final mode = input.adhanAlerts.soundModeFor(prayer);
        final plays = mode == AdhanSoundMode.full || mode == AdhanSoundMode.short;
        out.add(
          PlannedNotification(
            id: notificationId(NotificationKind.adhan, prayer, day),
            kind: NotificationKind.adhan,
            prayer: prayer,
            at: adhanAt,
            soundMode: mode,
            mosqueId: '',
            vibrate: alert.vibrate,
            // Ringing in silent only means something for a recording that plays.
            ringInSilent: plays && alert.ringInSilent,
            fullScreen: input.adhanAlerts.fullScreen,
            recordingAsset: mode == AdhanSoundMode.full
                ? adhanRecordingById(input.adhanAlerts.fullRecording).asset
                : null,
          ),
        );
      }
      if (alert.preAdhanMinutes case final before?) {
        out.add(
          PlannedNotification(
            id: notificationId(NotificationKind.preAdhan, prayer, day),
            kind: NotificationKind.preAdhan,
            prayer: prayer,
            // Real elapsed minutes, so a reminder across a DST change or midnight
            // still lands exactly [before] minutes ahead of the Adhan.
            at: adhanAt.subtract(Duration(minutes: before)),
            soundMode: null,
            mosqueId: '',
            vibrate: alert.vibrate,
            minutesBefore: before,
          ),
        );
      }
    }
    return out;
  }

  List<PlannedNotification> _iqamaNotifications(
    NotificationPlanInput input,
    LocalDay day,
    int zoneOffset,
  ) {
    if (input.iqamaRemindersPaused) return const [];
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
          minutesBefore: iqama.reminderMinutesBefore,
          vibrate: input.jamaahReminders.vibrate,
          reminderSound: input.jamaahReminders.sound,
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
/// Built from its parts rather than hashed, so two notifications can never share
/// an id: `kind * 1 000 000 + days since 1970 * 10 + prayer`. It stays inside a
/// positive 32-bit int (Android's limit) until the year 2243.
int notificationId(NotificationKind kind, Prayer prayer, LocalDay day) {
  final days = DateTime.utc(day.year, day.month, day.day)
      .difference(DateTime.utc(1970))
      .inDays;
  return kind.index * 1000000 + days * 10 + prayer.index;
}
