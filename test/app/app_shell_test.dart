import 'dart:ui' show Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/features/components/travel_switch.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/components/app_widgets.dart';
import 'package:jamaah/src/features/settings/settings_page.dart';
import '../helpers/fake_clock.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// The shell around the screens: four destinations along the bottom
/// (Horizon: Today · Mosques · Qibla · Settings), and an honest answer where
/// there is nothing to show yet.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late FakePlaceSource source;
  late FixedClock clock;

  setUpAll(loadTimeZoneDatabase);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    // These test the app after the first-run introduction.
    await settings.setOnboardingDone(true);
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

  /// Which tab the bar marks as current, read the way TalkBack reads it.
  int selectedTab(WidgetTester tester) {
    for (var i = 0; i < 4; i++) {
      final node = tester.getSemantics(find.byKey(BottomNav.tabKey(i)));
      if (node.flagsCollection.isSelected == Tristate.isTrue) return i;
    }
    return -1;
  }

  testApp('Today is where the app opens, and the bar names four places', (
    tester,
  ) async {
    await open(tester);

    expect(
      find.descendant(
        of: find.byType(BottomNav),
        matching: find.text(t.tabToday),
      ),
      findsOneWidget,
    );
    expect(find.text(t.tabMosques), findsOneWidget);
    expect(find.text(t.tabQibla), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomNav),
        matching: find.text(t.settingsTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.text(t.todayNeedsPlaceTitle),
      findsOneWidget,
      reason: 'the place question is asked on Today, not on a tab of its own',
    );
  });

  testApp('the bar marks only the screen you are on', (tester) async {
    await open(tester);

    expect(selectedTab(tester), 0);

    await goTo(tester, t.tabQibla);
    expect(selectedTab(tester), 2);

    await goTo(tester, t.tabToday);
    expect(selectedTab(tester), 0);
  });

  testApp('Mosques starts honestly empty, with the two ways to add one', (
    tester,
  ) async {
    await open(tester);
    await goTo(tester, t.tabMosques);

    expect(find.text(t.mosquesEmptyTitle), findsOneWidget);
    expect(
      find.byType(AppRow),
      findsNothing,
      reason: 'no mosque exists yet, so no row may look like one',
    );
    expect(
      find.text(t.mosquesEmptyFind),
      findsOneWidget,
      reason: 'a mosque gets here by being found nearby, or added by hand',
    );
    expect(find.text(t.mosquesEmptyAdd), findsOneWidget);
  });

  testApp('Qibla without a place asks for one, with no bearing on show', (
    tester,
  ) async {
    await open(tester);
    await goTo(tester, t.tabQibla);

    expect(find.text(t.qiblaNeedsPlaceTitle), findsOneWidget);
    expect(find.text(t.todayChoosePlace), findsOneWidget);
    expect(
      textMatchingDegrees(),
      findsNothing,
      reason: 'a degree reading here would be a number nobody measured',
    );
  });

  testApp('the Settings tab opens Settings, prayer times first, with no back arrow', (
    tester,
  ) async {
    await open(tester);

    await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(
      find.text(t.settingsPrayerTimesSection.toUpperCase()),
      findsOneWidget,
    );
    expect(find.text(t.settingsMethod), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
    expect(selectedTab(tester), BottomNav.settingsIndex);
  });

  testApp('every destination and the airplane are big enough to press', (
    tester,
  ) async {
    await open(tester, withPlace: true);
    final travel = tester.getSize(find.byType(TravelSwitch));
    for (var i = 0; i < 4; i++) {
      final tab = tester.getSize(find.byKey(BottomNav.tabKey(i)));
      expect(
        tab.width >= 48 && tab.height >= 48,
        isTrue,
        reason: 'tab $i is a touch target, not a decoration ($tab)',
      );
    }
    expect(travel.width >= 48 && travel.height >= 48, isTrue);
  });

  testApp('a dark device gets the dark theme', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

    await open(tester);

    expect(
      Theme.of(tester.element(find.byType(BottomNav))).brightness,
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
      Theme.of(tester.element(find.byType(BottomNav))).brightness,
      Brightness.light,
      reason: 'following the system is not the same as defaulting to dark',
    );
  });

  testApp('the mosque prompt on Today walks you to the Mosques tab', (
    tester,
  ) async {
    await open(tester, withPlace: true);

    expect(find.text(t.addMosqueTitle), findsOneWidget);
    await tester.ensureVisible(find.text(t.addMosqueTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.addMosqueTitle));
    await tester.pumpAndSettle();

    expect(find.text(t.mosquesEmptyTitle), findsOneWidget);
    expect(selectedTab(tester), 1);
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
    expect(find.text(t.nextPrayerAdhan.toUpperCase()), findsOneWidget);
  });
}

/// This SDK's `CommonFinders` has no regex finder, so match on the [Text] data.
Finder textMatchingDegrees() => find.byWidgetPredicate(
  (widget) => widget is Text && widget.data != null && _degree.hasMatch(widget.data!),
);

final _degree = RegExp(r'\d{1,3}°');
