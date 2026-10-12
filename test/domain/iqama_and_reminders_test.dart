import 'package:awqaity/src/domain/adhan_alerts.dart';
import 'package:awqaity/src/domain/mosque.dart';
import 'package:awqaity/src/domain/notification_plan.dart';
import 'package:awqaity/src/domain/prayer.dart';
import 'package:awqaity/src/domain/reminders.dart';
import 'package:awqaity/src/domain/time_model.dart';
import 'package:awqaity/src/domain/zone_offsets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Iqama and reminder math. Nothing here touches the device or the clock: every
/// value is a local time of day, exactly as AGENTS.md requires.
void main() {
  loadTimeZoneDatabase();

  final cairo = zoneOffsetsFor('Africa/Cairo');
  final day = const LocalDay(2026, 10, 12);

  PrayerIqama iqama(
    Prayer prayer, {
    int? at,
    bool reminder = false,
    int minutesBefore = 10,
  }) => PrayerIqama(
    prayer: prayer,
    iqama: at == null ? null : LocalTime(at),
    reminderEnabled: reminder,
    reminderMinutesBefore: minutesBefore,
  );

  group('schedule defaults', () {
    test('a new schedule starts entirely unconfigured', () {
      final schedule = Schedule.empty(mosqueId: 'm1');

      expect(schedule.prayers.keys, unorderedEquals(Prayer.iqamaPrayers));
      for (final prayer in Prayer.iqamaPrayers) {
        expect(schedule.iqamaFor(prayer).isConfigured, isFalse);
        expect(schedule.iqamaFor(prayer).reminderEnabled, isFalse);
      }
      expect(schedule.configuredCount, 0);
      expect(schedule.isFullyConfigured, isFalse);
      // Never invent a default time.
      expect(schedule.iqamaFor(Prayer.fajr).iqama, isNull);
    });

    test('sunrise is never an iqama prayer', () {
      final schedule = Schedule.empty();
      expect(schedule.prayers.containsKey(Prayer.sunrise), isFalse);
      expect(Prayer.iqamaPrayers, hasLength(5));
      expect(Prayer.sunrise.canHaveIqama, isFalse);
    });

    test('setting a time does not touch the other prayers', () {
      final schedule = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.fajr, at: 5 * 60 + 45));

      expect(schedule.iqamaFor(Prayer.fajr).isConfigured, isTrue);
      expect(schedule.configuredCount, 1);
      for (final prayer in [
        Prayer.dhuhr,
        Prayer.asr,
        Prayer.maghrib,
        Prayer.isha,
      ]) {
        expect(schedule.iqamaFor(prayer).isConfigured, isFalse);
      }
    });

    test('clearing a time turns the reminder off with it', () {
      final schedule = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.asr, at: 15 * 60, reminder: true))
          .withPrayer(iqama(Prayer.asr).copyWith(clearIqama: true));

      expect(schedule.iqamaFor(Prayer.asr).isConfigured, isFalse);
      expect(
        schedule.iqamaFor(Prayer.asr).hasReminder,
        isFalse,
        reason: 'an Iqama reminder needs an Iqama time to exist',
      );
    });
  });

  group('reminder math', () {
    test('the reminder fires before the iqama by the configured minutes', () {
      final asr = iqama(Prayer.asr, at: 15 * 60 + 30, reminder: true,
          minutesBefore: 15);
      expect(asr.hasReminder, isTrue);
      expect(asr.reminderOffsetMinutes, -15);

      final resolver = const ReminderResolver(180);
      final occurrence = resolver.resolve(
        Schedule.empty(mosqueId: 'm1').withPrayer(asr),
      ).firstWhere((o) => o.prayer == Prayer.asr);

      expect(occurrence.atMinutes, 15 * 60 + 15);
    });

    test('an unconfigured prayer produces no reminder but stays listed', () {
      final schedule = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.fajr, at: 5 * 60 + 45, reminder: true))
          .withPrayer(iqama(Prayer.maghrib, at: 18 * 60 + 10));

      final occurrences = const ReminderResolver(180).resolve(schedule);

      expect(occurrences, hasLength(5));
      final maghrib = occurrences.firstWhere((o) => o.prayer == Prayer.maghrib);
      expect(maghrib.hasIqama, isTrue, reason: 'the Iqama time exists');
      expect(maghrib.reminderEnabled, isFalse);
      expect(maghrib.fires, isFalse, reason: 'the reminder is off');
      // The would-be reminder time, 10 minutes before the 18:10 Iqama.
      expect(maghrib.atMinutes, 18 * 60);

      final asr = occurrences.firstWhere((o) => o.prayer == Prayer.asr);
      expect(asr.hasIqama, isFalse);
      expect(asr.atMinutes, isNull);
    });

    test('reminders are ordered by time and skip unconfigured prayers', () {
      final schedule = Schedule.empty(mosqueId: 'm1')
        ..prayers[Prayer.asr] = iqama(Prayer.asr, at: 15 * 60, reminder: true)
        ..prayers[Prayer.isha] = iqama(Prayer.isha, at: 19 * 60 + 45, reminder: true)
        ..prayers[Prayer.fajr] = iqama(Prayer.fajr, at: 5 * 60 + 45, reminder: true);

      final next = const ReminderResolver(180).nextReminder(schedule, 6 * 60);

      expect(next, isNotNull);
      expect(next!.prayer, Prayer.asr);
    });

    test('no reminders after the last iqama', () {
      final schedule = Schedule.empty(mosqueId: 'm1')
        ..prayers[Prayer.fajr] = iqama(Prayer.fajr, at: 5 * 60 + 45);

      expect(
        const ReminderResolver(180).nextReminder(schedule, 6 * 60),
        isNull,
      );
    });

    test('an isha iqama after midnight is an instant on the following day', () {
      // 00:30 stored as 30 minutes from midnight: the planner must attach it to
      // the day AFTER the 19:45 Isha Adhan.
      final resolver = const ReminderResolver(180);
      final schedule = Schedule.empty(mosqueId: 'm1');
      schedule.prayers[Prayer.isha] = iqama(Prayer.isha, at: 30, reminder: true);

      final occurrence = resolver
          .resolve(schedule)
          .firstWhere((o) => o.prayer == Prayer.isha);
      expect(occurrence.iqama!.minutes, 30);

      // The resolver reports the wall-clock time on `day` itself.
      expect(
        occurrence.iqamaInstant(day, 180),
        DateTime.utc(2026, 10, 11, 21, 30),
        reason: '00:30 local on 12 Oct is 21:30 UTC on 11 Oct',
      );
    });

    test('reminder instant precedes the iqama instant', () {
      final resolver = const ReminderResolver(180);
      final schedule = Schedule.empty(mosqueId: 'm1');
      schedule.prayers[Prayer.fajr] = iqama(
        Prayer.fajr,
        at: 5 * 60 + 45,
        reminder: true,
        minutesBefore: 15,
      );

      final occurrence = resolver.resolve(schedule).first;
      expect(
        occurrence.reminderInstant(day, 180),
        occurrence.iqamaInstant(day, 180).subtract(const Duration(minutes: 15)),
      );
    });

    test('formatting matches the prototype summary', () {
      expect(formatReminder(5 * 60 + 30), '5:30 AM');
      expect(formatReminder(13 * 60 + 5), '1:05 PM');
      expect(formatReminder(0), '12:00 AM');
      expect(formatReminder(12 * 60), '12:00 PM');
      // Wrapped past midnight.
      expect(formatReminder(-30), '11:30 PM');
    });
  });

  group('schedule resolution', () {
    Mosque mosqueWith(List<Schedule> schedules) => Mosque(
      id: 'm1',
      name: 'Masjid Al-Huda',
      address: '12 Garden Rd',
      source: MosqueSource.manual,
      schedules: schedules,
    );

    LocalTime? iqamaAt(Mosque mosque, LocalDay day, Prayer prayer) =>
        mosque.scheduleFor(day)?.iqamaFor(prayer).iqama;

    test('a single schedule applies to every day', () {
      final mosque = mosqueWith([Schedule.empty(mosqueId: 'm1')]);
      expect(iqamaAt(mosque, const LocalDay(2026, 10, 12), Prayer.fajr), isNull);
      expect(iqamaAt(mosque, const LocalDay(2027, 3, 1), Prayer.fajr), isNull);
    });

    test('a dated schedule wins on and after its effective date', () {
      final winter = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.fajr, at: 5 * 60 + 30));
      final ramadan = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.fajr, at: 4 * 60 + 15))
          .copyWith(effectiveFrom: const LocalDay(2027, 2, 20));

      final mosque = mosqueWith([winter, ramadan]);

      expect(
        iqamaAt(mosque, const LocalDay(2027, 2, 19), Prayer.fajr),
        const LocalTime(5 * 60 + 30),
        reason: 'one day before it starts',
      );
      expect(
        iqamaAt(mosque, const LocalDay(2027, 2, 20), Prayer.fajr),
        const LocalTime(4 * 60 + 15),
        reason: 'the first day it applies',
      );
      expect(
        iqamaAt(mosque, const LocalDay(2027, 4, 1), Prayer.fajr),
        const LocalTime(4 * 60 + 15),
      );
    });

    test('the latest applicable dated schedule wins', () {
      final summer = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.asr, at: 17 * 60))
          .copyWith(effectiveFrom: const LocalDay(2026, 7, 1));
      final autumn = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.asr, at: 16 * 60))
          .copyWith(effectiveFrom: const LocalDay(2026, 10, 1));

      final mosque = mosqueWith([summer, autumn]);

      expect(
        iqamaAt(mosque, const LocalDay(2026, 8, 15), Prayer.asr),
        const LocalTime(17 * 60),
      );
      expect(
        iqamaAt(mosque, const LocalDay(2026, 11, 15), Prayer.asr),
        const LocalTime(16 * 60),
      );
    });

    test('a future dated schedule does not take over early', () {
      final current = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.maghrib, at: 18 * 60));
      final next = Schedule.empty(mosqueId: 'm1')
          .withPrayer(iqama(Prayer.maghrib, at: 17 * 60 + 30))
          .copyWith(effectiveFrom: const LocalDay(2027, 1, 1));

      final mosque = mosqueWith([current, next]);

      expect(
        iqamaAt(mosque, const LocalDay(2026, 12, 31), Prayer.maghrib),
        const LocalTime(18 * 60),
      );
    });
  });

  group('adhan alert settings', () {
    test('nothing is enabled by default', () {
      final settings = AdhanAlertSettings.defaults();
      expect(settings.hasAnyEnabled, isFalse);
      expect(settings.defaultSoundMode, AdhanSoundMode.standard);
      for (final prayer in Prayer.adhanPrayers) {
        expect(settings.alertFor(prayer).enabled, isFalse);
      }
    });

    test('alerts are per prayer and independent of mosques', () {
      final settings = AdhanAlertSettings.defaults()
          .withAlert(Prayer.fajr, const AdhanAlert(enabled: true))
          .withAlert(
            Prayer.isha,
            const AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ),
          );

      expect(settings.alertFor(Prayer.fajr).enabled, isTrue);
      expect(settings.alertFor(Prayer.dhuhr).enabled, isFalse);
      expect(settings.enabledPrayers, [Prayer.fajr, Prayer.isha]);
      expect(settings.soundModeFor(Prayer.fajr), AdhanSoundMode.standard);
      expect(settings.soundModeFor(Prayer.isha), AdhanSoundMode.full);
    });

    test('a global sound mode applies to every enabled prayer', () {
      final settings = AdhanAlertSettings.defaults()
          .withSoundMode(AdhanSoundMode.short)
          .withAlert(Prayer.dhuhr, const AdhanAlert(enabled: true))
          .withAlert(Prayer.asr, const AdhanAlert(enabled: true));

      expect(settings.soundModeFor(Prayer.dhuhr), AdhanSoundMode.short);
      expect(settings.soundModeFor(Prayer.asr), AdhanSoundMode.short);
    });

    test('changing the global mode does not clear per-prayer overrides', () {
      final settings = AdhanAlertSettings.defaults()
          .withSoundMode(AdhanSoundMode.short)
          .withAlert(
            Prayer.fajr,
            const AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ),
          )
          .withSoundMode(AdhanSoundMode.standard);

      expect(settings.soundModeFor(Prayer.fajr), AdhanSoundMode.full);
      expect(settings.soundModeFor(Prayer.maghrib), AdhanSoundMode.standard);
    });

    test('clearing an override falls back to the global mode', () {
      final settings = AdhanAlertSettings.defaults()
          .withSoundMode(AdhanSoundMode.short)
          .withAlert(
            Prayer.isha,
            AdhanAlert(enabled: true, soundModeOverride: AdhanSoundMode.full),
          )
          .withAlert(
            Prayer.isha,
            AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ).copyWith(clearOverride: true),
          );

      expect(settings.soundModeFor(Prayer.isha), AdhanSoundMode.short);
    });

    test('sunrise can carry an adhan alert', () {
      final settings = AdhanAlertSettings.defaults().withAlert(
        Prayer.sunrise,
        const AdhanAlert(enabled: true),
      );
      expect(settings.alertFor(Prayer.sunrise).enabled, isTrue);
      // ...but never an Iqama.
      expect(Prayer.sunrise.canHaveIqama, isFalse);
    });
  });

  group('notification ids', () {
    test('the same day and prayer always produces the same id', () {
      expect(
        notificationId(NotificationKind.adhan, Prayer.fajr, day),
        notificationId(NotificationKind.adhan, Prayer.fajr, day),
      );
    });

    test('adhan and iqama reminders for the same prayer never collide', () {
      final adhan = notificationId(NotificationKind.adhan, Prayer.fajr, day);
      final iqama = notificationId(NotificationKind.iqama, Prayer.fajr, day);
      expect(adhan, isNot(iqama));
    });

    test('every prayer gets a distinct id per kind and day', () {
      final ids = <int>{};
      for (final kind in NotificationKind.values) {
        for (final prayer in Prayer.adhanPrayers) {
          for (var offset = 0; offset < 7; offset++) {
            final next = day.addDays(offset);
            expect(
              ids.add(notificationId(kind, prayer, next)),
              isTrue,
              reason: '$kind $prayer $next should be unique',
            );
          }
        }
      }
      expect(ids, hasLength(2 * 6 * 7));
    });
  });

  group('notification plan', () {
    Mosque mosqueWith(List<Schedule> schedules) => Mosque(
      id: 'm1',
      name: 'Masjid Al-Huda',
      address: '12 Garden Rd',
      source: MosqueSource.manual,
      schedules: schedules,
    );

    /// Cairo prayer times for 2026-10-12, used as a realistic input.
    final timesFor = <LocalDay, Map<Prayer, int>>{
      day: const {
        Prayer.fajr: 5 * 60 + 28,
        Prayer.sunrise: 6 * 60 + 55,
        Prayer.dhuhr: 12 * 60 + 43,
        Prayer.asr: 15 * 60 + 59,
        Prayer.maghrib: 18 * 60 + 28,
        Prayer.isha: 19 * 60 + 45,
      },
    };

    NotificationPlanInput input({
      Mosque? mosque,
      AdhanAlertSettings alerts = const AdhanAlertSettings(),
      DateTime? now,
      int windowDays = 7,
      int Function(LocalDay day)? zoneOffsetFor,
    }) => NotificationPlanInput(
      today: day,
      now: now ?? DateTime.utc(2026, 10, 12, 6, 0),
      prayerTimeOf: timesFor,
      zoneOffsetFor: zoneOffsetFor ?? (_) => 180,
      adhanAlerts: alerts,
      activeMosque: mosque,
      windowDays: windowDays,
    );

    test('nothing is planned when nothing is enabled', () {
      final planned = const NotificationPlanner().plan(input());
      expect(planned, isEmpty);
    });

    test('adhan alerts are planned for the enabled prayers only', () {
      final planned = const NotificationPlanner().plan(
        input(
          alerts: AdhanAlertSettings.defaults()
              .withAlert(Prayer.fajr, const AdhanAlert(enabled: true))
              .withAlert(
                Prayer.maghrib,
                const AdhanAlert(enabled: true),
              ),
          windowDays: 1,
        ),
      );

      expect(planned, hasLength(2));
      expect(planned.map((p) => p.prayer), containsAll([Prayer.fajr, Prayer.maghrib]));
      expect(planned.every((p) => p.kind == NotificationKind.adhan), isTrue);
      expect(
        planned.firstWhere((p) => p.prayer == Prayer.fajr).at,
        DateTime.utc(2026, 10, 12, 2, 28),
        reason: '05:28 local in UTC+3',
      );
    });

    test('adhan alerts ride the global sound mode', () {
      final planned = const NotificationPlanner().plan(
        input(
          alerts: AdhanAlertSettings.defaults()
              .withSoundMode(AdhanSoundMode.full)
              .withAlert(Prayer.asr, const AdhanAlert(enabled: true)),
          windowDays: 1,
        ),
      );

      expect(planned.single.soundMode, AdhanSoundMode.full);
      expect(planned.single.mosqueId, isEmpty, reason: 'alerts are global');
    });

    test('iqama reminders come from the active mosque only', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.dhuhr] = iqama(
            Prayer.dhuhr,
            at: 13 * 60,
            reminder: true,
            minutesBefore: 10,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        input(mosque: mosque, windowDays: 1),
      );

      expect(planned, hasLength(1));
      expect(planned.single.kind, NotificationKind.iqama);
      expect(planned.single.mosqueId, 'm1');
      expect(planned.single.at, DateTime.utc(2026, 10, 12, 9, 50));
    });

    test('an unconfigured iqama never produces a reminder', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.dhuhr] = iqama(
            Prayer.dhuhr,
            reminder: true,
            minutesBefore: 10,
          ),
      ]);

      expect(
        const NotificationPlanner().plan(input(mosque: mosque, windowDays: 1)),
        isEmpty,
      );
    });

    test('a disabled reminder produces nothing', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.dhuhr] = iqama(Prayer.dhuhr, at: 13 * 60),
      ]);

      expect(
        const NotificationPlanner().plan(input(mosque: mosque, windowDays: 1)),
        isEmpty,
      );
    });

    test('adhan and iqama streams are planned side by side', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.dhuhr] = iqama(
            Prayer.dhuhr,
            at: 13 * 60,
            reminder: true,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        input(
          mosque: mosque,
          alerts: AdhanAlertSettings.defaults().withAlert(
            Prayer.dhuhr,
            const AdhanAlert(enabled: true),
          ),
          windowDays: 1,
        ),
      );

      expect(planned, hasLength(2));
      expect(
        planned.where((p) => p.kind == NotificationKind.adhan).single.at,
        DateTime.utc(2026, 10, 12, 9, 43),
      );
      expect(
        planned.where((p) => p.kind == NotificationKind.iqama).single.at,
        DateTime.utc(2026, 10, 12, 9, 50),
      );
      // planned in time order
      expect(planned.first.at.isBefore(planned.last.at), isTrue);
    });

    test('the rolling window covers the requested number of days', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.fajr] = iqama(
            Prayer.fajr,
            at: 5 * 60 + 45,
            reminder: true,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        input(mosque: mosque, windowDays: 7),
      );

      expect(planned, hasLength(7));
      // Fajr Iqama 05:45, reminder 10 minutes before → 05:35 local = 02:35 UTC.
      expect(planned.first.at, DateTime.utc(2026, 10, 12, 2, 35));
      expect(planned.last.at, DateTime.utc(2026, 10, 18, 2, 35));
    });

    test('a dst change inside the window is honoured', () {
      // Egypt leaves DST on the night of 29 Oct 2026: offsets go from +3 to +2.
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.fajr] = iqama(
            Prayer.fajr,
            at: 5 * 60 + 45,
            reminder: true,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        NotificationPlanInput(
          today: const LocalDay(2026, 10, 28),
          now: DateTime.utc(2026, 10, 28, 6, 0),
          prayerTimeOf: {
            const LocalDay(2026, 10, 28): {Prayer.fajr: 5 * 60 + 45},
          },
          zoneOffsetFor: (d) => d.day >= 29 ? 120 : 180,
          adhanAlerts: const AdhanAlertSettings(),
          activeMosque: mosque,
          windowDays: 3,
        ),
      );

      expect(planned, hasLength(3));
      // 05:35 local is 02:35 UTC while the offset is +3.
      expect(planned[0].at, DateTime.utc(2026, 10, 28, 2, 35));
      // After the clocks go back, the same local time is 03:35 UTC.
      expect(planned[2].at, DateTime.utc(2026, 10, 30, 3, 35));
    });

    test('a plan is identical when rebuilt, so ids stay stable', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.isha] = iqama(
            Prayer.isha,
            at: 20 * 60,
            reminder: true,
            minutesBefore: 5,
          ),
      ]);
      final alerts = AdhanAlertSettings.defaults().withAlert(
        Prayer.fajr,
        const AdhanAlert(enabled: true),
      );

      final first = const NotificationPlanner().plan(
        input(mosque: mosque, alerts: alerts, windowDays: 3),
      );
      final second = const NotificationPlanner().plan(
        input(mosque: mosque, alerts: alerts, windowDays: 3),
      );

      expect(first.map((p) => p.id), second.map((p) => p.id));
      expect(first.map((p) => p.at), second.map((p) => p.at));
    });

    test('an isha iqama after midnight is planned for the following day', () {
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.isha] = iqama(
            Prayer.isha,
            at: 30,
            reminder: true,
            minutesBefore: 30,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        input(mosque: mosque, windowDays: 1),
      );

      expect(planned, hasLength(1));
      // Isha Adhan is 19:45 on 12 Oct; the 00:30 Iqama belongs to 13 Oct local,
      // so its 00:00 reminder is 21:00 UTC on 12 Oct.
      expect(planned.single.at, DateTime.utc(2026, 10, 12, 21, 0));
    });

    test('past reminders are still planned; filtering is the caller job', () {
      // The planner is pure and knows nothing about "now" beyond what it is given,
      // so a reminder earlier today remains listed. The data layer drops it.
      final mosque = mosqueWith([
        Schedule.empty(mosqueId: 'm1')
          ..prayers[Prayer.fajr] = iqama(
            Prayer.fajr,
            at: 5 * 60 + 45,
            reminder: true,
          ),
      ]);

      final planned = const NotificationPlanner().plan(
        input(mosque: mosque, windowDays: 1),
      );
      expect(planned, hasLength(1));
      expect(
        planned.single.isInPast(DateTime.utc(2026, 10, 12, 6, 0)),
        isTrue,
      );
    });
  });

  group('time model', () {
    test('local time wraps past midnight', () {
      expect(LocalTime(23 * 60 + 50).plusMinutes(20), LocalTime(10));
      expect(LocalTime(0).plusMinutes(-10), LocalTime(23 * 60 + 50));
      expect(LocalTime(0).plusMinutes(1440), LocalTime.zero);
    });

    test('local day arithmetic crosses months and years', () {
      expect(const LocalDay(2026, 10, 12).addDays(20), const LocalDay(2026, 11, 1));
      expect(const LocalDay(2026, 12, 31).addDays(1), const LocalDay(2027, 1, 1));
      expect(const LocalDay(2027, 3, 1).addDays(-1), const LocalDay(2027, 2, 28));
      expect(const LocalDay(2026, 1, 1).daysUntil(const LocalDay(2026, 12, 31)), 364);
    });

    test('zone offsets resolve through the injected resolver', () {
      expect(cairo.offsetMinutesAt(DateTime.utc(2026, 10, 12, 12)), 180);
      expect(cairo.zoneName, 'Africa/Cairo');
    });
  });
}

