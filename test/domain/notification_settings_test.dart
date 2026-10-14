import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/extra_times.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/notification_channels.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';

/// The per-prayer notification settings (decided 2026-10-13): vibrate, a
/// reminder before the Adhan, ringing in silent, full screen, and travel mode's
/// manual Iqama pause — and how each one reaches the plan.
void main() {
  const day = LocalDay(2026, 10, 12);

  /// Cairo, 2026-10-12, local minutes.
  const times = {
    Prayer.fajr: 5 * 60 + 28,
    Prayer.sunrise: 6 * 60 + 55,
    Prayer.dhuhr: 12 * 60 + 43,
    Prayer.asr: 15 * 60 + 59,
    Prayer.maghrib: 18 * 60 + 28,
    Prayer.isha: 19 * 60 + 45,
  };

  Mosque mosqueWithFajrReminder() {
    final schedule = Schedule.empty(mosqueId: 'm1').withPrayer(
      const PrayerIqama(
        prayer: Prayer.fajr,
        iqama: LocalTime(5 * 60 + 45),
        reminderEnabled: true,
        reminderMinutesBefore: 10,
      ),
    );
    return Mosque(
      id: 'm1',
      name: 'Masjid',
      address: '',
      source: MosqueSource.manual,
      schedules: [schedule],
    );
  }

  List<PlannedNotification> plan(
    AdhanAlertSettings alerts, {
    Mosque? mosque,
    bool paused = false,
    Map<Prayer, int> dayTimes = times,
  }) => const NotificationPlanner().plan(
    NotificationPlanInput(
      today: day,
      now: DateTime.utc(2026, 10, 12, 0, 0),
      prayerTimeOf: {day: dayTimes},
      zoneOffsetFor: (_) => 180,
      adhanAlerts: alerts,
      activeMosque: mosque,
      iqamaRemindersPaused: paused,
      windowDays: 1,
    ),
  );

  DateTime at(int minutes) =>
      NotificationPlanner.instantFor(day, minutes, 180);

  group('defaults', () {
    test('a new alert vibrates, has no early reminder and respects silent', () {
      const alert = AdhanAlert(enabled: true);
      expect(alert.vibrate, isTrue);
      expect(alert.preAdhanMinutes, isNull);
      expect(alert.hasPreAdhanReminder, isFalse);
      expect(
        alert.ringInSilent,
        isFalse,
        reason: 'never surprise anyone in a quiet room by default',
      );
    });

    test('full screen is off until the user turns it on', () {
      expect(AdhanAlertSettings.defaults().fullScreen, isFalse);
    });

    test('nothing is paused and nothing followed until the user says so', () {
      const travel = TravelSettings();
      expect(travel.pauseAllIqamaReminders, isFalse);
      expect(travel.travelMode, isFalse);
      expect(travel.followsLocation, isFalse);
      expect(
        travel.followLocation,
        isTrue,
        reason: 'turning travel mode on follows the phone unless told not to',
      );
    });

    test('an early reminder outside 1..120 minutes is a programming error', () {
      expect(
        () => AdhanAlert(enabled: true, preAdhanMinutes: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AdhanAlert(enabled: true, preAdhanMinutes: 121),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('reminder before the Adhan', () {
    test('fires the chosen minutes ahead, as its own notification', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true, preAdhanMinutes: 15),
        ),
      );

      final early = planned.singleWhere(
        (n) => n.kind == NotificationKind.preAdhan,
      );
      final adhan = planned.singleWhere((n) => n.kind == NotificationKind.adhan);
      expect(early.prayer, Prayer.fajr);
      expect(early.at, at(5 * 60 + 13));
      expect(early.minutesBefore, 15);
      expect(early.soundMode, isNull, reason: 'a reminder, not an Adhan');
      expect(early.id, isNot(adhan.id));
    });

    test('works with the Adhan alert itself switched off', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: false, preAdhanMinutes: 15),
        ),
      );
      expect(planned.map((n) => n.kind), [NotificationKind.preAdhan]);
    });

    test('a reminder before sunrise is allowed: it marks the end of Fajr', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.sunrise,
          const AdhanAlert(enabled: false, preAdhanMinutes: 20),
        ),
      );
      expect(planned.single.prayer, Prayer.sunrise);
      expect(planned.single.at, at(6 * 60 + 35));
    });

    test('crossing midnight lands on the evening before', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.isha,
          const AdhanAlert(enabled: false, preAdhanMinutes: 20),
        ),
        dayTimes: {...times, Prayer.isha: 10},
      );
      expect(
        planned.single.at,
        at(10).subtract(const Duration(minutes: 20)),
      );
      expect(planned.single.at.isBefore(at(0)), isTrue);
    });

    test('is independent of Iqama reminders', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: false, preAdhanMinutes: 15),
        ),
        mosque: mosqueWithFajrReminder(),
      );
      expect(
        planned.map((n) => n.kind).toSet(),
        {NotificationKind.preAdhan, NotificationKind.iqama},
      );
    });
  });

  group('how an Adhan alert behaves', () {
    test('vibration off reaches the plan, for the alert and its reminder', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.dhuhr,
          const AdhanAlert(enabled: true, vibrate: false, preAdhanMinutes: 5),
        ),
      );
      expect(planned.every((n) => !n.vibrate), isTrue);
    });

    test('ring in silent applies to any Adhan that makes a sound', () {
      for (final (mode, rings) in [
        (AdhanSoundMode.full, true),
        (AdhanSoundMode.short, true),
        (AdhanSoundMode.standard, true),
        (AdhanSoundMode.silent, false),
      ]) {
        final planned = plan(
          AdhanAlertSettings.defaults().withAlert(
            Prayer.asr,
            AdhanAlert(
              enabled: true,
              soundModeOverride: mode,
              ringInSilent: true,
            ),
          ),
        );
        expect(planned.single.ringInSilent, rings, reason: mode.name);
      }
    });

    test('full screen is carried by Adhan alerts, never by reminders', () {
      final planned = plan(
        AdhanAlertSettings.defaults()
            .copyWith(fullScreen: true)
            .withAlert(
              Prayer.maghrib,
              const AdhanAlert(enabled: true, preAdhanMinutes: 10),
            ),
        mosque: mosqueWithFajrReminder(),
      );
      for (final n in planned) {
        expect(
          n.fullScreen,
          n.kind == NotificationKind.adhan,
          reason: '${n.kind}',
        );
      }
    });
  });

  group('pausing Iqama reminders', () {
    test('a paused plan has no Iqama reminders, and keeps every Adhan alert', () {
      final alerts = AdhanAlertSettings.defaults()
          .withAlert(Prayer.fajr, const AdhanAlert(enabled: true))
          .withAlert(
            Prayer.isha,
            const AdhanAlert(enabled: true, preAdhanMinutes: 10),
          );

      final normal = plan(alerts, mosque: mosqueWithFajrReminder());
      final paused = plan(
        alerts,
        mosque: mosqueWithFajrReminder(),
        paused: true,
      );

      expect(
        normal.where((n) => n.kind == NotificationKind.iqama),
        hasLength(1),
      );
      expect(paused.where((n) => n.kind == NotificationKind.iqama), isEmpty);
      expect(
        paused.map((n) => n.id).toSet(),
        normal
            .where((n) => n.kind != NotificationKind.iqama)
            .map((n) => n.id)
            .toSet(),
        reason: 'AGENTS.md: Adhan alerts are never paused',
      );
    });
  });

  group('notification ids', () {
    test('are unique across every kind, prayer and day for over a year', () {
      final ids = <int>{};
      for (var offset = 0; offset < 400; offset++) {
        final d = day.addDays(offset);
        for (final kind in NotificationKind.values) {
          for (final prayer in Prayer.adhanPrayers) {
            expect(ids.add(notificationId(kind, prayer, d)), isTrue);
          }
        }
      }
    });

    test('stay positive 32-bit ints for Android', () {
      final late = notificationId(
        NotificationKind.iqama,
        Prayer.isha,
        const LocalDay(2200, 12, 31),
      );
      expect(late, greaterThan(0));
      expect(late, lessThan(0x7FFFFFFF));
    });
  });

  group('ringing on silent (2026-10-14)', () {
    test('the reminder before the Adhan rings on silent on its own switch', () {
      final planned = plan(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.dhuhr,
          const AdhanAlert(
            enabled: true,
            preAdhanMinutes: 10,
            preAdhanRingInSilent: true,
          ),
        ),
      );
      final adhan = planned.singleWhere((n) => n.kind == NotificationKind.adhan);
      final before = planned.singleWhere(
        (n) => n.kind == NotificationKind.preAdhan,
      );
      expect(adhan.ringInSilent, isFalse, reason: 'its own switch is off');
      expect(before.ringInSilent, isTrue);
      expect(channelFor(before).alarmStream, isTrue);
      expect(channelFor(before).id, 'jamaah_reminder_vib_alarm');
    });

    test('Jama’ah reminders and extra-time alerts follow the reminder switch', () {
      for (final ring in [false, true]) {
        final planned = const NotificationPlanner().plan(
          NotificationPlanInput(
            today: day,
            now: DateTime.utc(2026, 10, 12),
            prayerTimeOf: {day: times},
            zoneOffsetFor: (_) => 180,
            adhanAlerts: AdhanAlertSettings.defaults(),
            activeMosque: mosqueWithFajrReminder(),
            jamaahReminders: JamaahReminderSettings(ringInSilent: ring),
            extraTimes: [
              ExtraTimeAt(
                time: ExtraTime.imsak,
                day: day,
                at: const LocalTime(5 * 60 + 18),
                utc: at(5 * 60 + 18),
              ),
            ],
            windowDays: 1,
          ),
        );
        expect(planned, hasLength(2));
        for (final n in planned) {
          expect(n.ringInSilent, ring, reason: n.kind.name);
          expect(channelFor(n).alarmStream, ring, reason: n.kind.name);
        }
      }
    });

    test('a silent Jama’ah reminder stays silent', () {
      final n = PlannedNotification(
        id: 1,
        kind: NotificationKind.iqama,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: 'm1',
        reminderSound: ReminderSound.silent,
        ringInSilent: true,
      );
      expect(channelFor(n).alarmStream, isFalse);
    });

    test('one switch for every Adhan, and what it reads back', () {
      final none = AdhanAlertSettings.defaults();
      expect(none.ringInSilentFor(RingTarget.adhan), RingCoverage.none);
      final all = none.withRingInSilentForAll(RingTarget.adhan, on: true);
      expect(all.ringInSilentFor(RingTarget.adhan), RingCoverage.all);
      expect(
        Prayer.adhanPrayers.every((p) => all.alertFor(p).ringInSilent),
        isTrue,
      );
      expect(all.ringInSilentFor(RingTarget.preAdhan), RingCoverage.none);
      final some = all.withAlert(
        Prayer.fajr,
        all.alertFor(Prayer.fajr).copyWith(ringInSilent: false),
      );
      expect(some.ringInSilentFor(RingTarget.adhan), RingCoverage.some);
      final before = none.withRingInSilentForAll(RingTarget.preAdhan, on: true);
      expect(
        Prayer.adhanPrayers.every((p) => before.alertFor(p).preAdhanRingInSilent),
        isTrue,
      );
      expect(before.ringInSilentFor(RingTarget.adhan), RingCoverage.none);
    });
  });
}
