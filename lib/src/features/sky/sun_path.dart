import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/prayer.dart';
import '../../domain/sky/moon_phase.dart';
import '../../domain/sky/sun_path_geometry.dart';
import '../sky/sky_motion.dart';

/// One prayer's dot on the arc.
@immutable
class SunPathMarker {
  const SunPathMarker({
    required this.prayer,
    required this.minute,
    this.selected = false,
    this.next = false,
  });

  final Prayer prayer;
  final int minute;
  final bool selected;

  /// A quiet halo ring on the next prayer.
  final bool next;

  @override
  bool operator ==(Object other) =>
      other is SunPathMarker &&
      other.prayer == prayer &&
      other.minute == minute &&
      other.selected == selected &&
      other.next == next;

  @override
  int get hashCode => Object.hash(prayer, minute, selected, next);
}

/// The sky ink the path is drawn in (spec §2.3 A).
@immutable
class SunPathInk {
  const SunPathInk({required this.ink, required this.labelInk});

  final Color ink;

  /// The label under the sun, which takes its ink at its own point.
  final Color labelInk;

  Color get line => ink.withValues(alpha: 0.22);
  Color get trail => ink.withValues(alpha: 0.85);
  Color get mute => labelInk.withValues(alpha: 0.76);
}

/// The sun on its path (spec §3.4): the day arc above the horizon, the night
/// arc dotted below, the travelled trail, the sun, the moon and the prayer
/// markers. Dragging anywhere on it looks through the day.
///
/// Drawn in the design's 390 × 168 box and scaled to the width. It is a
/// picture of the sky, so it is never mirrored: sunrise stays on the left in
/// Arabic (spec §5).
class SunPath extends StatelessWidget {
  const SunPath({
    required this.geometry,
    required this.minute,
    required this.markers,
    required this.ink,
    this.moon,
    this.sunLabel,
    this.selectedLabel,
    this.labelStyle,
    this.selectedLabelStyle,
    this.onScrub,
    this.onScrubEnd,
    this.semanticLabel,
    this.semanticValue,
    this.semanticStep,
    super.key,
  });

  final SunPathGeometry geometry;

  /// The minute the sun is drawn at.
  final double minute;
  final List<SunPathMarker> markers;
  final SunPathInk ink;
  final MoonPhase? moon;

  /// "Now 1:59", or the viewed time.
  final String? sunLabel;

  /// The selected prayer's name, under its marker.
  final String? selectedLabel;
  final TextStyle? labelStyle;
  final TextStyle? selectedLabelStyle;

  /// Null makes the path a picture only (onboarding, full-screen Adhan).
  final ValueChanged<double>? onScrub;
  final VoidCallback? onScrubEnd;

  /// Slider semantics: "Look through the day", "4:12 PM, Asr".
  final String? semanticLabel;
  final String? semanticValue;

  /// The value text one step later and earlier, for TalkBack.
  final ({String up, String down})? semanticStep;

  static const keyStep = 5.0;
  static const keyBigStep = 30.0;
  static const talkBackStep = 15.0;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      // The sky is not text: it does not mirror.
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final scale = width / SunPathGeometry.width;
          final height = SunPathGeometry.height * scale;
          final sun = geometry.positionAt(minute).point;
          final selected = markers.where((m) => m.selected).firstOrNull;
          final selectedPoint = selected == null
              ? null
              : geometry.positionAt(selected.minute.toDouble()).point;

          Widget path = SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SunPathPainter(
                      geometry: geometry,
                      minute: minute,
                      markers: markers,
                      ink: ink,
                      moon: moon,
                      motion: SkyMotion.maybeOf(context),
                      scale: scale,
                    ),
                  ),
                ),
                if (sunLabel != null)
                  Positioned(
                    left: (sun.x - 50) * scale,
                    top: (sun.y < 70 ? sun.y + 22 : sun.y - 44) * scale,
                    width: 100 * scale,
                    child: ExcludeSemantics(
                      child: Text(
                        sunLabel!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.visible,
                        style: (labelStyle ?? const TextStyle(fontSize: 11))
                            .copyWith(color: ink.mute),
                      ),
                    ),
                  ),
                if (selectedLabel != null && selectedPoint != null)
                  Positioned(
                    left: (selectedPoint.x - 60) * scale,
                    top: (selectedPoint.y + 16) * scale,
                    width: 120 * scale,
                    child: ExcludeSemantics(
                      child: Text(
                        selectedLabel!,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        style: (selectedLabelStyle ?? const TextStyle())
                            .copyWith(color: ink.ink),
                      ),
                    ),
                  ),
              ],
            ),
          );

          final scrub = onScrub;
          if (scrub == null) return ExcludeSemantics(child: path);

          double toMinute(Offset local) =>
              geometry.timeAt(local.dx / scale, local.dy / scale);

          path = GestureDetector(
            behavior: HitTestBehavior.opaque,
            // The sun goes where the finger landed, not where the drag was
            // recognised.
            dragStartBehavior: DragStartBehavior.down,
            onTapDown: (d) => scrub(toMinute(d.localPosition)),
            onTapUp: (_) => onScrubEnd?.call(),
            onHorizontalDragStart: (d) => scrub(toMinute(d.localPosition)),
            onHorizontalDragUpdate: (d) => scrub(toMinute(d.localPosition)),
            onHorizontalDragEnd: (_) => onScrubEnd?.call(),
            onHorizontalDragCancel: () => onScrubEnd?.call(),
            child: path,
          );

          void step(double minutes) {
            scrub(SunPathGeometry.wrap(minute + minutes));
            onScrubEnd?.call();
          }

          return Focus(
            onKeyEvent: (node, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final big = HardwareKeyboard.instance.isShiftPressed;
              final amount = big ? keyBigStep : keyStep;
              final key = event.logicalKey;
              if (key == LogicalKeyboardKey.arrowRight ||
                  key == LogicalKeyboardKey.arrowUp) {
                step(amount);
                return KeyEventResult.handled;
              }
              if (key == LogicalKeyboardKey.arrowLeft ||
                  key == LogicalKeyboardKey.arrowDown) {
                step(-amount);
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: Semantics(
              slider: true,
              label: semanticLabel,
              value: semanticValue,
              increasedValue: semanticStep?.up,
              decreasedValue: semanticStep?.down,
              onIncrease: () => step(talkBackStep),
              onDecrease: () => step(-talkBackStep),
              child: ExcludeSemantics(child: path),
            ),
          );
        },
      ),
    );
  }
}

class _SunPathPainter extends CustomPainter {
  _SunPathPainter({
    required this.geometry,
    required this.minute,
    required this.markers,
    required this.ink,
    required this.moon,
    required this.motion,
    required this.scale,
  }) : super(repaint: motion?.animation);

  final SunPathGeometry geometry;
  final double minute;
  final List<SunPathMarker> markers;
  final SunPathInk ink;
  final MoonPhase? moon;
  final SkyMotion? motion;
  final double scale;

  /// Points along an arc from [from] to [to] of its half ellipse (0..1).
  List<Offset> _arc({required bool day, double from = 0, double to = 1}) {
    const steps = 72;
    final ry = day ? SunPathGeometry.dayRadiusY : SunPathGeometry.nightRadiusY;
    final n = math.max(1, ((to - from) * steps).ceil());
    return [
      for (var i = 0; i <= n; i++)
        () {
          final a = math.pi * (from + (to - from) * i / n);
          return day
              ? Offset(
                  SunPathGeometry.centreX -
                      SunPathGeometry.radiusX * math.cos(a),
                  SunPathGeometry.horizonY - ry * math.sin(a),
                )
              : Offset(
                  SunPathGeometry.centreX +
                      SunPathGeometry.radiusX * math.cos(a),
                  SunPathGeometry.horizonY + ry * math.sin(a),
                );
        }(),
    ];
  }

  void _stroke(Canvas canvas, List<Offset> pts, Paint paint) {
    if (pts.length < 2) return;
    canvas.drawPoints(ui.PointMode.polygon, pts, paint);
  }

  /// Round dots every 7 units along [pts] (the SVG "1 6" dash).
  void _dotted(Canvas canvas, List<Offset> pts, Color color, double width) {
    final paint = Paint()..color = color;
    var carry = 0.0;
    for (var i = 1; i < pts.length; i++) {
      final a = pts[i - 1], b = pts[i];
      final len = (b - a).distance;
      var d = carry;
      while (d <= len) {
        canvas.drawCircle(Offset.lerp(a, b, d / len)!, width / 2, paint);
        d += 7;
      }
      carry = d - len;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(scale);
    final seconds = motion?.seconds;

    final line = Paint()
      ..color = ink.line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawLine(
      const Offset(12, SunPathGeometry.horizonY),
      const Offset(378, SunPathGeometry.horizonY),
      line,
    );
    _stroke(canvas, _arc(day: true), line..strokeWidth = 1.5);
    _dotted(canvas, _arc(day: false), ink.line, 1.5);

    // Trail.
    final trail = geometry.trailAt(minute);
    if (trail.day > 0) {
      _stroke(
        canvas,
        _arc(day: true, to: trail.day),
        Paint()
          ..color = ink.trail
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round,
      );
    }
    if (trail.night > 0) {
      _dotted(canvas, _arc(day: false, to: trail.night), ink.trail, 2);
    }

    // Moon.
    final m = moon;
    if (m != null) {
      final place = m.placeAt(geometry, minute);
      if (place.visible) _paintMoon(canvas, m, place);
    }

    // Sun.
    final sun = geometry.positionAt(minute);
    final colours = SunPathGeometry.sunColours(sun.altitude);
    final core = Color(colours.core.argb);
    final opacity = SunPathGeometry.sunOpacity(sun.altitude);
    final c = Offset(sun.point.x, sun.point.y);
    final breathe = seconds == null
        ? 1.0
        : 1 + 0.09 * (1 - math.cos(2 * math.pi * seconds / 4.8));
    canvas.drawCircle(
      c,
      30 * breathe,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          30 * breathe,
          [
            core.withValues(alpha: 0.95 * opacity),
            core.withValues(alpha: 0.4 * opacity),
            core.withValues(alpha: 0),
          ],
          const [0, 0.45, 1],
        ),
    );
    canvas.drawCircle(
      c,
      8,
      Paint()..color = Color(colours.disc.argb).withValues(alpha: opacity),
    );
    canvas.drawCircle(
      c,
      8,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Markers.
    for (final marker in markers) {
      _paintMarker(canvas, marker, seconds);
    }
    canvas.restore();
  }

  void _paintMoon(Canvas canvas, MoonPhase m, MoonPlacement place) {
    const r = 9.0;
    const lit = Color(0xFFF4F1E6);
    canvas.save();
    canvas.translate(place.point.x, place.point.y);
    canvas.rotate(place.rotationDegrees * math.pi / 180);
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..color = lit.withValues(alpha: MoonPhase.discFill * place.opacity),
    );
    final rx = m.terminatorRadius(r);
    final path = Path()
      ..moveTo(0, -r)
      ..arcToPoint(
        const Offset(0, r),
        radius: const Radius.circular(r),
        clockwise: true,
      )
      ..arcToPoint(
        const Offset(0, -r),
        radius: Radius.elliptical(math.max(rx, 0.001), r),
        clockwise: !m.isCrescent,
      )
      ..close();
    canvas.drawPath(
      path,
      Paint()..color = lit.withValues(alpha: place.opacity),
    );
    canvas.restore();
  }

  void _paintMarker(Canvas canvas, SunPathMarker marker, double? seconds) {
    final p = geometry.positionAt(marker.minute.toDouble()).point;
    final c = Offset(p.x, p.y);
    final glow = Paint()
      ..color = ink.ink.withValues(alpha: marker.selected ? 0.7 : 0.45)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, marker.selected ? 7 : 4);

    if (marker.selected && seconds != null) {
      // The pulse: a ring that grows from the dot and fades (2.4 s).
      final f = (seconds % 2.4) / 2.4;
      canvas.drawCircle(
        c,
        8 * (1 + 1.8 * f),
        Paint()
          ..color = ink.ink.withValues(alpha: 0.75 * (1 - f))
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (marker.prayer == Prayer.sunrise) {
      final r = marker.selected ? 8.0 : 5.0;
      canvas.drawCircle(c, r, glow);
      canvas.drawCircle(
        c,
        r - 1,
        Paint()
          ..color = ink.ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }

    if (marker.selected) {
      canvas.drawCircle(c, 8, glow);
      canvas.drawCircle(c, 8, Paint()..color = ink.ink.withValues(alpha: 0.35));
      canvas.drawCircle(c, 4, Paint()..color = ink.ink);
      return;
    }

    canvas.drawCircle(c, 5, glow);
    if (marker.next) {
      canvas.drawCircle(c, 9, Paint()..color = ink.ink.withValues(alpha: 0.22));
    }
    canvas.drawCircle(c, 5, Paint()..color = ink.ink);
  }

  @override
  bool shouldRepaint(_SunPathPainter old) =>
      old.minute != minute ||
      old.ink.ink != ink.ink ||
      old.ink.labelInk != ink.labelInk ||
      old.scale != scale ||
      old.geometry.sunrise != geometry.sunrise ||
      old.geometry.sunset != geometry.sunset ||
      old.moon?.age != moon?.age ||
      old.motion?.still != motion?.still ||
      !_listEquals(old.markers, markers);

  static bool _listEquals(List<SunPathMarker> a, List<SunPathMarker> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
