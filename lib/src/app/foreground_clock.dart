import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock.dart';

/// Runs the minute ticker only while the app is in the foreground.
///
/// The ticker is what makes the countdown move and the day roll over without the
/// user reopening the app. Outside the foreground that is only battery drain, so it
/// stops, and coming back re-reads the clock immediately instead of waiting for the
/// next minute — otherwise a phone left in a pocket shows a stale day on unlock.
class ForegroundClock extends ConsumerStatefulWidget {
  const ForegroundClock({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<ForegroundClock> createState() => _ForegroundClockState();
}

class _ForegroundClockState extends ConsumerState<ForegroundClock> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(minuteClockProvider.notifier).resume();
      return;
    }
    // Pausing a clock nobody ever started would build it just to cancel it, so a
    // tick that was never ticking is left alone.
    if (ref.exists(minuteClockProvider)) {
      ref.read(minuteClockProvider.notifier).pause();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
