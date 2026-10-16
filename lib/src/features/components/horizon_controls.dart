import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/horizon_tokens.dart';
import 'line_icon.dart';

/// Controls of the Horizon system (spec §2.5), drawn on the solid surface of
/// secondary pages and sheets. Every one is at least 48 dp to touch.

/// A 52 × 32 solid switch. Off: a `divider` track and a muted knob. On:
/// `accent`. Disabled (no Iqama yet): a dashed outline track, and the reason
/// goes in [semanticLabel] ("available once an Iqama time is set").
class AppSwitch extends StatelessWidget {
  const AppSwitch({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });

  final bool value;

  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;
  final String semanticLabel;

  static const width = 52.0;
  static const height = 32.0;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final enabled = onChanged != null;
    final on = enabled && value;
    final still = MediaQuery.disableAnimationsOf(context);
    final track = Container(
      width: width,
      height: height,
      padding: const EdgeInsets.all(4),
      decoration: enabled
          ? BoxDecoration(
              color: on ? s.accent : s.divider,
              borderRadius: BorderRadius.circular(16),
            )
          : null,
      child: AnimatedAlign(
        duration: still ? Duration.zero : const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        alignment: on
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: !enabled ? s.divider : (on ? s.onAccent : s.onSurfaceMuted),
          ),
        ),
      ),
    );
    return Semantics(
      toggled: on,
      enabled: enabled,
      label: semanticLabel,
      onTap: enabled ? () => onChanged!(!value) : null,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged!(!value) : null,
        child: SizedBox(
          width: math.max(width, 48),
          height: 48,
          child: Center(
            child: enabled
                ? track
                : CustomPaint(
                    painter: DashedOutline(color: s.onSurfaceMuted, radius: 16),
                    child: track,
                  ),
          ),
        ),
      ),
    );
  }
}

/// One choice of a [Segmented]: a label and an optional line under it.
class SegmentOption<T> {
  const SegmentOption(this.value, this.label, {this.description});

  final T value;
  final String label;
  final String? description;
}

/// A `well` track with the selected segment raised on `surface` (spec §2.5).
class Segmented<T> extends StatelessWidget {
  const Segmented({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: s.well,
        borderRadius: BorderRadius.circular(HorizonShape.segmentedRadius),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final o in options)
              Expanded(
                child: Semantics(
                  inMutuallyExclusiveGroup: true,
                  checked: o.value == selected,
                  button: true,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: onChanged == null ? null : () => onChanged!(o.value),
                    child: AnimatedContainer(
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      constraints: const BoxConstraints(minHeight: 52),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: o.value == selected
                            ? s.surface
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(
                          HorizonShape.segmentedInnerRadius,
                        ),
                        boxShadow: o.value == selected
                            ? const [
                                BoxShadow(
                                  color: Color(0x2E000000),
                                  blurRadius: 3,
                                  offset: Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            o.label,
                            textAlign: TextAlign.center,
                            style: type.row.copyWith(
                              fontSize: 15,
                              color: s.onSurface,
                            ),
                          ),
                          if (o.description != null)
                            Text(
                              o.description!,
                              textAlign: TextAlign.center,
                              style: type.meta.copyWith(
                                fontSize: 12,
                                color: s.onSurfaceMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// "Not configured": a dashed 1.5 px outline and words, never a colour.
class NotConfiguredPill extends StatelessWidget {
  const NotConfiguredPill(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    return CustomPaint(
      painter: DashedOutline(color: s.onSurfaceMuted, radius: 15),
      child: Container(
        constraints: const BoxConstraints(minHeight: 30),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        alignment: Alignment.center,
        child: Text(text, style: type.meta.copyWith(color: s.onSurface)),
      ),
    );
  }
}

/// A fully round button, 48 tall: filled in [ink] with [onInk] text, or
/// outlined in [line]. Used on the sky (sky ink) and on surfaces (accent).
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onPressed,
    required this.ink,
    required this.onInk,
    required this.line,
    this.filled = false,
    this.icon,
    this.danger,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color ink;
  final Color onInk;
  final Color line;
  final bool filled;
  final LineIconData? icon;

  /// Text colour for a quiet destructive action (Remove, Clear).
  final Color? danger;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final fg = danger ?? (filled ? onInk : ink);
    return Semantics(
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: filled ? ink : Colors.transparent,
        shape: StadiumBorder(
          side: filled || danger != null
              ? BorderSide.none
              : BorderSide(color: line, width: 1.5),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onPressed,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: danger != null ? 4 : 18,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    LineIcon(icon!, size: 18, strokeWidth: 2, color: fg),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      style: type.row.copyWith(
                        fontSize: 15,
                        fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                        color: fg,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Horizon snackbar: [background] (ink, or accent on surfaces) with
/// [foreground] text, 2.2 s, read out politely by TalkBack.
void showHorizonSnackBar(
  BuildContext context,
  String text, {
  Color? background,
  Color? foreground,
}) {
  final s = HorizonTheme.of(context).surfaces;
  final type = HorizonTheme.typeOf(context);
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(
          text,
          style: type.body.copyWith(color: foreground ?? s.onAccent),
        ),
        backgroundColor: background ?? s.accent,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 2200),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
}

/// A dashed rounded outline, 1.5 px: "not set yet" is a shape plus words.
class DashedOutline extends CustomPainter {
  DashedOutline({required this.color, required this.radius, this.width = 1.5});

  final Color color;
  final double radius;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(width / 2),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(DashedOutline old) =>
      old.color != color || old.radius != radius || old.width != width;
}

/// A row of people praying together, with the last place still open
/// (dashed) for the user's mosque (spec §4.3, §4.6). [filled] is how many
/// places are taken; the rest are dashed.
class CongregationFigures extends StatelessWidget {
  const CongregationFigures({
    required this.color,
    this.count = 5,
    this.filled = 4,
    super.key,
  });

  final Color color;
  final int count;
  final int filled;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(count * 34.0 - 6, 40),
      painter: _FiguresPainter(color: color, count: count, filled: filled),
    ),
  );
}

class _FiguresPainter extends CustomPainter {
  _FiguresPainter({
    required this.color,
    required this.count,
    required this.filled,
  });

  final Color color;
  final int count;
  final int filled;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < count; i++) {
      final cx = 14.0 + i * 34;
      final head = Rect.fromCircle(center: Offset(cx, 9), radius: 7);
      final body = Path()
        ..moveTo(cx - 13, 40)
        ..lineTo(cx - 13, 30)
        ..arcToPoint(Offset(cx + 13, 30), radius: const Radius.circular(13))
        ..lineTo(cx + 13, 40);
      if (i < filled) {
        final paint = Paint()..color = color;
        canvas.drawOval(head, paint);
        canvas.drawPath(body..close(), paint);
      } else {
        final paint = Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        for (final p in [Path()..addOval(head), body]) {
          for (final metric in p.computeMetrics()) {
            var d = 0.0;
            while (d < metric.length) {
              canvas.drawPath(metric.extractPath(d, d + 3), paint);
              d += 6;
            }
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(_FiguresPainter old) =>
      old.color != color || old.count != count || old.filled != filled;
}
