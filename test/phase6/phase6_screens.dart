import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/compass.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/features/flight/in_flight_help_page.dart';
import 'package:jamaah/src/features/flight/in_flight_page.dart';
import 'package:jamaah/src/features/location/city_list_page.dart';
import 'package:jamaah/src/features/location/preview_city_page.dart';
import 'package:jamaah/src/features/mosques/mosque_detail_page.dart';
import 'package:jamaah/src/features/mosques/nearby_mosques_page.dart';
import 'package:jamaah/src/features/onboarding/onboarding_page.dart';
import 'package:jamaah/src/features/settings/adhan_alerts_page.dart';
import 'package:jamaah/src/features/settings/adhan_recordings_page.dart';
import 'package:jamaah/src/features/settings/extra_times_page.dart';
import 'package:jamaah/src/features/settings/jamaah_reminder_settings.dart';
import 'package:jamaah/src/features/settings/prayer_alert_page.dart';
import 'package:jamaah/src/features/settings/prayer_time_settings.dart';
import 'package:jamaah/src/features/settings/prayer_times_page.dart';
import 'package:jamaah/src/features/settings/preference_pages.dart';
import 'package:jamaah/src/features/settings/scheduled_notifications_page.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';

/// The screens Phase 6 checks, and the app they open in (Horizon spec §5,
/// §6): shared by the screen matrix and the golden tests.

/// Each screen, opened from the shell the way the app opens it.
final phase6Screens = <String, Future<void> Function(WidgetTester, String)>{
  'Today': (tester, _) => _tab(tester, 0),
  'Mosques': (tester, _) => _tab(tester, 1),
  'Qibla': (tester, _) => _tab(tester, 2),
  'Settings': (tester, _) => _tab(tester, 3),
  'Mosque page': (tester, id) => _push(tester, MosqueDetailPage(mosqueId: id)),
  'Prayer times': (tester, _) => _push(tester, const PrayerTimesPage()),
  'Method list': (tester, _) => _push(tester, const MethodListPage()),
  'Far north or south': (tester, _) => _push(tester, const HighLatitudePage()),
  'Minutes': (tester, _) => _push(tester, const AdjustmentsPage()),
  'Extra times': (tester, _) => _push(tester, const ExtraTimesPage()),
  'Adhan alerts': (tester, _) => _push(tester, const AdhanAlertsPage()),
  'One prayer': (tester, _) =>
      _push(tester, const PrayerAlertPage(prayer: Prayer.maghrib)),
  'Recordings': (tester, _) => _push(tester, const AdhanRecordingsPage()),
  "Jama'ah reminders": (tester, _) =>
      _push(tester, const JamaahRemindersPage()),
  'Travel': (tester, _) => _push(tester, const TravelPage()),
  'Language and look': (tester, _) => _push(tester, const LanguageLookPage()),
  'Help and about': (tester, _) => _push(tester, const HelpAboutPage()),
  'Late alerts': (tester, _) => _push(tester, const LateAlertsPage()),
  'Scheduled list': (tester, _) =>
      _push(tester, const ScheduledNotificationsPage()),
  'In flight': (tester, _) => _push(tester, const InFlightPage()),
  'How it works': (tester, _) => _push(tester, const InFlightHelpPage()),
  'Find nearby': (tester, _) => _push(tester, const NearbyMosquesPage()),
  'City list': (tester, _) => _push(tester, const CityListPage()),
  'Preview a city': (tester, _) =>
      _push(tester, const PreviewCityPage(city: cairo)),
  'Introduction': (tester, _) =>
      _push(tester, const OnboardingPage(replay: true)),
};

/// The app with a place, an active mosque with some Iqama times, and the
/// chosen language, text size and theme. Returns the mosque's id.
Future<String> startPhase6App(
  WidgetTester tester, {
  required AppLanguage language,
  required double scale,
  required AppThemeMode theme,
  double pixelRatio = 3,
}) async {
  tester.view.physicalSize = Size(360 * pixelRatio, 800 * pixelRatio);
  tester.view.devicePixelRatio = pixelRatio;
  addTearDown(tester.view.reset);

  final db = AppDatabase(NativeDatabase.memory());
  addTearDown(db.close);
  final settings = SettingsRepository(db);
  final mosques = MosqueRepository(db);
  await settings.setOnboardingDone(true);
  await settings.setLocation(cairo.toStored());
  await settings.setLanguage(language);
  await settings.setThemeMode(theme);
  final mosque = await mosques.add(
    name: 'Masjid al-Nour',
    address: '12 Garden Road',
    source: MosqueSource.manual,
  );
  await mosques.setAfterAdhanForAll(mosque.id, {
    Prayer.fajr: 20,
    Prayer.dhuhr: 15,
    Prayer.maghrib: 10,
  });
  await settings.setActiveMosqueId(mosque.id);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        // 10:00 in Cairo.
        appClockProvider.overrideWithValue(
          FixedClock(DateTime.utc(2026, 10, 12, 7, 0)),
        ),
        placeSourceProvider.overrideWithValue(
          FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
        ),
        notificationGatewayProvider.overrideWithValue(
          FakeNotificationGateway(),
        ),
        compassSourceProvider.overrideWithValue(_StillCompass()),
      ],
      child: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: const JamaahApp(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return mosque.id;
}

Future<void> _tab(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(BottomNav.tabKey(index)));
  await tester.pumpAndSettle();
}

Future<void> _push(WidgetTester tester, Widget page) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  unawaited(navigator.push(MaterialPageRoute<void>(builder: (_) => page)));
  await tester.pumpAndSettle();
}

/// A compass that answers once, pointing north: the dial is drawn turning.
class _StillCompass implements CompassSource {
  @override
  Stream<CompassReading> readings() =>
      Stream.value(const CompassReading(heading: 0, accuracy: 15));

  @override
  Future<double?> declination({
    required double latitude,
    required double longitude,
  }) async => 0;
}
