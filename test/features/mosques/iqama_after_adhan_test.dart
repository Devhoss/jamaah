import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
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
import 'package:jamaah/src/features/mosques/iqama_editor_sheet.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// Typing "22" for "22 minutes after the Adhan", as Kuwaiti mosques publish
/// their Iqama (tester feedback, 2026-10-14).
void main() {
  final t = AppLocalizationsEn();
  final ar = AppLocalizationsArDigits();

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FixedClock clock;
  LocalTime? pickerAnswer;

  setUpAll(loadTimeZoneDatabase);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    await settings.setOnboardingDone(true);
    // 10:00 in Cairo, Wednesday 14 October 2026.
    clock = FixedClock(DateTime.utc(2026, 10, 14, 7, 0));
    mosques = MosqueRepository(db, clock: clock);
    pickerAnswer = null;
    addTearDown(db.close);
  });

  Future<Mosque> addActive() async {
    final m = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await settings.setActiveMosqueId(m.id);
    return m;
  }

  Future<void> open(WidgetTester tester, {double textScale = 1.0}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(clock),
          phoneUtcOffsetProvider.overrideWithValue(null),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          notificationPermissionRequestProvider.overrideWithValue(() async {}),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          iqamaTimePickerProvider.overrideWithValue(
            (context, initial) async => pickerAnswer,
          ),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              alwaysUse24HourFormat: true,
              textScaler: TextScaler.linear(textScale),
            ),
            child: const JamaahApp(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await reveal(tester, find.text(text));
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> openMosque(WidgetTester tester) async {
    await tapText(tester, t.tabMosques);
    await tapText(tester, 'Masjid al-Nour');
  }

  int adhanOf(WidgetTester tester, Prayer p) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    return container.read(todayProvider)!.day.timeOf(p)!;
  }

  int tomorrowAdhanOf(WidgetTester tester, Prayer p) {
    final container = ProviderScope.containerOf(
      tester.element(find.byType(Scaffold).first),
    );
    final today = container.read(todayProvider)!.day.day;
    return container
        .read(prayerTimesCalculatorProvider)!
        .forDay(today.addDays(1))
        .timeOf(p)!;
  }

  String hhmm(int minutes) =>
      '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  Schedule stored(Mosque m) => m.schedules.single;

  testApp('a new Iqama starts as minutes after the Adhan, and adds them', (
    tester,
  ) async {
    final m = await addActive();
    await open(tester);
    final fajr = adhanOf(tester, Prayer.fajr);
    final fajrTomorrow = tomorrowAdhanOf(tester, Prayer.fajr);
    await openMosque(tester);
    await tapText(tester, t.prayerFajr);
    expect(find.byType(IqamaEditorSheet), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextField, t.iqamaMinutesLabel),
      '22',
    );
    await tester.pumpAndSettle();
    // At 10:00 today's Fajr is gone: the preview names tomorrow's, from
    // tomorrow's own Adhan.
    expect(
      find.text(
        t.iqamaAfterAdhanPreviewTomorrow(
          hhmm(fajrTomorrow),
          22,
          hhmm(fajrTomorrow + 22),
        ),
      ),
      findsOneWidget,
    );
    await tapText(tester, t.save);

    final e = stored((await mosques.byId(m.id))!).iqamaFor(Prayer.fajr);
    expect(e.afterAdhanMinutes, 22);
    expect(e.iqama, isNull);
    expect(find.text(t.rowAdhanPlus(22)), findsOneWidget);
    expect(find.text(hhmm(fajr + 22)), findsWidgets);
  });

  testApp('before Fajr, the preview names today’s Iqama', (tester) async {
    // 03:00 in Cairo.
    clock = FixedClock(DateTime.utc(2026, 10, 14, 0, 0));
    mosques = MosqueRepository(db, clock: clock);
    await addActive();
    await open(tester);
    final fajr = adhanOf(tester, Prayer.fajr);
    await openMosque(tester);
    await tapText(tester, t.prayerFajr);
    await tester.enterText(
      find.widgetWithText(TextField, t.iqamaMinutesLabel),
      '22',
    );
    await tester.pumpAndSettle();
    expect(
      find.text(t.iqamaAfterAdhanPreview(hhmm(fajr), 22, hhmm(fajr + 22))),
      findsOneWidget,
    );
  });

  testApp('a fixed time is still there for mosques that use one', (
    tester,
  ) async {
    final m = await addActive();
    await open(tester);
    await openMosque(tester);
    await tapText(tester, t.prayerMaghrib);
    await tapText(tester, t.iqamaModeFixed);
    pickerAnswer = const LocalTime(18 * 60 + 40);
    await tester.tap(
      find.descendant(
        of: find.byType(IqamaEditorSheet),
        matching: find.byIcon(Icons.schedule),
      ),
    );
    await tester.pumpAndSettle();
    await tapText(tester, t.save);
    final e = stored((await mosques.byId(m.id))!).iqamaFor(Prayer.maghrib);
    expect(e.iqama, const LocalTime(18 * 60 + 40));
    expect(e.afterAdhanMinutes, isNull);
  });

  testApp('minutes outside 1 to 90 cannot be saved', (tester) async {
    await addActive();
    await open(tester);
    await openMosque(tester);
    await tapText(tester, t.prayerAsr);
    for (final bad in ['0', '95']) {
      await tester.enterText(
        find.widgetWithText(TextField, t.iqamaMinutesLabel),
        bad,
      );
      await tester.pumpAndSettle();
      expect(find.text(t.iqamaMinutesInvalid), findsOneWidget);
      final save = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, t.save),
      );
      expect(save.onPressed, isNull);
    }
  });

  testApp('all five at once, as the mosque card gives them', (tester) async {
    final m = await addActive();
    await open(tester);
    final dhuhr = adhanOf(tester, Prayer.dhuhr);
    await openMosque(tester);
    await tapText(tester, t.enterAllFive);
    final fields = find.byType(TextField);
    expect(fields, findsNWidgets(5));
    for (final (i, v) in ['22', '20', '20', '10', ''].indexed) {
      await tester.enterText(fields.at(i), v);
    }
    await tester.pumpAndSettle();
    await tapText(tester, t.save);

    final s = stored((await mosques.byId(m.id))!);
    expect(s.iqamaFor(Prayer.fajr).afterAdhanMinutes, 22);
    expect(s.iqamaFor(Prayer.dhuhr).afterAdhanMinutes, 20);
    expect(s.iqamaFor(Prayer.maghrib).afterAdhanMinutes, 10);
    expect(s.iqamaFor(Prayer.isha).isConfigured, isFalse);

    // Today adds them to the day's Adhan.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tapText(tester, t.tabToday);
    await reveal(tester, find.text(t.rowIqama(hhmm(dhuhr + 20))));
    expect(find.text(t.rowIqama(hhmm(dhuhr + 20))), findsOneWidget);
  });

  testApp('Arabic at a large text size', (tester) async {
    await addActive();
    await settings.setLanguage(AppLanguage.ar);
    await open(tester, textScale: 2.0);
    await tapText(tester, ar.tabMosques);
    await tapText(tester, 'Masjid al-Nour');
    await tapText(tester, ar.enterAllFive);
    expect(tester.takeException(), isNull);
    await tapText(tester, ar.cancel);
    await tester.scrollUntilVisible(
      find.text(ar.prayerFajr),
      -200,
      scrollable: find.byType(Scrollable).last,
    );
    await tapText(tester, ar.prayerFajr);
    expect(tester.takeException(), isNull);
    expect(find.text(ar.iqamaModeAfterAdhan), findsOneWidget);
  });
}
