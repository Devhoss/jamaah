import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/features/components/travel_switch.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/placeholder_places.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/location/preview_city_page.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// The travel screens: following the phone, saying how fresh the place is, and
/// looking at another city without moving.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late FakePlaceSource source;
  final now = DateTime.utc(2026, 10, 12, 7, 0);

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    source = FakePlaceSource(const PlaceFound(devicePlace));
    addTearDown(db.close);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(FixedClock(now)),
          placeSourceProvider.overrideWithValue(source),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
        ],
        child: const JamaahApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
    await tester.tap(finder.last);
    await tester.pumpAndSettle();
  }

  testApp('Today says how fresh the followed place is', (tester) async {
    await settings.setLocation(devicePlace.toStored());
    await settings.saveTravel(const TravelSettings(travelMode: true));
    await open(tester);

    expect(find.text(t.followingUpdated(t.agoJustNow)), findsOneWidget);
  });

  testApp('a failed check is said plainly, with the age of the last place', (
    tester,
  ) async {
    await settings.setLocation(devicePlace.toStored());
    await settings.saveTravel(const TravelSettings(travelMode: true));
    await settings.markPlaceChecked(
      at: now.subtract(const Duration(hours: 6)),
      failed: false,
    );
    source.silentReading = const PlaceRejected(PlaceFailure.timeout);
    await open(tester);

    expect(find.text(t.followingStale(t.agoHours(6))), findsOneWidget);
  });

  testApp('without following there is no follow line at all', (tester) async {
    await settings.setLocation(cairo.toStored());
    await open(tester);
    expect(find.textContaining('Following your location'), findsNothing);
    expect(source.silentCount, 0);
  });

  testApp('a refused permission leaves following off, and says why', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    source.reading = const PlaceRejected(PlaceFailure.denied);
    await open(tester);
    await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
    await tester.pumpAndSettle();
    await tapText(tester, t.settingsTravelMode);

    expect(find.text(t.followDenied), findsOneWidget);
    final travel = (await settings.read()).travel;
    expect(travel.travelMode, isTrue);
    expect(travel.followLocation, isFalse);
  });

  testApp('the travel switch on the top bar switches travel mode', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    source.reading = const PlaceFound(devicePlace);
    await open(tester);

    await tester.tap(find.byType(TravelSwitch));
    await tester.pumpAndSettle();
    expect((await settings.read()).travel.travelMode, isTrue);
    expect(find.text(t.travelModeOnSnack), findsOneWidget);
    expect(find.textContaining('Following your location'), findsOneWidget);

    await tester.tap(find.byType(TravelSwitch));
    await tester.pumpAndSettle();
    expect((await settings.read()).travel.travelMode, isFalse);
    expect(find.text(t.travelModeOffSnack), findsOneWidget);
    expect(find.textContaining('Following your location'), findsNothing);
  });

  testApp('previewing another city shows its times and moves nothing', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    await open(tester);
    await tapText(tester, placeLabelFor(cairo));
    await tapText(tester, t.previewCity);
    final riyadh = placeholderPlaces.firstWhere(
      (p) => p.displayName.startsWith('Riyadh'),
    );
    await tapText(tester, riyadh.displayName);

    expect(find.byType(PreviewCityPage), findsOneWidget);
    expect(find.text(t.previewTitle(riyadh.displayName)), findsOneWidget);
    expect(find.text(t.prayerMaghrib), findsOneWidget);
    expect((await settings.read()).location!.ianaZone, cairo.ianaZone);
  });
}

/// The chip's words for a city picked from the list.
String placeLabelFor(Place place) => place.displayName;
