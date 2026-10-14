import 'dart:async';

import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notifications/local_notifications_gateway.dart';
import '../data/notifications/notification_sync.dart';
import '../domain/adhan_alerts.dart';
import '../domain/extra_times.dart';
import '../domain/mosque.dart';
import '../domain/notification_channels.dart';
import '../domain/notification_plan.dart';
import '../domain/prayer.dart';
import '../domain/prayer_times_calculator.dart';
import '../domain/time_model.dart';
import '../domain/today.dart';
import '../domain/zone_offsets.dart';
import 'clock.dart';
import '../data/settings_repository.dart';
import 'l10n/app_locale.dart';
import 'l10n/digits.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/prayer_labels.dart';
import 'providers.dart';

/// The 7-day plan for the saved place, from the stored settings and the active
/// mosque. Pure: everything it needs is passed in.
List<PlannedNotification> buildNotificationPlan({
  required PrayerTimesCalculator calculator,
  required ZoneOffsets zone,
  required DateTime nowUtc,
  required AdhanAlertSettings alerts,
  required TravelSettings travel,
  required Mosque? activeMosque,
  JamaahReminderSettings reminders = const JamaahReminderSettings(),
  InFlightHold? inFlight,
  ExtraTimesSettings extraTimes = const ExtraTimesSettings(),
  int windowDays = 7,
}) {
  final today = LocalMoment.inZone(zone: zone, utcInstant: nowUtc).day;
  // One day past the window, so an Iqama after midnight on the last day has the
  // next day's times to be placed against.
  final days = [for (var i = 0; i <= windowDays; i++) today.addDays(i)];
  final times = {for (final d in days) d: calculator.forDay(d).times};

  final plan = const NotificationPlanner().plan(
    NotificationPlanInput(
      today: today,
      now: nowUtc,
      prayerTimeOf: times,
      // The offset at the place's local noon: a DST change happens overnight, so
      // noon carries the offset every prayer of that day is read with.
      zoneOffsetFor: (day) => zone.offsetMinutesAt(
        day.midnightUtc().add(const Duration(hours: 12)),
      ),
      adhanAlerts: alerts,
      activeMosque: activeMosque,
      // Paused for every mosque, or for the active one (2026-10-13).
      iqamaRemindersPaused:
          travel.pauseAllIqamaReminders ||
          (activeMosque?.remindersPaused ?? false),
      jamaahReminders: reminders,
      extraTimes: [
        for (final d in days.take(windowDays))
          for (final e in extraTimesFor(
            calculator: calculator,
            day: d,
            settings: extraTimes,
          ))
            if (extraTimes.alerts.contains(e.time)) e,
      ],
      windowDays: windowDays,
    ),
  );
  return applyInFlightHold(plan, inFlight, alerts: alerts, nowUtc: nowUtc);
}

/// [plan] with in-flight mode's hold applied: nothing from the regular plan
/// until the hold ends, plus the alert for the next prayer projected along
/// the route (as that prayer's Adhan alert is set up; none if it is off).
List<PlannedNotification> applyInFlightHold(
  List<PlannedNotification> plan,
  InFlightHold? hold, {
  required AdhanAlertSettings alerts,
  required DateTime nowUtc,
}) {
  if (hold == null || !hold.activeAt(nowUtc)) return plan;
  final out = [
    for (final n in plan)
      if (!n.at.isBefore(hold.pausedUntil)) n,
  ];
  final prayer = hold.prayer;
  final at = hold.at;
  if (prayer != null &&
      at != null &&
      at.isAfter(nowUtc) &&
      alerts.alertFor(prayer).enabled) {
    out.add(
      adhanAlert(
        alerts,
        prayer,
        at: at,
        id: inFlightAlertId(prayer),
        estimated: true,
      ),
    );
  }
  return out..sort((a, b) => a.at.compareTo(b.at));
}

/// The words a notification shows.
({String title, String body}) notificationText(
  AppLocalizations l10n,
  PlannedNotification n, {
  required String? Function(String mosqueId) mosqueName,
}) {
  final prayer = n.jumuah ? l10n.prayerJumuah : prayerName(l10n, n.prayer);
  final sunrise = n.prayer == Prayer.sunrise;
  return switch (n.kind) {
    NotificationKind.adhan when n.estimated => (
      title: l10n.notifAdhanTitle(prayer),
      body: l10n.notifInFlightBody(prayer),
    ),
    NotificationKind.adhan => (
      title: l10n.notifAdhanTitle(prayer),
      body: sunrise ? l10n.notifSunriseBody : l10n.notifAdhanBody(prayer),
    ),
    NotificationKind.preAdhan => (
      title: l10n.notifPreAdhanTitle(prayer, n.minutesBefore ?? 0),
      body: sunrise ? l10n.notifPreSunriseBody : l10n.notifPreAdhanBody,
    ),
    // «حيّ على الصلاة», "come to prayer", from the Adhan itself, says at a
    // glance that it is time to go; the details are underneath.
    NotificationKind.iqama => (
      title: l10n.notifIqamaCall,
      body: switch (mosqueName(n.mosqueId)) {
        final name? when name.isNotEmpty => l10n.notifIqamaBody(
          prayer,
          n.minutesBefore ?? 0,
          name,
        ),
        _ => l10n.notifIqamaBodyNoMosque(prayer, n.minutesBefore ?? 0),
      },
    ),
    NotificationKind.extra => (
      title: extraTimeName(l10n, n.extraTime!),
      body: switch (n.extraTime!) {
        ExtraTime.imsak => l10n.notifImsakBody,
        ExtraTime.duha => l10n.notifDuhaBody,
        ExtraTime.qiyam => l10n.notifQiyamBody,
      },
    ),
  };
}

/// The name Android shows for a channel in the app's notification settings.
String channelDisplayName(AppLocalizations l10n, ChannelSpec c) {
  var name = switch (c.group) {
    ChannelGroup.adhan => l10n.channelAdhan(
      soundModeName(l10n, c.mode ?? AdhanSoundMode.standard),
    ),
    ChannelGroup.preAdhan => l10n.channelPreAdhan,
    ChannelGroup.iqama => l10n.channelIqama(
      reminderSoundName(l10n, c.reminderSound ?? ReminderSound.chime),
    ),
    ChannelGroup.extra => l10n.channelExtra(
      reminderSoundName(l10n, c.reminderSound ?? ReminderSound.chime),
    ),
  };
  if (!c.vibrate) name = l10n.channelNoVibration(name);
  if (c.alarmStream) name = l10n.channelAlarmVolume(name);
  return name;
}

String reminderSoundName(AppLocalizations l10n, ReminderSound sound) =>
    switch (sound) {
      ReminderSound.chime => l10n.reminderSoundChime,
      ReminderSound.hayya => l10n.soundHayya,
      ReminderSound.standard => l10n.soundModeStandard,
      ReminderSound.silent => l10n.soundModeSilent,
    };

String soundModeName(AppLocalizations l10n, AdhanSoundMode mode) =>
    switch (mode) {
      AdhanSoundMode.full => l10n.soundModeFull,
      AdhanSoundMode.short => l10n.soundModeShort,
      AdhanSoundMode.standard => l10n.soundModeStandard,
      AdhanSoundMode.silent => l10n.soundModeSilent,
    };

/// The strings notifications are written in: the language chosen in Settings,
/// or the phone's. Notifications are built outside any widget, so they cannot
/// read the locale from a context.
final notificationL10nProvider = Provider<AppLocalizations>(
  (ref) => appStringsFor(
    // Only the language: the gateway is rebuilt from these strings.
    switch (ref.watch(
      appSettingsProvider.select((s) => s.value?.language),
    )) {
      AppLanguage.ar => kArabicLocale,
      AppLanguage.en => kEnglishLocale,
      AppLanguage.system || null => resolveAppLocale(
        PlatformDispatcher.instance.locale,
      ),
    },
  ),
);

final localNotificationsGatewayProvider = Provider<LocalNotificationsGateway>((
  ref,
) {
  final l10n = ref.watch(notificationL10nProvider);
  return LocalNotificationsGateway(
    channelName: (c) => channelDisplayName(l10n, c),
  );
});

/// The platform side of notifications; overridden with a fake in tests.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) => ref.watch(localNotificationsGatewayProvider),
);

/// The last sync, for the scheduled-notifications screen.
class NotificationSyncState {
  const NotificationSyncState({this.report, this.error, this.syncing = false});

  final SyncReport? report;
  final Object? error;
  final bool syncing;
}

/// Keeps the platform's scheduled notifications in step with everything they
/// depend on: settings (alerts, sounds, travel), the place and its zone, the
/// active mosque and its Iqama times, and the day.
///
/// Changes in one frame are coalesced into one sync, and a change that lands
/// while a sync is running triggers exactly one more. A failure is kept for the
/// debug screen and never reaches the UI as an exception.
class NotificationScheduler extends Notifier<NotificationSyncState> {
  bool _queued = false;
  bool _running = false;
  bool _again = false;

  @override
  NotificationSyncState build() {
    ref.listen(appSettingsProvider, (_, _) => requestSync());
    ref.listen(savedMosquesProvider, (_, _) => requestSync());
    ref.listen(prayerTimesCalculatorProvider, (_, _) => requestSync());
    // The window moves when the place's date changes.
    ref.listen(
      todayProvider.select((t) => t?.day.day),
      (_, _) => requestSync(),
    );
    requestSync();
    return const NotificationSyncState();
  }

  /// Asks for a sync soon (this microtask turn), however many times it is called.
  void requestSync() {
    if (_queued) return;
    _queued = true;
    scheduleMicrotask(() {
      _queued = false;
      unawaited(syncNow());
    });
  }

  Future<void> syncNow() async {
    if (_running) {
      _again = true;
      return;
    }
    _running = true;
    try {
      do {
        _again = false;
        await _syncOnce();
      } while (_again);
    } finally {
      _running = false;
    }
  }

  Future<void> _syncOnce() async {
    if (!ref.mounted) return;
    final settings = ref.read(appSettingsProvider).value;
    final calculator = ref.read(prayerTimesCalculatorProvider);
    final zone = ref.read(placeZoneProvider);
    final mosques = ref.read(savedMosquesProvider).value;
    // Until the stored state has loaded, any plan would be built from guesses,
    // and syncing it would cancel real notifications. Wait for the next change.
    if (settings == null || mosques == null) return;

    final l10n = ref.read(notificationL10nProvider);
    final gateway = ref.read(notificationGatewayProvider);
    final now = ref.read(appClockProvider).nowUtc();
    final names = {for (final m in mosques) m.id: m.name};
    Mosque? active;
    for (final m in mosques) {
      if (m.id == settings.activeMosqueId) active = m;
    }

    state = NotificationSyncState(report: state.report, syncing: true);
    try {
      final plan = calculator == null || zone == null
          // No place: nothing can be timed, so nothing stays scheduled.
          ? const <PlannedNotification>[]
          : buildNotificationPlan(
              calculator: calculator,
              zone: zone,
              nowUtc: now,
              alerts: settings.adhanAlerts,
              travel: settings.travel,
              activeMosque: active,
              reminders: settings.jamaahReminders,
              inFlight: settings.inFlight,
              extraTimes: settings.extraTimes,
            );
      final report = await NotificationSync(gateway).apply(
        plan: plan,
        now: now,
        textFor: (n) =>
            notificationText(l10n, n, mosqueName: (id) => names[id]),
        stopLabel: l10n.adhanStop,
        // The time on the place's own clock, in the phone's 12/24-hour format,
        // for the full-screen page.
        timeLabel: zone == null
            ? null
            : (at) {
                final local = at.add(
                  Duration(minutes: zone.offsetMinutesAt(at)),
                );
                return plainClockTime(
                  LocalTime.of(local.hour, local.minute),
                  use24Hour: PlatformDispatcher.instance.alwaysUse24HourFormat,
                  languageCode: l10n.localeName,
                );
              },
      );
      debugPrint('Notifications: $report');
      // The app (or a test) may have closed while the platform was answering.
      if (!ref.mounted) return;
      state = NotificationSyncState(report: report);
    } on Object catch (error) {
      debugPrint('Notifications: sync failed: $error');
      if (!ref.mounted) return;
      state = NotificationSyncState(report: state.report, error: error);
    }
  }
}

final notificationSchedulerProvider =
    NotifierProvider<NotificationScheduler, NotificationSyncState>(
      NotificationScheduler.new,
    );

/// Starts the scheduler with the app and re-syncs whenever the app comes back to
/// the foreground (a reboot, a time-zone change or a long sleep may have moved
/// things while it was away).
class NotificationsKeeper extends ConsumerStatefulWidget {
  const NotificationsKeeper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<NotificationsKeeper> createState() =>
      _NotificationsKeeperState();
}

class _NotificationsKeeperState extends ConsumerState<NotificationsKeeper> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          ref.read(notificationSchedulerProvider.notifier).requestSync(),
    );
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watching keeps the scheduler (and its listeners) alive for the whole app.
    ref.watch(notificationSchedulerProvider);
    return widget.child;
  }
}

/// Asks Android for permission to show notifications, if it has not been given.
///
/// Called right after the user turns a reminder or alert on: Android 13+ only
/// lets an app ask in response to something the user did, and asking at start-up
/// for a feature nobody has switched on would be the wrong moment. Never throws.
final notificationPermissionRequestProvider = Provider<Future<void> Function()>(
  (ref) => () async {
    try {
      final gateway = ref.read(localNotificationsGatewayProvider);
      if (!await gateway.notificationsEnabled()) {
        await gateway.requestNotificationPermission();
      }
      ref.read(notificationSchedulerProvider.notifier).requestSync();
    } on Object catch (error) {
      debugPrint('Notifications: permission request failed: $error');
    }
  },
);

/// The two system requests the scheduled-notifications screen can make,
/// overridable so a test can stand in for the platform.
class NotificationPermissionActions {
  const NotificationPermissionActions({
    required this.requestNotifications,
    required this.requestExactAlarms,
  });

  final Future<void> Function() requestNotifications;
  final Future<void> Function() requestExactAlarms;
}

final notificationPermissionActionsProvider =
    Provider<NotificationPermissionActions>((ref) {
      final gateway = ref.watch(localNotificationsGatewayProvider);
      return NotificationPermissionActions(
        requestNotifications: gateway.requestNotificationPermission,
        requestExactAlarms: gateway.requestExactAlarms,
      );
    });

/// `05:36` or `5:36 AM`, without intl: the scheduler runs before the app's
/// localizations (and intl's date data) have loaded, and English is the only
/// language so far.
String plainClockTime(
  LocalTime t, {
  required bool use24Hour,
  String languageCode = 'en',
}) {
  final arabic = languageCode == 'ar';
  final m = t.minute.toString().padLeft(2, '0');
  final String text;
  if (use24Hour) {
    text = '${t.hour.toString().padLeft(2, '0')}:$m';
  } else {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final period = t.hour < 12 ? (arabic ? 'ص' : 'AM') : (arabic ? 'م' : 'PM');
    text = '$h:$m $period';
  }
  return localDigits(text, languageCode);
}
