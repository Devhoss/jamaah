import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
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

    test('an enabled Adhan is planned at the computed time on each of 7 days',
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

      expect(plan, hasLength(7));
      for (final n in plan) {
        final day = LocalMoment.inZone(zone: zone, utcInstant: n.at).day;
        final expected = zone.utcInstantOf(
          day: day,
          time: LocalTime(calculator.forDay(day).times[Prayer.dhuhr]!),
        );
        expect(n.at, expected, reason: '$day');
      }
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

    test('travel mode\'s pause keeps Adhan alerts and drops Iqama reminders', () {
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
      List<PlannedNotification> planWith(TravelSettings travel) =>
          buildNotificationPlan(
            calculator: calculatorFor(30.0444, 31.2357, zone),
            zone: zone,
            nowUtc: DateTime.utc(2026, 10, 13, 0),
            alerts: AdhanAlertSettings.defaults().withAlert(
              Prayer.asr,
              const AdhanAlert(enabled: true),
            ),
            travel: travel,
            activeMosque: mosque,
          );

      final home = planWith(const TravelSettings());
      final away = planWith(
        const TravelSettings(travelMode: true, pauseIqamaReminders: true),
      );
      expect(home.where((n) => n.kind == NotificationKind.iqama), hasLength(7));
      expect(away.where((n) => n.kind == NotificationKind.iqama), isEmpty);
      expect(away.where((n) => n.kind == NotificationKind.adhan), hasLength(7));
    });
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
      expect(iqama.title, t.notifIqamaTitle(t.prayerAsr, 10));
      expect(iqama.body, t.notifIqamaBody('Masjid al-Nour'));

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

    test('turning on an Iqama reminder schedules it, and turning it off removes it',
        () async {
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
        hasLength(7),
      );
      expect(
        gateway.scheduled.values.first.body,
        t.notifIqamaBody('Masjid al-Nour'),
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
      expect(
        gateway.scheduled.values.first.planned.mosqueId,
        second.id,
      );
    });

    test('Adhan alert changes reschedule straight away', () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true, preAdhanMinutes: 15),
        ),
      );
      await settle();
      expect(
        kinds().map((k) => k.kind).toSet(),
        {NotificationKind.adhan, NotificationKind.preAdhan},
      );
    });

    test('travel mode\'s pause removes Iqama reminders until it is lifted',
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
      expect(gateway.scheduled, hasLength(7));

      await settings.saveTravel(
        const TravelSettings(travelMode: true, pauseIqamaReminders: true),
      );
      await settle();
      expect(gateway.scheduled, isEmpty);

      await settings.saveTravel(
        const TravelSettings(travelMode: false, pauseIqamaReminders: true),
      );
      await settle();
      expect(gateway.scheduled, hasLength(7));
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
}

typedef ScheduledKind = ({NotificationKind kind, Prayer prayer});
