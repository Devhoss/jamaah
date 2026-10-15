import 'package:flutter/material.dart';

import '../../domain/sky/star_field.dart';

/// The one clock behind every slow movement on the sky: twinkle, the sun's
/// breathing halo, the selected marker's pulse (spec §3.6).
///
/// A single looping controller, so a screen full of stars costs one ticker.
/// It stops when the screen is hidden (TickerMode), when the app goes to the
/// background, and for good under reduce motion
/// (`MediaQuery.disableAnimations`), where [SkyMotion.secondsOf] is null and
/// painters draw their resting state.
class SkyMotionScope extends StatefulWidget {
  const SkyMotionScope({required this.child, super.key});

  final Widget child;

  @override
  State<SkyMotionScope> createState() => _SkyMotionScopeState();
}

class _SkyMotionScopeState extends State<SkyMotionScope>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (StarField.loop * 1000).round()),
  );
  bool _reduceMotion = false;
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
    _sync();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _sync();
  }

  void _sync() {
    final run = _foreground && !_reduceMotion;
    if (run && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!run && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SkyMotion(
    animation: _controller,
    still: _reduceMotion,
    child: widget.child,
  );
}

/// Read by painters: a [Listenable] to repaint on, and the seconds into the
/// loop (null when motion is reduced).
class SkyMotion extends InheritedWidget {
  const SkyMotion({
    required this.animation,
    required this.still,
    required super.child,
    super.key,
  });

  final Animation<double> animation;

  /// Reduce motion: nothing twinkles, breathes or pulses.
  final bool still;

  double? get seconds => still ? null : animation.value * StarField.loop;

  /// The nearest scope; a scope-less tree (a test, a preview) is still.
  static SkyMotion? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<SkyMotion>();

  static Listenable repaintOf(BuildContext context) =>
      maybeOf(context)?.animation ?? const AlwaysStoppedAnimation(0.0);

  static double? secondsOf(BuildContext context) => maybeOf(context)?.seconds;

  @override
  bool updateShouldNotify(SkyMotion oldWidget) =>
      animation != oldWidget.animation || still != oldWidget.still;
}
