import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/app_shell.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/onboarding/onboarding_page.dart';
import 'package:jamaah/src/features/settings/preference_pages.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// The first-run introduction (2026-10-14).
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

  Future<void> open(
    WidgetTester tester, {
    double textScale = 1.0,
    PlaceReading reading = const PlaceRejected(PlaceFailure.denied),
  }) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 14, 7, 0)),
          ),
          phoneUtcOffsetProvider.overrideWithValue(null),
          placeSourceProvider.overrideWithValue(FakePlaceSource(reading)),
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
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    final finder = find.text(text).last;
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Step 2 needs a place (owner, 2026-10-16): one from the bundled list.
  Future<void> chooseCity(WidgetTester tester, String choose) async {
    await tapText(tester, choose);
    await tapText(tester, 'Riyadh, Saudi Arabia');
  }

  testApp('a fresh install starts with the introduction', (tester) async {
    await open(tester);
    expect(find.byType(OnboardingPage), findsOneWidget);
    expect(find.text(t.onbWelcomeTagline), findsOneWidget);
    expect(find.text(t.onbStep(1, 5).toUpperCase()), findsOneWidget);
  });

  testApp('an install that already has a place goes straight in', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    await open(tester);
    expect(find.byType(OnboardingPage), findsNothing);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testApp('the whole way through: Arabic, a city, alerts, travel', (
    tester,
  ) async {
    await open(tester);

    // 1: the language switches at once, and the step stays where it is.
    await tapText(tester, 'العربية');
    expect(find.text(ar.onbWelcomeTagline), findsOneWidget);
    expect((await settings.read()).language, AppLanguage.ar);
    await tapText(tester, ar.onbContinue);

    // 2: a city from the list.
    expect(find.text(ar.locationSheetTitle), findsOneWidget);
    await tapText(tester, ar.locationChooseCity);
    await tapText(tester, 'Riyadh, Saudi Arabia');
    expect(find.textContaining('Riyadh'), findsOneWidget);
    expect((await settings.read()).location, isNotNull);
    expect(
      find.byType(OnboardingPage),
      findsOneWidget,
      reason: 'saving a place does not end the introduction',
    );
    await tapText(tester, ar.onbContinue);

    // 3: no mosque yet.
    await tapText(tester, ar.onbNotNow);

    // 4: alerts on (the default): five prayers, and the permission is asked.
    expect(find.text(ar.onbAlertsTitle), findsOneWidget);
    await tapText(tester, ar.onbContinue);
    final alerts = (await settings.read()).adhanAlerts;
    expect(alerts.enabledPrayers.toSet(), Prayer.iqamaPrayers.toSet());
    expect(permissionAsks, 1);

    // 5: travel mode on, then start.
    await tapText(tester, ar.onbTravelSwitch);
    await tapText(tester, ar.onbStart);
    final done = await settings.read();
    expect(done.onboardingDone, isTrue);
    expect(done.travel.travelMode, isTrue);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testApp('using the phone’s location says where it found you', (tester) async {
    await open(tester, reading: const PlaceFound(devicePlace));
    await tapText(tester, t.onbContinue);
    await tapText(tester, t.locationUseDevice);
    expect(find.text(t.onbPlaceFound('Cairo')), findsOneWidget);
    expect((await settings.read()).location!.usesGps, isTrue);
  });

  testApp('a refusal is said plainly, with the city list still there', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    await tapText(tester, t.locationUseDevice);
    expect(find.text(t.locationDenied), findsOneWidget);
    expect(find.text(t.locationChooseCity), findsOneWidget);
  });

  testApp('the place step waits for a place, and says nothing is lost', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    expect(find.text(t.onbStep(2, 5).toUpperCase()), findsOneWidget);
    await tapText(tester, t.onbContinue);
    expect(
      find.text(t.onbStep(2, 5).toUpperCase()),
      findsOneWidget,
      reason: 'Continue is disabled until there is a place',
    );
    expect(find.text(t.locationChooseCity), findsOneWidget);
    await chooseCity(tester, t.locationChooseCity);
    await tapText(tester, t.onbContinue);
    expect(find.text(t.onbStep(3, 5).toUpperCase()), findsOneWidget);
  });

  testApp('after the place, everything can be left for later', (tester) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    await chooseCity(tester, t.locationChooseCity);
    await tapText(tester, t.onbContinue);
    await tapText(tester, t.onbNotNow); // mosque
    await tapText(tester, t.onbAlertsSwitch); // off
    await tapText(tester, t.onbContinue);
    expect(permissionAsks, 0, reason: 'nothing to allow without alerts');
    expect((await settings.read()).adhanAlerts.hasAnyEnabled, isFalse);
    await tapText(tester, t.onbStart);
    expect(find.byType(AppShell), findsOneWidget);
  });

  testApp('alerts can be set to ring on silent, all of them at once', (
    tester,
  ) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    await chooseCity(tester, t.locationChooseCity);
    await tapText(tester, t.onbContinue);
    await tapText(tester, t.onbNotNow); // mosque
    await tapText(tester, t.onbRingInSilent);
    await tapText(tester, t.onbContinue);
    final s = await settings.read();
    expect(s.adhanAlerts.ringInSilentFor(RingTarget.adhan), RingCoverage.all);
    expect(
      s.adhanAlerts.ringInSilentFor(RingTarget.preAdhan),
      RingCoverage.all,
    );
    expect(s.jamaahReminders.ringInSilent, isTrue);
  });

  testApp('left alone, nothing rings on silent', (tester) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    await chooseCity(tester, t.locationChooseCity);
    await tapText(tester, t.onbContinue);
    await tapText(tester, t.onbNotNow);
    expect(find.text(t.onbRingInSilent), findsOneWidget);
    await tapText(tester, t.onbContinue);
    final s = await settings.read();
    expect(s.adhanAlerts.ringInSilentFor(RingTarget.adhan), RingCoverage.none);
    expect(s.jamaahReminders.ringInSilent, isFalse);
  });

  testApp('Back returns to the step before', (tester) async {
    await open(tester);
    await tapText(tester, t.onbContinue);
    expect(find.text(t.onbStep(2, 5).toUpperCase()), findsOneWidget);
    await tapText(tester, t.onbBack);
    expect(find.text(t.onbStep(1, 5).toUpperCase()), findsOneWidget);
  });

  testApp('Settings can show the introduction again, and comes back', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    // The user's own setup: Maghrib only. Walking through must keep it.
    await settings.saveAdhanAlerts(
      AdhanAlertSettings.defaults().withAlert(
        Prayer.maghrib,
        const AdhanAlert(enabled: true),
      ),
    );
    await open(tester);
    await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
    await tester.pumpAndSettle();
    await tapText(tester, t.settingsHelpAbout);
    await tester.scrollUntilVisible(
      find.text(t.settingsShowIntro),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    await tapText(tester, t.settingsShowIntro);
    expect(find.byType(OnboardingPage), findsOneWidget);
    await tapText(tester, t.onbContinue); // language
    await tapText(tester, t.onbContinue); // the place is already set
    await tapText(tester, t.onbNotNow); // no mosque
    await tapText(tester, t.onbContinue); // alerts
    await tapText(tester, t.onbStart);
    expect(find.byType(HelpAboutPage), findsOneWidget);
    expect((await settings.read()).adhanAlerts.enabledPrayers, [
      Prayer.maghrib,
    ], reason: 'replaying changes nothing the user did not change');
    expect(
      permissionAsks,
      0,
      reason: 'the switch started off (not all five on), so nothing to allow',
    );
  });

  testApp('every step survives Arabic at a large text size', (tester) async {
    await settings.setLanguage(AppLanguage.ar);
    await open(tester, textScale: 2.0);
    expect(tester.takeException(), isNull, reason: 'step 1');
    await tapText(tester, ar.onbContinue);
    expect(tester.takeException(), isNull, reason: 'step 2');
    await chooseCity(tester, ar.locationChooseCity);
    expect(tester.takeException(), isNull, reason: 'step 2, found');
    await tapText(tester, ar.onbContinue);
    expect(tester.takeException(), isNull, reason: 'step 3');
    await tapText(tester, ar.onbNotNow);
    expect(tester.takeException(), isNull, reason: 'step 4');
    await tapText(tester, ar.onbContinue);
    expect(tester.takeException(), isNull, reason: 'step 5');
    expect(find.text(ar.onbTravelTitle), findsOneWidget);
  });
}
