import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/app/date_labels.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/settings/prayer_time_settings.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The prayer-time settings: the full method list, Auto detect, custom angles,
/// Asr, the higher-latitude rule and manual adjustments — each one changing the
/// times the app shows (and therefore schedules).
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
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
    await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
    await tester.pumpAndSettle();
    // Settings → Prayer times (Horizon, 2026-10-16).
    await tester.tap(find.text(t.settingsPrayerTimesSection));
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

  /// Today's time for [prayer] at the saved place, as the app computes it.
  int timeOf(WidgetTester tester, Prayer prayer) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(MaterialApp)),
    );
    return container.read(todayProvider)!.day.timeOf(prayer)!;
  }

  testApp('the list has every method, and choosing one changes the times', (
    tester,
  ) async {
    await open(tester);
    await settings.setPrayerTimesPreferences(
      calculationMethod: CalculationMethod.jafari,
    );
    await tester.pumpAndSettle();
    final mwlFajr = timeOf(tester, Prayer.fajr);
    await tapText(tester, t.settingsMethod);

    expect(find.byType(MethodListPage), findsOneWidget);
    expect(find.text(t.methodAuto), findsOneWidget);
    expect(
      find.text(t.methodAngles('19.5', '17.5')),
      findsNWidgets(2),
      reason: 'Egypt itself, and Auto detect, which picks Egypt for Cairo',
    );

    await tapText(tester, t.methodEgyptian);
    expect(
      (await settings.read()).calculationMethod,
      CalculationMethod.egyptian,
    );
    expect(
      timeOf(tester, Prayer.fajr),
      lessThan(mwlFajr),
      reason: "Egypt's 19.5° Fajr is earlier than MWL's 18°",
    );
    expect(find.text(t.methodEgyptian), findsOneWidget);
  });

  testApp('auto detect says which method it chose for the place', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, t.settingsMethod);
    await tapText(tester, t.methodAuto);

    expect((await settings.read()).calculationMethod, CalculationMethod.auto);
    expect(
      find.text(t.methodAutoResolved(t.methodEgyptian, cairo.displayName)),
      findsOneWidget,
    );
  });

  testApp('custom angles are checked, then used', (tester) async {
    await open(tester);
    await tapText(tester, t.settingsMethod);
    await tapText(tester, t.methodCustom);

    final fajr = find.widgetWithText(TextField, t.customFajr);
    await tester.enterText(fajr, '25');
    await tester.pump();
    expect(find.text(t.customAngleError), findsOneWidget);

    await tester.enterText(fajr, '16');
    await tester.pump();
    await tapText(tester, t.customIshaByMinutes);
    await tester.enterText(
      find.widgetWithText(TextField, t.customIshaMinutes),
      '80',
    );
    await tester.pump();
    await tapText(tester, t.save);

    final stored = await settings.read();
    expect(stored.calculationMethod, CalculationMethod.custom);
    expect(stored.customAngles.fajrAngle, 16);
    expect(stored.customAngles.ishaMinutesAfterMaghrib, 80);
    expect(timeOf(tester, Prayer.isha) - timeOf(tester, Prayer.maghrib), 80);
  });

  testApp('Hanafi gives the later Asr', (tester) async {
    await open(tester);
    final standard = timeOf(tester, Prayer.asr);
    await tapText(tester, t.asrHanafi);

    expect((await settings.read()).madhab, Madhab.hanafi);
    expect(timeOf(tester, Prayer.asr), greaterThan(standard));
  });

  testApp('the Hijri date moves by the chosen days, on Today too', (
    tester,
  ) async {
    await open(tester);
    final base = DateLabels.hijri(DateTime(2026, 10, 12), 'en');
    final earlier = DateLabels.hijri(
      DateTime(2026, 10, 12),
      'en',
      adjustDays: -1,
    );
    expect(base, isNot(earlier));
    expect(find.text(base), findsOneWidget, reason: 'the list shows today');
    expect(find.text(t.hijriAsCalculated), findsOneWidget);
    await tapText(tester, t.hijriEarlier(1));

    expect((await settings.read()).hijriAdjustDays, -1);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(BottomNav.tabKey(0)));
    await tester.pumpAndSettle();
    expect(find.textContaining(earlier), findsOneWidget);
  });

  testApp('the higher-latitude rule is chosen with what it does', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, t.settingsAdvanced);
    await tapText(tester, t.settingsHighLatitude);
    expect(find.text(t.highLatitudeSettingsNote), findsOneWidget);
    await tapText(tester, t.ruleSeventhOfTheNightTitle);
    expect(
      (await settings.read()).highLatitudeRule,
      HighLatitudeRule.seventhOfTheNight,
    );
  });

  testApp('manual adjustments move a time by the minute, and reset', (
    tester,
  ) async {
    await open(tester);
    final before = timeOf(tester, Prayer.maghrib);
    await tapText(tester, t.settingsAdvanced);
    await tapText(tester, t.settingsAdjustments);

    final later = find.byTooltip(t.adjustmentsPlus(t.prayerMaghrib));
    await tester.tap(later);
    await tester.pumpAndSettle();
    await tester.tap(later);
    await tester.pumpAndSettle();

    expect((await settings.read()).minuteOffsets[Prayer.maghrib], 2);
    expect(timeOf(tester, Prayer.maghrib), before + 2);
    expect(find.text(t.adjustmentsValue(2)), findsOneWidget);

    await tapText(tester, t.adjustmentsReset);
    expect((await settings.read()).minuteOffsets, isEmpty);
  });

  testApp('the method list and adjustments survive a large text size', (
    tester,
  ) async {
    await open(tester, textScale: 2.0);
    await tapText(tester, t.settingsMethod);
    expect(tester.takeException(), isNull);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapText(tester, t.settingsAdvanced);
    await tapText(tester, t.settingsAdjustments);
    expect(tester.takeException(), isNull);
  });
}
