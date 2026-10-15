import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/sky/sky_model.dart';
import 'package:jamaah/src/features/sky/grain.dart';
import 'package:jamaah/src/features/sky/sky_background.dart';
import 'package:jamaah/src/features/sky/sky_motion.dart';

void main() {
  group('grain', () {
    test('is a fixed greyscale tile centred on mid grey', () {
      final a = Grain.pixels(), b = Grain.pixels();
      expect(a, b);
      var sum = 0;
      for (var i = 0; i < a.length; i += 4) {
        expect(a[i], a[i + 1]);
        expect(a[i], a[i + 2]);
        expect(a[i + 3], 255);
        sum += a[i];
      }
      final mean = sum / (a.length / 4);
      // Overlay with mid grey leaves the sky's colour as it is on average.
      expect(mean, closeTo(127.5, 6));
    });
  });

  group('motion', () {
    Future<SkyMotion> pumpScope(
      WidgetTester tester, {
      bool reduce = false,
    }) async {
      late SkyMotion motion;
      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(disableAnimations: reduce),
          child: SkyMotionScope(
            child: Builder(
              builder: (context) {
                motion = SkyMotion.maybeOf(context)!;
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      return motion;
    }

    testWidgets('one looping clock runs while the screen is shown', (
      tester,
    ) async {
      final motion = await pumpScope(tester);
      expect(motion.still, isFalse);
      expect(motion.running, isTrue);
      await tester.pump(const Duration(seconds: 2));
      expect(motion.seconds, closeTo(2, 0.05));
      // About 24 ticks a second, not one per display frame.
      var ticks = 0;
      motion.clock.addListener(() => ticks++);
      await tester.pump(const Duration(seconds: 1));
      expect(ticks, inInclusiveRange(23, 25));
    });

    testWidgets('reduce motion stops it: nothing twinkles or pulses', (
      tester,
    ) async {
      final motion = await pumpScope(tester, reduce: true);
      expect(motion.still, isTrue);
      expect(motion.seconds, isNull);
      expect(motion.running, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('it stops in the background and starts again on return', (
      tester,
    ) async {
      await pumpScope(tester);
      SkyMotion current() => tester.widget<SkyMotion>(find.byType(SkyMotion));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      // A paused app draws no frames, so read the clock itself: it stops.
      final paused = current().clock.value;
      await tester.pump(const Duration(seconds: 2));
      expect(current().clock.value, paused, reason: 'no ticks while hidden');
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(current().running, isTrue);
    });

    testWidgets('a hidden tab holds no running ticker', (tester) async {
      await tester.pumpWidget(
        const TickerMode(
          enabled: false,
          child: SkyMotionScope(child: SizedBox()),
        ),
      );
      expect(tester.widget<SkyMotion>(find.byType(SkyMotion)).running, isFalse);
    });
  });

  group('SkyBackground', () {
    for (final dark in [false, true]) {
      for (final minute in [60.0, 342.0, 689.0, 1035.0]) {
        testWidgets('paints ${dark ? 'dark' : 'light'} at minute $minute', (
          tester,
        ) async {
          await tester.pumpWidget(
            SkyMotionScope(
              child: SkyBackground(
                frame: SkyModel.reference.frameAt(minute, dark: dark),
                dark: dark,
                shades: [SkyShade(0, 0.08, SkyModel.reference.frameAt(0).glow)],
                child: const SizedBox.expand(),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(tester.takeException(), isNull);
          expect(find.byType(SkyBackground), findsOneWidget);
        });
      }
    }
  });
}
