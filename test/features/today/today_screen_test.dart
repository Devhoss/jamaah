import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/app/clock.dart';
import 'package:awqaity/src/app/l10n/generated/app_localizations.dart';
import 'package:awqaity/src/app/l10n/generated/app_localizations_en.dart';
import 'package:awqaity/src/app/l10n/prayer_labels.dart';
import 'package:awqaity/src/app/providers.dart';
import 'package:awqaity/src/app/theme/theme.dart';
import 'package:awqaity/src/app/theme/tokens.dart';
import 'package:awqaity/src/data/app_database.dart';
import 'package:awqaity/src/data/mosque_repository.dart';
import 'package:awqaity/src/data/settings_repository.dart';
import 'package:awqaity/src/domain/mosque.dart';
import 'package:awqaity/src/domain/place.dart';
import 'package:awqaity/src/domain/prayer.dart';
import 'package:awqaity/src/domain/time_model.dart';
import 'package:awqaity/src/domain/today.dart';
import 'package:awqaity/src/domain/zone_offsets.dart';
import 'package:awqaity/src/features/components/app_widgets.dart';
import 'package:awqaity/src/features/today/today_screen.dart';
import '../../helpers/fake_clock.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The Today screen: the day at the saved place, the countdown in front of it, and
/// the six times around that — plus what it says when there is no place, no mosque
/// or no Iqama yet.
void main() {
  final t = AppLocalizationsEn();

  const timePattern = r'^\d{2}:\d{2}$';
  const clockReading = r'\d{2}:\d{2}';
  final countdownPattern = RegExp(r'^in (\d+ min|\d+h \d+m)$');

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FakePlaceSource source;
  late FixedClock clock;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    mosques = MosqueRepository(db);
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable));
    // 10:00 in Cairo on the place's own clock: inside the sunrise-to-Dhuhr gap,
    // with Dhuhr ahead.
    clock = FixedClock(DateTime.utc(2026, 10, 12, 7, 0));
    addTearDown(db.close);
  });

  // Riverpod's `Override` is not exported from the public library, so these lists
  // are built where they are used and their type is left to inference.
  baseOverrides() => [
    appDatabaseProvider.overrideWithValue(db),
    appClockProvider.overrideWithValue(clock),
    placeSourceProvider.overrideWithValue(source),
  ];

  /// The device's 12/24-hour setting, stated the way a system states it.
  ///
  /// The reading reaches an app as MediaQuery data, which the test binding resolves
  /// from its own dispatcher before the body runs — so setting that dispatcher from
  /// inside a test is read one test late. The override goes directly above the
  /// screen, where it is the nearest reading no matter what the app shell builds on
  /// the way down. Everything else about the surface is inherited unchanged.
  Widget withClock(Widget child, {required bool use24Hour}) => Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: use24Hour),
      child: child,
    ),
  );

  Widget appShell({
    VoidCallback? onOpenMosques,
    bool dark = false,
    bool use24Hour = true,
  }) => MaterialApp(
    // Every string here is compared against the English one (`AppLocalizationsEn`),
    // so the tree reads the same locale the test does rather than whatever the host
    // machine resolves — including the space before a 12-hour meridiem marker.
    locale: const Locale('en'),
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: withClock(
      Scaffold(body: TodayScreen(onOpenMosques: onOpenMosques)),
      use24Hour: use24Hour,
    ),
  );

  /// Riverpod keeps its container when a `ProviderScope` is merely updated, so an
  /// app opened a second time in one test would still read the clock from the first
  /// opening. Each opening gets its own key: that is the app starting again, at the
  /// instant the test has moved the fake clock to.
  int openings = 0;

  /// The app on a device that reads 24-hour unless the test says otherwise.
  Widget harness({
    VoidCallback? onOpenMosques,
    bool dark = false,
    bool use24Hour = true,
  }) => ProviderScope(
    key: ValueKey('app-${++openings}'),
    overrides: baseOverrides(),
    child: appShell(
      onOpenMosques: onOpenMosques,
      dark: dark,
      use24Hour: use24Hour,
    ),
  );

  /// A reading built by hand, for the days a test bench cannot reach through a real
  /// place: a rule-bound day, a day estimated from another latitude, a day with no
  /// sunrise at all.
  TodayReading readingAt({
    Map<Prayer, int> times = const {},
    Set<Prayer> unavailable = const {},
    Set<Prayer> movedByRule = const {},
    double? estimatedFrom,
    bool estimates = false,
  }) => TodayReading(
    day: PrayerDay(
      day: const LocalDay(2026, 10, 12),
      times: times,
      unavailable: unavailable,
      highLatitudeMovedPrayers: movedByRule,
      estimatedFromLatitude: estimatedFrom,
      timesAreEstimates: estimates,
    ),
    moment: LocalMoment.inZone(
      zone: zoneOffsetsFor(cairo.ianaZone),
      utcInstant: DateTime.utc(2026, 10, 12, 7, 0),
    ),
  );

  /// The Cairo day the real calculator answers at 10:00, reused by the hand-built
  /// readings below so only the flag under test differs.
  const cairoTimes = <Prayer, int>{
    Prayer.fajr: 5 * 60 + 28,
    Prayer.sunrise: 6 * 60 + 55,
    Prayer.dhuhr: 12 * 60 + 42,
    Prayer.asr: 16 * 60,
    Prayer.maghrib: 18 * 60 + 28,
    Prayer.isha: 19 * 60 + 45,
  };

  Future<void> openWithReading(
    WidgetTester tester,
    TodayReading reading, {
    bool use24Hour = true,
  }) async {
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [...baseOverrides(), todayProvider.overrideWithValue(reading)],
        child: appShell(use24Hour: use24Hour),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openToday(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  /// The place saved and the screen open, at [instant] in UTC.
  Future<void> openAt(
    WidgetTester tester,
    DateTime instant, {
    VoidCallback? onOpenMosques,
  }) async {
    clock.instant = instant;
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(harness(onOpenMosques: onOpenMosques));
    await tester.pumpAndSettle();
  }

  /// The texts inside one prayer row, so a test reads that row rather than the
  /// whole screen.
  List<String> rowTexts(WidgetTester tester, String name) => tester
      .widgetList<Text>(
        find.descendant(
          of: find.ancestor(
            of: find.text(name),
            matching: find.byType(AppRow),
          ),
          matching: find.byType(Text),
        ),
      )
      .map((text) => text.data!)
      .toList();

  AppRow rowFor(WidgetTester tester, String name) => tester.widget<AppRow>(
    find.ancestor(of: find.text(name), matching: find.byType(AppRow)),
  );

  /// The row itself, so a layout test can measure inside it.
  Finder rowFinder(String name) => find.ancestor(
    of: find.text(name),
    matching: find.byType(AppRow),
  );

  double rowHeight(WidgetTester tester, String name) =>
      tester.getRect(rowFinder(name)).height;

  /// Everything a row says has to sit on the name's line, or the six rows stop
  /// being six equal lines.
  void expectSameLine(WidgetTester tester, String name, List<Finder> parts) {
    final nameRect = tester.getRect(
      find.descendant(of: rowFinder(name), matching: find.text(name)),
    );
    for (final part in parts) {
      final rect = tester.getRect(
        find.descendant(of: rowFinder(name), matching: part),
      );
      expect(
        rect.center.dy,
        closeTo(nameRect.center.dy, 0.5),
        reason: '$part should read beside "$name", not on a line of its own',
      );
    }
  }

  /// The reading at the end of [name]'s row, in whatever clock format the test pins.
  /// Used where the time itself comes from the real calculator and only its shape is
  /// under test.
  String rowTime(WidgetTester tester, String name, RegExp pattern) =>
      rowTexts(tester, name).firstWhere((text) => pattern.hasMatch(text));

  /// The Adhan time printed at the end of [name]'s row, on a 24-hour device.
  String adhanTimeOf(WidgetTester tester, String name) =>
      rowTime(tester, name, RegExp(timePattern));

  String? rowMarkedNext(WidgetTester tester) {
    for (final prayer in Prayer.adhanPrayers) {
      final name = prayerName(t, prayer);
      if (rowTexts(tester, name).contains(t.tagNext)) return name;
    }
    return null;
  }

  /// This SDK's `CommonFinders` has no regex finder, so match on the [Text] data.
  Finder textMatching(RegExp pattern) => find.byWidgetPredicate((widget) =>
      widget is Text && widget.data != null && pattern.hasMatch(widget.data!));

  /// A device that reads 12-hour says the marker after a narrow no-break space,
  /// which is what CLDR asks for and what intl prints.
  String twelve(int hour, int minute) =>
      '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')}'
      '\u202F${hour < 12 ? 'AM' : 'PM'}';

  /// Minutes from midnight, read off a 24-hour row.
  int minutesOf(String hhmm) =>
      int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));

  /// Minutes from midnight, written the way a 24-hour device shows it.
  String clockOf(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  /// The whole day with the active mosque's Iqama times as given, read at [instant].
  Future<void> openWithMosque(
    WidgetTester tester,
    Map<Prayer, LocalTime> iqamas, {
    required DateTime instant,
    bool use24Hour = true,
  }) async {
    clock.instant = instant;
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    for (final entry in iqamas.entries) {
      await mosques.setIqama(mosque.id, entry.key, entry.value);
    }
    await settings.setActiveMosqueId(mosque.id);

    await tester.pumpWidget(harness(use24Hour: use24Hour));
    await tester.pumpAndSettle();
  }

  /// The whole day with one Dhuhr Iqama entered, at 10:00 in Cairo.
  Future<void> openWithIqama(
    WidgetTester tester, {
    bool use24Hour = true,
  }) async {
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(
      mosque.id,
      Prayer.dhuhr,
      const LocalTime(12 * 60 + 15),
      reminderEnabled: true,
    );
    await settings.setActiveMosqueId(mosque.id);

    await tester.pumpWidget(harness(use24Hour: use24Hour));
    await tester.pumpAndSettle();
  }

  /// The notes and the last rows live below the fold, and a ListView only builds
  /// what it paints. A tall phone-width surface builds the whole day at once, so a
  /// test can read all of it and still be strict about horizontal overflow.
  void showWholeDay(WidgetTester tester) {
    tester.view.physicalSize = const Size(1170, 24000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// The whole day on a wide surface, for the rows that also carry an Iqama.
  ///
  /// `flutter test` falls back to a square font whose glyphs are far wider than the
  /// device's, so a phone-width row that fits on a phone wraps here. Claims about
  /// what sits on the same line are checked where the content really does fit; the
  /// phone-width tests above and the 3x test below cover the rest.
  void showWideDay(WidgetTester tester) {
    tester.view.physicalSize = const Size(1800, 24000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  /// Riverpod will not take a different number of overrides on a scope that is
  /// still mounted, so a test with two readings has to close the first one.
  Future<void> closeToday(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testApp('the first read is named, not blank', (tester) async {
    // A first read that has not landed: this stream stays open and says nothing.
    final silent = StreamController<AppSettingsSnapshot>();
    addTearDown(silent.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(),
          appSettingsProvider.overrideWith((ref) => silent.stream),
        ],
        child: appShell(),
      ),
    );
    await tester.pump();

    expect(find.text(t.todayLoading), findsOneWidget);
  });

  testApp('a real database settles out of loading on its own', (tester) async {
    await openToday(tester);

    expect(find.text(t.todayLoading), findsNothing);
  });

  testApp('asks for a place before it shows any times', (tester) async {
    await openToday(tester);

    expect(find.text(t.todayNeedsPlaceTitle), findsOneWidget);
    expect(find.text(t.todayNeedsPlaceBody), findsOneWidget);
    expect(find.text(t.todayChoosePlace), findsOneWidget);
    expect(
      find.byType(AppRow),
      findsNothing,
      reason: 'there is nothing to calculate yet, so no rows and no invented time',
    );
  });

  testApp('the place prompt opens the sheet, and asks the device for nothing', (
    tester,
  ) async {
    await openToday(tester);

    await tester.tap(find.text(t.todayChoosePlace));
    await tester.pumpAndSettle();

    expect(find.text(t.locationSheetTitle), findsOneWidget);
    expect(source.requestCount, 0);
  });

  testApp('a denial is still on the screen once the sheet is closed', (
    tester,
  ) async {
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.denied));
    await openToday(tester);

    await tester.tap(find.text(t.todayChoosePlace));
    await tester.pumpAndSettle();
    await tester.tap(find.text(t.locationUseDevice));
    await tester.pumpAndSettle();

    // Close it the way the user does: tap away, not by choosing a place. The sheet
    // has to be gone, or the message below would only be the sheet's own.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(find.text(t.locationSheetTitle), findsNothing);
    expect(find.text(t.locationDenied), findsOneWidget);
    expect(find.text(t.todayChoosePlace), findsOneWidget);
  });

  testApp('the chip names the saved place and reopens the sheet', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    await openToday(tester);

    expect(find.text(cairo.displayName), findsOneWidget);

    await tester.tap(find.text(cairo.displayName));
    await tester.pumpAndSettle();
    expect(find.text(t.locationSheetTitle), findsOneWidget);
  });

  testApp('a device place is named as the device, not as a city', (
    tester,
  ) async {
    await settings.setLocation(devicePlace.toStored());
    await openToday(tester);

    expect(find.text(t.locationCurrentPlace), findsWidgets);
    expect(
      find.text(devicePlace.displayName),
      findsNothing,
      reason: '"Africa/Cairo" is a zone name, and a zone is not a place label',
    );
  });

  testApp('the day is named in both calendars', (tester) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));

    expect(find.text('Monday, 12 October'), findsOneWidget);
    expect(
      textMatching(RegExp(r'\b14\d\d\b')),
      findsOneWidget,
      reason: 'one Hijri sub-line, and its year cannot be a Gregorian one',
    );
  });

  testApp('six rows in order, sunrise muted, and nothing invented', (
    tester,
  ) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));

    for (final prayer in Prayer.adhanPrayers) {
      expect(
        find.text(prayerName(t, prayer)),
        findsOneWidget,
        reason: '${prayer.name} belongs on the list',
      );
    }
    expect(rowFor(tester, prayerName(t, Prayer.sunrise)).muted, isTrue);
    expect(rowFor(tester, prayerName(t, Prayer.fajr)).muted, isFalse);

    expect(
      find.text(t.notConfigured),
      findsNothing,
      reason: 'a missing Iqama is silence on the row, not a status to read',
    );
    // An Iqama line is the label plus a reading; the "add your mosque" copy also
    // says the word, so only a line that starts with it counts.
    expect(
      textMatching(RegExp('^${t.rowIqama('')}$clockReading')),
      findsNothing,
    );
    expect(find.text(t.remindersAreSettingsNote), findsNothing);
  });

  testApp('the six rows are six equal lines, pill included', (tester) async {
    showWholeDay(tester);
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));

    final heights = [
      for (final prayer in Prayer.adhanPrayers)
        rowHeight(tester, prayerName(t, prayer)),
    ];
    for (final height in heights) {
      expect(
        height,
        closeTo(heights.first, 0.5),
        reason: 'one row taller than the rest is the layout bug this pins',
      );
    }

    // The dot is invisible on a row that is not next, but its slot and its gap are
    // both real, so every name starts at the same distance from the edge.
    for (final prayer in Prayer.adhanPrayers) {
      final name = prayerName(t, prayer);
      final dot = tester.getRect(
        find.descendant(of: rowFinder(name), matching: find.byIcon(Icons.circle)),
      );
      final text = tester.getRect(find.descendant(of: rowFinder(name), matching: find.text(name)));
      expect(
        text.left - dot.right,
        greaterThanOrEqualTo(AppSpace.md),
        reason: 'a dot touching the name reads as a smudge, not a marker',
      );
    }

    final next = prayerName(t, Prayer.dhuhr);
    expectSameLine(tester, next, [
      find.text(t.tagNext),
      find.text(adhanTimeOf(tester, next)),
    ]);
  });

  testApp('an Iqama stays on its row\'s line', (tester) async {
    showWideDay(tester);
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(
      mosque.id,
      Prayer.dhuhr,
      const LocalTime(12 * 60 + 15),
      reminderEnabled: true,
    );
    await settings.setActiveMosqueId(mosque.id);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    final dhuhr = prayerName(t, Prayer.dhuhr);
    expectSameLine(tester, dhuhr, [
      find.text(t.rowIqama('12:15')),
      find.byIcon(Icons.notifications_none),
      find.text(t.tagNext),
    ]);

    final heights = [
      for (final prayer in Prayer.adhanPrayers)
        rowHeight(tester, prayerName(t, prayer)),
    ];
    for (final height in heights) {
      expect(
        height,
        closeTo(heights.first, 0.5),
        reason: 'a row that gained an Iqama must not grow taller than the rest',
      );
    }
  });

  testApp('between sunrise and Dhuhr no row is marked current', (
    tester,
  ) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));

    expect(
      Prayer.adhanPrayers.where((p) => rowFor(tester, prayerName(t, p)).selected),
      isEmpty,
      reason: "Fajr's window closed at sunrise (06:55) and Dhuhr has not "
          'arrived, so highlighting either one would be a claim the day is not making',
    );

    final next = rowMarkedNext(tester);
    expect(next, prayerName(t, Prayer.dhuhr));
    expect(
      find.text(t.prayerAtTime(next!, adhanTimeOf(tester, next))),
      findsOneWidget,
      reason: 'the card counts down to the row marked Next, at that row\'s time',
    );
    expect(find.text(t.nextPrayerAdhan), findsOneWidget);
    expect(textMatching(countdownPattern), findsWidgets);
  });

  testApp('before sunrise the prayer in force is Fajr', (tester) async {
    // 06:00 in Cairo: after Fajr (05:28), before sunrise (06:55).
    await openAt(tester, DateTime.utc(2026, 10, 12, 3, 0));

    expect(rowFor(tester, prayerName(t, Prayer.fajr)).selected, isTrue);
    expect(
      Prayer.adhanPrayers.where(
        (p) => p != Prayer.fajr && rowFor(tester, prayerName(t, p)).selected,
      ),
      isEmpty,
      reason: 'one row at a time, and sunrise is not a prayer',
    );
    expect(rowMarkedNext(tester), prayerName(t, Prayer.dhuhr));
  });

  testApp('after Isha the card counts down to tomorrow\'s Fajr', (
    tester,
  ) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 20, 30));

    // 23:30 in Cairo, so the day\'s five times are all behind the clock.
    final ishaHour = int.parse(
      adhanTimeOf(tester, prayerName(t, Prayer.isha)).substring(0, 2),
    );
    expect(ishaHour, lessThan(23));

    expect(find.text(t.tomorrow), findsOneWidget);
    expect(
      textMatching(
        RegExp('^${prayerName(t, Prayer.fajr)} $clockReading\$'),
      ),
      findsOneWidget,
      reason: 'tomorrow\'s Fajr is named, never a time that has already passed',
    );
  });

  testApp('no mosque yet: a quiet prompt, and nothing where a time would be', (
    tester,
  ) async {
    var opened = 0;
    await openAt(
      tester,
      DateTime.utc(2026, 10, 12, 7, 0),
      onOpenMosques: () => opened++,
    );

    expect(find.text(t.addMosqueTitle), findsOneWidget);
    expect(find.text(t.addMosqueBody), findsOneWidget);
    expect(find.text(t.nextIqamaLabel('')), findsNothing);

    await tester.tap(find.text(t.addMosqueTitle));
    await tester.pump();
    expect(opened, 1);
  });

  testApp('a mosque with no Iqama times asks to set them', (tester) async {
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await settings.setActiveMosqueId(mosque.id);

    var opened = 0;
    await tester.pumpWidget(harness(onOpenMosques: () => opened++));
    await tester.pumpAndSettle();

    expect(find.text(t.mosqueHasNoIqama('Masjid al-Nour')), findsOneWidget);
    expect(find.text(t.addMosqueTitle), findsNothing);
    expect(find.text(t.nextIqamaLabel('Masjid al-Nour')), findsNothing);
    expect(
      find.text(t.noIqamaLeftToday),
      findsNothing,
      reason: 'a schedule that has never been entered is not a day that has run out',
    );

    await tester.tap(find.text(t.mosqueHasNoIqama('Masjid al-Nour')));
    await tester.pump();
    expect(opened, 1);
  });

  testApp('a configured Iqama appears on its row and on the card', (
    tester,
  ) async {
    await openWithIqama(tester);

    expect(find.text(t.rowIqama('12:15')), findsOneWidget);
    expect(find.text(t.nextIqamaLabel('Masjid al-Nour')), findsOneWidget);
    expect(
      find.text(t.prayerAtTime(prayerName(t, Prayer.dhuhr), '12:15')),
      findsOneWidget,
    );
    expect(find.text(t.reminderBeforeIqama(10)), findsOneWidget);
    expect(find.text(t.remindersAreSettingsNote), findsOneWidget);
    expect(
      find.byIcon(Icons.notifications_none),
      findsOneWidget,
      reason: 'the one prayer with a reminder on is the one that gets the bell',
    );

    // Only the prayer whose Iqama the user entered carries one.
    for (final prayer in [
      Prayer.fajr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
      Prayer.sunrise,
    ]) {
      expect(
        rowTexts(tester, prayerName(t, prayer)).where(
          (text) => text.startsWith(t.rowIqama('')),
        ),
        isEmpty,
        reason: '${prayer.name} has no Iqama entered, so it shows nothing',
      );
    }
  });

  testApp('the next Iqama is the earliest one left, not the Adhan\'s own', (
    tester,
  ) async {
    // Read where the evening actually falls here, then sit two minutes after Maghrib.
    await openAt(tester, DateTime.utc(2026, 10, 12, 14, 0));
    final maghrib = minutesOf(adhanTimeOf(tester, prayerName(t, Prayer.maghrib)));
    final isha = minutesOf(adhanTimeOf(tester, prayerName(t, Prayer.isha)));
    final offset = zoneOffsetsFor(cairo.ianaZone)
        .offsetMinutesAt(DateTime.utc(2026, 10, 12, 14, 0));

    await openWithMosque(
      tester,
      {
        Prayer.maghrib: LocalTime(maghrib + 10),
        Prayer.isha: LocalTime(isha + 25),
      },
      instant: DateTime.utc(
        2026,
        10,
        12,
      ).add(Duration(minutes: maghrib + 2 - offset)),
    );

    expect(
      rowMarkedNext(tester),
      prayerName(t, Prayer.isha),
      reason: 'the Adhan in front of the user is still Isha',
    );
    expect(
      find.text(
        t.prayerAtTime(prayerName(t, Prayer.maghrib), clockOf(maghrib + 10)),
      ),
      findsOneWidget,
      reason: "the jama'ah that has not happened yet is the next Iqama, even "
          "though its own Adhan is behind the clock",
    );
    expect(
      find.text(t.prayerAtTime(prayerName(t, Prayer.isha), clockOf(isha + 25))),
      findsNothing,
    );
  });

  testApp('the day\'s last Iqama behind it says there are no more today', (
    tester,
  ) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 14, 0));
    final isha = minutesOf(adhanTimeOf(tester, prayerName(t, Prayer.isha)));
    final offset = zoneOffsetsFor(cairo.ianaZone)
        .offsetMinutesAt(DateTime.utc(2026, 10, 12, 14, 0));

    await openWithMosque(
      tester,
      {Prayer.isha: LocalTime(isha + 5)},
      instant: DateTime.utc(
        2026,
        10,
        12,
      ).add(Duration(minutes: isha + 30 - offset)),
    );

    expect(find.text(t.noIqamaLeftToday), findsOneWidget);
    expect(
      find.text('Masjid al-Nour'),
      findsOneWidget,
      reason: 'the sentence is about a named mosque, not the app in general',
    );
    expect(find.text(t.nextIqamaLabel('Masjid al-Nour')), findsNothing);
    expect(
      textMatching(RegExp('^${t.rowIqama('')}$clockReading')),
      findsOneWidget,
      reason: 'the row keeps the time the user entered',
    );
  });

  testApp('after the day\'s Iqamas, tomorrow\'s Fajr is labelled tomorrow', (
    tester,
  ) async {
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
    final fajr = minutesOf(adhanTimeOf(tester, prayerName(t, Prayer.fajr)));
    final offset = zoneOffsetsFor(cairo.ianaZone)
        .offsetMinutesAt(DateTime.utc(2026, 10, 12, 7, 0));

    // Mid-morning with only a Fajr time entered: today\'s is gone, so the hand-over
    // to tomorrow is the one honest thing the card can say.
    await openWithMosque(
      tester,
      {Prayer.fajr: LocalTime(fajr + 12)},
      instant: DateTime.utc(
        2026,
        10,
        12,
      ).add(Duration(minutes: fajr + 40 - offset)),
    );

    expect(
      rowMarkedNext(tester),
      prayerName(t, Prayer.dhuhr),
      reason: 'the Adhan ahead is Dhuhr, not tomorrow\'s Fajr',
    );
    expect(find.text(t.tomorrow), findsOneWidget);
    expect(
      find.text(t.prayerAtTime(prayerName(t, Prayer.fajr), clockOf(fajr + 12))),
      findsOneWidget,
    );
  });

  testApp('a 24-hour device shows four digits and no marker', (tester) async {
    await openWithIqama(tester);

    final dhuhr = prayerName(t, Prayer.dhuhr);
    final adhan = rowTime(tester, dhuhr, RegExp(timePattern));
    expect(
      find.text(t.prayerAtTime(dhuhr, adhan)),
      findsOneWidget,
      reason: 'the hero repeats the row\'s reading rather than formatting it again',
    );
    // 12:15 is the user's own Iqama time, so it is exact rather than calculated.
    expect(find.text(t.rowIqama('12:15')), findsOneWidget);
    expect(find.text(t.prayerAtTime(dhuhr, '12:15')), findsOneWidget);

    for (final prayer in Prayer.adhanPrayers) {
      final name = prayerName(t, prayer);
      expect(
        rowTexts(tester, name).where((text) => RegExp(timePattern).hasMatch(text)),
        hasLength(1),
        reason: '$name shows its Adhan as one 24-hour reading',
      );
    }

    expect(
      textMatching(RegExp(r'[AP]M')),
      findsNothing,
      reason: 'a meridiem marker would be a second clock on the same screen',
    );
  });

  testApp('a 12-hour device reads its own clock on the card and on the rows', (
    tester,
  ) async {
    final meridiem = RegExp(r'^\d{1,2}:\d{2}\u202F[AP]M$');
    await openWithIqama(tester, use24Hour: false);

    final dhuhr = prayerName(t, Prayer.dhuhr);
    expect(
      find.text(t.prayerAtTime(dhuhr, rowTime(tester, dhuhr, meridiem))),
      findsOneWidget,
      reason: 'the hero Adhan follows the device, and is the row\'s own reading',
    );
    expect(
      find.text(t.prayerAtTime(dhuhr, twelve(12, 15))),
      findsOneWidget,
      reason: 'so does the hero Iqama under it',
    );
    expect(find.text(t.rowIqama(twelve(12, 15))), findsOneWidget);

    for (final prayer in Prayer.adhanPrayers) {
      final name = prayerName(t, prayer);
      expect(
        rowTexts(tester, name).where((text) => meridiem.hasMatch(text)),
        hasLength(1),
        reason: '$name shows its Adhan as one 12-hour reading, marker included',
      );
    }

    expect(
      textMatching(RegExp(r'^\d{2}:\d{2}$')),
      findsNothing,
      reason: 'no 24-hour reading is left anywhere on the screen',
    );
    expect(
      textMatching(countdownPattern),
      findsWidgets,
      reason: 'the wait is a duration, so the clock format says nothing about it',
    );
  });

  testApp('a reminder left off says so instead of showing a bell', (
    tester,
  ) async {
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(mosque.id, Prayer.dhuhr, const LocalTime(12 * 60 + 15));
    await settings.setActiveMosqueId(mosque.id);

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(t.reminderOffForPrayer), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none), findsNothing);
    expect(
      find.text(t.countdownMinutes(0)),
      findsNothing,
      reason: 'a countdown is a duration, never a time of day',
    );
  });

  testApp('a day with no honest times says so instead of guessing', (tester) async {
    await openWithReading(tester, readingAt(estimates: true));

    expect(find.text(t.timesUnavailableTitle), findsOneWidget);
    expect(find.text(t.timesUnavailableBody), findsOneWidget);
    expect(
      find.byType(AppRow),
      findsNothing,
      reason: 'a row of numbers nobody calculated is worse than no row',
    );
  });

  testApp('the rule note appears only when the rule moved a time', (
    tester,
  ) async {
    showWholeDay(tester);
    await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
    expect(
      textMatching(RegExp(t.ruleMiddleOfTheNight)),
      findsNothing,
      reason: 'Cairo at midday needs no lecture about the night',
    );

    await closeToday(tester);
    await openWithReading(
      tester,
      readingAt(times: cairoTimes, movedByRule: {Prayer.fajr, Prayer.isha}),
    );
    final note = tester.widget<Text>(
      textMatching(RegExp(t.ruleMiddleOfTheNight)),
    ).data!;
    expect(note, contains(prayerName(t, Prayer.fajr)));
    expect(note, contains(prayerName(t, Prayer.isha)));
  });

  testApp('a day estimated from a nearer latitude names that latitude', (
    tester,
  ) async {
    showWholeDay(tester);
    await openWithReading(
      tester,
      readingAt(times: cairoTimes, estimatedFrom: 48.5),
    );

    expect(
      textMatching(RegExp('48\\.5')),
      findsOneWidget,
      reason: 'the estimate is honest about where it came from',
    );
  });

  testApp('a row whose time is missing says so', (tester) async {
    await openWithReading(
      tester,
      readingAt(
        times: {
          Prayer.fajr: cairoTimes[Prayer.fajr]!,
          Prayer.dhuhr: cairoTimes[Prayer.dhuhr]!,
        },
        unavailable: {Prayer.maghrib},
      ),
    );

    expect(
      rowTexts(tester, prayerName(t, Prayer.maghrib)),
      contains(t.noTimeToday),
      reason: 'the row stays, and admits it has no time',
    );
    expect(
      rowTexts(tester, prayerName(t, Prayer.maghrib))
          .where((text) => RegExp(timePattern).hasMatch(text)),
      isEmpty,
    );
  });

  testApp('a very large text size still fits', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // Phone width, tall enough that every row and note is laid out at 3x; a clip or
    // an overflow in any of them fails this test on its own.
    showWholeDay(tester);
    await settings.setLocation(cairo.toStored());

    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    expect(find.text(t.nextPrayerAdhan), findsOneWidget);
    expect(find.text(prayerName(t, Prayer.asr)), findsOneWidget);
    expect(
      find.text(prayerName(t, Prayer.isha)),
      findsOneWidget,
      reason: 'the last row is the one a narrow line would have pushed off first',
    );
  });

  testApp('a very large text size fits on a 12-hour device too', (tester) async {
    tester.platformDispatcher.textScaleFactorTestValue = 3.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    // A 12-hour reading is wider than its 24-hour twin by a whole marker, and
    // `flutter test` draws with a square fallback font far wider than the device's,
    // so this is the same day at the same scale with the room a phone at the largest
    // system font really has.
    showWideDay(tester);
    await settings.setLocation(cairo.toStored());

    await tester.pumpWidget(harness(use24Hour: false));
    await tester.pumpAndSettle();

    expect(find.text(prayerName(t, Prayer.isha)), findsOneWidget);
    expect(
      textMatching(RegExp(r'^\d{1,2}:\d{2}\u202F[AP]M$')),
      findsWidgets,
      reason: 'the marker arrives with the size, not instead of the reading',
    );
  });

  testApp('the dark theme keeps the same reading', (tester) async {
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(harness(dark: true));
    await tester.pumpAndSettle();

    expect(find.text(t.nextPrayerAdhan), findsOneWidget);
    expect(find.text(prayerName(t, Prayer.dhuhr)), findsOneWidget);
  });

  testApp('the bell tells a screen reader what it means', (tester) async {
    await settings.setLocation(cairo.toStored());
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    await mosques.setIqama(
      mosque.id,
      Prayer.dhuhr,
      const LocalTime(12 * 60 + 15),
      reminderEnabled: true,
    );
    await settings.setActiveMosqueId(mosque.id);

    final handle = tester.ensureSemantics();
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();

    // The bell is a picture; the row's own announcement is what carries its meaning.
    expect(
      tester.getSemantics(find.text(prayerName(t, Prayer.dhuhr))).label,
      allOf(contains(t.rowIqama('12:15')), contains(t.reminderOnSemantics)),
      reason: 'one row, read as one sentence, reminder state included',
    );
    expect(
      tester.getSemantics(find.text(prayerName(t, Prayer.fajr))).label,
      isNot(contains(t.reminderOnSemantics)),
      reason: 'the bell belongs to the prayer that has a reminder, not to every row',
    );
    handle.dispose();
  });
}
