import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/compass.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/qibla.dart';
import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

class FakeCompass implements CompassSource {
  FakeCompass({this.declinationValue = 5.0});

  final controller = StreamController<CompassReading>.broadcast();
  double? declinationValue;

  void send(double heading, {double? accuracy = 15}) =>
      controller.add(CompassReading(heading: heading, accuracy: accuracy));

  @override
  Stream<CompassReading> readings() => controller.stream;

  @override
  Future<double?> declination({
    required double latitude,
    required double longitude,
  }) async => declinationValue;
}

/// The Qibla screen: the bearing from the saved place, a compass corrected to
/// true north, and an honest answer without a compass.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late FakeCompass compass;

  // Cairo's Qibla, as the screen rounds it.
  final bearing = qiblaBearingRounded(
    latitude: cairo.latitude,
    longitude: cairo.longitude,
  );

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    compass = FakeCompass();
    addTearDown(db.close);
  });

  Future<void> open(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 12, 7, 0)),
          ),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          compassSourceProvider.overrideWithValue(compass),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: const JamaahApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BottomNav.tabKey(2)));
    await tester.pumpAndSettle();
  }

  Future<void> heading(
    WidgetTester tester,
    double magnetic, {
    double? accuracy = 15,
  }) async {
    compass.send(magnetic, accuracy: accuracy);
    await tester.pumpAndSettle();
  }

  testApp('the bearing is there before the compass answers', (tester) async {
    expect(bearing, 136, reason: 'Cairo, as the domain tests pin it');
    await open(tester);

    expect(find.text(t.qiblaDegrees('$bearing')), findsOneWidget);
    expect(find.text(t.qiblaFromNorth('$bearing')), findsOneWidget);
    expect(find.bySemanticsLabel(t.qiblaDialLabel('$bearing')), findsOneWidget);
    await heading(tester, 0);
  });

  testApp('the turn is measured from true north, not magnetic', (tester) async {
    await open(tester);
    // Magnetic 100 + 5 declination = 105 true; 136 - 105 = 31 to the right.
    await heading(tester, 100);
    expect(find.text(t.qiblaTurnRight('31')), findsOneWidget);
    expect(find.text(t.qiblaDeclinationNote('5.0')), findsOneWidget);
  });

  testApp('facing it says so; past it says turn left', (tester) async {
    await open(tester);
    await heading(tester, 131); // 136 true
    expect(find.text(t.qiblaAligned), findsOneWidget);

    await heading(tester, 145); // 150 true: 14 too far
    expect(find.text(t.qiblaTurnLeft('14')), findsOneWidget);

    await heading(tester, 300); // 305 true: the short way is left
    expect(find.text(t.qiblaTurnLeft('169')), findsOneWidget);
  });

  testApp('without the declination it says the compass is magnetic', (
    tester,
  ) async {
    compass.declinationValue = null;
    await open(tester);
    await heading(tester, 136);
    expect(find.text(t.qiblaAligned), findsOneWidget);
    expect(find.text(t.qiblaMagneticNote), findsOneWidget);
  });

  testApp('a silent compass leaves the bearing and how to use it', (
    tester,
  ) async {
    await open(tester);
    await tester.pump(const Duration(seconds: 4));

    expect(find.text(t.qiblaNoCompassTitle), findsOneWidget);
    expect(find.text(t.qiblaNoCompassHint), findsOneWidget);
    expect(find.text(t.qiblaDegrees('$bearing')), findsOneWidget);
    // Cairo's 136° is south-east, in words.
    expect(find.text(t.compassPointSouthEast), findsOneWidget);
  });

  testApp(
    'a low-accuracy compass asks for a moment, says how, then says steady',
    (tester) async {
      await open(tester);
      await heading(tester, 100, accuracy: 45);
      expect(find.text(t.qiblaNeedsMoment), findsOneWidget);
      expect(find.text(t.qiblaCalibrateBody), findsOneWidget);

      final how = find.text(t.qiblaCalibrate);
      await tester.ensureVisible(how);
      await tester.pumpAndSettle();
      await tester.tap(how);
      await tester.pumpAndSettle();
      expect(find.text(t.qiblaCalibrateTitle), findsOneWidget);
      await tester.tap(find.text(t.qiblaCalibrateDone));
      await tester.pumpAndSettle();

      await heading(tester, 100);
      expect(find.text(t.qiblaNeedsMoment), findsNothing);
      expect(find.text(t.qiblaSteadyNow), findsOneWidget);
    },
  );

  testApp('the distance to the Kaaba is shown', (tester) async {
    await open(tester);
    final km = distanceKm(
      latitude: cairo.latitude,
      longitude: cairo.longitude,
    ).round();
    expect(find.textContaining('km to the Kaaba'), findsOneWidget);
    expect(km, inInclusiveRange(1200, 1350));
    await heading(tester, 0);
  });

  testApp('the screen survives a large text size', (tester) async {
    await open(tester, textScale: 2.0);
    await heading(tester, 100, accuracy: 45);
    expect(tester.takeException(), isNull);
  });
}
