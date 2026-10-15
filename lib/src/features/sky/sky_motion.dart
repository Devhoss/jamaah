import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/sky/star_field.dart';

/// The one clock behind every slow movement on the sky: twinkle, the sun's
/// breathing halo, the selected marker's pulse (spec §3.6).
///
/// It ticks at [fps] rather than every display frame: these movements are
/// slow, and only the small layers that show them repaint on each tick, while
/// the gradient, glow and grain stay cached (owner, 2026-10-16: Today idled
/// at ~90% of a core when everything repainted at 60 fps).
///
/// It stops when the screen is hidden (TickerMode), when the app goes to the
/// background, and for good under reduce motion
/// (`MediaQuery.disableAnimations`), where [SkyMotion.seconds] is null and
/// painters draw their resting state.
class SkyMotionScope extends StatefulWidget {
  const SkyMotionScope({required this.child, super.key});

  final Widget child;

  /// Ticks per second for twinkle, breathe and pulse.
  static const fps = 24;

  @override
  State<SkyMotionScope> createState() => _SkyMotionScopeState();
}

class _SkyMotionScopeState extends State<SkyMotionScope>
    with WidgetsBindingObserver {
  final _clock = ValueNotifier<double>(0);
  int _ticks = 0;
  Timer? _timer;
  bool _reduceMotion = false;
  bool _visible = true;
  bool _foreground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _visible = TickerMode.valuesOf(context).enabled;
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    // Outside a build, so the scope can tell its painters at once.
    setState(_sync);
  }

  bool get _running => _timer != null;

  void _sync() {
    final run = _foreground && _visible && !_reduceMotion;
    if (run && !_running) {
      // Counted in ticks rather than read off a stopwatch, so a paused clock
      // resumes where it stopped (and tests can drive it with fake time).
      _timer = Timer.periodic(
        Duration(microseconds: 1000000 ~/ SkyMotionScope.fps),
        (_) => _clock.value = (++_ticks / SkyMotionScope.fps) % StarField.loop,
      );
    } else if (!run && _running) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SkyMotion(
    clock: _clock,
    still: _reduceMotion,
    running: _running,
    child: widget.child,
  );
}

/// Read by painters: a [Listenable] to repaint on, and the seconds into the
/// loop (null when motion is reduced).
class SkyMotion extends InheritedWidget {
  const SkyMotion({
    required this.clock,
    required this.still,
    required this.running,
    required super.child,
    super.key,
  });

  /// Seconds into the loop, updated [SkyMotionScope.fps] times a second.
  final ValueListenable<double> clock;

  /// Reduce motion: nothing twinkles, breathes or pulses.
  final bool still;

  /// Whether the clock is ticking now (not hidden, not in the background).
  final bool running;

  double? get seconds => still ? null : clock.value;

  /// The nearest scope; a scope-less tree (a test, a preview) is still.
  static SkyMotion? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkyMotion>();

  @override
  bool updateShouldNotify(SkyMotion oldWidget) =>
      clock != oldWidget.clock ||
      still != oldWidget.still ||
      running != oldWidget.running;
}
