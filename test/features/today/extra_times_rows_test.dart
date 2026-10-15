import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/extra_times.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/today/today_screen.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// Imsak, Duha and the last third of the night on Today (2026-10-14): quiet
/// rows in time order, never the next prayer.
void main() {
  final t = AppLocalizationsEn();
  final ar = AppLocalizationsArDigits();

  late AppDatabase db;
  late SettingsRepository settings;

  setUpAll(loadTimeZoneDatabase);

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    addTearDown(db.close);
  });

  final cairoZone = zoneOffsetsFor('Africa/Cairo');
  DateTime cairoAt(LocalDay day, int h, int m) =>
      cairoZone.utcInstantOf(day: day, time: LocalTime.of(h, m));
  const day = LocalDay(2026, 10, 14);

  late ProviderContainer container;
  var openings = 0;

  Future<void> open(
    WidgetTester tester, {
    required DateTime now,
    Locale locale = const Locale('en'),
  }) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        key: ValueKey('app-${++openings}'),
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(FixedClock(now)),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
        ],
        child: MaterialApp(
          locale: locale,
          theme: AppTheme.light(),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(alwaysUse24HourFormat: true),
              child: const Scaffold(body: TodayScreen()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    container = ProviderScope.containerOf(
      tester.element(find.byType(TodayScreen)),
    );
  }

  /// The expected time of [time] for the night or day [on], as Today shows it.
  String hhmm(ExtraTime time, LocalDay on, ExtraTimesSettings s) {
    final e = extraTimesFor(
      calculator: container.read(prayerTimesCalculatorProvider)!,
      day: on,
      settings: s,
    ).singleWhere((e) => e.time == time);
    return '${e.at.hour.toString().padLeft(2, '0')}:'
        '${e.at.minute.toString().padLeft(2, '0')}';
  }

  /// The row's own label: the hero and the sun's path can name the same
  /// prayer higher up, and the rows come last.
  double top(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text).last).dy;

  testApp('by default Imsak alone, just above Fajr', (tester) async {
    await open(tester, now: cairoAt(day, 12, 0));
    expect(find.text(t.extraImsak), findsOneWidget);
    expect(find.text(t.extraDuha), findsNothing);
    expect(find.text(t.extraQiyam), findsNothing);
    expect(
      find.text(hhmm(ExtraTime.imsak, day, const ExtraTimesSettings())),
      findsOneWidget,
    );
    expect(top(tester, t.extraImsak), lessThan(top(tester, t.prayerFajr)));
  });

  testApp('Duha after Sunrise, the last third after Isha', (tester) async {
    const shown = ExtraTimesSettings(shown: {ExtraTime.duha, ExtraTime.qiyam});
    await settings.saveExtraTimes(shown);
    await open(tester, now: cairoAt(day, 12, 0));
    expect(find.text(t.extraImsak), findsNothing);
    expect(top(tester, t.extraDuha), greaterThan(top(tester, t.prayerSunrise)));
    expect(top(tester, t.extraDuha), lessThan(top(tester, t.prayerDhuhr)));
    expect(top(tester, t.extraQiyam), greaterThan(top(tester, t.prayerIsha)));
    expect(find.text(hhmm(ExtraTime.qiyam, day, shown)), findsOneWidget);
  });

  testApp('at 02:00 the last third is the night in progress', (tester) async {
    const shown = ExtraTimesSettings(shown: {ExtraTime.qiyam});
    await settings.saveExtraTimes(shown);
    await open(tester, now: cairoAt(day, 2, 0));
    expect(
      find.text(hhmm(ExtraTime.qiyam, day.addDays(-1), shown)),
      findsOneWidget,
    );
  });

  testApp('an extra time is never the next prayer', (tester) async {
    // Five minutes before Imsak: Fajr is still what the card counts to.
    await open(tester, now: cairoAt(day, 12, 0));
    final imsak = extraTimesFor(
      calculator: container.read(prayerTimesCalculatorProvider)!,
      day: day,
      settings: const ExtraTimesSettings(),
    ).first;
    await open(tester, now: imsak.utc.subtract(const Duration(minutes: 5)));
    expect(find.textContaining(t.prayerFajr), findsWidgets);
    expect(
      find.textContaining(RegExp('^${t.extraImsak} ')),
      findsNothing,
      reason: 'the card never says "Imsak at …"',
    );
  });

  testApp('Arabic names and digits', (tester) async {
    await settings.setLanguage(AppLanguage.ar);
    await open(
      tester,
      now: cairoAt(day, 12, 0),
      locale: const Locale('ar', 'EG'),
    );
    expect(find.text(ar.extraImsak), findsOneWidget);
  });
}
