import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/clock_format.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/components/horizon_controls.dart';
import 'package:jamaah/src/features/mosques/iqama_editor_sheet.dart';
import 'package:jamaah/src/features/mosques/mosque_detail_page.dart';
import 'package:jamaah/src/features/mosques/mosques_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The Mosques tab, a mosque's Iqama schedule and the editor, driven the way a
/// user would: through the real shell, the real providers and an in-memory
/// database. The only stand-in is the time picker, answered by [pickerAnswer].
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FixedClock clock;
  LocalTime? pickerAnswer;
  // What the editor opened the picker at, so a test can check the starting point.
  LocalTime? pickerOpenedAt;
  var pickerOpened = false;

  setUpAll(loadTimeZoneDatabase);

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    // These test the app after the first-run introduction.
    await settings.setOnboardingDone(true);
    // 10:00 in Cairo: Dhuhr is still ahead.
    clock = FixedClock(DateTime.utc(2026, 10, 12, 7, 0));
    mosques = MosqueRepository(db, clock: clock);
    pickerAnswer = null;
    pickerOpenedAt = null;
    pickerOpened = false;
    addTearDown(db.close);
  });

  Widget harness({double textScale = 1.0}) => ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
      appClockProvider.overrideWithValue(clock),
      placeSourceProvider.overrideWithValue(
        FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
      ),
      iqamaTimePickerProvider.overrideWithValue(
        (context, initial) async {
          pickerOpened = true;
          pickerOpenedAt = initial;
          return pickerAnswer;
        },
      ),
    ],
    child: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: const JamaahApp(),
      ),
    ),
  );

  Future<void> open(
    WidgetTester tester, {
    bool withPlace = true,
    double textScale = 1.0,
  }) async {
    // A phone's shape (360 x 800 logical), so what is on screen here is what is
    // on screen on the device, and anything lower has to be scrolled to.
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    if (withPlace) await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(harness(textScale: textScale));
    await tester.pumpAndSettle();
  }

  /// Scrolls the topmost list until [finder] is on screen, the way a user would
  /// before reading or tapping something low on a phone-sized page.
  Future<void> reveal(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).last,
      );
    }
    final rect = tester.getRect(finder.last);
    final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
    if (rect.top >= 0 && rect.bottom <= screen.height) return;
    await tester.ensureVisible(finder.last);
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await reveal(tester, find.text(text));
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> goToMosques(WidgetTester tester) =>
      tapText(tester, t.tabMosques);

  /// The clock format the screen itself resolved, so expectations follow the
  /// test device's 12/24-hour setting rather than assuming one.
  ClockFormat clockOn(WidgetTester tester) =>
      ClockFormat.of(tester.element(find.byType(Scaffold).last));

  Future<Mosque> savedMosque(String name) async {
    final all = await mosques.saved();
    return all.singleWhere((m) => m.name == name);
  }

  PrayerIqama storedEntry(Mosque mosque, Prayer prayer) =>
      mosque.schedules.single.iqamaFor(prayer);

  /// The reminder switch on the Iqama editor, which opens over the mosque page
  /// and so comes after that page's own "Pause" switch.
  Finder editorSwitch() => find.byType(SwitchListTile).last;

  /// The quick reminder switches on the schedule rows, without the page's
  /// "Pause this mosque's reminders" switch.
  Finder rowSwitches() => find.byElementPredicate(
    (e) =>
        e.widget is Switch &&
        e.findAncestorWidgetOfExactType<SwitchListTile>() == null,
  );

  Finder buttonWith(String label) => find.ancestor(
    of: find.text(label),
    matching: find.bySubtype<ButtonStyleButton>(),
  );

  bool isEnabled(WidgetTester tester, String label) =>
      tester.widget<ButtonStyleButton>(buttonWith(label).last).onPressed !=
      null;

  /// The tab's add button: "Add one yourself" while the list is empty,
  /// "Add manually" once it has a mosque (Horizon).
  Future<void> tapAddOnTab(WidgetTester tester) async {
    final empty = find.text(t.mosquesEmptyAdd);
    await tapText(
      tester,
      empty.evaluate().isNotEmpty ? t.mosquesEmptyAdd : t.mosquesAddManually,
    );
  }

  /// Adds a mosque through the sheet, landing on its detail page.
  Future<void> addThroughSheet(
    WidgetTester tester, {
    String name = 'Masjid al-Nour',
    String address = '12 Garden Road',
  }) async {
    await goToMosques(tester);
    await tapAddOnTab(tester);
    await tester.enterText(
      find.widgetWithText(TextField, t.mosqueNameLabel),
      name,
    );
    await tester.enterText(
      find.widgetWithText(TextField, t.mosqueAddressLabel),
      address,
    );
    await tester.pump();
    await tester.tap(buttonWith(t.add));
    await tester.pumpAndSettle();
  }

  /// Opens the editor for [prayer] on the detail page that is showing.
  Future<void> openEditor(WidgetTester tester, Prayer prayer) async {
    final name = switch (prayer) {
      Prayer.fajr => t.prayerFajr,
      Prayer.dhuhr => t.prayerDhuhr,
      Prayer.asr => t.prayerAsr,
      Prayer.maghrib => t.prayerMaghrib,
      Prayer.isha => t.prayerIsha,
      Prayer.sunrise => throw ArgumentError('Sunrise has no Iqama'),
    };
    await tapText(tester, name);
    // These tests use the time picker: a new Iqama opens on "Minutes after
    // Adhan" (2026-10-14), so switch to a fixed time first.
    final pickerField = find.descendant(
      of: find.byType(IqamaEditorSheet),
      matching: find.byIcon(Icons.schedule),
    );
    if (pickerField.evaluate().isEmpty) {
      await tester.tap(find.text(t.iqamaModeFixed));
      await tester.pumpAndSettle();
    }
  }

  Future<void> chooseTime(WidgetTester tester, LocalTime time) async {
    pickerAnswer = time;
    // The field's wording depends on whether there is an Adhan time to start
    // from, so tap it by its clock icon rather than by its text.
    await tester.tap(find.byIcon(Icons.schedule));
    await tester.pumpAndSettle();
  }

  group('the Mosques tab (Horizon)', () {
    testApp('empty: there is a place for you, and nothing is guessed', (
      tester,
    ) async {
      await open(tester);
      await goToMosques(tester);
      expect(find.text(t.mosquesEmptyTitle), findsOneWidget);
      expect(find.text(t.mosquesEmptyBody), findsOneWidget);
      expect(find.text(t.mosquesEmptyNote), findsOneWidget);
      expect(find.text(t.mosquesEmptyFind), findsOneWidget);
      expect(find.text(t.mosquesEmptyAdd), findsOneWidget);
      expect(find.byType(CongregationFigures), findsOneWidget);
    });

    testApp('each mosque says where it came from and how much is set', (
      tester,
    ) async {
      final found = await mosques.add(
        name: 'Found Mosque',
        address: '',
        source: MosqueSource.google,
      );
      await settings.setActiveMosqueId(found.id);
      await open(tester);
      await goToMosques(tester);
      expect(find.text(t.mosqueSourceGoogleUnverified), findsOneWidget);
      expect(find.text(t.mosqueNoIqamaYet), findsOneWidget);
      expect(find.text(t.mosqueActiveLong), findsOneWidget);
      expect(find.text(t.mosquesLead('Found Mosque')), findsOneWidget);
      await mosques.setIqama(found.id, Prayer.fajr, LocalTime.of(5, 0));
      await mosques.setIqama(found.id, Prayer.asr, null, afterAdhanMinutes: 15);
      await tester.pumpAndSettle();
      expect(find.text(t.iqamaStatusPartial(2, 6)), findsOneWidget);
      await reveal(tester, find.text(t.mosquesFooter));
      expect(find.text(t.mosquesFooter), findsOneWidget);
    });

    testApp('Make active moves Today to that mosque, and says so', (
      tester,
    ) async {
      final first = await mosques.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.add(name: 'Second', address: '', source: MosqueSource.manual);
      await settings.setActiveMosqueId(first.id);
      await open(tester);
      await goToMosques(tester);
      expect(find.text(t.mosqueMakeActive), findsOneWidget);
      await tapText(tester, t.mosqueMakeActive);
      final second = await savedMosque('Second');
      expect((await settings.read()).activeMosqueId, second.id);
      expect(find.text(t.mosqueMadeActive('Second')), findsOneWidget);
      expect(find.text(t.mosquesLead('Second')), findsOneWidget);
    });
  });

  group('adding a mosque by hand', () {
    testApp('Add stays disabled until there is a name', (tester) async {
      await open(tester);
      await goToMosques(tester);
      await tapAddOnTab(tester);

      expect(isEnabled(tester, t.add), isFalse);
      await tester.enterText(
        find.widgetWithText(TextField, t.mosqueNameLabel),
        '   ',
      );
      await tester.pump();
      expect(
        isEnabled(tester, t.add),
        isFalse,
        reason: 'spaces are not a name',
      );

      await tester.enterText(
        find.widgetWithText(TextField, t.mosqueNameLabel),
        'Masjid al-Nour',
      );
      await tester.pump();
      expect(isEnabled(tester, t.add), isTrue);
    });

    testApp('a new mosque opens with every Iqama time not configured', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester, name: '  Masjid al-Nour ');

      expect(find.byType(MosqueDetailPage), findsOneWidget);
      expect(find.text('Masjid al-Nour'), findsOneWidget);
      expect(
        find.text(t.notConfigured),
        findsNWidgets(6),
        reason: 'AGENTS.md: a new mosque never gets invented Iqama times',
      );
      expect(
        find.text(t.prayerSunrise),
        findsNothing,
        reason: 'Sunrise has no Iqama, so it has no row here',
      );
      await reveal(tester, find.text(t.scheduleNothingEntered));
      expect(find.text(t.scheduleNothingEntered), findsOneWidget);

      final stored = await savedMosque('Masjid al-Nour');
      expect(stored.address, '12 Garden Road');
      expect(stored.source, MosqueSource.manual);
      expect(stored.schedules.single.configuredCount, 0);
    });

    testApp('the first mosque becomes active, and the list says so', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);

      expect(find.text(t.tagActive), findsOneWidget);
      expect(find.text(t.setAsActive), findsNothing);

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.byType(MosquesScreen), findsOneWidget);
      expect(find.text('Masjid al-Nour'), findsOneWidget);
      expect(find.text(t.mosqueActiveLong), findsOneWidget);
      expect(find.text(t.mosqueNoIqamaYet), findsOneWidget);
      expect(find.text(t.mosquesEmptyTitle), findsNothing);
    });

    testApp('cancelling stores nothing', (tester) async {
      await open(tester);
      await goToMosques(tester);
      await tapAddOnTab(tester);
      await tester.enterText(
        find.widgetWithText(TextField, t.mosqueNameLabel),
        'Masjid al-Nour',
      );
      await tapText(tester, t.cancel);

      expect(await mosques.saved(), isEmpty);
      expect(find.text(t.mosquesEmptyTitle), findsOneWidget);
    });
  });

  group('the Iqama editor', () {
    testApp('an empty Iqama starts the picker at the Adhan time, saving nothing', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.fajr);

      final container = ProviderScope.containerOf(
        tester.element(find.byType(IqamaEditorSheet)),
      );
      final adhan = LocalTime(
        container.read(todayProvider)!.day.timeOf(Prayer.fajr)!,
      );
      final at = clockOn(tester).time;

      expect(find.text(t.iqamaStartsAtAdhan(at(adhan))), findsOneWidget);
      expect(
        isEnabled(tester, t.save),
        isFalse,
        reason: 'the Adhan time is where the picker starts, never a saved value '
            '(AGENTS.md: Iqama is never derived from Adhan)',
      );
      expect(find.text(t.summaryNoTime), findsOneWidget);

      // Backing out of the picker leaves nothing chosen.
      pickerAnswer = null;
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      expect(pickerOpened, isTrue);
      expect(pickerOpenedAt, adhan);
      expect(isEnabled(tester, t.save), isFalse);

      await tapText(tester, t.cancel);
      expect(
        storedEntry(await savedMosque('Masjid al-Nour'), Prayer.fajr)
            .isConfigured,
        isFalse,
      );
    });

    testApp('a configured Iqama reopens the picker at that Iqama', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      final mosque = await savedMosque('Masjid al-Nour');
      await mosques.setIqama(mosque.id, Prayer.fajr, LocalTime.of(5, 50));
      await tester.pumpAndSettle();
      await openEditor(tester, Prayer.fajr);

      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      expect(pickerOpenedAt, LocalTime.of(5, 50));
    });

    testApp('without a place there is no Adhan time to start from', (
      tester,
    ) async {
      await open(tester, withPlace: false);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.fajr);

      expect(find.text(t.iqamaChooseTime), findsOneWidget);
      await tester.tap(find.byIcon(Icons.schedule));
      await tester.pumpAndSettle();
      expect(pickerOpened, isTrue);
      expect(pickerOpenedAt, isNull);
    });

    testApp('names the mosque and prayer, and Save waits for a time', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.fajr);

      expect(find.text(t.iqamaEditorTitle(t.prayerFajr)), findsOneWidget);
      expect(find.text(t.iqamaEditorEditing('Masjid al-Nour')), findsOneWidget);
      expect(find.text(t.summaryNoTime), findsOneWidget);
      expect(isEnabled(tester, t.save), isFalse);
      expect(
        tester.widget<SwitchListTile>(editorSwitch()).onChanged,
        isNull,
        reason: 'no Iqama time, no reminder (AGENTS.md)',
      );
      expect(find.text(t.reminderNeedsTime), findsOneWidget);
      expect(find.text(t.clearIqamaTime), findsNothing);
    });

    testApp('saving a time and a reminder lands on the mosque', (tester) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.fajr);
      final clockFormat = clockOn(tester);
      final at = clockFormat.time;

      await chooseTime(tester, LocalTime.of(5, 40));
      expect(
        find.text(t.summaryReminderOff(t.prayerFajr, at(LocalTime.of(5, 40)))),
        findsOneWidget,
      );

      await tester.tap(editorSwitch());
      await tester.pumpAndSettle();
      expect(
        find.text(
          t.summaryReminderAt(
            t.prayerFajr,
            at(LocalTime.of(5, 40)),
            at(LocalTime.of(5, 30)),
          ),
        ),
        findsOneWidget,
        reason: 'a new reminder starts at 10 minutes, as stored',
      );

      await tapText(tester, t.reminderMinutesChip(15));
      expect(
        find.text(
          t.summaryReminderAt(
            t.prayerFajr,
            at(LocalTime.of(5, 40)),
            at(LocalTime.of(5, 25)),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(buttonWith(t.save));
      await tester.pumpAndSettle();

      final fajr = storedEntry(
        await savedMosque('Masjid al-Nour'),
        Prayer.fajr,
      );
      expect(fajr.iqama, LocalTime.of(5, 40));
      expect(fajr.reminderEnabled, isTrue);
      expect(fajr.reminderMinutesBefore, 15);

      // Back on the schedule: the row shows the Iqama, its reminder, and the stamp.
      expect(find.text(at(LocalTime.of(5, 40))), findsOneWidget);
      expect(
        find.text(t.rowReminderAt(at(LocalTime.of(5, 25)))),
        findsOneWidget,
      );
      expect(find.text(t.notConfigured), findsNWidgets(5));
      await reveal(tester, find.text(t.scheduleSetByYou('12 Oct 2026')));
      expect(find.text(t.scheduleSetByYou('12 Oct 2026')), findsOneWidget);
    });

    testApp('Cancel discards the edit', (tester) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.dhuhr);
      await chooseTime(tester, LocalTime.of(13, 15));
      await tapText(tester, t.cancel);

      expect(
        storedEntry(
          await savedMosque('Masjid al-Nour'),
          Prayer.dhuhr,
        ).isConfigured,
        isFalse,
      );
      expect(find.text(t.notConfigured), findsNWidgets(6));
    });

    testApp('Clear returns the prayer to not configured', (tester) async {
      await open(tester);
      await addThroughSheet(tester);
      final mosque = await savedMosque('Masjid al-Nour');
      await mosques.setIqama(
        mosque.id,
        Prayer.asr,
        LocalTime.of(16, 0),
        reminderEnabled: true,
      );
      await tester.pumpAndSettle();
      await openEditor(tester, Prayer.asr);
      await tapText(tester, t.clearIqamaTime);

      final asr = storedEntry(await savedMosque('Masjid al-Nour'), Prayer.asr);
      expect(asr.isConfigured, isFalse);
      expect(asr.hasReminder, isFalse);
      expect(find.text(t.notConfigured), findsNWidgets(6));
    });

    testApp('a custom interval is checked before it can be saved', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.maghrib);
      await chooseTime(tester, LocalTime.of(18, 30));
      await tester.tap(editorSwitch());
      await tester.pumpAndSettle();
      await tapText(tester, t.reminderCustom);

      final field = find.widgetWithText(TextField, t.reminderCustomLabel);
      for (final (input, error) in [
        ('0', t.reminderCustomOutOfRange),
        ('121', t.reminderCustomOutOfRange),
        ('7.5', t.reminderCustomNotWhole),
      ]) {
        await tester.enterText(field, input);
        await tester.pump();
        expect(find.text(error), findsOneWidget, reason: '"$input"');
        expect(isEnabled(tester, t.save), isFalse, reason: '"$input"');
      }

      await tester.enterText(field, '25');
      await tester.pump();
      final at = clockOn(tester).time;
      expect(
        find.text(
          t.summaryReminderAt(
            t.prayerMaghrib,
            at(LocalTime.of(18, 30)),
            at(LocalTime.of(18, 5)),
          ),
        ),
        findsOneWidget,
      );
      expect(isEnabled(tester, t.save), isTrue);
      await tester.tap(buttonWith(t.save));
      await tester.pumpAndSettle();

      expect(
        storedEntry(
          await savedMosque('Masjid al-Nour'),
          Prayer.maghrib,
        ).reminderMinutesBefore,
        25,
      );
    });

    testApp('a reminder before midnight says so instead of implying the day', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.isha);
      await chooseTime(tester, LocalTime.of(0, 5));
      await tester.tap(editorSwitch());
      await tester.pumpAndSettle();

      final at = clockOn(tester).time;
      expect(
        find.text(
          t.summaryReminderBeforeMidnight(
            t.prayerIsha,
            at(LocalTime.of(0, 5)),
            at(LocalTime.of(23, 55)),
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(buttonWith(t.save));
      await tester.pumpAndSettle();
      expect(
        find.text(t.rowReminderBeforeMidnight(at(LocalTime.of(23, 55)))),
        findsOneWidget,
      );
    });
  });

  group('the schedule rows', () {
    testApp('the quick switch waits for a time, then toggles the reminder', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await addThroughSheet(tester);

      final fajrSwitch = find.bySemanticsLabel(
        RegExp(RegExp.escape(t.reminderSwitchLabel(t.prayerFajr))),
      );
      expect(fajrSwitch, findsOneWidget);
      final switches = tester.widgetList<Switch>(rowSwitches());
      expect(
        switches.every((s) => s.onChanged == null),
        isTrue,
        reason: 'no prayer has a time yet, so no reminder can be switched on',
      );
      expect(find.text(t.rowReminderNeedsIqama), findsNWidgets(6));

      final mosque = await savedMosque('Masjid al-Nour');
      await mosques.setIqama(mosque.id, Prayer.fajr, LocalTime.of(5, 40));
      await tester.pumpAndSettle();
      expect(find.text(t.rowReminderOff), findsOneWidget);

      await tester.tap(rowSwitches().first);
      await tester.pumpAndSettle();

      expect(
        storedEntry(
          await savedMosque('Masjid al-Nour'),
          Prayer.fajr,
        ).hasReminder,
        isTrue,
      );
      expect(find.text(t.rowReminderOff), findsNothing);
      handle.dispose();
    });

    testApp('each row shows the day\'s Adhan time apart from the Iqama', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);

      expect(
        find.textContaining(RegExp('^${RegExp.escape(t.rowAdhanTime(''))}')),
        findsNWidgets(5),
        reason: 'the Adhan time is a small secondary line, never the Iqama',
      );
    });

    testApp('Edit details renames the mosque everywhere', (tester) async {
      await open(tester);
      await addThroughSheet(tester);
      await tapText(tester, t.editDetails);
      await tester.enterText(
        find.widgetWithText(TextField, t.mosqueNameLabel),
        'Al-Nour Mosque',
      );
      await tester.pump();
      await tester.tap(buttonWith(t.save));
      await tester.pumpAndSettle();

      expect(find.text('Al-Nour Mosque'), findsOneWidget);
      expect(
        find.text(t.iqamaScheduleHeader('Al-Nour Mosque').toUpperCase()),
        findsOneWidget,
      );
      expect((await mosques.saved()).single.name, 'Al-Nour Mosque');
    });
  });

  group('active mosque and removal', () {
    testApp('Set as active moves the Active tag', (tester) async {
      await open(tester);
      await addThroughSheet(tester, name: 'First');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapAddOnTab(tester);
      await tester.enterText(
        find.widgetWithText(TextField, t.mosqueNameLabel),
        'Second',
      );
      await tester.pump();
      await tester.tap(buttonWith(t.add));
      await tester.pumpAndSettle();

      expect(find.text(t.setAsActive), findsOneWidget);
      await tapText(tester, t.setAsActive);

      final second = await savedMosque('Second');
      expect((await settings.read()).activeMosqueId, second.id);
      expect(find.text(t.setAsActive), findsNothing);
      expect(find.text(t.tagActive), findsOneWidget);
    });

    testApp('removing asks first, and Cancel keeps the mosque', (tester) async {
      await open(tester);
      await addThroughSheet(tester);
      await tapText(tester, t.removeMosque);

      expect(find.text(t.removeMosqueTitle('Masjid al-Nour')), findsOneWidget);
      expect(find.text(t.removeMosqueBodyActive), findsOneWidget);
      await tapText(tester, t.cancel);

      expect(await mosques.saved(), hasLength(1));
      expect(find.byType(MosqueDetailPage), findsOneWidget);
    });

    testApp('removing the active mosque clears it, and Today asks again', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await tapText(tester, t.removeMosque);
      await tapText(tester, t.remove);

      expect(await mosques.saved(), isEmpty);
      expect((await settings.read()).activeMosqueId, isNull);
      expect(find.byType(MosqueDetailPage), findsNothing);
      expect(find.text(t.mosquesEmptyTitle), findsOneWidget);

      await tapText(tester, t.tabToday);
      expect(find.text(t.addMosqueTitle), findsOneWidget);
    });
  });

  group('pausing one mosque\'s reminders', () {
    testApp('the switch is on the mosque, and Today and the list say so', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      final pause = find.widgetWithText(SwitchListTile, t.mosquePauseReminders);
      await reveal(tester, pause);
      await tester.tap(pause);
      await tester.pumpAndSettle();

      expect((await savedMosque('Masjid al-Nour')).remindersPaused, isTrue);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text(t.tagRemindersPaused), findsOneWidget);

      await tapText(tester, t.tabToday);
      expect(find.text(t.pausedMosqueNote('Masjid al-Nour')), findsOneWidget);
    });

    testApp('with all reminders paused, the mosque page says where', (
      tester,
    ) async {
      await settings.saveTravel(
        const TravelSettings(pauseAllIqamaReminders: true),
      );
      await open(tester);
      await addThroughSheet(tester);
      await reveal(tester, find.text(t.mosquePauseAllOn));
      expect(find.text(t.mosquePauseAllOn), findsOneWidget);
    });
  });

  group('Today follows the mosque', () {
    testApp('an Iqama entered in the editor reaches Today at once', (
      tester,
    ) async {
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.dhuhr);
      await chooseTime(tester, LocalTime.of(12, 15));
      await tester.tap(buttonWith(t.save));
      await tester.pumpAndSettle();
      final at = clockOn(tester).time;

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, t.tabToday);

      await reveal(tester, find.text(t.rowIqama(at(LocalTime.of(12, 15)))));
      expect(find.text(t.rowIqama(at(LocalTime.of(12, 15)))), findsOneWidget);
      expect(find.text('IQAMA · Masjid al-Nour', findRichText: true), findsOneWidget);

      // Change it without leaving Today: the stream carries the edit.
      final mosque = await savedMosque('Masjid al-Nour');
      await mosques.setIqama(mosque.id, Prayer.dhuhr, LocalTime.of(12, 30));
      await tester.pumpAndSettle();
      await reveal(tester, find.text(t.rowIqama(at(LocalTime.of(12, 30)))));
      expect(find.text(t.rowIqama(at(LocalTime.of(12, 30)))), findsOneWidget);
      expect(find.text(t.rowIqama(at(LocalTime.of(12, 15)))), findsNothing);
    });

    testApp('switching the active mosque switches Today\'s Iqama', (
      tester,
    ) async {
      await open(tester);
      final first = await mosques.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );
      final second = await mosques.add(
        name: 'Second',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(first.id, Prayer.dhuhr, LocalTime.of(12, 15));
      await mosques.setIqama(second.id, Prayer.dhuhr, LocalTime.of(12, 45));
      await tester.pumpAndSettle();
      final at = clockOn(tester).time;

      expect(find.text('IQAMA · First', findRichText: true), findsOneWidget);
      await reveal(tester, find.text(t.rowIqama(at(LocalTime.of(12, 15)))));
      expect(find.text(t.rowIqama(at(LocalTime.of(12, 15)))), findsOneWidget);

      await goToMosques(tester);
      await tapText(tester, 'Second');
      await tapText(tester, t.setAsActive);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tapText(tester, t.tabToday);

      expect(find.text('IQAMA · Second', findRichText: true), findsOneWidget);
      await reveal(tester, find.text(t.rowIqama(at(LocalTime.of(12, 45)))));
      expect(find.text(t.rowIqama(at(LocalTime.of(12, 45)))), findsOneWidget);
    });

    testApp('"tap to set" on Today opens that mosque', (tester) async {
      await open(tester);
      await mosques.add(
        name: 'Masjid al-Nour',
        address: '',
        source: MosqueSource.manual,
      );
      await tester.pumpAndSettle();

      await tapText(tester, t.ticketSetTime);

      expect(find.byType(MosqueDetailPage), findsOneWidget);
      expect(find.text(t.notConfigured), findsNWidgets(6));
    });

    testApp('without a place the schedule still opens, minus Adhan lines', (
      tester,
    ) async {
      await open(tester, withPlace: false);
      await addThroughSheet(tester);

      expect(find.text(t.notConfigured), findsNWidgets(6));
      expect(
        find.textContaining(RegExp('^${RegExp.escape(t.rowAdhanTime(''))}')),
        findsNothing,
        reason:
            'with no place there is no Adhan time to show, and none is guessed',
      );
    });
  });

  group('accessibility', () {
    testApp('the schedule and the editor survive a large text size', (
      tester,
    ) async {
      await open(tester, textScale: 2.0);
      await addThroughSheet(
        tester,
        name: 'Masjid al-Nour al-Kabir wa al-Jadid',
      );
      final mosque = await savedMosque('Masjid al-Nour al-Kabir wa al-Jadid');
      await mosques.setIqama(
        mosque.id,
        Prayer.fajr,
        LocalTime.of(5, 40),
        reminderEnabled: true,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await openEditor(tester, Prayer.fajr);
      await tapText(tester, t.reminderCustom);
      expect(tester.takeException(), isNull);

      await tapText(tester, t.cancel);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(MosquesScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testApp('every control on the schedule is a 48dp target with a label', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await addThroughSheet(tester);
      final mosque = await savedMosque('Masjid al-Nour');
      await mosques.setIqama(mosque.id, Prayer.fajr, LocalTime.of(5, 40));
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));

      await tester.pageBack();
      await tester.pumpAndSettle();
      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });

    testApp('the editor\'s controls are 48dp targets with labels', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await open(tester);
      await addThroughSheet(tester);
      await openEditor(tester, Prayer.fajr);
      await chooseTime(tester, LocalTime.of(5, 40));
      await tester.tap(editorSwitch());
      await tester.pumpAndSettle();

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      handle.dispose();
    });
  });
}
