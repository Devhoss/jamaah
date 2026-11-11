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

/// "Follow my location", automatic: the place follows the phone whenever the
/// app opens, a flight reschedules every notification for the new place, and
/// a place picked by hand is offered, never moved silently.
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

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await pumpEventQueue();
    }
    await container.read(notificationSchedulerProvider.notifier).syncNow();
  }

  test('the first-run introduction is never skipped by an automatic place', () async {
    await settings.setLocation(null);
    await follower().refresh();
    expect(source.silentCount, 0);
    expect((await settings.read()).location, isNull);
  });

  test('an install older than the introduction keeps following', () async {
    // A place saved before the introduction existed; onboarding is not done.
    expect((await settings.read()).onboardingDone, isFalse);
    source.reading = const PlaceFound(dubai);
    await follower().refresh();
    expect(source.silentCount, 1);
    expect((await settings.read()).location!.ianaZone, 'Asia/Dubai');
  });

  test('the device is checked on the app opening, never asked', () async {
    await follower().refresh();
    expect(source.silentCount, 1);
    expect(source.requestCount, 0, reason: 'no permission dialog');
  });

  test('travel mode alone does not touch the device', () async {
    await follower().setTravelMode(true);
    expect(source.requestCount, 0);
    expect(source.silentCount, 0);
    expect((await settings.read()).travel.travelMode, isTrue);
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
                travel: const TravelSettings(),
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

  test('a few kilometres still updates the device place', () async {
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
    expect(snapshot.location!.latitude, 30.06);
    expect(snapshot.placeCheckedAt, clock.nowUtc());
    expect(snapshot.placeCheckFailed, isFalse);
  });

  test('a geocode fallback keeps the good name, takes the new coordinates', () async {
    await settings.setLocation(
      devicePlace
          .copyWith(displayName: 'Cairo, Egypt')
          .toStored(),
    );
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

    final stored = (await settings.read()).location!;
    expect(stored.placeLabel, 'Cairo, Egypt');
    expect(stored.latitude, 30.06);
  });

  test('no fix keeps the last place and says the check failed', () async {
    source.silentReading = const PlaceRejected(PlaceFailure.timeout);
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, devicePlace.ianaZone);
    expect(snapshot.placeCheckFailed, isTrue);
  });

  test('no permission keeps the last place and stamps nothing', () async {
    source.silentReading = const PlaceRejected(PlaceFailure.denied);
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, devicePlace.ianaZone);
    expect(snapshot.placeCheckedAt, isNull);
    expect(snapshot.placeCheckFailed, isFalse);
  });

  test('a fix near a picked place stands an offer and moves nothing', () async {
    await settings.setLocation(cairo.toStored());
    source.silentReading = const PlaceFound(dubai);
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, devicePlace.ianaZone);
    final offer = snapshot.followOffer;
    expect(offer!.place.ianaZone, 'Asia/Dubai');
    expect(offer.at, clock.nowUtc());
    // A check that found nothing new takes any standing offer away.
    source.silentReading = const PlaceFound(devicePlace);
    await follower().refresh();
    expect((await settings.read()).followOffer, isNull);
  });

  test('applying the offer moves the place and un-pins it', () async {
    await settings.setLocation(cairo.toStored());
    source.silentReading = const PlaceFound(dubai);
    await follower().refresh();
    await follower().applyOffer();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, 'Asia/Dubai');
    expect(snapshot.location!.usesGps, isTrue);
    expect(snapshot.followOffer, isNull);
  });

  test('dismissing the offer keeps the place', () async {
    await settings.setLocation(cairo.toStored());
    source.silentReading = const PlaceFound(dubai);
    await follower().refresh();
    await follower().dismissOffer();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, devicePlace.ianaZone);
    expect(snapshot.followOffer, isNull);
  });

  test('a device place takes the new city with no offer', () async {
    source.silentReading = const PlaceFound(dubai);
    await follower().refresh();

    final snapshot = await settings.read();
    expect(snapshot.location!.ianaZone, 'Asia/Dubai');
    expect(snapshot.followOffer, isNull);
  });

  test('a stored offer that cannot be read is no offer', () async {
    await db.customStatement(
      "INSERT INTO app_settings (key, value) VALUES ('follow_offer', 'gone')",
    );
    expect((await settings.read()).followOffer, isNull);
  });
}
