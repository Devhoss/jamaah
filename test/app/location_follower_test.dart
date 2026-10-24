import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/location_follower.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';

/// "Follow my location" for cabin crew: the place follows the phone when the app
/// opens, a flight reschedules every notification for the new place, and a
/// failed check keeps the last place and says so.
void main() {
  const dubai = Place(
    displayName: 'Asia/Dubai',
    latitude: 25.2048,
    longitude: 55.2708,
    ianaZone: 'Asia/Dubai',
    fromDevice: true,
  );

  late AppDatabase db;
  late SettingsRepository settings;
  late FakePlaceSource source;
  late FakeNotificationGateway gateway;
  late FixedClock clock;
  late ProviderContainer container;

  setUpAll(loadTimeZoneDatabase);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    source = FakePlaceSource(const PlaceFound(devicePlace));
    gateway = FakeNotificationGateway();
    clock = FixedClock(DateTime.utc(2026, 10, 13, 6, 0));
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appClockProvider.overrideWithValue(clock),
        placeSourceProvider.overrideWithValue(source),
        notificationGatewayProvider.overrideWithValue(gateway),
      ],
    );
    await settings.setLocation(devicePlace.toStored());
    container.listen(notificationSchedulerProvider, (_, _) {});
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  LocationFollower follower() => container.read(locationFollowerProvider);

  Future<void> following() =>
      settings.saveTravel(const TravelSettings(travelMode: true));

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await pumpEventQueue();
    }
    await container.read(notificationSchedulerProvider.notifier).syncNow();
  }

  test('with travel mode off, the device is never asked', () async {
    await follower().refresh();
    expect(source.silentCount, 0);
    expect(source.requestCount, 0);
  });

  test(
    'with travel mode on but the option off, the device is never asked',
    () async {
      await settings.saveTravel(
        const TravelSettings(travelMode: true, followLocation: false),
      );
      await follower().refresh();
      expect(source.silentCount, 0);
    },
  );

  test('opening the app never shows a permission dialog', () async {
    await following();
    await follower().refresh();
    expect(source.silentCount, 1);
    expect(source.requestCount, 0);
  });

  test(
    'a flight to Dubai moves the place, its zone, and every Adhan alert',
    () async {
      await settings.saveAdhanAlerts(
        AdhanAlertSettings.defaults().withAlert(
          Prayer.fajr,
          const AdhanAlert(enabled: true),
        ),
      );
      await following();
      await settle();
      final cairoTimes = {for (final i in gateway.scheduled.values) i.at};

      source.silentReading = const PlaceFound(dubai);
      await follower().refresh();
      await settle();

      final stored = (await settings.read()).location!;
      expect(stored.ianaZone, 'Asia/Dubai');
      expect(stored.usesGps, isTrue);

      final zone = zoneOffsetsFor('Asia/Dubai');
      final expected =
          buildNotificationPlan(
                calculator: PrayerTimesCalculator(
                  latitude: dubai.latitude,
                  longitude: dubai.longitude,
                  zone: zone,
                  method: CalculationMethod.auto.resolvedForPlace(
                    dubai.ianaZone,
                    dubai.countryCode,
                  ),
                  madhab: Madhab.standard,
                  highLatitudeRule: HighLatitudeRule.middleOfTheNight,
                  minuteOffsets: const {},
                ),
                zone: zone,
                nowUtc: clock.nowUtc(),
                alerts: (await settings.read()).adhanAlerts,
                travel: const TravelSettings(followLocation: true),
                activeMosque: null,
              )
              .where(
                (n) =>
                    n.kind == NotificationKind.adhan &&
                    n.at.isAfter(clock.nowUtc()),
              )
              .map((n) => n.at)
              .toSet();

      final dubaiTimes = {for (final i in gateway.scheduled.values) i.at};
      expect(dubaiTimes, expected);
      expect(dubaiTimes.intersection(cairoTimes), isEmpty);
    },
  );

  test('a few kilometres keeps the place but records the check', () async {
    await following();
    source.silentReading = const PlaceFound(
      Place(
        displayName: 'Africa/Cairo',
        latitude: 30.06,
        longitude: 31.25,
        ianaZone: 'Africa/Cairo',
        fromDevice: true,
      ),
    );
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.latitude, devicePlace.latitude);
    expect(snapshot.placeCheckedAt, clock.nowUtc());
    expect(snapshot.placeCheckFailed, isFalse);
  });

  test('no fix keeps the last place and says the check failed', () async {
    await following();
    source.silentReading = const PlaceRejected(PlaceFailure.timeout);
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, devicePlace.ianaZone);
    expect(snapshot.placeCheckFailed, isTrue);
  });

  test(
    'turning travel mode on may ask, and a refusal turns only following off',
    () async {
      source.reading = const PlaceRejected(PlaceFailure.denied);
      final failure = await follower().setTravelMode(true);
      expect(failure, PlaceFailure.denied);
      expect(source.requestCount, 1);
      var travel = (await settings.read()).travel;
      expect(travel.travelMode, isTrue);
      expect(travel.followLocation, isFalse);

      source.reading = const PlaceFound(dubai);
      expect(await follower().setFollowLocation(true), isNull);
      final snapshot = await settings.read();
      expect(snapshot.travel.followsLocation, isTrue);
      expect(snapshot.location!.ianaZone, 'Asia/Dubai');

      expect(await follower().setTravelMode(false), isNull);
      travel = (await settings.read()).travel;
      expect(travel.travelMode, isFalse);
      expect(travel.followLocation, isTrue, reason: 'the option is remembered');
    },
  );

  test('with travel mode off, the option is only remembered', () async {
    expect(await follower().setFollowLocation(false), isNull);
    expect(await follower().setFollowLocation(true), isNull);
    expect(source.requestCount, 0);
    expect((await settings.read()).travel.followLocation, isTrue);
  });

  test('turning travel mode on starts following at once', () async {
    source.reading = const PlaceFound(dubai);
    expect(await follower().setTravelMode(true), isNull);
    expect((await settings.read()).location!.ianaZone, 'Asia/Dubai');
  });
}
