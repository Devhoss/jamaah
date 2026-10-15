import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/features/components/alert_sheet.dart';
import 'package:jamaah/src/features/sky/sky_palette.dart';
import 'package:jamaah/src/features/today/alert_choice.dart';
import 'package:jamaah/src/features/today/prayer_rows.dart';

final _t = AppLocalizationsEn();
const _palette = SkyPalette(ink: Color(0xFF15161C), deep: Color(0xFFFBFAF7));

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('alert choice', () {
    final defaults = AdhanAlertSettings.defaults().copyWith(
      defaultSoundMode: AdhanSoundMode.short,
    );

    test('Off is disabled; Silent is a shown notification', () {
      final off = applyAlertChoice(defaults, Prayer.asr, AlertChoice.off);
      expect(off.alertFor(Prayer.asr).enabled, isFalse);
      final silent = applyAlertChoice(defaults, Prayer.asr, AlertChoice.silent);
      expect(silent.alertFor(Prayer.asr).enabled, isTrue);
      expect(silent.soundModeFor(Prayer.asr), AdhanSoundMode.silent);
      expect(alertChoiceFor(off, Prayer.asr), AlertChoice.off);
      expect(alertChoiceFor(silent, Prayer.asr), AlertChoice.silent);
    });

    test(
      'picking the default follows it; anything else is the prayer\'s own',
      () {
        final own = applyAlertChoice(defaults, Prayer.asr, AlertChoice.full);
        expect(own.alertFor(Prayer.asr).soundModeOverride, AdhanSoundMode.full);
        final back = applyAlertChoice(own, Prayer.asr, AlertChoice.short);
        expect(back.alertFor(Prayer.asr).soundModeOverride, isNull);
        // ...so a later change of the default carries it along.
        final changed = back.withSoundMode(AdhanSoundMode.standard);
        expect(changed.soundModeFor(Prayer.asr), AdhanSoundMode.standard);
      },
    );

    test('Off keeps the prayer\'s own sound for when it comes back', () {
      final own = applyAlertChoice(defaults, Prayer.asr, AlertChoice.full);
      final off = applyAlertChoice(own, Prayer.asr, AlertChoice.off);
      expect(off.alertFor(Prayer.asr).soundModeOverride, AdhanSoundMode.full);
    });

    test('only turning an alert on asks for the permission', () {
      final off = applyAlertChoice(defaults, Prayer.sunrise, AlertChoice.off);
      expect(turnsAlertOn(off, Prayer.sunrise, AlertChoice.standard), isTrue);
      final on = applyAlertChoice(off, Prayer.sunrise, AlertChoice.standard);
      expect(turnsAlertOn(on, Prayer.sunrise, AlertChoice.full), isFalse);
      expect(turnsAlertOn(on, Prayer.sunrise, AlertChoice.off), isFalse);
    });
  });

  group('rows', () {
    final rows = [
      const PrayerTodayRow(
        PrayerRowData(
          prayer: Prayer.fajr,
          name: 'Fajr',
          time: '4:21 AM',
          iqama: 'Iqama 4:41',
          alert: AlertChoice.full,
        ),
      ),
      const ExtraTodayRow(ExtraRowData(name: 'Duha', time: '6:05 AM')),
      const PrayerTodayRow(
        PrayerRowData(
          prayer: Prayer.sunrise,
          name: 'Sunrise',
          time: '5:42 AM',
          alert: AlertChoice.off,
        ),
      ),
      const PrayerTodayRow(
        PrayerRowData(
          prayer: Prayer.asr,
          name: 'Asr',
          time: '2:49 PM',
          iqama: 'Iqama not set',
          alert: AlertChoice.silent,
          isNext: true,
          selected: true,
        ),
      ),
    ];

    Future<(List<Prayer>, List<Prayer>)> pump(WidgetTester tester) async {
      final picks = <Prayer>[], alerts = <Prayer>[];
      await tester.pumpWidget(
        _app(
          PrayerRows(
            rows: rows,
            palette: _palette,
            onPick: picks.add,
            onAlert: alerts.add,
          ),
        ),
      );
      return (picks, alerts);
    }

    testWidgets('a row tap picks it; its button opens its alert', (
      tester,
    ) async {
      final (picks, alerts) = await pump(tester);
      await tester.tap(find.text('Asr'));
      await tester.tap(find.text(_t.alertShortFull));
      expect(picks, [Prayer.asr]);
      expect(alerts, [Prayer.fajr]);
    });

    testWidgets('alert modes are words, not colours', (tester) async {
      await pump(tester);
      expect(find.text(_t.alertShortFull), findsOneWidget);
      expect(find.text(_t.alertShortOff), findsOneWidget);
      expect(find.text(_t.alertShortSilent), findsOneWidget);
    });

    testWidgets('Sunrise has no Iqama; an extra time has no alert button', (
      tester,
    ) async {
      final (picks, alerts) = await pump(tester);
      expect(find.textContaining('Iqama'), findsNWidgets(2));
      await tester.tap(find.text('Duha'), warnIfMissed: false);
      expect(picks, isEmpty);
      expect(alerts, isEmpty);
    });

    testWidgets('Next is tagged and the selected row is marked for TalkBack', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester);
      expect(find.text(_t.tagNext.toUpperCase()), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          _t.alertButtonSemantics('Asr', _t.soundModeSilent),
        ),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('every row and alert button is at least 48 dp', (tester) async {
      await pump(tester);
      for (final label in [_t.alertShortFull, _t.alertShortOff]) {
        final box = tester.getSize(
          find
              .ancestor(of: find.text(label), matching: find.byType(InkWell))
              .first,
        );
        expect(box.height, greaterThanOrEqualTo(48));
        expect(box.width, greaterThanOrEqualTo(48));
      }
    });
  });

  group('alert sheet', () {
    Future<List<AlertChoice>> pump(
      WidgetTester tester, {
      AlertChoice current = AlertChoice.short,
    }) async {
      final chosen = <AlertChoice>[];
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showAlertSheet(
                context,
                prayerName: 'Asr',
                adhanTime: '2:49 PM',
                current: current,
                defaultMode: AdhanSoundMode.short,
                onChoose: (c) async => chosen.add(c),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return chosen;
    }

    testWidgets('three groups, the default marked, Off apart', (tester) async {
      await pump(tester);
      expect(find.text(_t.alertSheetTitle('Asr')), findsOneWidget);
      expect(find.text(_t.alertSheetAdhan('2:49 PM')), findsOneWidget);
      expect(find.text(_t.alertGroupSound.toUpperCase()), findsOneWidget);
      expect(find.text(_t.alertGroupQuiet.toUpperCase()), findsOneWidget);
      expect(find.text(_t.alertDefaultMark(_t.soundModeShort)), findsOneWidget);
      expect(find.text(_t.soundModeFull), findsOneWidget);
      expect(find.text(_t.alertShortOff), findsOneWidget);
      expect(find.text(_t.alertDescOff), findsOneWidget);
    });

    testWidgets('a pick applies at once; Done closes', (tester) async {
      final chosen = await pump(tester);
      await tester.tap(find.text(_t.soundModeSilent));
      await tester.pump();
      await tester.tap(find.text(_t.alertShortOff));
      await tester.pump();
      expect(chosen, [AlertChoice.silent, AlertChoice.off]);
      await tester.tap(find.text(_t.alertDone));
      await tester.pumpAndSettle();
      expect(find.text(_t.alertSheetTitle('Asr')), findsNothing);
    });

    testWidgets('the current choice reads as checked', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, current: AlertChoice.full);
      expect(
        tester.getSemantics(find.bySemanticsLabel(_t.soundModeFull)),
        isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
      );
      handle.dispose();
    });
  });
}
