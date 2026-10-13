import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/flight_gps.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/in_flight.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/flight/in_flight_page.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

class FakeFlightGps implements FlightGps {
  FlightGpsFailure? failure;
  int prepared = 0;
  final controller = StreamController<InFlightFix>.broadcast();

  @override
  Future<FlightGpsFailure?> prepare() async {
    prepared++;
    return failure;
  }

  @override
  Stream<InFlightFix> fixes() => controller.stream;

  @override
  Future<void> openSettings() async {}
}

/// In-flight mode, phase 1 (docs/in-flight-mode.md).
void main() {
  final t = AppLocalizationsEn();
  // 13:00 in Kuwait: over the Gulf, after Dhuhr, before Asr.
  final now = DateTime.utc(2026, 10, 14, 10, 0);

  late AppDatabase db;
  late SettingsRepository settings;
  late FakeFlightGps gps;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    gps = FakeFlightGps();
    addTearDown(db.close);
  });

  Future<void> open(
    WidgetTester tester, {
    bool travel = true,
    AppLanguage language = AppLanguage.en,
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await settings.setLanguage(language);
    await settings.saveTravel(
      TravelSettings(travelMode: travel, followLocation: false),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(FixedClock(now)),
          phoneUtcOffsetProvider.overrideWithValue(null),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          flightGpsProvider.overrideWithValue(gps),
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
  }

  Future<void> tapStart(WidgetTester tester, String label) async {
    await tester.ensureVisible(find.text(label));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label));
  }

  /// The waiting spinner never settles, so pump a few frames instead.
  Future<void> settleWhileWaiting(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> openCard(WidgetTester tester, String title) async {
    await tester.scrollUntilVisible(
      find.text(title),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(title));
    await tester.pumpAndSettle();
  }

  /// Cruising over the Gulf, north of Kuwait, heading north-west.
  InFlightFix cruising({DateTime? at}) => InFlightFix(
    latitude: 29.8,
    longitude: 48.2,
    at: at ?? now,
    altitudeMeters: 11000,
    speedMetersPerSecond: 240,
    courseDegrees: 315,
  );

  testApp('the card is there only in travel mode', (tester) async {
    await open(tester, travel: false);
    expect(find.text(t.inFlightCardTitle), findsNothing);
    await settings.saveTravel(
      const TravelSettings(travelMode: true, followLocation: false),
    );
    await tester.pumpAndSettle();
    expect(find.text(t.inFlightCardTitle), findsOneWidget);
  });

  testApp('nothing starts until the user asks, after the explanation', (
    tester,
  ) async {
    await open(tester);
    await openCard(tester, t.inFlightCardTitle);
    expect(find.byType(InFlightPage), findsOneWidget);
    expect(find.text(t.inFlightExplainBody), findsOneWidget);
    expect(gps.prepared, 0);

    await tapStart(tester, t.inFlightStart);
    await settleWhileWaiting(tester);
    expect(gps.prepared, 1);
    expect(find.text(t.inFlightWaiting), findsOneWidget);
  });

  testApp('a fix at cruise gives the times aboard and the Qibla', (
    tester,
  ) async {
    await open(tester);
    await openCard(tester, t.inFlightCardTitle);
    await tapStart(tester, t.inFlightStart);
    await settleWhileWaiting(tester);
    gps.controller.add(cruising());
    await tester.pumpAndSettle();

    expect(find.text(t.inFlightNow(t.prayerDhuhr)), findsOneWidget);
    expect(find.textContaining('Next: ${t.prayerAsr}'), findsOneWidget);
    expect(find.text(t.inFlightAltitudeSpeed('11000', '864')), findsOneWidget);

    // Qibla from 29.8N 48.2E is about 225°; heading 315° puts it 90° left.
    final scroll = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text(t.inFlightEnterHeading),
      200,
      scrollable: scroll,
    );
    expect(find.textContaining('to the left of the nose'), findsOneWidget);
    expect(find.text(t.inFlightHeadingGps('315')), findsOneWidget);
  });

  testApp('a heading from the seat-back map overrides the GPS course', (
    tester,
  ) async {
    await open(tester);
    await openCard(tester, t.inFlightCardTitle);
    await tapStart(tester, t.inFlightStart);
    await settleWhileWaiting(tester);
    gps.controller.add(
      cruising().copyWithCourse(null, speed: 0), // on the ground
    );
    await tester.pumpAndSettle();
    final scroll = find.byType(Scrollable).last;
    await tester.scrollUntilVisible(
      find.text(t.inFlightEnterHeading),
      200,
      scrollable: scroll,
    );
    expect(find.text(t.inFlightNoCourse), findsOneWidget);

    await tester.tap(find.text(t.inFlightEnterHeading));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '400');
    await tester.pump();
    expect(find.text(t.inFlightHeadingError), findsOneWidget);
    await tester.enterText(find.byType(TextField), '225');
    await tester.pump();
    await tester.tap(find.text(t.save));
    await tester.pumpAndSettle();

    expect(find.text(t.inFlightHeadingManual('225')), findsOneWidget);
    expect(find.text(t.inFlightQiblaAhead), findsOneWidget);
    await tester.tap(find.text(t.inFlightUseGps));
    await tester.pumpAndSettle();
    expect(find.text(t.inFlightNoCourse), findsOneWidget);
  });

  testApp('an old fix is shown as lost, not as current', (tester) async {
    await open(tester);
    await openCard(tester, t.inFlightCardTitle);
    await tapStart(tester, t.inFlightStart);
    await settleWhileWaiting(tester);
    gps.controller.add(cruising(at: now.subtract(const Duration(minutes: 6))));
    await tester.pumpAndSettle();
    expect(find.text(t.inFlightFixLost(t.agoMinutes(6))), findsOneWidget);
  });

  testApp('each refusal says what to do', (tester) async {
    gps.failure = FlightGpsFailure.permanentlyDenied;
    await open(tester);
    await openCard(tester, t.inFlightCardTitle);
    await tapStart(tester, t.inFlightStart);
    await settleWhileWaiting(tester);
    expect(find.text(t.inFlightPermanentlyDenied), findsOneWidget);
    expect(find.text(t.inFlightOpenSettings), findsOneWidget);

    gps.failure = null;
    await tester.tap(find.text(t.inFlightTryAgain));
    await settleWhileWaiting(tester);
    expect(find.text(t.inFlightWaiting), findsOneWidget);
  });

  testApp('in Arabic at a large text size nothing overflows', (tester) async {
    final ar = AppLocalizationsArDigits();
    await open(tester, language: AppLanguage.ar, textScale: 2.0);
    await openCard(tester, ar.inFlightCardTitle);
    await tapStart(tester, ar.inFlightStart);
    await settleWhileWaiting(tester);
    gps.controller.add(cruising());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text(ar.inFlightNow(ar.prayerDhuhr)), findsOneWidget);
  });
}

extension on InFlightFix {
  InFlightFix copyWithCourse(double? course, {required double speed}) =>
      InFlightFix(
        latitude: latitude,
        longitude: longitude,
        at: at,
        altitudeMeters: altitudeMeters,
        speedMetersPerSecond: speed,
        courseDegrees: course,
      );
}
