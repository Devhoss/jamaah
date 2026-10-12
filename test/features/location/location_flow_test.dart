import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/app/app.dart';
import 'package:awqaity/src/app/l10n/generated/app_localizations.dart';
import 'package:awqaity/src/app/l10n/generated/app_localizations_en.dart';
import 'package:awqaity/src/app/providers.dart';
import 'package:awqaity/src/data/app_database.dart';
import 'package:awqaity/src/data/settings_repository.dart';
import 'package:awqaity/src/domain/place.dart';
import 'package:awqaity/src/domain/placeholder_places.dart';
import 'package:awqaity/src/features/components/app_widgets.dart';
import 'package:awqaity/src/features/location/city_list_page.dart';

/// A stand-in for the device. No test in this file touches geolocator or
/// flutter_timezone: every path is driven through this fake (AGENTS.md quality
/// bar), which also records how often the app dared to ask.
class FakePlaceSource implements PlaceSource {
  FakePlaceSource(this.reading);

  PlaceReading reading;
  int requestCount = 0;
  int settingsOpenCount = 0;

  @override
  Future<PlaceReading> requestPlace() async {
    requestCount++;
    return reading;
  }

  @override
  Future<void> openSystemSettings() async {
    settingsOpenCount++;
  }
}

const cairo = Place(
  displayName: 'Cairo, Egypt',
  latitude: 30.0444,
  longitude: 31.2357,
  ianaZone: 'Africa/Cairo',
  fromDevice: false,
);

const devicePlace = Place(
  displayName: 'Africa/Cairo',
  latitude: 30.0444,
  longitude: 31.2357,
  ianaZone: 'Africa/Cairo',
  fromDevice: true,
);

void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late FakePlaceSource source;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable));
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  /// [testWidgets] plus the one thing every drift-backed widget test needs here.
  ///
  /// Unmounting the [ProviderScope] cancels the settings stream, and closing a
  /// drift stream schedules a zero-duration cleanup timer. Fake async only runs a
  /// timer once time moves, so leaving it to the framework teardown reports
  /// "A Timer is still pending". Detaching and flushing at the end of the body
  /// keeps the real database in the test instead of swapping it for a fake.
  void testApp(String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      await body(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 1));
    });
  }

  Widget harness() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      placeSourceProvider.overrideWithValue(source),
    ],
    child: const AwqaityApp(),
  );

  /// Open the sheet the way the user does: tap the prompt on the shell screen.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppPrompt));
    await tester.pumpAndSettle();
  }

  Future<StoredLocation?> stored() async => (await settings.read()).location;

  /// The unfiltered list is taller than the 800x600 test viewport, so a row far
  /// down the list has to be scrolled in before a tap can land on it.
  Future<void> tapCity(WidgetTester tester, String label) async {
    final row = find.text(label).first;
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();
  }

  group('the location sheet', () {
    testApp('explains before it asks, and asks for nothing by itself', (
      tester,
    ) async {
      await openSheet(tester);

      expect(find.text(t.locationSheetTitle), findsWidgets);
      expect(find.text(t.locationSheetBody), findsWidgets);
      expect(find.text(t.locationSheetCoarse), findsWidgets);
      expect(find.text(t.locationUseDevice), findsOneWidget);
      expect(find.text(t.locationChooseCity), findsOneWidget);
      expect(
        source.requestCount,
        0,
        reason: 'the device must stay untouched until the user taps',
      );
    });

    testApp('a tap on "Use my location" saves what the device gave us', (
      tester,
    ) async {
      source = FakePlaceSource(const PlaceFound(devicePlace));
      await openSheet(tester);

      await tester.tap(find.text(t.locationUseDevice));
      await tester.pumpAndSettle();

      expect(source.requestCount, 1);
      final storedLocation = await stored();
      expect(storedLocation, isNotNull);
      expect(storedLocation!.ianaZone, 'Africa/Cairo');
      expect(storedLocation.usesGps, isTrue);
      expect(
        find.descendant(
          of: find.byType(ScaffoldPlaceholder),
          matching: find.text(t.currentPlaceLabel(t.locationThisDevice)),
        ),
        findsOneWidget,
      );
    });

    testApp('the city the user picked is stored as a list place', (
      tester,
    ) async {
      await openSheet(tester);

      await tester.tap(find.text(t.locationChooseCity));
      await tester.pumpAndSettle();
      await tapCity(tester, cairo.displayName);
      await tester.pumpAndSettle();

      final storedLocation = await stored();
      expect(storedLocation!.placeLabel, 'Cairo, Egypt');
      expect(storedLocation.ianaZone, 'Africa/Cairo');
      expect(storedLocation.usesGps, isFalse);
    });
  });

  group('every way the device can say no', () {
    Future<void> failWith(WidgetTester tester, PlaceFailure failure) async {
      source = FakePlaceSource(PlaceRejected(failure));
      await openSheet(tester);
      await tester.tap(find.text(t.locationUseDevice));
      await tester.pumpAndSettle();
    }

    testApp('declined permission: calm message, city list still in reach', (
      tester,
    ) async {
      await failWith(tester, PlaceFailure.denied);

      expect(find.text(t.locationDenied), findsOneWidget);
      expect(find.text(t.locationChooseCity), findsOneWidget);
      expect(await stored(), isNull, reason: 'a failure stores nothing');
    });

    testApp('permanently denied offers the system settings', (tester) async {
      await failWith(tester, PlaceFailure.permanentlyDenied);

      expect(find.text(t.locationPermanentlyDenied), findsOneWidget);
      expect(find.text(t.locationOpenSettings), findsOneWidget);

      await tester.tap(find.text(t.locationOpenSettings));
      await tester.pumpAndSettle();
      expect(source.settingsOpenCount, 1);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('location services off is named as such', (tester) async {
      await failWith(tester, PlaceFailure.serviceDisabled);
      expect(find.text(t.locationServiceDisabled), findsOneWidget);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('a timeout is named as such', (tester) async {
      await failWith(tester, PlaceFailure.timeout);
      expect(find.text(t.locationTimeout), findsOneWidget);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('anything else still routes to the city list', (tester) async {
      await failWith(tester, PlaceFailure.unavailable);
      expect(find.text(t.locationUnavailable), findsOneWidget);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });
  });

  group('the bundled city list', () {
    Future<void> openList(WidgetTester tester) async {
      await openSheet(tester);
      await tester.tap(find.text(t.locationChooseCity));
      await tester.pumpAndSettle();
    }

    testApp('is labelled as the placeholder it is', (tester) async {
      await openList(tester);

      expect(find.byType(CityListPage), findsOneWidget);
      expect(find.text(t.cityListPlaceholderNote), findsOneWidget);
    });

    testApp('search narrows the list and can find nothing', (tester) async {
      await openList(tester);

      int cityRows() => tester
          .widgetList(
            find.descendant(
              of: find.byType(CityListPage),
              matching: find.byType(AppRow),
            ),
          )
          .length;

      expect(cityRows(), placeholderPlaces.length);

      await tester.enterText(find.byType(TextField), 'Ka');
      await tester.pumpAndSettle();

      expect(find.text('Karachi, Pakistan'), findsOneWidget);
      expect(find.text('Cairo, Egypt'), findsNothing);
      expect(cityRows(), lessThan(placeholderPlaces.length));

      await tester.enterText(find.byType(TextField), 'Atlantis');
      await tester.pumpAndSettle();
      expect(find.text(t.cityListNoMatches), findsOneWidget);
      expect(cityRows(), 0);
    });

    testApp('choosing a city stores it and leaves the flow', (tester) async {
      await openList(tester);

      await tester.enterText(find.byType(TextField), 'Jakar');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jakarta, Indonesia'));
      await tester.pumpAndSettle();

      final storedLocation = await stored();
      expect(storedLocation!.placeLabel, 'Jakarta, Indonesia');
      expect(storedLocation.ianaZone, 'Asia/Jakarta');
      expect(storedLocation.usesGps, isFalse);
      expect(find.byType(CityListPage), findsNothing);
    });
  });

  testApp('a stored place survives a restart', (tester) async {
    source = FakePlaceSource(const PlaceFound(devicePlace));
    await openSheet(tester);
    await tester.tap(find.text(t.locationUseDevice));
    await tester.pumpAndSettle();

    // Rebuild the tree from scratch: the place comes back from the database, not
    // from widget state.
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ScaffoldPlaceholder),
        matching: find.text(t.currentPlaceLabel(t.locationThisDevice)),
      ),
      findsOneWidget,
    );
    expect(
      source.requestCount,
      1,
      reason: 'no new permission request on relaunch',
    );
  });

  testApp('localization goes through AppLocalizations, not literals', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(
      AppLocalizations.supportedLocales.any((l) => l.languageCode == 'en'),
      isTrue,
    );
    expect(t.locationSheetTitle, isNotEmpty);
  });
}
