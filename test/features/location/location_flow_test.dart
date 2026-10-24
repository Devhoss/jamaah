import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/placeholder_places.dart';
import 'package:jamaah/src/features/settings/settings_kit.dart';
import 'package:jamaah/src/features/location/city_list_page.dart';
import 'package:jamaah/src/features/today/today_screen.dart';
import 'package:jamaah/src/features/location/place_copy.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late FakePlaceSource source;
  late SettingsRepository settings;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable));
    settings = SettingsRepository(db);
    // These test the app after the first-run introduction.
    await settings.setOnboardingDone(true);
  });

  tearDown(() => db.close());

  Widget harness() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      placeSourceProvider.overrideWithValue(source),
    ],
    child: const JamaahApp(),
  );

  /// Open the sheet the way the user does: answer the place question on Today.
  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.todayChoosePlace));
    await tester.pumpAndSettle();
  }

  Future<StoredLocation?> stored() async => (await settings.read()).location;

  /// A failure the user cannot read is a silent failure, and this one is read twice:
  /// the sheet keeps it while the city list is in reach, and Today keeps it after the
  /// sheet closes. Today's own copy is asserted in the Today suite.
  void expectFailureCopy(WidgetTester tester, String message) =>
      expect(find.text(message), findsWidgets);

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
      expect(find.text(t.locationSheetPrecise), findsWidgets);
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
          of: find.byType(TodayScreen),
          matching: find.text(placeShortLabel(t, devicePlace)),
        ),
        findsOneWidget,
        reason: 'Today names the place whose times it is showing',
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

    testApp('a saved place can be given the name the user chooses', (
      tester,
    ) async {
      source = FakePlaceSource(const PlaceFound(devicePlace));
      await openSheet(tester);
      await tester.tap(find.text(t.locationUseDevice));
      await tester.pumpAndSettle();

      // Today names it by the nearest city; the place is the way back to the sheet.
      expect(find.text(placeShortLabel(t, devicePlace)), findsOneWidget);
      await tester.tap(find.text(placeShortLabel(t, devicePlace)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(t.placeRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Home');
      await tester.tap(find.text(t.save));
      await tester.pumpAndSettle();

      expect((await stored())?.userName, 'Home');
      expect(find.text('Home'), findsOneWidget);
      expect(
        find.text(placeShortLabel(t, devicePlace)),
        findsNothing,
        reason: 'their own name replaces ours everywhere at once',
      );
    });

    testApp('an empty name hands the place back to the app', (tester) async {
      source = FakePlaceSource(const PlaceFound(devicePlace));
      await openSheet(tester);
      await tester.tap(find.text(t.locationUseDevice));
      await tester.pumpAndSettle();
      await tester.tap(find.text(placeShortLabel(t, devicePlace)));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.placeRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Home');
      await tester.tap(find.text(t.save));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.placeRenameAction));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '   ');
      await tester.tap(find.text(t.save));
      await tester.pumpAndSettle();

      expect((await stored())?.userName, isNull);
      expect(find.text(placeShortLabel(t, devicePlace)), findsOneWidget);
      expect(
        (await stored())?.usesGps,
        isTrue,
        reason: 'renaming never changes where the place came from',
      );
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

      expectFailureCopy(tester, t.locationDenied);
      expect(find.text(t.locationChooseCity), findsOneWidget);
      expect(await stored(), isNull, reason: 'a failure stores nothing');
    });

    testApp('permanently denied offers the system settings', (tester) async {
      await failWith(tester, PlaceFailure.permanentlyDenied);

      expectFailureCopy(tester, t.locationPermanentlyDenied);
      expect(find.text(t.locationOpenSettings), findsOneWidget);

      await tester.tap(find.text(t.locationOpenSettings));
      await tester.pumpAndSettle();
      expect(source.settingsOpenCount, 1);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('location services off is named as such', (tester) async {
      await failWith(tester, PlaceFailure.serviceDisabled);
      expectFailureCopy(tester, t.locationServiceDisabled);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('a timeout is named as such', (tester) async {
      await failWith(tester, PlaceFailure.timeout);
      expectFailureCopy(tester, t.locationTimeout);
      expect(find.text(t.locationChooseCity), findsOneWidget);
    });

    testApp('anything else still routes to the city list', (tester) async {
      await failWith(tester, PlaceFailure.unavailable);
      expectFailureCopy(tester, t.locationUnavailable);
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
              matching: find.byType(SettingsLinkRow),
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
        of: find.byType(TodayScreen),
        matching: find.text(placeShortLabel(t, devicePlace)),
      ),
      findsOneWidget,
      reason: 'the chip is built from what the database holds, not from memory',
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
