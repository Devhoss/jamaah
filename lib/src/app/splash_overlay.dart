import 'package:flutter/material.dart';

import '../features/components/brand_mark.dart' show kBrandAmber;
import '../features/components/line_icon.dart' show parseSvgPath;

/// How long the app must have been away before a return shows the splash
/// again. Shorter absences (switching apps, a permission dialog, the sound
/// picker) go straight back to where the user was — a splash every time
/// would punish checking the time.
const kSplashResumeThreshold = Duration(seconds: 15);

/// The evening sky the splash sits on, and the mark's cream ink. These are
/// the same values as `brand_colors.xml` (brand_splash / brand_cream) and
/// the Android 12 system splash; keep them in step.
const kSplashBackground = Color(0xFF1F2A5E);
const kSplashInk = Color(0xFFFFF4EA);

/// The splash on a *return*, not on a cold start.
///
/// Android's system splash (values-v31, the animated vector) only appears
/// when the activity is created, so a cold start is already covered — and
/// covering it again here would double it. Resuming an existing activity
/// (tapping the icon while the app sits in the background, the common
/// "open Jama'ah" path) gets no system splash at all, so this overlay
/// plays the same 1 000 ms story in Flutter on resume after
/// [kSplashResumeThreshold] away. Timing is make_brand.py's SPLASH dict,
/// the same one behind the native animated vector: arch 0–400 ms, figures
/// 300–680 ms staggered, "you" 620–1 000 ms, then a 200 ms fade.
class SplashOverlay extends StatefulWidget {
  const SplashOverlay({
    required this.child,
    this.clock = DateTime.now,
    super.key,
  });

  final Widget child;

  /// Injectable for tests; production uses the wall clock.
  final DateTime Function() clock;

  @override
  State<SplashOverlay> createState() => _SplashOverlayState();
}

class _SplashOverlayState extends State<SplashOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final AppLifecycleListener _lifecycle;
  DateTime? _pausedAt;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) {
            setState(() => _show = false);
          }
        });
    _lifecycle = AppLifecycleListener(onStateChange: _onStateChange);
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onStateChange(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pausedAt ??= widget.clock();
      return;
    }
    if (state != AppLifecycleState.resumed) return;
    final pausedAt = _pausedAt;
    _pausedAt = null;
    if (_show || pausedAt == null) return;
    if (widget.clock().difference(pausedAt) < kSplashResumeThreshold) return;
    // A user who turned off animations gets no splash theatre.
    if (MediaQuery.maybeDisableAnimationsOf(context) == true) return;
    setState(() => _show = true);
    _controller.forward(from: 0);
  }

  void _skip() {
    if (!_show) return;
    _controller.value = 1;
    setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_show)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _skip,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final elapsed = _controller.value * 1200;
                return Opacity(
                  opacity: _splashOpacity(elapsed),
                  child: ColoredBox(
                    color: kSplashBackground,
                    child: Center(
                      child: _AnimatedBrandMark(height: 180, elapsed: elapsed),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

/// Fully drawn for the first 1 000 ms, then fades out over 200 ms.
double _splashOpacity(double elapsed) {
  if (elapsed <= 1000) return 1;
  return (1 - (elapsed - 1000) / 200).clamp(0, 1);
}

/// The Saff + Mihrab mark mid-story. Same geometry as `BrandMark`
/// (brand_mark.dart) and the native `splash_icon_groups.xml`; the
/// animation parameters are the SPLASH dict in make_brand.py.
class _AnimatedBrandMark extends StatelessWidget {
  const _AnimatedBrandMark({required this.height, required this.elapsed});

  final double height;

  /// Milliseconds into the 1 000 ms story.
  final double elapsed;

  static const _box = Rect.fromLTWH(26, 22, 56, 58);
  static const _arch = 'M30,76 V52 C30,40 44,31 54,26 C64,31 78,40 78,52 V76';
  static const _figOffsets = [300, 340, 380, 420];

  static String _figure(double x) =>
      'M${x - 3.1},52 a3.1,3.1 0 1,0 6.2,0 a3.1,3.1 0 1,0 -6.2,0 Z '
      'M${x - 3.7},60.7 A3.7,3.7 0 0,1 ${x + 3.7},60.7 V68.3 '
      'A3.7,3.7 0 0,1 ${x - 3.7},68.3 Z';

  static final _archPath = parseSvgPath(_arch);
  static final _figures = [
    for (final x in const [37.0, 45.5, 54.0, 62.5, 71.0])
      parseSvgPath(_figure(x)),
  ];
  static const _pivots = [37.0, 45.5, 54.0, 62.5, 71.0];

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: CustomPaint(
        size: Size(height * _box.width / _box.height, height),
        painter: _AnimatedMarkPainter(elapsed: elapsed),
      ),
    );
  }
}

class _AnimatedMarkPainter extends CustomPainter {
  _AnimatedMarkPainter({required this.elapsed});

  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / _AnimatedBrandMark._box.height;
    canvas.save();
    canvas.scale(s);
    canvas.translate(
      -_AnimatedBrandMark._box.left,
      -_AnimatedBrandMark._box.top,
    );

    // The arch draws itself: trimPathEnd 0 -> 1 over 0-400 ms.
    final archT = Curves.fastOutSlowIn.transform(
      (elapsed / 400).clamp(0.0, 1.0),
    );
    if (archT > 0) {
      // PathMetrics is single-pass (one iterator, no memoizing): reading
      // it twice in one paint exhausts it and the second read throws
      // "Bad state: No element". Capture the metric once and reuse it.
      final metric = _AnimatedBrandMark._archPath.computeMetrics().first;
      final drawn = archT >= 1
          ? _AnimatedBrandMark._archPath
          : metric.extractPath(0, metric.length * archT);
      canvas.drawPath(
        drawn,
        Paint()
          ..color = kSplashInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // The row gathers: figures fade in and grow 0.2 -> 1, staggered.
    for (var i = 0; i < 4; i++) {
      final local = ((elapsed - _AnimatedBrandMark._figOffsets[i]) / 260).clamp(
        0.0,
        1.0,
      );
      if (local <= 0) continue;
      // easeOutBack stands in for Android's overshoot interpolator.
      final scale = 0.2 + 0.8 * Curves.easeOutBack.transform(local);
      _drawFigure(canvas, i, scale, local);
    }

    // You step in last: fade in while sliding 14.7 units left, 620-1000 ms.
    final youLocal = ((elapsed - 620) / 380).clamp(0.0, 1.0);
    if (youLocal > 0) {
      final eased = Curves.decelerate.transform(youLocal);
      canvas.save();
      canvas.translate(14.7 * (1 - eased), 0);
      _drawFigure(canvas, 4, 1, eased, amber: true);
      canvas.restore();
    }

    canvas.restore();
  }

  void _drawFigure(
    Canvas canvas,
    int index,
    double scale,
    double alpha, {
    bool amber = false,
  }) {
    final pivotX = _AnimatedBrandMark._pivots[index];
    canvas.save();
    canvas.translate(pivotX, 60.45);
    canvas.scale(scale);
    canvas.translate(-pivotX, -60.45);
    canvas.drawPath(
      _AnimatedBrandMark._figures[index],
      Paint()
        ..color = (amber ? kBrandAmber : kSplashInk).withValues(
          alpha: alpha.clamp(0.0, 1.0),
        ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AnimatedMarkPainter old) => old.elapsed != elapsed;
}
