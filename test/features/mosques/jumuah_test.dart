import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/clock_format.dart';
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
import 'package:jamaah/src/features/components/app_widgets.dart';
import 'package:jamaah/src/features/mosques/iqama_editor_sheet.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_notification_gateway.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// Jumu'ah (2026-10-14): each mosque's own time, in place of Dhuhr's Iqama on
/// the place's Fridays.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FixedClock clock;
  LocalTime? pickerAnswer;
  LocalTime? pickerOpenedAt;

  setUpAll(loadTimeZoneDatabase);

  /// 10:00 in Cairo on Friday 16 October 2026.
  final fridayMorning = DateTime.utc(2026, 10, 16, 7, 0);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    await settings.setOnboardingDone(true);
    clock = FixedClock(fridayMorning);
    mosques = MosqueRepository(db, clock: clock);
    pickerAnswer = null;
    pickerOpenedAt = null;
    addTearDown(db.close);
  });

  Future<Mosque> activeMosque({LocalTime? jumuah}) async {
    final m = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(
      m.id,
      Prayer.dhuhr,
      const LocalTime(12 * 60 + 55),
      reminderEnabled: true,
    );
    if (jumuah != null) await mosques.setJumuah(m.id, jumuah);
    await settings.setActiveMosqueId(m.id);
    return m;
  }

  Future<void> open(WidgetTester tester, {Place place = cairo}) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(place.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(clock),
          phoneUtcOffsetProvider.overrideWithValue(null),
          notificationGatewayProvider.overrideWithValue(
            FakeNotificationGateway(),
          ),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          iqamaTimePickerProvider.overrideWithValue((context, initial) async {
            pickerOpenedAt = initial;
            return pickerAnswer;
          }),
        ],
        child: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
            child: const JamaahApp(),
          ),
        ),
      ),
    );
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

  String clockText(WidgetTester tester, LocalTime time) =>
      ClockFormat.of(tester.element(find.byType(Scaffold).last)).time(time);

  group('Today on a Friday', () {
    testApp("Dhuhr is Jumu'ah, with the mosque's Jumu'ah time", (tester) async {
      await activeMosque(jumuah: const LocalTime(12 * 60 + 15));
      await open(tester);
      expect(find.text(t.prayerDhuhr), findsNothing);
      expect(find.textContaining(t.prayerJumuah), findsWidgets);
      final at = clockText(tester, const LocalTime(12 * 60 + 15));
      expect(find.text(t.rowIqama(at)), findsOneWidget);
      expect(find.text(t.jumuahNotSetNote), findsNothing);
    });

    testApp("without a Jumu'ah time: Dhuhr's Iqama, said plainly", (
      tester,
    ) async {
      await activeMosque();
      await open(tester);
      expect(find.text(t.jumuahNotSetNote), findsOneWidget);
      final at = clockText(tester, const LocalTime(12 * 60 + 55));
      expect(find.text(t.rowIqama(at)), findsOneWidget);
    });

    testApp('a Thursday is Dhuhr as usual', (tester) async {
      clock = FixedClock(DateTime.utc(2026, 10, 15, 7, 0));
      await activeMosque(jumuah: const LocalTime(12 * 60 + 15));
      await open(tester);
      expect(find.text(t.prayerDhuhr), findsOneWidget);
      expect(find.text(t.prayerJumuah), findsNothing);
    });

    testApp("the place's Friday, while the phone is still on Thursday", (
      tester,
    ) async {
      // 20:00 UTC Thursday is 10:00 Friday at Kiritimati (UTC+14).
      clock = FixedClock(DateTime.utc(2026, 10, 15, 20, 0));
      await activeMosque(jumuah: const LocalTime(12 * 60 + 15));
      await open(
        tester,
        place: const Place(
          displayName: 'Kiritimati, Kiribati',
          latitude: 1.87,
          longitude: -157.43,
          ianaZone: 'Pacific/Kiritimati',
          fromDevice: false,
        ),
      );
      expect(find.text(t.prayerDhuhr), findsNothing);
      expect(find.textContaining(t.prayerJumuah), findsWidgets);
    });
  });

  group('the mosque page', () {
    Future<void> openMosque(WidgetTester tester) async {
      await open(tester);
      await tapText(tester, t.tabMosques);
      await tapText(tester, 'Masjid al-Nour');
    }

    testApp("a Jumu'ah row, not configured on a new mosque", (tester) async {
      await activeMosque();
      await openMosque(tester);
      await tester.scrollUntilVisible(
        find.text(t.jumuahRowHint),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text(t.prayerJumuah), findsOneWidget);
      expect(find.text(t.jumuahRowHint), findsOneWidget);
    });

    testApp("setting the Jumu'ah time starts at Dhuhr's Adhan", (tester) async {
      final m = await activeMosque();
      await openMosque(tester);
      pickerAnswer = const LocalTime(12 * 60 + 10);
      await tapText(tester, t.jumuahRowHint);
      expect(find.byType(IqamaEditorSheet), findsOneWidget);
      expect(find.text(t.iqamaEditorTitle(t.prayerJumuah)), findsOneWidget);
      await tester.tap(
        find.descendant(
          of: find.byType(IqamaEditorSheet),
          matching: find.byIcon(Icons.schedule),
        ),
      );
      await tester.pumpAndSettle();
      expect(pickerOpenedAt, isNotNull, reason: "Dhuhr's Adhan, to start");
      await tapText(tester, t.save);
      final saved = (await mosques.byId(m.id))!.schedules.single;
      expect(saved.jumuah.iqama, const LocalTime(12 * 60 + 10));
      expect(
        saved.iqamaFor(Prayer.dhuhr).iqama,
        const LocalTime(12 * 60 + 55),
        reason: 'Dhuhr is untouched',
      );
    });

    testApp("its reminder switch is Jumu'ah's own", (tester) async {
      final m = await activeMosque(jumuah: const LocalTime(12 * 60 + 15));
      await openMosque(tester);
      final row = find.ancestor(
        of: find.text(t.jumuahRowHint),
        matching: find.byType(AppRow),
      );
      await tester.scrollUntilVisible(
        find.text(t.jumuahRowHint),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      final toggle = find.descendant(of: row, matching: find.byType(Switch));
      await tester.ensureVisible(toggle);
      await tester.pumpAndSettle();
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      final saved = (await mosques.byId(m.id))!.schedules.single;
      expect(saved.jumuah.hasReminder, isTrue);
      expect(saved.iqamaFor(Prayer.dhuhr).hasReminder, isTrue);
    });
  });
}
