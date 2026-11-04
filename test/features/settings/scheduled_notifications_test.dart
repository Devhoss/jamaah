import 'dart:async';
import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/settings/scheduled_notifications_page.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The scheduled-notifications screen: what the phone has actually scheduled, and
/// the two permissions, which must update as soon as the user grants them —
/// whether or not the system ever replies to the request (seen on the device).
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late FakeNotificationGateway gateway;
  late int notificationRequests;
  late int exactRequests;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    gateway = FakeNotificationGateway(enabled: false, exact: false);
    notificationRequests = 0;
    exactRequests = 0;
    addTearDown(db.close);
  });

  /// A request the system never answers; the permission arrives anyway, the way
  /// it does when the user grants it.
  Future<void> neverAnswered(void Function() grant) {
    Timer(const Duration(milliseconds: 300), grant);
    return Completer<void>().future;
  }

  Future<void> open(WidgetTester tester) async {
    final clock = FixedClock(DateTime.utc(2026, 10, 13, 6, 0));
    final settings = SettingsRepository(db);
    await settings.setLocation(cairo.toStored());
    final mosques = MosqueRepository(db, clock: clock);
    final mosque = await mosques.add(
      name: 'Test Mosque',
      address: '',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(
      mosque.id,
      Prayer.asr,
      LocalTime.of(16, 5),
      reminderEnabled: true,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(clock),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          notificationGatewayProvider.overrideWithValue(gateway),
          notificationPermissionActionsProvider.overrideWithValue(
            NotificationPermissionActions(
              requestNotifications: () {
                notificationRequests++;
                return neverAnswered(() => gateway.enabled = true);
              },
              requestExactAlarms: () {
                exactRequests++;
                return neverAnswered(() => gateway.exact = true);
              },
            ),
          ),
        ],
        // As in the app: the keeper runs the scheduler for as long as the app
        // is open.
        child: const NotificationsKeeper(
          child: MaterialApp(
            locale: Locale('en'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ScheduledNotificationsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testApp('says plainly when notifications and exact alarms are not allowed', (
    tester,
  ) async {
    await open(tester);
    expect(find.text(t.scheduledNotificationsOff), findsOneWidget);
    expect(find.text(t.scheduledAllowNotifications), findsOneWidget);
    expect(find.text(t.scheduledExactOff), findsOneWidget);
    expect(find.text(t.scheduledAllowExact), findsOneWidget);
  });

  testApp('granting notifications clears the warning, with no reply needed', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.text(t.scheduledAllowNotifications));
    await tester.pump();
    expect(notificationRequests, 1);

    // The grant lands, and the next re-check (once a second) sees it.
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text(t.scheduledAllowNotifications), findsNothing);
    expect(find.text(t.scheduledNotificationsOff), findsNothing);
    expect(
      find.text(t.scheduledAllowExact),
      findsOneWidget,
      reason: 'the other permission is still missing, and still says so',
    );
  });

  testApp('granting exact alarms clears the warning and reschedules on time', (
    tester,
  ) async {
    // This test isolates exact-alarm access; notifications are already allowed.
    gateway.enabled = true;
    await open(tester);
    await tester.tap(find.text(t.scheduledAllowExact));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(exactRequests, 1);
    expect(find.text(t.scheduledAllowExact), findsNothing);
    expect(gateway.exactFlags.values, isNotEmpty);
    expect(
      gateway.exactFlags.values.every((exact) => exact),
      isTrue,
      reason: 'everything is rescheduled with exact timing once it is allowed',
    );
  });

  testApp('lists what is scheduled, in time order', (tester) async {
    // The device must allow notifications for the platform to have a schedule.
    gateway.enabled = true;
    await open(tester);
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(
      find.text(t.scheduledCount(gateway.scheduled.length)),
      findsOneWidget,
    );
    final titles = tester
        .widgetList<Text>(find.text(t.notifIqamaCall))
        .length;
    expect(titles, gateway.scheduled.length);
    expect(gateway.scheduled, isNotEmpty);
  });

  testApp('battery state is said plainly when optimisation is lifted', (
    tester,
  ) async {
    gateway.enabled = true;
    await open(tester);
    expect(find.text(t.scheduledBatteryExempt), findsOneWidget);
  });

  testApp('battery state warns while optimisation still applies', (tester) async {
    gateway.enabled = true;
    gateway.batteryExempt = false;
    await open(tester);
    expect(find.text(t.scheduledBatteryRestricted), findsOneWidget);
    expect(find.text(t.scheduledBatteryExempt), findsNothing);
  });

  testApp('battery state stays silent when the phone cannot be asked', (
    tester,
  ) async {
    gateway.enabled = true;
    gateway.batteryExempt = null;
    await open(tester);
    expect(find.text(t.scheduledBatteryExempt), findsNothing);
    expect(find.text(t.scheduledBatteryRestricted), findsNothing);
  });

  testApp('a test adhan schedules one real alarm two minutes out', (
    tester,
  ) async {
    // Debug builds (widget tests are one) show the delivery- check button.
    gateway.enabled = true;
    // A tall surface, so the delivery-check section is on screen: this test
    // is about the alarm, not the scroll.
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await open(tester);

    await tester.tap(find.text(t.scheduledTestAdhanButton));
    await tester.pumpAndSettle();

    expect(gateway.testAdhans, hasLength(1));
    final payload =
        jsonDecode(gateway.testAdhans.single.payload!) as Map<String, Object?>;
    final at = DateTime.parse(payload['at']! as String);
    final now = DateTime.now();
    expect(
      at.isAfter(now.add(const Duration(minutes: 1, seconds: 30))),
      isTrue,
      reason: 'far enough out to measure delivery, not so far one forgets it',
    );
    expect(
      at.isBefore(now.add(const Duration(minutes: 2, seconds: 30))),
      isTrue,
    );
    // The alarm joins the list, the way the native store reports it.
    expect(find.text(t.scheduledTestAdhanTitle), findsOneWidget);
  });
}
