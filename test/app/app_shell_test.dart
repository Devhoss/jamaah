import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/branding.g.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/components/app_widgets.dart';
import '../helpers/fake_clock.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// The shell around the screens: three destinations, the settings gear the
/// prototype puts on every tab, and an honest answer on the tabs whose feature has
/// not been built yet.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late FakePlaceSource source;
  late FixedClock clock;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable));
    // 10:00 in Cairo, so Today has a full day to show.
    clock = FixedClock(DateTime.utc(2026, 10, 12, 7, 0));
    addTearDown(db.close);
  });

  Widget harness() => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      placeSourceProvider.overrideWithValue(source),
      appClockProvider.overrideWithValue(clock),
    ],
    child: const JamaahApp(),
  );

  Future<void> open(WidgetTester tester, {bool withPlace = false}) async {
    if (withPlace) await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  /// Tap a destination by the words under it, the way a user reads the bar.
  Future<void> goTo(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testApp('the top bar names the app, straight from the branding file', (
    tester,
  ) async {
    await open(tester);

    expect(find.text(kWordmark), findsOneWidget);
    expect(
      find.text('Prayer companion'),
      findsNothing,
      reason: 'the name lives in branding.yaml. A second copy in the strings file '
          'is a second thing to forget to change.',
    );
  });

  testApp('Today is where the app opens, and the bar names three places', (
    tester,
  ) async {
    await open(tester);

    expect(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(t.tabToday),
      ),
      findsOneWidget,
    );
    expect(find.text(t.tabMosques), findsOneWidget);
    expect(find.text(t.tabQibla), findsOneWidget);
    expect(
      find.text(t.todayNeedsPlaceTitle),
      findsOneWidget,
      reason: 'the place question is asked on Today, not on a tab of its own',
    );
  });

  testApp('the bar marks only the screen you are on', (tester) async {
    await open(tester);

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);

    await goTo(tester, t.tabQibla);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      2,
    );

    await goTo(tester, t.tabToday);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      0,
    );
  });

  testApp('Mosques starts honestly empty instead of showing an invented list', (
    tester,
  ) async {
    await open(tester);
    await goTo(tester, t.tabMosques);

    expect(find.text(t.noSavedMosques), findsOneWidget);
    expect(
      find.byType(AppRow),
      findsNothing,
      reason: 'no mosque exists yet, so no row may look like one',
    );
    final nearby = tester.widget<ButtonStyleButton>(
      find.ancestor(
        of: find.text(t.findNearbyMosques),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    expect(
      nearby.onPressed,
      isNull,
      reason: 'discovery is a later step: visible, but leads nowhere fake',
    );
    expect(find.text(t.findNearbyLater), findsOneWidget);
  });

  testApp('Qibla says the same kind of truth, with no bearing on show', (
    tester,
  ) async {
    await open(tester);
    await goTo(tester, t.tabQibla);

    expect(find.text(t.qiblaComingTitle), findsOneWidget);
    expect(find.text(t.qiblaComingBody), findsOneWidget);
    expect(
      textMatchingDegrees(),
      findsNothing,
      reason: 'a degree reading here would be a number nobody measured',
    );
  });

  testApp('the gear opens Settings and admits it is not built yet', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text(t.settingsComingTitle), findsOneWidget);
    expect(find.text(t.settingsComingBody), findsOneWidget);
  });

  testApp('every destination and the gear is big enough to press', (
    tester,
  ) async {
    await open(tester);

    // IconButton draws a 40x40 ink circle and wraps it in its own hit padding, so
    // the button's box is what a finger lands on — not the ink. The M3 bar answers a
    // tap with a private InkResponse subclass over the whole destination, so the
    // search is by type-or-subclass rather than by exact runtime type.
    final gear = tester.getSize(find.byType(IconButton));
    final destination = tester.getSize(
      find.ancestor(
        of: find.text(t.tabMosques),
        matching: find.byWidgetPredicate((widget) => widget is InkResponse),
      ).first,
    );

    for (final (label, size) in [('gear', gear), ('Mosques tab', destination)]) {
      expect(
        size.width >= 48 && size.height >= 48,
        isTrue,
        reason: '$label is a touch target, not a decoration ($size)',
      );
    }
  });

  testApp('a dark device gets the dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await open(tester);

    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.dark,
      reason: 'the device already made this choice; a light answer to a dark phone '
          'is exactly the hard-coded convention AGENTS.md rules out',
    );
  });

  testApp('a light device gets the light theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await open(tester);

    expect(
      Theme.of(tester.element(find.byType(NavigationBar))).brightness,
      Brightness.light,
      reason: 'following the system is not the same as defaulting to dark',
    );
  });

  testApp('the mosque prompt on Today walks you to the Mosques tab', (
    tester,
  ) async {
    await open(tester, withPlace: true);

    expect(find.text(t.addMosqueTitle), findsOneWidget);
    await tester.tap(find.text(t.addMosqueTitle));
    await tester.pumpAndSettle();

    expect(find.text(t.noSavedMosques), findsOneWidget);
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      1,
    );
    expect(
      find.text(t.addMosqueTitle),
      findsNothing,
      reason: 'the prompt belongs on Today, and does not follow you here',
    );
  });

  testApp('coming back to Today keeps the day you left', (tester) async {
    await open(tester, withPlace: true);

    await goTo(tester, t.tabMosques);
    await goTo(tester, t.tabToday);

    expect(find.text(cairo.displayName), findsOneWidget);
    expect(find.text(t.nextPrayerAdhan), findsOneWidget);
  });
}

/// This SDK's `CommonFinders` has no regex finder, so match on the [Text] data.
Finder textMatchingDegrees() => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data != null && _degree.hasMatch(widget.data!),
);

final _degree = RegExp(r'\d{1,3}°');
