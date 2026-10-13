import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/foreground_clock.dart';

/// The foreground half of the minute ticker: the countdown moves while the screen
/// is on, stops when the app is not, and catches up the moment it is.
void main() {
  late _FakeClock clock;

  setUp(() {
    clock = _FakeClock(DateTime.utc(2026, 10, 12, 9, 0));
  });

  Widget harness() => ProviderScope(
    overrides: [appClockProvider.overrideWithValue(clock)],
    child: ForegroundClock(
      child: Directionality(
        // The widget under test is the lifecycle wiring, so the tree stays bare —
        // and a bare Text still needs a direction to lay out in.
        textDirection: TextDirection.ltr,
        child: Consumer(
          builder: (context, ref, _) => Text(
            ref.watch(minuteClockProvider).toIso8601String(),
          ),
        ),
      ),
    ),
  );

  String shown(WidgetTester tester) =>
      tester.widget<Text>(find.byType(Text)).data!;

  /// The platform's way out of the foreground, in the order Android reports it.
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

  /// Unmounting the scope disposes the container, which is what cancels the
  /// ticker. Fake async only reports "a Timer is still pending" at teardown, so the
  /// cancellation has to happen inside the body.
  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the reading moves with each minute in the foreground', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    expect(shown(tester), '2026-10-12T09:00:00.000Z');

    clock.instant = DateTime.utc(2026, 10, 12, 9, 1);
    await tester.pump(const Duration(minutes: 1));
    expect(shown(tester), '2026-10-12T09:01:00.000Z');

    await unmount(tester);
  });

  testWidgets('time passing in the background does not tick the clock', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);

    clock.instant = DateTime.utc(2026, 10, 12, 9, 20);
    await tester.pump(const Duration(minutes: 5));

    expect(
      shown(tester),
      '2026-10-12T09:00:00.000Z',
      reason: 'a backgrounded app is not reading the clock at all',
    );

    await unmount(tester);
  });

  testWidgets('returning refreshes at once, then keeps ticking', (
    tester,
  ) async {
    await tester.pumpWidget(harness());
    await leaveForeground(tester);
    clock.instant = DateTime.utc(2026, 10, 12, 21, 1);

    await returnToForeground(tester);
    expect(
      shown(tester),
      '2026-10-12T21:01:00.000Z',
      reason: 'the screen must not wait for the next minute to be correct',
    );

    clock.instant = DateTime.utc(2026, 10, 12, 21, 2);
    await tester.pump(const Duration(minutes: 1));
    expect(shown(tester), '2026-10-12T21:02:00.000Z');

    await unmount(tester);
  });
}

class _FakeClock implements AppClock {
  _FakeClock(this.instant);

  DateTime instant;

  @override
  DateTime nowUtc() => instant;
}
