import 'dart:async';

import 'dart:ui' show PlatformDispatcher;
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'diagnostics.dart';
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
import 'adhan_screen.dart';
import 'clock.dart';
import '../data/settings_repository.dart';
import 'l10n/app_locale.dart';
import 'l10n/digits.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/prayer_labels.dart';
import 'providers.dart';

/// How far ahead notifications are planned (2026-10-14: two weeks). The plan
/// is renewed whenever the app opens and by a daily background job; two weeks
/// keeps alerts coming for someone who does not open the app, even if the
/// phone skips that job for a while. About 20 a day stays well inside
/// Android's limit of 500 scheduled alarms per app.
const kPlanWindowDays = 14;

/// The plan for the saved place, from the stored settings and the active
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
  int windowDays = kPlanWindowDays,
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
        // From yesterday: after midnight, the night in progress is yesterday
        // evening's, and its last third is still ahead.
        for (final d in [today.addDays(-1), ...days.take(windowDays)])
          for (final e in extraTimesFor(
            calculator: calculator,
            day: d,
            settings: extraTimes,
          ))
            if (extraTimes.alerts.contains(e.time) && e.utc.isAfter(nowUtc)) e,
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
      ReminderSound.shortAzan => l10n.reminderSoundShortAzan,
      ReminderSound.shortAllahAkbar => l10n.reminderSoundShortAllahAkbar,
      ReminderSound.shortAzanOne => l10n.reminderSoundShortAzanOne,
      ReminderSound.shortVerseOne => l10n.reminderSoundShortVerseOne,
      ReminderSound.shortVerseTwo => l10n.reminderSoundShortVerseTwo,
      ReminderSound.standard => l10n.soundModeStandard,
      ReminderSound.silent => l10n.soundModeSilent,
      ReminderSound.custom => l10n.reminderSoundCustom,
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
    switch (ref.watch(appSettingsProvider.select((s) => s.value?.language))) {
      AppLanguage.ar => kArabicLocale,
      AppLanguage.en => kEnglishLocale,
      AppLanguage.system ||
      null => resolveAppLocale(PlatformDispatcher.instance.locale),
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
  String _nextTrigger = 'scheduler_initialization';

  @override
  NotificationSyncState build() {
    ref.listen(appSettingsProvider, (_, _) => requestSync('settings_change'));
    ref.listen(savedMosquesProvider, (_, _) => requestSync('mosque_change'));
    ref.listen(
      prayerTimesCalculatorProvider,
      (_, _) => requestSync('calculation_or_location_change'),
    );
    // The window moves when the place's date changes.
    ref.listen(
      todayProvider.select((t) => t?.day.day),
      (_, _) => requestSync('day_change'),
    );
    requestSync('scheduler_initialization');
    return const NotificationSyncState();
  }

  /// Asks for a sync soon, however many times it is called.
  ///
  /// Requests within [debounce] become one sync: one tap can write settings
  /// twice (travel mode, then the location follower's check), and each full
  /// sync reschedules every notification on this isolate. Waiting also lets
  /// the switch that started it finish its animation first (2026-10-16).
  void requestSync([String trigger = 'manual_retry']) {
    _nextTrigger = trigger;
    if (_queued) return;
    _queued = true;
    Timer(debounce, () {
      _queued = false;
      final trigger = _nextTrigger;
      if (ref.mounted) unawaited(syncNow(trigger: trigger));
    });
  }

  static const debounce = Duration(milliseconds: 400);

  /// Syncs now. While a sync is already running this asks for one more pass
  /// and waits for both, so a caller always returns after its change is in.
  Future<void> syncNow({String trigger = 'manual_retry'}) async {
    _nextTrigger = trigger;
    if (_running) {
      _again = true;
      return _done?.future;
    }
    _running = true;
    final done = _done = Completer<void>();
    try {
      do {
        _again = false;
        await _syncOnce(trigger: _nextTrigger);
      } while (_again);
    } finally {
      _running = false;
      done.complete();
    }
  }

  Completer<void>? _done;

  Future<void> _syncOnce({required String trigger}) async {
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
    String? syncId;
    Stopwatch? syncTimer;
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
      syncId =
          '${now.microsecondsSinceEpoch}-${math.Random().nextInt(1 << 32)}';
      syncTimer = Stopwatch()..start();
      unawaited(
        Diagnostics.record(
          'notification_sync_started',
          values: {
            'syncId': syncId,
            'startedAtUtc': now.toUtc().toIso8601String(),
            'trigger': trigger,
            'planned': plan.length,
            'selectedForScheduling': plan
                .where((n) => n.at.isAfter(now))
                .length,
            'countsByKind': {
              for (final kind in NotificationKind.values)
                kind.name: plan.where((n) => n.kind == kind).length,
            },
            'countsByMechanism': {
              'native_app_managed': plan.where(playsInApp).length,
              'platform_notification': plan.where((n) => !playsInApp(n)).length,
            },
            'configuration': {
              'calculationMethod': settings.calculationMethod.name,
              'effectiveCalculationMethod': calculator?.method.name,
              'madhab': settings.madhab.name,
              'highLatitudeRule': settings.highLatitudeRule.name,
              'customAngles': {
                'fajrAngle': settings.customAngles.fajrAngle,
                'ishaAngle': settings.customAngles.ishaAngle,
                'ishaMinutesAfterMaghrib':
                    settings.customAngles.ishaMinutesAfterMaghrib,
              },
              'minuteOffsets': {
                for (final entry in settings.minuteOffsets.entries)
                  entry.key.name: entry.value,
              },
              'adhan': {
                'defaultSoundMode': settings.adhanAlerts.defaultSoundMode.name,
                'fullScreen': settings.adhanAlerts.fullScreen,
                'fullRecordingId': settings.adhanAlerts.fullRecording,
                'shortAdhan': settings.adhanAlerts.shortAdhan.name,
                'prayers': {
                  for (final prayer in Prayer.adhanPrayers)
                    prayer.name: {
                      'enabled': settings.adhanAlerts.alertFor(prayer).enabled,
                      'enabledSource':
                          settings.adhanAlerts.alerts.containsKey(prayer)
                          ? 'prayer_setting'
                          : 'default_disabled',
                      'soundMode': settings.adhanAlerts
                          .soundModeFor(prayer)
                          .name,
                      'soundModeSource':
                          settings.adhanAlerts
                                  .alertFor(prayer)
                                  .soundModeOverride ==
                              null
                          ? 'global_default'
                          : 'prayer_override',
                      'vibrate': settings.adhanAlerts.alertFor(prayer).vibrate,
                      'ringInSilent': settings.adhanAlerts
                          .alertFor(prayer)
                          .ringInSilent,
                      'preAdhanMinutes': settings.adhanAlerts
                          .alertFor(prayer)
                          .preAdhanMinutes,
                      'preAdhanRingInSilent': settings.adhanAlerts
                          .alertFor(prayer)
                          .preAdhanRingInSilent,
                      'recordingId': settings.adhanAlerts.recordingFor(prayer),
                      'recordingSource':
                          settings.adhanAlerts.alertFor(prayer).recording ==
                              null
                          ? 'global_setting'
                          : 'prayer_override',
                      'customRecording': settings.adhanAlerts
                          .recordingFor(prayer)
                          .startsWith('custom:'),
                    },
                },
              },
              'travel': {
                'mode': settings.travel.travelMode,
                'pauseAllIqamaReminders':
                    settings.travel.pauseAllIqamaReminders,
              },
              'jamaahReminders': {
                'sound': settings.jamaahReminders.sound.name,
                'vibrate': settings.jamaahReminders.vibrate,
                'ringInSilent': settings.jamaahReminders.ringInSilent,
                'customSoundConfigured':
                    settings.jamaahReminders.customSoundPath != null,
              },
              'extraTimes': {
                'shown': settings.extraTimes.shown.map((e) => e.name).toList(),
                'alerts': settings.extraTimes.alerts
                    .map((e) => e.name)
                    .toList(),
                'imsakMinutes': settings.extraTimes.imsakMinutes,
                'duhaMinutes': settings.extraTimes.duhaMinutes,
              },
              'activeMosqueId': active?.id,
              'activeMosqueRemindersPaused': active?.remindersPaused,
              'activeMosqueSchedules': [
                for (final schedule in active?.schedules ?? const <Schedule>[])
                  {
                    'scheduleId': schedule.id,
                    'effectiveFrom': schedule.effectiveFrom?.toString(),
                    'prayers': {
                      for (final prayer in Prayer.iqamaPrayers)
                        prayer.name: {
                          'configured': schedule.iqamaFor(prayer).isConfigured,
                          'fixedMinutesAfterMidnight': schedule
                              .iqamaFor(prayer)
                              .iqama
                              ?.minutes,
                          'minutesAfterAdhan': schedule
                              .iqamaFor(prayer)
                              .afterAdhanMinutes,
                          'reminderEnabled': schedule
                              .iqamaFor(prayer)
                              .reminderEnabled,
                          'reminderMinutesBefore': schedule
                              .iqamaFor(prayer)
                              .reminderMinutesBefore,
                          'effectiveSource': 'mosque_schedule',
                        },
                    },
                    'jumuah': {
                      'configured': schedule.jumuah.isConfigured,
                      'fixedMinutesAfterMidnight':
                          schedule.jumuah.iqama?.minutes,
                      'minutesAfterAdhan': schedule.jumuah.afterAdhanMinutes,
                      'reminderEnabled': schedule.jumuah.reminderEnabled,
                      'reminderMinutesBefore':
                          schedule.jumuah.reminderMinutesBefore,
                      'effectiveSource': 'mosque_schedule',
                    },
                  },
              ],
              'locationZone': settings.location?.ianaZone,
            },
            'plannedSchedule': [
              for (final n in plan.take(400))
                {
                  'id': n.id,
                  'correlationId': 'notification_${n.id}',
                  'kind': n.kind.name,
                  'category': n.kind == NotificationKind.extra
                      ? 'extra_${n.extraTime?.name}'
                      : n.kind.name,
                  'prayer': n.prayer.name,
                  'mosqueId': n.mosqueId.isEmpty ? null : n.mosqueId,
                  'atUtc': n.at.toUtc().toIso8601String(),
                  'timezone': settings.location?.ianaZone ?? 'unknown',
                  'localTimeLabel': zone == null
                      ? null
                      : () {
                          final local = n.at.toUtc().add(
                            Duration(minutes: zone.offsetMinutesAt(n.at)),
                          );
                          return plainClockTime(
                            LocalTime.of(local.hour, local.minute),
                            use24Hour: PlatformDispatcher
                                .instance
                                .alwaysUse24HourFormat,
                            languageCode: l10n.localeName,
                          );
                        }(),
                  'minutesBefore': n.minutesBefore,
                  'estimated': n.estimated,
                  'mechanism': playsInApp(n)
                      ? 'native_app_managed'
                      : 'platform_notification',
                  'selected': n.at.isAfter(now),
                  'exclusionReason': n.at.isAfter(now) ? null : 'past',
                  'soundMode': n.soundMode?.name ?? n.reminderSound?.name,
                  'vibrate': n.vibrate,
                  'ringInSilent': n.ringInSilent,
                  'fullScreen': n.fullScreen,
                  'customRecordingConfigured': n.customSoundPath != null,
                },
            ],
            'scheduleTruncated': plan.length > 400,
            'excludedEvents': {
              'available': false,
              'reason': 'The production planner returns selected notifications only; the plan does not expose rejected candidates. Effective enablement settings are included above.',
            },
          },
        ),
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
        // The full-screen page's sky, sun path and words (spec §4.2).
        screenFor: calculator == null || zone == null
            ? null
            : (n) => adhanScreenPayload(
                planned: n,
                calculator: calculator,
                zone: zone,
                l10n: l10n,
                mosque: active,
                theme: settings.themeMode.name,
                hijriAdjustDays: settings.hijriAdjustDays,
                clockTime: (t) => plainClockTime(
                  t,
                  use24Hour: PlatformDispatcher.instance.alwaysUse24HourFormat,
                  languageCode: l10n.localeName,
                ),
              ),
        syncId: syncId,
      );
      debugPrint('Notifications: $report');
      unawaited(
        Diagnostics.record(
          'notification_sync_completed',
          values: {
            'syncId': syncId,
            'durationMs': syncTimer.elapsedMilliseconds,
            'lockWaitMs': report.lockWaitMs,
            'anotherSyncWasInProgress': report.anotherSyncWasInProgress,
            'scheduled': report.scheduled,
            'cancelled': report.cancelled,
            'exact_alarm': report.exact,
            'notifications_enabled': report.notificationsEnabled,
            'platform_pending': report.platformPending,
            'platform_pending_duplicates_before':
                report.platformPendingDuplicatesBefore,
            'platform_pending_duplicates_after':
                report.platformPendingDuplicates,
            'platform_pending_unexpected': report.platformPendingUnexpected,
            'platform_pending_missing': report.platformPendingMissing,
            'app_adhan_alarms_pending': report.adhanAlarms,
            'app_adhan_alarm_duplicates': report.adhanAlarmDuplicates,
            'app_adhan_alarms_missing': report.adhanAlarmsMissing,
            'planned_duplicate_ids': report.plannedDuplicateIds,
            'adhan_time_collisions': report.adhanTimeCollisions,
            'byKind': {
              for (final kind in NotificationKind.values)
                kind.name: plan.where((n) => n.kind == kind).length,
            },
            'nativeDesired': report.nativeDesired,
            'platformDesired': report.platformDesired,
            'reconciliation': report.reconciliation,
          },
        ),
      );
      // The app (or a test) may have closed while the platform was answering.
      if (!ref.mounted) return;
      state = NotificationSyncState(report: report);
    } on Object catch (error) {
      debugPrint('Notifications: sync failed: $error');
      unawaited(
        Diagnostics.record(
          'notification_sync_failed',
          values: {
            'syncId': syncId,
            'error_type': error.runtimeType.toString(),
          },
        ),
      );
      if (!ref.mounted) return;
      state = NotificationSyncState(report: state.report, error: error);
    }
  }
}

/// One full sync from what is stored, with no screen open: the daily
/// background refresh (2026-10-14, see DailyRefreshJob on Android). Waits for
/// the stored settings and mosques first, so the plan is never built from
/// guesses.
Future<void> refreshNotifications(ProviderContainer container) async {
  // Listened to while this runs: a provider nobody listens to is paused, and
  // the stored settings would never arrive.
  final keep = [
    container.listen(appSettingsProvider, (_, _) {}),
    container.listen(savedMosquesProvider, (_, _) {}),
    container.listen(notificationSchedulerProvider, (_, _) {}),
  ];
  try {
    await container.read(appSettingsProvider.future);
    await container.read(savedMosquesProvider.future);
    await container
        .read(notificationSchedulerProvider.notifier)
        .syncNow(trigger: 'daily_refresh');
  } finally {
    for (final k in keep) {
      k.close();
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
      onStateChange: (state) {
        unawaited(
          Diagnostics.record('app_lifecycle', values: {'state': state.name}),
        );
        if (state == AppLifecycleState.resumed) {
          ref
              .read(notificationSchedulerProvider.notifier)
              .requestSync('app_resume');
        }
      },
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
      ref
          .read(notificationSchedulerProvider.notifier)
          .requestSync('permission_change');
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
