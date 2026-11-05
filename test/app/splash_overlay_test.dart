import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/splash_overlay.dart';

/// The return splash: none on a cold start or a quick return, the full
/// brand story after a real absence, and a tap skips it.
void main() {
  late DateTime now;

  setUp(() {
    now = DateTime.utc(2026, 11, 4, 19, 0);
  });

  Widget harness() => MaterialApp(
    home: SplashOverlay(clock: () => now, child: const Text('home')),
  );

  bool splashShown(WidgetTester tester) => tester
      .widgetList(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == kSplashBackground,
        ),
      )
      .isNotEmpty;

  /// The platform's way out of and back into the foreground, in the order
  /// Android reports it (AppLifecycleListener rejects paused -> resumed).
  Future<void> leaveForeground(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  Future<void> returnToForeground(WidgetTester tester) async {
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
  }

  testWidgets('no splash on the first frame', (tester) async {
    await tester.pumpWidget(harness());
    expect(splashShown(tester), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('no splash after a short absence', (tester) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);
    now = now.add(const Duration(seconds: 5));
    await returnToForeground(tester);
    expect(splashShown(tester), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('splash after a long absence, then it goes away', (tester) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);
    now = now.add(const Duration(seconds: 30));
    await returnToForeground(tester);

    expect(splashShown(tester), isTrue);
    // Mid-story the mark is animating, not yet faded.
    await tester.pump(const Duration(milliseconds: 500));
    expect(splashShown(tester), isTrue);

    // Past the 1 200 ms controller the overlay is gone.
    await tester.pump(const Duration(milliseconds: 800));
    expect(splashShown(tester), isFalse);
    expect(find.text('home'), findsOneWidget);
  });

  testWidgets('the arch draws frame by frame without throwing', (tester) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);
    now = now.add(const Duration(seconds: 30));
    await returnToForeground(tester);

    // Pump in small steps so frames land inside the arch's 0-400 ms
    // trimPath window, where the painter extracts a sub-path from the
    // arch's metrics. PathMetrics is single-pass: reading it twice in
    // one paint throws "Bad state: No element" on device.
    for (var ms = 0; ms < 1150; ms += 50) {
      await tester.pump(const Duration(milliseconds: 50));
      expect(splashShown(tester), isTrue, reason: 'at ${ms + 50} ms');
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(splashShown(tester), isFalse);
  });

  testWidgets('a tap skips the splash', (tester) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);
    now = now.add(const Duration(seconds: 60));
    await returnToForeground(tester);
    expect(splashShown(tester), isTrue);

    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is ColoredBox && w.color == kSplashBackground,
      ),
    );
    await tester.pump();
    expect(splashShown(tester), isFalse);
  });
}
