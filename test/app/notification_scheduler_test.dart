import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/extra_times.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';

/// From stored state to what the phone is asked to show: the 7-day plan built
/// from real prayer times, and the scheduler re-syncing after every change that
/// matters (AGENTS.md: reschedule on any setting, Iqama edit, active mosque or
/// place change).
void main() {
  final t = AppLocalizationsEn();

  setUpAll(loadTimeZoneDatabase);

  group('the 7-day plan', () {
    PrayerTimesCalculator calculatorFor(
      double lat,
      double lng,
      ZoneOffsets zone,
    ) => PrayerTimesCalculator(
      latitude: lat,
      longitude: lng,
      zone: zone,
      method: CalculationMethod.muslimWorldLeague,
      madhab: Madhab.standard,
      highLatitudeRule: HighLatitudeRule.middleOfTheNight,
      minuteOffsets: const {},
    );

    test(
      'an enabled Adhan is planned at the computed time on each of 7 days',
      () {
        final zone = zoneOffsetsFor('Africa/Cairo');
        final calculator = calculatorFor(30.0444, 31.2357, zone);
        final plan = buildNotificationPlan(
          calculator: calculator,
          zone: zone,
          nowUtc: DateTime.utc(2026, 10, 13, 0, 0),
          alerts: AdhanAlertSettings.defaults().withAlert(
            Prayer.dhuhr,
            const AdhanAlert(enabled: true),
          ),
          travel: const TravelSettings(),
          activeMosque: null,
        );

        expect(plan, hasLength(kPlanWindowDays));
        for (final n in plan) {
          final day = LocalMoment.inZone(zone: zone, utcInstant: n.at).day;
          final expected = zone.utcInstantOf(
            day: day,
            time: LocalTime(calculator.forDay(day).times[Prayer.dhuhr]!),
          );
          expect(n.at, expected, reason: '$day');
        }
      },
    );

    test('a full Adhan carries its recording; a short one its clip', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      List<PlannedNotification> planFor(AdhanAlertSettings alerts) =>
          buildNotificationPlan(
            calculator: calculatorFor(30.0444, 31.2357, zone),
            zone: zone,
            nowUtc: DateTime.utc(2026, 10, 13, 0, 0),
            alerts: alerts,
            travel: const TravelSettings(),
            activeMosque: null,
          );
      final alerts = AdhanAlertSettings.defaults()
          .withAlert(
            Prayer.fajr,
            const AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.full,
            ),
          )
          .withAlert(
            Prayer.dhuhr,
            const AdhanAlert(
              enabled: true,
              soundModeOverride: AdhanSoundMode.short,
            ),
          )
          .copyWith(fullRecording: 'ahmed_el_haddad');

      final plan = planFor(alerts);
      expect(
        plan.where((n) => n.prayer == Prayer.fajr).map((n) => n.recordingAsset),
        everyElement(adhanRecordingById('ahmed_el_haddad').asset),
      );
      expect(
        plan
            .where((n) => n.prayer == Prayer.dhuhr)
            .map((n) => n.recordingAsset),
        everyElement(ShortAdhan.azanShort.asset),
        reason: 'a short Adhan shown full screen plays the chosen clip',
      );
      expect(
        planFor(alerts.copyWith(shortAdhan: ShortAdhan.adhanVerseTwo))
            .where((n) => n.prayer == Prayer.dhuhr)
            .map((n) => (n.recordingAsset, n.shortAdhan)),
        everyElement((
          ShortAdhan.adhanVerseTwo.asset,
          ShortAdhan.adhanVerseTwo,
        )),
      );
    });

    test('the plan reaches two weeks ahead', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      final plan = buildNotificationPlan(
        calculator: calculatorFor(30.0444, 31.2357, zone),
        zone: zone,
        nowUtc: DateTime.utc(2026, 10, 13, 0, 0),
        alerts: AdhanAlertSettings.defaults().withAlert(
          Prayer.dhuhr,
          const AdhanAlert(enabled: true),
        ),
        travel: const TravelSettings(),
        activeMosque: null,
      );
      expect(kPlanWindowDays, 14);
      expect(plan, hasLength(14));
      // Thirteen days apart, give or take Dhuhr's drift of a minute or two.
      expect(
        plan.last.at.difference(plan.first.at).inHours,
        greaterThanOrEqualTo(13 * 24 - 1),
        reason: 'so a phone left alone for two weeks keeps its alerts',
      );
    });

    group('extra-time alerts (2026-10-14)', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      final now = DateTime.utc(2026, 10, 14, 10, 0);
      List<PlannedNotification> planWith(
        ExtraTimesSettings extra, {
        InFlightHold? hold,
      }) => buildNotificationPlan(
        calculator: calculatorFor(30.0444, 31.2357, zone),
        zone: zone,
        nowUtc: now,
        alerts: AdhanAlertSettings.defaults(),
        travel: const TravelSettings(),
        activeMosque: null,
        extraTimes: extra,
        inFlight: hold,
      );

      test('one alert a day for each alerted time, none for the others', () {
        final plan = planWith(
          const ExtraTimesSettings(alerts: {ExtraTime.qiyam}),
        );
        expect(plan, hasLength(kPlanWindowDays));
        expect(plan.every((n) => n.extraTime == ExtraTime.qiyam), isTrue);
        expect(plan.map((n) => n.text(t).title).toSet(), {t.extraQiyam});
      });

      test('after midnight, the night in progress keeps its alert', () {
        // 01:00 in Cairo on 15 October: tonight's last third is still ahead.
        final early = DateTime.utc(2026, 10, 14, 22, 0);
        final plan = buildNotificationPlan(
          calculator: calculatorFor(30.0444, 31.2357, zone),
          zone: zone,
          nowUtc: early,
          alerts: AdhanAlertSettings.defaults(),
          travel: const TravelSettings(),
          activeMosque: null,
          extraTimes: const ExtraTimesSettings(alerts: {ExtraTime.qiyam}),
        );
        final first = plan.first.at;
        expect(first.isAfter(early), isTrue);
        expect(
          first.difference(early),
          lessThan(const Duration(hours: 4)),
          reason: 'the alert at about 02:40 tonight, not tomorrow night',
        );
      });

      test('nothing while none is alerted', () {
        expect(planWith(const ExtraTimesSettings()), isEmpty);
      });

      test('held by in-flight mode like everything else', () {
        final until = now.add(const Duration(days: 2));
        final plan = planWith(
          const ExtraTimesSettings(alerts: {ExtraTime.imsak}),
          hold: InFlightHold(pausedUntil: until),
        );
        expect(plan.every((n) => !n.at.isBefore(until)), isTrue);
        expect(plan, isNotEmpty);
      });
    });

    group('in-flight mode’s hold', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      final now = DateTime.utc(2026, 10, 14, 10, 0);
      final alerts = AdhanAlertSettings.defaults()
          .withAlert(Prayer.maghrib, const AdhanAlert(enabled: true))
          .withAlert(Prayer.isha, const AdhanAlert(enabled: true));
      List<PlannedNotification> planWith(InFlightHold? hold) =>
          buildNotificationPlan(
            calculator: calculatorFor(30.0444, 31.2357, zone),
            zone: zone,
            nowUtc: now,
            alerts: alerts,
            travel: const TravelSettings(),
            activeMosque: null,
            inFlight: hold,
          );

      test('holds the regular alerts and alerts the projected prayer', () {
        final until = now.add(const Duration(hours: 4));
        final projected = now.add(const Duration(hours: 6, minutes: 3));
        final plan = planWith(
          InFlightHold(
            pausedUntil: until,
            prayer: Prayer.maghrib,
            at: projected,
          ),
        );
        final regular = plan.where((n) => !n.estimated);
        expect(regular.every((n) => !n.at.isBefore(until)), isTrue);
        expect(regular, isNotEmpty, reason: 'later days are kept');
        final estimated = plan.where((n) => n.estimated).single;
        expect(estimated.prayer, Prayer.maghrib);
        expect(estimated.at, projected);
        expect(estimated.id, inFlightAlertId(Prayer.maghrib));
        expect(estimated.soundMode, alerts.soundModeFor(Prayer.maghrib));
      });

      test('no projected alert for a prayer whose alert is off', () {
        final plan = planWith(
          InFlightHold(
            pausedUntil: now.add(const Duration(hours: 4)),
            prayer: Prayer.asr,
            at: now.add(const Duration(hours: 2)),
          ),
        );
        expect(plan.where((n) => n.estimated), isEmpty);
      });

      test('an expired hold changes nothing', () {
        expect(
          planWith(
            InFlightHold(
              pausedUntil: now.subtract(const Duration(minutes: 1)),
              prayer: Prayer.maghrib,
              at: now.add(const Duration(hours: 2)),
            ),
          ).map((n) => n.id),
          planWith(null).map((n) => n.id),
        );
      });

      test('the estimated alert says it is estimated', () {
        final text = notificationText(
          t,
          adhanAlert(alerts, Prayer.maghrib, at: now, id: 1, estimated: true),
          mosqueName: (_) => null,
        );
        expect(text.body, t.notifInFlightBody(t.prayerMaghrib));
      });
    });

    test('a daylight-saving change inside the window is honoured', () {
      // New York leaves DST on 2026-11-01: Fajr must move by the clock change
      // on the right day, not keep the offset of the first day.
      final zone = zoneOffsetsFor('America/New_York');
      final calculator = calculatorFor(40.7128, -74.0060, zone);
      final plan = buildNotificationPlan(
        calculator: calculator,
        zone: zone,
        nowUtc: DateTime.utc(2026, 10, 29, 12),
        alerts: AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true),
        ),
        travel: const TravelSettings(),
        activeMosque: null,
      );

      final days = {
        for (final n in plan)
          LocalMoment.inZone(zone: zone, utcInstant: n.at).day: n,
      };
      for (final entry in days.entries) {
        final expected = zone.utcInstantOf(
          day: entry.key,
          time: LocalTime(calculator.forDay(entry.key).times[Prayer.fajr]!),
        );
        expect(entry.value.at, expected, reason: '${entry.key}');
      }
      expect(days.keys, contains(const LocalDay(2026, 11, 2)));
    });

    test('either pause keeps Adhan alerts and drops Iqama reminders', () {
      final zone = zoneOffsetsFor('Africa/Cairo');
      final mosque = Mosque(
        id: 'm1',
        name: 'Masjid',
        address: '',
        source: MosqueSource.manual,
        schedules: [
          Schedule.empty(mosqueId: 'm1').withPrayer(
            const PrayerIqama(
              prayer: Prayer.asr,
              iqama: LocalTime(16 * 60 + 15),
              reminderEnabled: true,
            ),
          ),
        ],
      );
      List<PlannedNotification> planWith(
        TravelSettings travel, {
        Mosque? active,
      }) => buildNotificationPlan(
        calculator: calculatorFor(30.0444, 31.2357, zone),
        zone: zone,
        nowUtc: DateTime.utc(2026, 10, 13, 0),
        alerts: AdhanAlertSettings.defaults().withAlert(
          Prayer.asr,
          const AdhanAlert(enabled: true),
        ),
        travel: travel,
        activeMosque: active ?? mosque,
      );

      final quiet = buildNotificationPlan(
        calculator: calculatorFor(30.0444, 31.2357, zone),
        zone: zone,
        nowUtc: DateTime.utc(2026, 10, 13, 0),
        alerts: AdhanAlertSettings.defaults(),
        travel: const TravelSettings(),
        activeMosque: mosque,
        reminders: const JamaahReminderSettings(
          sound: ReminderSound.silent,
          vibrate: false,
        ),
      );
      expect(quiet, hasLength(kPlanWindowDays));
      expect(quiet.map((n) => (n.reminderSound, n.vibrate)).toSet(), {
        (ReminderSound.silent, false),
      });

      final home = planWith(const TravelSettings());
      final all = planWith(const TravelSettings(pauseAllIqamaReminders: true));
      final thisMosque = planWith(
        const TravelSettings(),
        active: mosque.copyWith(remindersPaused: true),
      );
      expect(
        home.where((n) => n.kind == NotificationKind.iqama),
        hasLength(kPlanWindowDays),
      );
      for (final paused in [all, thisMosque]) {
        expect(paused.where((n) => n.kind == NotificationKind.iqama), isEmpty);
        expect(
          paused.where((n) => n.kind == NotificationKind.adhan),
          hasLength(kPlanWindowDays),
        );
      }
    });
  });

  test('the full-screen time needs no locale data, in either clock', () {
    expect(plainClockTime(LocalTime.of(5, 6), use24Hour: true), '05:06');
    expect(plainClockTime(LocalTime.of(5, 6), use24Hour: false), '5:06 AM');
    expect(plainClockTime(LocalTime.of(0, 30), use24Hour: false), '12:30 AM');
    expect(plainClockTime(LocalTime.of(12, 0), use24Hour: false), '12:00 PM');
    expect(plainClockTime(LocalTime.of(19, 45), use24Hour: false), '7:45 PM');
  });

  group('the words', () {
    test('Adhan, early reminder and Iqama say what they are', () {
      PlannedNotification of(NotificationKind kind, Prayer prayer) =>
          PlannedNotification(
            id: 1,
            kind: kind,
            prayer: prayer,
            at: DateTime.utc(2026),
            soundMode: null,
            mosqueId: 'm1',
            minutesBefore: 10,
          );
      String? name(String id) => id == 'm1' ? 'Masjid al-Nour' : null;

      final adhan = notificationText(
        t,
        of(NotificationKind.adhan, Prayer.fajr),
        mosqueName: name,
      );
      expect(adhan.title, t.notifAdhanTitle(t.prayerFajr));
      expect(adhan.body, t.notifAdhanBody(t.prayerFajr));

      final iqama = notificationText(
        t,
        of(NotificationKind.iqama, Prayer.asr),
        mosqueName: name,
      );
      expect(iqama.title, 'حيّ على الصلاة');
      expect(iqama.title, t.notifIqamaCall);
      expect(iqama.body, t.notifIqamaBody(t.prayerAsr, 10, 'Masjid al-Nour'));
      expect(
        notificationText(
          t,
          of(NotificationKind.iqama, Prayer.asr),
          mosqueName: (_) => null,
        ).body,
        t.notifIqamaBodyNoMosque(t.prayerAsr, 10),
        reason: 'a mosque without a name never leaves a dangling "at"',
      );

      final sunrise = notificationText(
        t,
        of(NotificationKind.preAdhan, Prayer.sunrise),
        mosqueName: name,
      );
      expect(sunrise.body, t.notifPreSunriseBody);
    });
  });

  group('the scheduler', () {
    late AppDatabase db;
    late FakeNotificationGateway gateway;
    late ProviderContainer container;
    late MosqueRepository mosques;
    late SettingsRepository settings;

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      gateway = FakeNotificationGateway();
      final clock = FixedClock(DateTime.utc(2026, 10, 13, 6, 0));
      container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(clock),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
        ],
      );
      mosques = MosqueRepository(db, clock: clock);
      settings = SettingsRepository(db);
      await settings.setLocation(cairo.toStored());
      container.listen(notificationSchedulerProvider, (_, _) {});
    });

    tearDown(() async {
      container.dispose();
      await db.close();
    });

    /// Lets the streams deliver and the coalesced sync finish.
    Future<void> settle() async {
      for (var i = 0; i < 10; i++) {
        await pumpEventQueue();
      }
      await container.read(notificationSchedulerProvider.notifier).syncNow();
    }

    Iterable<ScheduledKind> kinds() => gateway.scheduled.values.map(
      (i) => (kind: i.planned.kind, prayer: i.planned.prayer),
    );

    test('nothing is scheduled until something is turned on', () async {
      await settle();
      expect(gateway.scheduled, isEmpty);
    });

    test('turning on an Iqama reminder schedules it, and turning it off removes it', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nour',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(
        mosque.id,
        Prayer.asr,
        LocalTime.of(16, 15),
        reminderEnabled: true,
      );
      await settle();

      expect(
        kinds().where((k) => k.kind == NotificationKind.iqama),
        hasLength(kPlanWindowDays),
      );
      expect(
        gateway.scheduled.values.first.body,
        t.notifIqamaBody(t.prayerAsr, 10, 'Masjid al-Nour'),
      );

      await mosques.setReminderEnabled(mosque.id, Prayer.asr, enabled: false);
      await settle();
      expect(gateway.scheduled, isEmpty);
    });

    test('switching the active mosque switches the reminders', () async {
      final first = await mosques.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );
      final second = await mosques.add(
        name: 'Second',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(
        first.id,
        Prayer.asr,
        LocalTime.of(16, 15),
        reminderEnabled: true,
      );
      await mosques.setIqama(
        second.id,
        Prayer.maghrib,
        LocalTime.of(18, 40),
        reminderEnabled: true,
      );
      await settle();
      expect(kinds().map((k) => k.prayer).toSet(), {Prayer.asr});

      await settings.setActiveMosqueId(second.id);
      await settle();
      expect(kinds().map((k) => k.prayer).toSet(), {Prayer.maghrib});
      expect(gateway.scheduled.values.first.planned.mosqueId, second.id);
    });

    test('Adhan alert changes reschedule straight away', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true, preAdhanMinutes: 15),
        ),
      );
      await settle();
      expect(kinds().map((k) => k.kind).toSet(), {
        NotificationKind.adhan,
        NotificationKind.preAdhan,
      });
    });

    test(
      'pausing all Iqama reminders removes them until it is lifted',
      () async {
        final mosque = await mosques.add(
          name: 'Masjid',
          address: '',
          source: MosqueSource.manual,
        );
        await mosques.setIqama(
          mosque.id,
          Prayer.asr,
          LocalTime.of(16, 15),
          reminderEnabled: true,
        );
        await settle();
        expect(gateway.scheduled, hasLength(kPlanWindowDays));

        await settings.saveTravel(
          const TravelSettings(pauseAllIqamaReminders: true),
        );
        await settle();
        expect(gateway.scheduled, isEmpty);

        await settings.saveTravel(const TravelSettings());
        await settle();
        expect(gateway.scheduled, hasLength(kPlanWindowDays));
      },
    );

    test('a paused mosque is silent only while it is the active one', () async {
      final home = await mosques.add(
        name: 'Home',
        address: '',
        source: MosqueSource.manual,
      );
      final away = await mosques.add(
        name: 'Away',
        address: '',
        source: MosqueSource.manual,
      );
      for (final m in [home, away]) {
        await mosques.setIqama(
          m.id,
          Prayer.asr,
          LocalTime.of(16, 15),
          reminderEnabled: true,
        );
      }
      await settings.setActiveMosqueId(home.id);
      await settle();
      expect(gateway.scheduled, hasLength(kPlanWindowDays));

      await mosques.setRemindersPaused(home.id, paused: true);
      await settle();
      expect(gateway.scheduled, isEmpty);

      // Another mosque, not paused, brings its own reminders back.
      await settings.setActiveMosqueId(away.id);
      await settle();
      expect(gateway.scheduled, hasLength(kPlanWindowDays));
      expect(gateway.scheduled.values.map((s) => s.planned.mosqueId).toSet(), {
        away.id,
      });

      // Home again: still paused, its Iqama times untouched.
      await settings.setActiveMosqueId(home.id);
      await settle();
      expect(gateway.scheduled, isEmpty);
      final kept = (await mosques.saved()).singleWhere((m) => m.id == home.id);
      expect(
        kept.schedules.single.iqamaFor(Prayer.asr).iqama,
        LocalTime.of(16, 15),
      );

      await mosques.setRemindersPaused(home.id, paused: false);
      await settle();
      expect(gateway.scheduled, hasLength(kPlanWindowDays));
    });

    test('forgetting the place clears every notification', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.isha,
          const AdhanAlert(enabled: true),
        ),
      );
      await settle();
      expect(gateway.scheduled, isNotEmpty);

      await settings.setLocation(null);
      await settle();
      expect(gateway.scheduled, isEmpty);
    });
  });

  group('the daily background refresh (2026-10-14)', () {
    test('renews the plan from what is stored, with no screen open', () async {
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      final settings = SettingsRepository(db);
      await settings.setLocation(cairo.toStored());
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.dhuhr,
          const AdhanAlert(enabled: true),
        ),
      );
      final gateway = FakeNotificationGateway();
      final container = ProviderContainer(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 13, 6, 0)),
          ),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
        ],
      );
      addTearDown(container.dispose);

      await refreshNotifications(container);

      expect(gateway.scheduled, hasLength(kPlanWindowDays));
    });
  });
}

typedef ScheduledKind = ({NotificationKind kind, Prayer prayer});

extension on PlannedNotification {
  ({String title, String body}) text(AppLocalizationsEn t) =>
      notificationText(t, this, mosqueName: (_) => null);
}
