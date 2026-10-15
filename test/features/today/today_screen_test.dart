import 'dart:async';
import 'dart:ui' show SemanticsAction, Tristate;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/date_labels.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/l10n/prayer_labels.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/components/line_icon.dart';
import 'package:jamaah/src/features/location/place_copy.dart';
import 'package:jamaah/src/features/sky/sun_path.dart';
import 'package:jamaah/src/features/today/iqama_ticket.dart';
import 'package:jamaah/src/features/today/prayer_rows.dart';
import 'package:jamaah/src/features/today/today_hero.dart';
import 'package:jamaah/src/features/today/today_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// The Today screen (Horizon): the sky for the time being shown, the hero for
/// the selected prayer, the mosque's Iqama as a separate ticket, and the six
/// rows — plus what it says when there is no place, no mosque or no Iqama yet.
void main() {
  final t = AppLocalizationsEn();

  const timePattern = r'^\d{2}:\d{2}$';
  final countdownPattern = RegExp(r'^in (\d+ min|\d+h \d+m)$');

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FakePlaceSource source;
  late FixedClock clock;
  late int permissionRequests;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    mosques = MosqueRepository(db);
    source = FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable));
    // 10:00 in Cairo on the place's own clock: inside the sunrise-to-Dhuhr gap,
    // with Dhuhr ahead.
    clock = FixedClock(DateTime.utc(2026, 10, 12, 7, 0));
    permissionRequests = 0;
    addTearDown(db.close);
  });

  // Riverpod's `Override` is not exported from the public library, so these lists
  // are built where they are used and their type is left to inference.
  baseOverrides() => [
    appDatabaseProvider.overrideWithValue(db),
    appClockProvider.overrideWithValue(clock),
    placeSourceProvider.overrideWithValue(source),
    notificationPermissionRequestProvider.overrideWithValue(
      () async => permissionRequests++,
    ),
  ];

  /// The device's 12/24-hour setting, stated the way a system states it, right
  /// above the screen so it is the nearest reading.
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
    // Every string here is compared against the English one.
    locale: const Locale('en'),
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: withClock(
      Scaffold(body: TodayScreen(onOpenMosques: onOpenMosques)),
      use24Hour: use24Hour,
    ),
  );

  /// Each opening gets its own key: that is the app starting again, at the
  /// instant the test has moved the fake clock to.
  int openings = 0;

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

  /// A reading built by hand, for the days a test bench cannot reach through a
  /// real place: a rule-bound day, an estimated day, a day with no sunrise.
  TodayReading readingAt({
    Map<Prayer, int> times = const {},
    Set<Prayer> unavailable = const {},
    Set<Prayer> movedByRule = const {},
    double? estimatedFrom,
    bool estimates = false,
  }) {
    final moment = LocalMoment.inZone(
      zone: zoneOffsetsFor(cairo.ianaZone),
      utcInstant: DateTime.utc(2026, 10, 12, 7, 0),
    );
    final day = PrayerDay(
      day: const LocalDay(2026, 10, 12),
      times: times,
      unavailable: unavailable,
      highLatitudeMovedPrayers: movedByRule,
      estimatedFromLatitude: estimatedFrom,
      timesAreEstimates: estimates,
    );
    NextPrayer? next;
    for (final p in Prayer.iqamaPrayers) {
      final m = times[p];
      if (m != null && m > moment.minutesOfDay) {
        next = NextPrayer(
          prayer: p,
          on: day.day,
          at: LocalTime(m),
          minutesUntil: m - moment.minutesOfDay,
          isTomorrow: false,
        );
        break;
      }
    }
    return TodayReading(day: day, moment: moment, next: next);
  }

  const cairoTimes = <Prayer, int>{
    Prayer.fajr: 5 * 60 + 28,
    Prayer.sunrise: 6 * 60 + 55,
    Prayer.dhuhr: 12 * 60 + 42,
    Prayer.asr: 16 * 60,
    Prayer.maghrib: 18 * 60 + 28,
    Prayer.isha: 19 * 60 + 45,
  };

  /// A surface tall enough to lay out the whole day at once.
  void showWholeDay(WidgetTester tester, {double width = 1170}) {
    tester.view.physicalSize = Size(width, 9000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openWithReading(
    WidgetTester tester,
    TodayReading reading, {
    bool use24Hour = true,
  }) async {
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...baseOverrides(),
          todayProvider.overrideWithValue(reading),
        ],
        child: appShell(use24Hour: use24Hour),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openToday(WidgetTester tester) async {
    await tester.pumpWidget(harness());
    await tester.pumpAndSettle();
  }

  Future<void> openAt(
    WidgetTester tester,
    DateTime instant, {
    VoidCallback? onOpenMosques,
    bool use24Hour = true,
  }) async {
    clock.instant = instant;
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      harness(onOpenMosques: onOpenMosques, use24Hour: use24Hour),
    );
    await tester.pumpAndSettle();
  }

  Future<Mosque> addMosque({
    Map<Prayer, LocalTime> iqamas = const {},
    Map<Prayer, int> after = const {},
    bool reminder = false,
  }) async {
    final mosque = await mosques.add(
      name: 'Masjid al-Nour',
      address: '12 Garden Road',
      source: MosqueSource.manual,
    );
    for (final e in iqamas.entries) {
      await mosques.setIqama(
        mosque.id,
        e.key,
        e.value,
        reminderEnabled: reminder,
      );
    }
    for (final e in after.entries) {
      await mosques.setIqama(
        mosque.id,
        e.key,
        null,
        afterAdhanMinutes: e.value,
        reminderEnabled: reminder,
      );
    }
    await settings.setActiveMosqueId(mosque.id);
    return mosque;
  }

  Finder row(Prayer prayer) => find.byKey(PrayerRows.rowKey(prayer));

  List<String> rowTexts(WidgetTester tester, Prayer prayer) => tester
      .widgetList<Text>(
        find.descendant(of: row(prayer), matching: find.byType(Text)),
      )
      .map((text) => text.data!)
      .toList();

  /// The row's Adhan reading on a 24-hour device.
  String rowTime(WidgetTester tester, Prayer prayer, [Pattern? pattern]) =>
      rowTexts(tester, prayer).firstWhere(
        (s) => RegExp(pattern?.toString() ?? timePattern).hasMatch(s),
      );

  bool isSelected(WidgetTester tester, Prayer prayer) {
    final node = tester.getSemantics(
      find.descendant(of: row(prayer), matching: find.byType(InkWell)).first,
    );
    return node.getSemanticsData().flagsCollection.isSelected ==
        Tristate.isTrue;
  }

  Prayer? rowMarkedNext(WidgetTester tester) {
    for (final p in Prayer.adhanPrayers) {
      if (rowTexts(tester, p).contains(t.tagNext.toUpperCase())) return p;
    }
    return null;
  }

  TodayHero hero(WidgetTester tester) =>
      tester.widget<TodayHero>(find.byType(TodayHero));

  TicketContent ticket(WidgetTester tester) =>
      tester.widget<IqamaTicket>(find.byType(IqamaTicket)).content;

  Finder textMatching(RegExp pattern) => find.byWidgetPredicate(
    (widget) =>
        widget is Text && widget.data != null && pattern.hasMatch(widget.data!),
  );

  String twelve(int hour, int minute) =>
      '${hour % 12 == 0 ? 12 : hour % 12}:'
      '${minute.toString().padLeft(2, '0')}'
      ' ${hour < 12 ? 'AM' : 'PM'}';

  int minutesOf(String hhmm) =>
      int.parse(hhmm.substring(0, 2)) * 60 + int.parse(hhmm.substring(3));

  String clockOf(int minutes) =>
      '${(minutes ~/ 60 % 24).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  Future<void> closeToday(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  group('before there is a day to show', () {
    testApp('the first read is named, not blank', (tester) async {
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

    testApp('a real database settles out of loading on its own', (
      tester,
    ) async {
      await openToday(tester);
      expect(find.text(t.todayLoading), findsNothing);
    });

    testApp('asks for a place before it shows any times', (tester) async {
      await openToday(tester);
      expect(find.text(t.todayNeedsPlaceTitle), findsOneWidget);
      expect(find.text(t.todayNeedsPlaceBody), findsOneWidget);
      expect(find.text(t.todayChoosePlace), findsOneWidget);
      expect(
        find.byType(PrayerRows),
        findsNothing,
        reason: 'there is nothing to calculate yet, so no rows and no invented time',
      );
      expect(find.byType(TodayHero), findsNothing);
    });

    testApp(
      'the place prompt opens the sheet, and asks the device for nothing',
      (tester) async {
        await openToday(tester);
        await tester.tap(find.text(t.todayChoosePlace));
        await tester.pumpAndSettle();
        expect(find.text(t.locationSheetTitle), findsOneWidget);
        expect(source.requestCount, 0);
      },
    );

    testApp('a denial is still on the screen once the sheet is closed', (
      tester,
    ) async {
      source = FakePlaceSource(const PlaceRejected(PlaceFailure.denied));
      await openToday(tester);
      await tester.tap(find.text(t.todayChoosePlace));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.locationUseDevice));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.text(t.locationSheetTitle), findsNothing);
      expect(find.text(t.locationDenied), findsOneWidget);
      expect(find.text(t.todayChoosePlace), findsOneWidget);
    });

    testApp('a day with no honest times says so instead of guessing', (
      tester,
    ) async {
      await openWithReading(tester, readingAt(estimates: true));
      expect(find.text(t.timesUnavailableTitle), findsOneWidget);
      expect(find.text(t.timesUnavailableBody), findsOneWidget);
      expect(
        find.byType(PrayerRows),
        findsNothing,
        reason: 'a row of numbers nobody calculated is worse than no row',
      );
    });
  });

  group('the top bar', () {
    testApp('names the saved place and reopens the sheet', (tester) async {
      await settings.setLocation(cairo.toStored());
      await openToday(tester);
      expect(find.text(cairo.displayName), findsOneWidget);
      await tester.tap(find.text(cairo.displayName));
      await tester.pumpAndSettle();
      expect(find.text(t.locationSheetTitle), findsOneWidget);
    });

    testApp('a device place is named near the closest city, never by its zone', (
      tester,
    ) async {
      await settings.setLocation(devicePlace.toStored());
      await openToday(tester);
      expect(find.text(placeShortLabel(t, devicePlace)), findsOneWidget);
      expect(placeShortLabel(t, devicePlace), startsWith('Near '));
      expect(
        find.text(devicePlace.displayName),
        findsNothing,
        reason: '"Africa/Cairo" is a zone name, and a zone is not a place label',
      );
    });

    testApp('the day is named in both calendars, on one line', (tester) async {
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      final date = DateLabels.weekdayDate(DateTime.utc(2026, 10, 12), 'en');
      final line = textMatching(
        RegExp('^${RegExp.escape(date)} · .*\\b14\\d\\d\\b'),
      );
      expect(
        line,
        findsOneWidget,
        reason: 'the Hijri year cannot be a Gregorian one',
      );
    });
  });

  group('the hero and the rows', () {
    testApp('six rows in order, Sunrise quieter, and nothing invented', (
      tester,
    ) async {
      showWholeDay(tester);
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      double top(Prayer p) => tester.getTopLeft(row(p)).dy;
      for (var i = 1; i < Prayer.adhanPrayers.length; i++) {
        expect(
          top(Prayer.adhanPrayers[i]),
          greaterThan(top(Prayer.adhanPrayers[i - 1])),
        );
      }
      expect(
        find.textContaining('Iqama'),
        findsNothing,
        reason: 'with no mosque there is no Iqama to mention on any row',
      );
      expect(find.text(t.notConfigured), findsNothing);
    });

    testApp('the six rows are six equal lines', (tester) async {
      showWholeDay(tester, width: 1800);
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      final heights = [
        for (final p in Prayer.adhanPrayers) tester.getSize(row(p)).height,
      ];
      for (final h in heights) {
        expect(h, closeTo(heights.first, 0.5));
        expect(h, greaterThanOrEqualTo(52));
      }
    });

    testApp(
      'at rest the hero is the next Adhan, and its row is the selected one',
      (tester) async {
        await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
        final h = hero(tester);
        expect(h.kicker, t.nextPrayerAdhan.toUpperCase());
        expect(h.name, prayerName(t, Prayer.dhuhr));
        expect(rowMarkedNext(tester), Prayer.dhuhr);
        expect(
          h.time,
          rowTime(tester, Prayer.dhuhr),
          reason: 'the hero repeats the row\'s reading rather than formatting it again',
        );
        expect(countdownPattern.hasMatch(h.meta), isTrue, reason: h.meta);
        expect(isSelected(tester, Prayer.dhuhr), isTrue);
        expect(
          Prayer.adhanPrayers.where(
            (p) => p != Prayer.dhuhr && isSelected(tester, p),
          ),
          isEmpty,
        );
      },
    );

    testApp('before sunrise the next prayer is Dhuhr, never Sunrise', (
      tester,
    ) async {
      // 06:00 in Cairo: after Fajr, before sunrise.
      await openAt(tester, DateTime.utc(2026, 10, 12, 3, 0));
      expect(rowMarkedNext(tester), Prayer.dhuhr);
      expect(hero(tester).name, prayerName(t, Prayer.dhuhr));
    });

    testApp('after Isha the hero is tomorrow\'s Fajr', (tester) async {
      await openAt(tester, DateTime.utc(2026, 10, 12, 20, 30));
      final h = hero(tester);
      expect(h.kicker, t.heroKickerTomorrow.toUpperCase());
      expect(h.name, prayerName(t, Prayer.fajr));
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
      expect(rowTexts(tester, Prayer.maghrib), contains(t.noTimeToday));
      expect(
        rowTexts(
          tester,
          Prayer.maghrib,
        ).where((s) => RegExp(timePattern).hasMatch(s)),
        isEmpty,
      );
    });

    testApp('a row tap pins its prayer; Back to now lets go', (tester) async {
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      await tester.ensureVisible(row(Prayer.asr));
      await tester.tap(
        find.descendant(
          of: row(Prayer.asr),
          matching: find.text(prayerName(t, Prayer.asr)),
        ),
      );
      await tester.pumpAndSettle();
      expect(hero(tester).kicker, t.heroKickerAdhan.toUpperCase());
      expect(hero(tester).name, prayerName(t, Prayer.asr));
      expect(
        tester.widget<SunPath>(find.byType(SunPath)).minute,
        minutesOf(rowTime(tester, Prayer.asr)),
      );
      await tester.ensureVisible(find.text(t.heroBackToNow));
      await tester.tap(find.text(t.heroBackToNow));
      await tester.pumpAndSettle();
      expect(hero(tester).kicker, t.nextPrayerAdhan.toUpperCase());
      expect(find.text(t.heroBackToNow), findsNothing);
    });

    testApp('looking through the day names what is in force there', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      final path = find.semantics.byLabel(t.sunPathLabel);
      // 10:00 + 7 × 15 min, every step past Dhuhr at 12:42.
      for (var i = 0; i < 12; i++) {
        tester.semantics.performAction(path, SemanticsAction.increase);
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(hero(tester).kicker, startsWith('IN FORCE AT'));
      expect(hero(tester).name, prayerName(t, Prayer.dhuhr));
      handle.dispose();
    });
  });

  group('the Iqama ticket', () {
    testApp('no mosque yet: one quiet way to add one', (tester) async {
      var opened = 0;
      await openAt(
        tester,
        DateTime.utc(2026, 10, 12, 7, 0),
        onOpenMosques: () => opened++,
      );
      expect(ticket(tester), isA<TicketNoMosque>());
      await tester.ensureVisible(find.text(t.addMosqueTitle));
      await tester.tap(find.text(t.addMosqueTitle));
      await tester.pump();
      expect(opened, 1);
    });

    testApp('nothing while the saved mosques are still being read', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      final pending = StreamController<List<Mosque>>();
      addTearDown(pending.close);
      await tester.pumpWidget(
        ProviderScope(
          key: ValueKey('app-${++openings}'),
          overrides: [
            ...baseOverrides(),
            savedMosquesProvider.overrideWith((ref) => pending.stream),
          ],
          child: appShell(),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(t.addMosqueTitle),
        findsNothing,
        reason: 'a user who has a mosque must not be told to add one while it loads',
      );
      expect(find.byType(PrayerRows), findsOneWidget);
    });

    testApp('a mosque with no Iqama: Not configured, and Set time opens it', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await addMosque();
      var opened = 0;
      await tester.pumpWidget(harness(onOpenMosques: () => opened++));
      await tester.pumpAndSettle();
      expect(ticket(tester), isA<TicketNotConfigured>());
      expect(find.text(t.addMosqueTitle), findsNothing);
      expect(
        rowTexts(tester, Prayer.dhuhr),
        contains(t.rowIqamaNotSet),
        reason: 'the app never fills one in',
      );
      expect(
        rowTexts(tester, Prayer.sunrise).any((s) => s.contains('Iqama')),
        isFalse,
      );
      await tester.ensureVisible(find.text(t.ticketSetTime));
      await tester.tap(find.text(t.ticketSetTime));
      await tester.pump();
      expect(opened, 1);
    });

    testApp('a configured Iqama is on its row and on the ticket', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(
        iqamas: {Prayer.dhuhr: LocalTime.of(12, 15)},
        reminder: true,
      );
      await openToday(tester);
      expect(rowTexts(tester, Prayer.dhuhr), contains(t.rowIqama('12:15')));
      final set = ticket(tester) as TicketSet;
      expect(set.mosque, 'Masjid al-Nour');
      expect(set.time, '12:15');
      expect(set.rule, t.ticketRuleFixed);
      expect(set.reminderOn, isTrue);
      expect(set.reminder, t.ticketReminder('12:05'));
      for (final p in [Prayer.fajr, Prayer.asr, Prayer.maghrib, Prayer.isha]) {
        expect(rowTexts(tester, p), contains(t.rowIqamaNotSet), reason: p.name);
      }
    });

    testApp('minutes after the Adhan: the user\'s minutes, added to the day', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(after: {Prayer.dhuhr: 20});
      await openToday(tester);
      final set = ticket(tester) as TicketSet;
      expect(set.time, clockOf(minutesOf(rowTime(tester, Prayer.dhuhr)) + 20));
      expect(set.rule, t.ticketRuleAfter(20));
      expect(set.reminder, t.ticketNoReminder);
      expect(set.reminderOn, isFalse);
    });

    testApp(
      'between Adhan and Iqama the prayer is held, with the Iqama counting',
      (tester) async {
        await settings.setLocation(cairo.toStored());
        await addMosque(after: {Prayer.dhuhr: 20});
        // Read the day's Dhuhr, then come back five minutes after it (UTC+3).
        await openToday(tester);
        final dhuhr = minutesOf(rowTime(tester, Prayer.dhuhr));
        await closeToday(tester);
        clock.instant = DateTime.utc(
          2026,
          10,
          12,
        ).add(Duration(minutes: dhuhr + 5 - 180));
        await openToday(tester);
        final h = hero(tester);
        expect(
          h.kicker,
          t
              .heroKickerHeld(
                prayerName(t, Prayer.dhuhr),
                t.countdownMinutes(15),
              )
              .toUpperCase(),
        );
        expect(h.name, prayerName(t, Prayer.dhuhr));
        expect(h.meta, t.heroAdhanAgo(t.agoMinutes(5)));
        expect(
          rowMarkedNext(tester),
          Prayer.asr,
          reason: 'Next stays on the next Adhan',
        );
        expect((ticket(tester) as TicketSet).relative, t.countdownMinutes(15));
      },
    );

    testApp('no hold while Iqama reminders are paused for travel', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(after: {Prayer.dhuhr: 20});
      await settings.saveTravel(
        const TravelSettings(
          travelMode: true,
          followLocation: false,
          pauseAllIqamaReminders: true,
        ),
      );
      // Read the day's Dhuhr, then come back five minutes after it (UTC+3).
      await openToday(tester);
      final dhuhr = minutesOf(rowTime(tester, Prayer.dhuhr));
      await closeToday(tester);
      clock.instant = DateTime.utc(
        2026,
        10,
        12,
      ).add(Duration(minutes: dhuhr + 5 - 180));
      await openToday(tester);
      expect(hero(tester).kicker, t.nextPrayerAdhan.toUpperCase());
      expect(hero(tester).name, prayerName(t, Prayer.asr));
      expect(find.text(t.pausedAllNote), findsOneWidget);
    });

    testApp('after the day\'s last Iqama: tomorrow\'s Fajr, honestly unset', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(iqamas: {Prayer.isha: LocalTime.of(19, 50)});
      clock.instant = DateTime.utc(2026, 10, 12, 20, 30);
      await openToday(tester);
      expect(hero(tester).kicker, t.heroKickerTomorrow.toUpperCase());
      expect(ticket(tester), isA<TicketNotConfigured>());
      expect(
        rowTexts(tester, Prayer.isha),
        contains(t.rowIqama('19:50')),
        reason: 'the row keeps the time the user entered',
      );
    });
  });

  group('clock formats', () {
    testApp('a 24-hour device shows four digits and no marker', (tester) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(iqamas: {Prayer.dhuhr: LocalTime.of(12, 15)});
      await openToday(tester);
      for (final p in Prayer.adhanPrayers) {
        expect(
          rowTexts(tester, p).where((s) => RegExp(timePattern).hasMatch(s)),
          hasLength(1),
          reason: '${p.name} shows its Adhan as one 24-hour reading',
        );
      }
      expect(textMatching(RegExp(r'\d[  ]?[AP]M')), findsNothing);
      expect(countdownPattern.hasMatch(hero(tester).meta), isTrue);
    });

    testApp(
      'a 12-hour device reads its own clock on the hero, ticket and rows',
      (tester) async {
        final meridiem = RegExp(r'^\d{1,2}:\d{2} [AP]M$');
        await settings.setLocation(cairo.toStored());
        await addMosque(iqamas: {Prayer.dhuhr: LocalTime.of(12, 15)});
        await tester.pumpWidget(harness(use24Hour: false));
        await tester.pumpAndSettle();
        final h = hero(tester);
        expect(
          rowTime(tester, Prayer.dhuhr, meridiem.pattern),
          '${h.time} PM',
          reason: 'the big time is the row reading, without its marker',
        );
        expect(h.meta, startsWith('PM · '));
        expect((ticket(tester) as TicketSet).time, twelve(12, 15));
        expect(
          rowTexts(tester, Prayer.dhuhr),
          contains(t.rowIqama(twelve(12, 15))),
        );
        for (final p in Prayer.adhanPrayers) {
          expect(
            rowTexts(tester, p).where((s) => meridiem.hasMatch(s)),
            hasLength(1),
            reason: '${p.name} shows its Adhan as one 12-hour reading',
          );
        }
        // The hero's big time has no marker by design; its PM is beside it.
      },
    );
  });

  group('notes', () {
    testApp('the rule note appears only when the rule moved a time', (
      tester,
    ) async {
      await openAt(tester, DateTime.utc(2026, 10, 12, 7, 0));
      expect(textMatching(RegExp(t.ruleMiddleOfTheNight)), findsNothing);
      await closeToday(tester);
      await openWithReading(
        tester,
        readingAt(times: cairoTimes, movedByRule: {Prayer.fajr, Prayer.isha}),
      );
      final note = tester
          .widget<Text>(textMatching(RegExp(t.ruleMiddleOfTheNight)))
          .data!;
      expect(note, contains(prayerName(t, Prayer.fajr)));
      expect(note, contains(prayerName(t, Prayer.isha)));
    });

    testApp('a day estimated from a nearer latitude names that latitude', (
      tester,
    ) async {
      await openWithReading(
        tester,
        readingAt(times: cairoTimes, estimatedFrom: 48.5),
      );
      expect(textMatching(RegExp('48\\.5')), findsOneWidget);
    });

    testApp('travel mode adds the way to in-flight mode', (tester) async {
      await settings.setLocation(cairo.toStored());
      await openToday(tester);
      expect(find.text(t.inFlightCardTitle), findsNothing);
      await closeToday(tester);
      await settings.saveTravel(
        const TravelSettings(travelMode: true, followLocation: false),
      );
      await openToday(tester);
      expect(find.text(t.inFlightCardTitle), findsOneWidget);
    });
  });

  group('alerts from Today', () {
    testApp('each row says its alert in a word, and its sheet changes it', (
      tester,
    ) async {
      await settings.setLocation(cairo.toStored());
      await openToday(tester);
      final sunriseButton = find.descendant(
        of: row(Prayer.sunrise),
        matching: find.text(t.alertShortOff),
      );
      expect(
        sunriseButton,
        findsOneWidget,
        reason: 'Sunrise\'s alert is off by default',
      );
      await tester.ensureVisible(sunriseButton);
      await tester.tap(sunriseButton);
      await tester.pumpAndSettle();
      expect(
        find.text(t.alertSheetTitle(prayerName(t, Prayer.sunrise))),
        findsOneWidget,
      );
      await tester.tap(find.text(t.soundModeSilent));
      await tester.pumpAndSettle();
      final alerts = (await settings.read()).adhanAlerts;
      expect(alerts.alertFor(Prayer.sunrise).enabled, isTrue);
      expect(alerts.soundModeFor(Prayer.sunrise), AdhanSoundMode.silent);
      expect(
        permissionRequests,
        1,
        reason: 'turning an alert on asks for the permission',
      );
      await tester.tap(find.text(t.alertDone));
      await tester.pumpAndSettle();
      expect(
        find.descendant(
          of: row(Prayer.sunrise),
          matching: find.text(t.alertShortSilent),
        ),
        findsOneWidget,
      );
    });

    testApp('Off is not Silent: it turns the alert off', (tester) async {
      await settings.setLocation(cairo.toStored());
      await openToday(tester);
      final fajr = find.descendant(
        of: row(Prayer.fajr),
        matching: find.byType(LineIcon),
      );
      await tester.ensureVisible(fajr.first);
      await tester.tap(fajr.first);
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.alertShortOff).last);
      await tester.pumpAndSettle();
      expect(
        (await settings.read()).adhanAlerts.alertFor(Prayer.fajr).enabled,
        isFalse,
      );
      expect(permissionRequests, 0);
    });
  });

  group('every size and theme', () {
    testApp('a very large text size still fits, and nothing truncates a time', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      showWholeDay(tester);
      await settings.setLocation(cairo.toStored());
      await tester.pumpWidget(harness());
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(hero(tester).kicker, t.nextPrayerAdhan.toUpperCase());
      expect(row(Prayer.isha), findsOneWidget);
    });

    testApp('a very large text size fits on a 12-hour device too', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 3.0;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      showWholeDay(tester, width: 1800);
      await settings.setLocation(cairo.toStored());
      await tester.pumpWidget(harness(use24Hour: false));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(textMatching(RegExp(r'^\d{1,2}:\d{2} [AP]M$')), findsWidgets);
    });

    testApp('a short phone at normal size scrolls instead of overflowing', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 1800);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await settings.setLocation(cairo.toStored());
      await settings.saveTravel(
        const TravelSettings(travelMode: true, followLocation: false),
      );
      await openToday(tester);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(row(Prayer.isha), 200);
      expect(row(Prayer.isha), findsOneWidget);
    });

    testApp('scrolling the whole day to the end never breaks the page', (
      tester,
    ) async {
      // A small phone, travel mode on, so the hero scrolls fully away.
      tester.view.physicalSize = const Size(1080, 1500);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await settings.setLocation(cairo.toStored());
      await settings.saveTravel(
        const TravelSettings(travelMode: true, followLocation: false),
      );
      await openToday(tester);
      final scroll = find.byType(Scrollable).first;
      for (var i = 0; i < 6; i++) {
        await tester.drag(scroll, const Offset(0, -400));
        await tester.pump();
        expect(tester.takeException(), isNull, reason: 'drag $i');
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(row(Prayer.isha), findsOneWidget);
      expect(find.byType(ErrorWidget), findsNothing);
    });

    testApp('the dark theme keeps the same reading', (tester) async {
      await settings.setLocation(cairo.toStored());
      await tester.pumpWidget(harness(dark: true));
      await tester.pumpAndSettle();
      expect(hero(tester).kicker, t.nextPrayerAdhan.toUpperCase());
      expect(hero(tester).name, prayerName(t, Prayer.dhuhr));
    });

    testApp('a row is read as one line, Iqama included', (tester) async {
      await settings.setLocation(cairo.toStored());
      await addMosque(iqamas: {Prayer.dhuhr: LocalTime.of(12, 15)});
      final handle = tester.ensureSemantics();
      await openToday(tester);
      final label = tester
          .getSemantics(
            find
                .descendant(
                  of: row(Prayer.dhuhr),
                  matching: find.byType(InkWell),
                )
                .first,
          )
          .label;
      expect(
        label,
        allOf(
          contains(prayerName(t, Prayer.dhuhr)),
          contains(t.rowIqama('12:15')),
        ),
      );
      handle.dispose();
    });
  });
}
