import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// [testWidgets] plus the one thing every drift-backed widget test needs here.
///
/// Unmounting the [ProviderScope] cancels the settings stream, and closing a drift
/// stream schedules a zero-duration cleanup timer. Fake async only runs a timer once
/// time moves, so leaving it to the framework teardown reports "A Timer is still
/// pending". Detaching and flushing at the end of the body keeps the real database
/// in the test instead of swapping it for a fake.
///
/// The app is run with reduce motion on (Horizon, 2026-10-15): the sky's stars,
/// sun and markers move on one looping clock that never settles, and reduce
/// motion is the user setting that stills it. Glides are then instant, so a
/// test reads the end state. Tests about motion itself use [testWidgets].
void testApp(String description, Future<void> Function(WidgetTester) body) {
  testWidgets(description, (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await body(tester);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
