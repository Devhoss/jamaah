import 'dart:ui' show SemanticsAction;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/sky/moon_phase.dart';
import 'package:jamaah/src/domain/sky/sun_path_geometry.dart';
import 'package:jamaah/src/features/sky/sky_motion.dart';
import 'package:jamaah/src/features/sky/sun_path.dart';

void main() {
  const geometry = SunPathGeometry.reference; // 342 .. 1035
  const ink = SunPathInk(ink: Color(0xFF15161C), labelInk: Color(0xFF15161C));
  const markers = [
    SunPathMarker(prayer: Prayer.fajr, minute: 261),
    SunPathMarker(prayer: Prayer.sunrise, minute: 342),
    SunPathMarker(prayer: Prayer.dhuhr, minute: 689, selected: true),
    SunPathMarker(prayer: Prayer.asr, minute: 889, next: true),
    SunPathMarker(prayer: Prayer.maghrib, minute: 1035),
    SunPathMarker(prayer: Prayer.isha, minute: 1111),
  ];

  Future<List<double>> pump(
    WidgetTester tester, {
    double minute = 689,
    bool interactive = true,
    TextDirection direction = TextDirection.ltr,
    List<int>? ends,
  }) async {
    final scrubs = <double>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Directionality(
          textDirection: direction,
          child: SkyMotionScope(
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 390,
                child: SunPath(
                  geometry: geometry,
                  minute: minute,
                  markers: markers,
                  ink: ink,
                  moon: MoonPhase.fromHijriDay(4),
                  sunLabel: 'Now 11:29',
                  selectedLabel: 'Dhuhr',
                  onScrub: interactive ? scrubs.add : null,
                  onScrubEnd: interactive ? () => ends?.add(1) : null,
                  semanticLabel: 'Look through the day',
                  semanticValue: '11:29 AM, Dhuhr',
                  semanticStep: (up: '11:44 AM', down: '11:14 AM'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 50));
    return scrubs;
  }

  testWidgets('is 390 × 168 at the design width', (tester) async {
    await pump(tester);
    expect(tester.getSize(find.byType(SunPath)), const Size(390, 168));
  });

  testWidgets('a touch on the arc looks at that minute', (tester) async {
    final scrubs = await pump(tester);
    // The top of the day arc is halfway between sunrise and sunset.
    await tester.tapAt(const Offset(195, 22));
    expect(scrubs.single, closeTo((342 + 1035) / 2, 0.5));
  });

  testWidgets('a drag follows the finger and ends once', (tester) async {
    final ends = <int>[];
    final scrubs = await pump(tester, ends: ends);
    final rise = geometry.positionAt(400).point;
    final set = geometry.positionAt(1000).point;
    await tester.dragFrom(
      Offset(rise.x, rise.y),
      Offset(set.x - rise.x, set.y - rise.y),
    );
    await tester.pump();
    expect(scrubs.first, closeTo(400, 2));
    expect(scrubs.last, closeTo(1000, 2));
    expect(ends, hasLength(1));
  });

  testWidgets('below the horizon reads the night arc', (tester) async {
    final scrubs = await pump(tester);
    await tester.tapAt(const Offset(195, 118 + 36));
    expect(geometry.isDay(scrubs.single), isFalse);
  });

  testWidgets('is a slider for TalkBack, 15 minutes a step', (tester) async {
    final handle = tester.ensureSemantics();
    final scrubs = await pump(tester);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Look through the day')),
      isSemantics(
        isSlider: true,
        label: 'Look through the day',
        value: '11:29 AM, Dhuhr',
        increasedValue: '11:44 AM',
        decreasedValue: '11:14 AM',
        hasIncreaseAction: true,
        hasDecreaseAction: true,
      ),
    );
    tester.semantics.performAction(
      find.semantics.byLabel('Look through the day'),
      SemanticsAction.increase,
    );
    expect(scrubs.single, 689 + 15);
    handle.dispose();
  });

  testWidgets('arrow keys move 5 minutes, with Shift 30', (tester) async {
    final scrubs = await pump(tester);
    Focus.of(tester.element(find.text('Dhuhr'))).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(scrubs, [694, 659]);
  });

  testWidgets('without a handler it is a picture: no slider, no gestures', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await pump(tester, interactive: false);
    expect(find.byType(GestureDetector), findsNothing);
    expect(find.bySemanticsLabel('Look through the day'), findsNothing);
    handle.dispose();
  });

  testWidgets('is not mirrored in Arabic: sunrise stays on the left', (
    tester,
  ) async {
    final scrubs = await pump(tester, direction: TextDirection.rtl);
    final early = geometry.positionAt(400).point;
    await tester.tapAt(Offset(early.x, early.y));
    expect(scrubs.single, closeTo(400, 2));
  });

  testWidgets('scales with the width', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 780,
            child: SunPath(
              geometry: geometry,
              minute: 689,
              markers: markers,
              ink: ink,
            ),
          ),
        ),
      ),
    );
    expect(tester.getSize(find.byType(SunPath)), const Size(780, 336));
  });
}
