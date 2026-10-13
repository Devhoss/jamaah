import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/zone_lookup.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// Travelling without changing the phone's zone (2026-10-14): a place read
/// from the device takes its zone from where it is, and Today says when its
/// times are not on the phone's clock.
void main() {
  final t = AppLocalizationsEn();
  setUpAll(loadTimeZoneDatabase);

  group('the zone at a point', () {
    test('cities get their own zone, with no network', () {
      String? at(double lat, double lng) =>
          zoneAt(latitude: lat, longitude: lng);
      expect(at(29.3759, 47.9774), 'Asia/Kuwait');
      expect(at(29.3375, 47.6581), 'Asia/Kuwait', reason: 'Jahra');
      expect(at(51.5074, -0.1278), 'Europe/London');
      expect(at(40.7128, -74.006), 'America/New_York');
      expect(at(39.7684, -86.1581), 'America/Indiana/Indianapolis');
      expect(at(30.0444, 31.2357), 'Africa/Cairo');
    });

    test('open sea still gets a zone the app knows', () {
      final zone = zoneAt(latitude: 35, longitude: -40);
      expect(zone, isNotNull);
      expect(() => zoneOffsetsFor(zone!), returnsNormally);
    });

    test('offsets read the way people write them', () {
      expect(utcOffsetLabel(180), '+3');
      expect(utcOffsetLabel(330), '+5:30');
      expect(utcOffsetLabel(-240), '-4');
      expect(utcOffsetLabel(0), '+0');
    });
  });

  group('the note on Today', () {
    late AppDatabase db;
    late SettingsRepository settings;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
      addTearDown(db.close);
    });

    const london = Place(
      displayName: 'London, United Kingdom',
      latitude: 51.5074,
      longitude: -0.1278,
      ianaZone: 'Europe/London',
      fromDevice: false,
    );

    Future<void> open(
      WidgetTester tester, {
      required Place place,
      required Duration? phoneOffset,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await settings.setLocation(place.toStored());
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            // 12 October 2026: London is on summer time, UTC+1.
            appClockProvider.overrideWithValue(
              FixedClock(DateTime.utc(2026, 10, 12, 9, 0)),
            ),
            phoneUtcOffsetProvider.overrideWithValue(phoneOffset),
            placeSourceProvider.overrideWithValue(
              FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
            ),
            notificationGatewayProvider.overrideWithValue(
              FakeNotificationGateway(),
            ),
          ],
          child: const JamaahApp(),
        ),
      );
      await tester.pumpAndSettle();
    }

    String utc(String offset) => '\u2066UTC$offset\u2069';

    testApp('a phone still on Kuwait time in London is told which is which', (
      tester,
    ) async {
      await open(tester, place: london, phoneOffset: const Duration(hours: 3));
      expect(
        find.text(t.zoneNotePlace(london.displayName, utc('+1'), utc('+3'))),
        findsOneWidget,
      );
    });

    testApp('a place read from the device says "where you are"', (
      tester,
    ) async {
      await open(
        tester,
        place: const Place(
          displayName: 'Europe/London',
          latitude: 51.5074,
          longitude: -0.1278,
          ianaZone: 'Europe/London',
          fromDevice: true,
        ),
        phoneOffset: const Duration(hours: 3),
      );
      expect(find.text(t.zoneNoteHere(utc('+1'), utc('+3'))), findsOneWidget);
    });

    testApp('no note when the phone is on the place’s time', (tester) async {
      await open(tester, place: london, phoneOffset: const Duration(hours: 1));
      expect(find.textContaining('Your phone'), findsNothing);
    });
  });
}
