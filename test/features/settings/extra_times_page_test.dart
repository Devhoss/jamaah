import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/extra_times.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/settings/extra_times_page.dart';
import 'package:jamaah/src/features/settings/settings_kit.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// Settings → Extra times (2026-10-14): which of Imsak, Duha and the last
/// third of the night are shown and alerted, and their minutes.
void main() {
  final t = AppLocalizationsEn();
  final ar = AppLocalizationsArDigits();

  late AppDatabase db;
  late SettingsRepository settings;
  late int permissionAsks;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    permissionAsks = 0;
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
            FixedClock(DateTime.utc(2026, 10, 14, 7, 0)),
          ),
          phoneUtcOffsetProvider.overrideWithValue(null),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          notificationPermissionRequestProvider.overrideWithValue(
            () async => permissionAsks++,
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
    // Settings → Prayer times, the hub's first row (Horizon, 2026-10-16).
    await tester.tap(find.byType(SettingsLinkRow).first);
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

  Future<void> tapSwitch(WidgetTester tester, Key key) async {
    final finder = find.byKey(key);
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testApp('Prayer times shows them inline and opens the page', (tester) async {
    await open(tester);
    await tester.scrollUntilVisible(
      find.text(t.extraAlertsAndTiming),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.widgetWithText(SettingsSwitchRow, t.extraImsak), findsOne);
    await tapText(tester, t.extraAlertsAndTiming);
    expect(find.byType(ExtraTimesPage), findsOneWidget);
    expect(find.text(t.extraTimesIntro), findsOneWidget);
  });

  testApp('showing Duha and alerting Qiyam are saved', (tester) async {
    await open(tester);
    await tapText(tester, t.extraAlertsAndTiming);

    await tapSwitch(tester, const ValueKey('show-duha'));
    expect((await settings.read()).extraTimes.shown, {ExtraTime.duha});

    await tapSwitch(tester, const ValueKey('alert-qiyam'));
    expect((await settings.read()).extraTimes.alerts, {ExtraTime.qiyam});
    expect(permissionAsks, 1, reason: 'an alert needs notifications allowed');

    await tapSwitch(tester, const ValueKey('alert-qiyam'));
    expect((await settings.read()).extraTimes.alerts, isEmpty);
    expect(permissionAsks, 1, reason: 'switching off asks nothing');
  });

  testApp('Imsak and Duha minutes are chosen from a list', (tester) async {
    await open(tester);
    await tapText(tester, t.extraAlertsAndTiming);

    await tapText(tester, t.extraImsakRule(10));
    for (final m in const [0, 5, 10, 15, 20]) {
      expect(find.text(t.extraImsakRule(m)), findsWidgets);
    }
    await tapText(tester, t.extraImsakRule(5));
    expect((await settings.read()).extraTimes.imsakMinutes, 5);

    await tapText(tester, t.extraDuhaRule(15));
    await tapText(tester, t.extraDuhaRule(25));
    expect((await settings.read()).extraTimes.duhaMinutes, 25);
  });

  testApp('the switches on Prayer times show one on Today', (tester) async {
    await settings.saveExtraTimes(const ExtraTimesSettings(shown: {}));
    await open(tester);
    final duha = find.widgetWithText(SettingsSwitchRow, t.extraDuha);
    await tester.scrollUntilVisible(
      duha,
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.ensureVisible(duha);
    await tester.pumpAndSettle();
    await tester.tap(duha);
    await tester.pumpAndSettle();
    expect((await settings.read()).extraTimes.shown, {ExtraTime.duha});
  });

  testApp('Arabic at a large text size', (tester) async {
    await settings.setLanguage(AppLanguage.ar);
    await open(tester, textScale: 2.0);
    await tapText(tester, ar.extraAlertsAndTiming);
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(
      find.text(ar.extraQiyam),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
    expect(find.text(ar.extraQiyam), findsOneWidget);
  });
}
