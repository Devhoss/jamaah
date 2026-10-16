import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/features/components/bottom_nav.dart';
import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/compass.dart';
import 'package:jamaah/src/app/l10n/app_locale.dart';
import 'package:jamaah/src/app/l10n/arabic_digits_localizations.dart';
import 'package:jamaah/src/app/l10n/digits.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/notification_scheduler.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/fake_clock.dart';
import '../helpers/fake_notification_gateway.dart';
import '../helpers/fake_place_source.dart';
import '../helpers/test_app.dart';

/// Arabic (2026-10-14): every string translated, Arabic-Indic digits, Arabic
/// counting, right-to-left screens, and notifications in the chosen language.
void main() {
  final en = AppLocalizationsEn();
  final ar = AppLocalizationsArDigits();

  group('the strings', () {
    test('every English string has an Arabic one', () {
      Set<String> keys(String path) => {
        for (final k in (jsonDecode(File(path).readAsStringSync()) as Map).keys)
          if (!(k as String).startsWith('@')) k,
      };
      expect(
        keys('lib/src/app/l10n/app_ar.arb'),
        keys('lib/src/app/l10n/app_en.arb'),
      );
    });

    test('the digits class covers every string (rerun the generator)', () {
      final source = File('lib/src/app/l10n/generated/app_localizations.dart')
          .readAsStringSync();
      final strings = RegExp(
        r'^  String (get )?\w+',
        multiLine: true,
      ).allMatches(source).length;
      final digits = File('lib/src/app/l10n/arabic_digits_localizations.dart')
          .readAsStringSync();
      expect(RegExp('@override').allMatches(digits).length, strings);
    });

    test('digits are Arabic-Indic', () {
      expect(arabicDigits('5:30 · 1,290'), '٥:٣٠ · ١,٢٩٠');
      expect(
        ar.qiblaDegrees('136'),
        '\u2066١٣٦°\u2069',
        reason: 'the degree sign stays after the number in a right-to-left line',
      );
      expect(en.qiblaDegrees('136'), '136°');
    });

    test('minutes are counted the Arabic way', () {
      expect(ar.countdownMinutes(1), 'بعد دقيقة');
      expect(ar.countdownMinutes(2), 'بعد دقيقتين');
      expect(ar.countdownMinutes(5), 'بعد ٥ دقائق');
      expect(ar.countdownMinutes(15), 'بعد ١٥ دقيقة');
      expect(ar.countdownMinutes(100), 'بعد ١٠٠ دقيقة');
    });

    test('the Jama’ah reminder title is the same in both languages', () {
      expect(ar.notifIqamaCall, en.notifIqamaCall);
    });

    test('any Arabic the phone asks for gets the app’s Arabic', () {
      expect(resolveAppLocale(const Locale('ar', 'KW')), kArabicLocale);
      expect(resolveAppLocale(const Locale('ar')), kArabicLocale);
      expect(resolveAppLocale(const Locale('fr')), kEnglishLocale);
      expect(resolveAppLocale(null), kEnglishLocale);
    });

    test('the full-screen time reads in Arabic', () {
      expect(
        plainClockTime(
          LocalTime.of(17, 5),
          use24Hour: false,
          languageCode: 'ar',
        ),
        '٥:٠٥ م',
      );
      expect(plainClockTime(LocalTime.of(5, 5), use24Hour: false), '5:05 AM');
    });
  });

  group('the app in Arabic', () {
    late AppDatabase db;
    late SettingsRepository settings;
    late FakeNotificationGateway gateway;

    setUpAll(loadTimeZoneDatabase);

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      settings = SettingsRepository(db);
      gateway = FakeNotificationGateway();
      addTearDown(db.close);
    });

    Future<ProviderContainer> open(
      WidgetTester tester, {
      AppLanguage language = AppLanguage.ar,
      double textScale = 1.0,
    }) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await settings.setLocation(cairo.toStored());
      await settings.setLanguage(language);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appDatabaseProvider.overrideWithValue(db),
            appClockProvider.overrideWithValue(
              FixedClock(DateTime.utc(2026, 10, 12, 7, 0)),
            ),
            placeSourceProvider.overrideWithValue(
              FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
            ),
            notificationGatewayProvider.overrideWithValue(gateway),
            compassSourceProvider.overrideWithValue(_SilentCompass()),
            phoneUtcOffsetProvider.overrideWithValue(null),
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
      return ProviderScope.containerOf(
        tester.element(find.byType(MaterialApp)),
      );
    }

    testApp('Today is right to left, in Arabic, with Arabic digits', (
      tester,
    ) async {
      await open(tester);
      expect(
        Directionality.of(tester.element(find.text(ar.prayerFajr).last)),
        TextDirection.rtl,
      );
      expect(find.text(ar.prayerFajr), findsWidgets);
      expect(find.text(ar.tabQibla), findsOneWidget);
      final texts = tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
      expect(
        RegExp('[0-9]').hasMatch(texts),
        isFalse,
        reason: 'no Western digit on an Arabic screen: $texts',
      );
    });

    testApp('Settings switches the language at once, and back', (tester) async {
      await open(tester, language: AppLanguage.en);
      await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
      await tester.pumpAndSettle();

      await tester.tap(find.text(en.settingsLanguageLook));
      await tester.pumpAndSettle();
      await tester.tap(find.text('العربية'));
      await tester.pumpAndSettle();

      expect((await settings.read()).language, AppLanguage.ar);
      expect(find.text(ar.settingsLanguageLook), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(ar.settingsLanguageLook))),
        TextDirection.rtl,
      );

      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text(en.settingsLanguageLook), findsOneWidget);
    });

    testApp('notifications are written in the chosen language', (tester) async {
      final container = await open(tester);
      final l10n = container.read(notificationL10nProvider);
      final text = notificationText(
        l10n,
        PlannedNotification(
          id: 1,
          kind: NotificationKind.iqama,
          prayer: Prayer.fajr,
          at: DateTime.utc(2026),
          soundMode: null,
          mosqueId: 'm',
          minutesBefore: 10,
        ),
        mosqueName: (_) => 'مسجد النور',
      );
      expect(text.title, 'حيّ على الصلاة');
      expect(text.body, 'إقامة الفجر بعد ١٠ دقائق في مسجد النور.');
    });

    testApp('every tab and Settings survive Arabic at a large text size', (
      tester,
    ) async {
      await open(tester, textScale: 2.0);
      expect(tester.takeException(), isNull);
      for (final tab in [ar.tabMosques, ar.tabQibla, ar.tabToday]) {
        await tester.tap(find.text(tab));
        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: tab);
      }
      await tester.tap(find.byKey(BottomNav.tabKey(BottomNav.settingsIndex)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _SilentCompass implements CompassSource {
  @override
  Stream<CompassReading> readings() => const Stream.empty();

  @override
  Future<double?> declination({
    required double latitude,
    required double longitude,
  }) async => null;
}
