import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:jamaah/src/app/clock_format.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/features/components/line_icon.dart';
import 'package:jamaah/src/features/components/travel_switch.dart';
import 'package:jamaah/src/features/sky/sky_palette.dart';
import 'package:jamaah/src/features/today/today_hero.dart';
import 'package:jamaah/src/features/today/today_notes.dart';
import 'package:jamaah/src/features/today/today_top_bar.dart';

const _palette = SkyPalette(ink: Color(0xFF15161C), deep: Color(0xFFFBFAF7));
final _t = AppLocalizationsEn();

Widget _app(Widget child, {double textScale = 1, bool reduceMotion = false}) =>
    MaterialApp(
      theme: AppTheme.light(),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
            disableAnimations: reduceMotion,
          ),
          child: Scaffold(body: SafeArea(child: child)),
        ),
      ),
    );

Rect _tightBounds(Path path) {
  var l = double.infinity, t = double.infinity;
  var r = -double.infinity, btm = -double.infinity;
  for (final m in path.computeMetrics()) {
    for (var d = 0.0; d <= m.length; d += 0.05) {
      final p = m.getTangentForOffset(d)!.position;
      if (p.dx < l) l = p.dx;
      if (p.dy < t) t = p.dy;
      if (p.dx > r) r = p.dx;
      if (p.dy > btm) btm = p.dy;
    }
  }
  return Rect.fromLTRB(l, t, r, btm);
}

void main() {
  setUpAll(() => initializeDateFormatting());

  group('line icons', () {
    final all = [
      LineIcons.chevronRight,
      LineIcons.chevronDown,
      LineIcons.back,
      LineIcons.check,
      LineIcons.home,
      LineIcons.plane,
      LineIcons.planeTakeoff,
      LineIcons.bell,
      LineIcons.bellOff,
      LineIcons.soundFull,
      LineIcons.soundShort,
      LineIcons.silent,
      LineIcons.pin,
      LineIcons.pause,
      LineIcons.info,
      LineIcons.globe,
    ];

    test('every path parses and stays inside the 24-unit box', () {
      for (final icon in all) {
        for (final shape in icon.shapes) {
          if (shape is! PathShape) continue;
          // getBounds counts curve control points; sample the outline.
          final b = _tightBounds(parseSvgPath(shape.d));
          expect(b.isEmpty && b.width == 0 && b.height == 0, isFalse);
          expect(b.left, greaterThanOrEqualTo(-0.5), reason: shape.d);
          expect(b.top, greaterThanOrEqualTo(-0.5), reason: shape.d);
          expect(b.right, lessThanOrEqualTo(24.5), reason: shape.d);
          expect(b.bottom, lessThanOrEqualTo(24.5), reason: shape.d);
        }
      }
    });

    test('relative commands and arcs land where SVG puts them', () {
      // m9 18 6-6-6-6: a chevron from (9,18) to (15,12) to (9,6).
      final b = _tightBounds(parseSvgPath('m9 18 6-6-6-6'));
      expect(b.left, closeTo(9, 0.05));
      expect(b.top, closeTo(6, 0.05));
      expect(b.right, closeTo(15, 0.05));
      expect(b.bottom, closeTo(18, 0.05));
      // A half circle of radius 6 from (6,8) to (18,8), bulging upward.
      final arc = _tightBounds(parseSvgPath('M6 8a6 6 0 0 1 12 0'));
      expect(arc.top, closeTo(2, 0.05));
      expect(arc.left, closeTo(6, 0.05));
      expect(arc.right, closeTo(18, 0.05));
    });

    testWidgets('is decoration unless given a label', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(_app(const LineIcon(LineIcons.bell)));
      expect(find.bySemanticsLabel('Bell'), findsNothing);
      await tester.pumpWidget(
        _app(const LineIcon(LineIcons.bell, semanticLabel: 'Bell')),
      );
      expect(find.bySemanticsLabel('Bell'), findsOneWidget);
      handle.dispose();
    });
  });

  group('clock parts', () {
    test('12-hour splits the period off', () {
      const f = ClockFormat(use24Hour: false, locale: 'en');
      final p = f.parts(LocalTime.of(13, 59));
      expect(p.clock, '1:59');
      expect(p.period, 'PM');
    });

    test('24-hour has no period', () {
      const f = ClockFormat(use24Hour: true, locale: 'en');
      final p = f.parts(LocalTime.of(13, 59));
      expect(p.clock, '13:59');
      expect(p.period, isNull);
    });
  });

  group('travel switch', () {
    Future<List<bool>> pump(
      WidgetTester tester, {
      required bool value,
      bool reduceMotion = false,
    }) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(
          Center(
            child: TravelSwitch(
              value: value,
              onChanged: changes.add,
              label: 'Travel mode',
              colors: const TravelSwitchColors(
                ink: Color(0xFF15161C),
                deep: Color(0xFFFBFAF7),
                outline: Color(0x3815161C),
              ),
            ),
          ),
          reduceMotion: reduceMotion,
        ),
      );
      return changes;
    }

    testWidgets('a tap asks for the other state', (tester) async {
      final changes = await pump(tester, value: false);
      await tester.tap(find.byType(TravelSwitch));
      expect(changes, [true]);
    });

    testWidgets('is a switch for TalkBack, with its name', (tester) async {
      final handle = tester.ensureSemantics();
      await pump(tester, value: true);
      expect(
        tester.getSemantics(find.bySemanticsLabel('Travel mode')),
        isSemantics(hasToggledState: true, isToggled: true, hasTapAction: true),
      );
      handle.dispose();
    });

    testWidgets('is a 48 dp target around a 72 × 40 pill', (tester) async {
      await pump(tester, value: false);
      final size = tester.getSize(find.byType(TravelSwitch));
      expect(size.width, 72);
      expect(size.height, 48);
    });

    testWidgets('the knob springs across, and a plane replaces the house', (
      tester,
    ) async {
      await pump(tester, value: false);
      expect(
        find.byWidgetPredicate(
          (w) => w is LineIcon && w.icon == LineIcons.home,
        ),
        findsOneWidget,
      );
      await pump(tester, value: true);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(
        find.byWidgetPredicate(
          (w) => w is LineIcon && w.icon == LineIcons.plane,
        ),
        findsOneWidget,
      );
    });

    testWidgets('under reduce motion it simply changes', (tester) async {
      await pump(tester, value: false, reduceMotion: true);
      await pump(tester, value: true, reduceMotion: true);
      await tester.pump();
      // One frame later it is already on: the plane is in, the knob is right.
      expect(
        find.byWidgetPredicate(
          (w) => w is LineIcon && w.icon == LineIcons.plane,
        ),
        findsOneWidget,
      );
      final knob = tester.getRect(
        find.byWidgetPredicate((w) => w is LineIcon).last,
      );
      final track = tester.getRect(find.byType(TravelSwitch));
      expect(track.right - knob.right, lessThan(20));
    });
  });

  group('hero', () {
    Widget hero({VoidCallback? back}) => TodayHero(
      kicker: 'NEXT PRAYER · ADHAN',
      time: '2:49',
      name: 'Asr',
      meta: 'PM · in 50 min',
      palette: _palette,
      kickerPalette: _palette,
      onBackToNow: back,
    );

    testWidgets('shows the kicker, time, name and meta', (tester) async {
      await tester.pumpWidget(_app(hero()));
      for (final s in [
        'NEXT PRAYER · ADHAN',
        '2:49',
        'Asr',
        'PM · in 50 min',
      ]) {
        expect(find.text(s), findsOneWidget);
      }
      expect(find.text(_t.heroBackToNow), findsNothing);
    });

    testWidgets('Back to now appears only when the view is moved', (
      tester,
    ) async {
      var taps = 0;
      await tester.pumpWidget(_app(hero(back: () => taps++)));
      await tester.tap(find.text(_t.heroBackToNow));
      expect(taps, 1);
      expect(
        tester
            .getSize(
              find.ancestor(
                of: find.text(_t.heroBackToNow),
                matching: find.byType(InkWell),
              ),
            )
            .height,
        greaterThanOrEqualTo(48),
      );
    });

    testWidgets('at 2× text the name wraps under the time; nothing overflows', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app(hero(back: () {}), textScale: 2));
      expect(tester.takeException(), isNull);
      final time = tester.getRect(find.text('2:49'));
      final name = tester.getRect(find.text('Asr'));
      expect(name.top, greaterThan(time.top));
      // The time grows no further than 1.3×.
      expect(
        MediaQuery.textScalerOf(tester.element(find.text('2:49'))).scale(108),
        closeTo(108 * 1.3, 0.01),
      );
    });
  });

  group('notes', () {
    List<TodayNote> notes(int n) => [
      for (var i = 1; i <= n; i++) TodayNote('Note $i'),
    ];

    testWidgets('two show as lines', (tester) async {
      await tester.pumpWidget(
        _app(TodayNotes(notes: notes(2), palette: _palette)),
      );
      expect(find.text('Note 1'), findsOneWidget);
      expect(find.text('Note 2'), findsOneWidget);
      expect(find.text(_t.moreNotes(1)), findsNothing);
    });

    testWidgets(
      'three or more collapse into "2 more notes", opened in a sheet',
      (tester) async {
        await tester.pumpWidget(
          _app(TodayNotes(notes: notes(3), palette: _palette)),
        );
        expect(find.text('Note 1'), findsOneWidget);
        expect(find.text('Note 2'), findsNothing);
        await tester.tap(find.text(_t.moreNotes(2)));
        await tester.pumpAndSettle();
        expect(find.text(_t.notesTitle), findsOneWidget);
        for (final s in ['Note 2', 'Note 3']) {
          expect(find.text(s), findsOneWidget);
        }
      },
    );

    testWidgets('a note can carry its action (the in-flight End)', (
      tester,
    ) async {
      var ended = 0;
      await tester.pumpWidget(
        _app(
          TodayNotes(
            notes: [
              TodayNote('Held', actionLabel: 'End', onAction: () => ended++),
            ],
            palette: _palette,
          ),
        ),
      );
      await tester.tap(find.text('End'));
      expect(ended, 1);
    });

    testWidgets('no notes, nothing drawn', (tester) async {
      await tester.pumpWidget(
        _app(TodayNotes(notes: const [], palette: _palette)),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('top bar', () {
    testWidgets('the place opens its sheet and the switch toggles travel', (
      tester,
    ) async {
      var placeTaps = 0;
      final travel = <bool>[];
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          TodayTopBar(
            place: 'Kuwait City',
            subline: 'Thu 15 Oct · 4 Jumada al-Awwal 1448',
            onPlace: () => placeTaps++,
            travelOn: false,
            onTravel: travel.add,
            palette: _palette,
          ),
        ),
      );
      expect(
        find.bySemanticsLabel(_t.placeButtonSemantics('Kuwait City')),
        findsOneWidget,
      );
      await tester.tap(find.text('Kuwait City'));
      await tester.tap(find.byType(TravelSwitch));
      expect(placeTaps, 1);
      expect(travel, [true]);
      handle.dispose();
    });
  });
}
