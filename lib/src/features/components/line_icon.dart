import 'package:flutter/material.dart';

/// One stroke icon set for the whole app (spec §2.5): 24-unit paths drawn
/// with round caps at 1.6–1.8 width. The shapes are Lucide's (ISC licence,
/// see docs/icon-licence.md), as used by the Horizon design.
@immutable
class LineIconData {
  const LineIconData(this.shapes);

  final List<IconShape> shapes;
}

sealed class IconShape {
  const IconShape();
}

/// An SVG path in the 24 × 24 box.
class PathShape extends IconShape {
  const PathShape(this.d);

  final String d;
}

class CircleShape extends IconShape {
  const CircleShape(this.cx, this.cy, this.r);

  final double cx;
  final double cy;
  final double r;
}

class RectShape extends IconShape {
  const RectShape(
    this.x,
    this.y,
    this.width,
    this.height, {
    this.radius = 0,
    this.filled = false,
  });

  final double x;
  final double y;
  final double width;
  final double height;
  final double radius;
  final bool filled;
}

abstract final class LineIcons {
  static const chevronRight = LineIconData([PathShape('m9 18 6-6-6-6')]);
  static const chevronDown = LineIconData([PathShape('m6 9 6 6 6-6')]);
  static const back = LineIconData([PathShape('M19 12H5M12 19l-7-7 7-7')]);
  static const check = LineIconData([PathShape('M20 6 9 17l-5-5')]);
  static const home = LineIconData([
    PathShape(
      'M3 10.5 12 3l9 7.5V20a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z',
    ),
  ]);
  static const plane = LineIconData([
    PathShape(
      'M17.8 19.2 16 11l3.5-3.5C21 6 21.5 4 21 3c-1-.5-3 0-4.5 1.5L13 8 '
      '4.8 6.2c-.5-.1-.9.1-1.1.5l-.3.5c-.2.5-.1 1 .3 1.3L9 12l-2 3H4l-1 1 3 '
      '2 2 3 1-1v-3l3-2 3.5 5.3c.3.4.8.5 1.3.3l.5-.2c.4-.3.6-.7.5-1.2z',
    ),
  ]);
  static const planeTakeoff = LineIconData([
    PathShape('M2 22h20'),
    PathShape(
      'M6.36 17.4 4 17l-2-4 1.1-.55a2 2 0 0 1 1.8 0l.17.1a2 2 0 0 0 1.8 0L8 '
      '12 5 6l.9-.45a2 2 0 0 1 2.09.2l4.02 3a2 2 0 0 0 2.1.2l4.19-2.06a2.41 '
      '2.41 0 0 1 1.73-.17L21 7a1.4 1.4 0 0 1 .87 1.99l-.38.76c-.23.46-.6.84'
      '-1.07 1.08L7.58 17.2a2 2 0 0 1-1.22.18Z',
    ),
  ]);
  static const bell = LineIconData([
    PathShape('M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9'),
    PathShape('M10.3 21a1.94 1.94 0 0 0 3.4 0'),
  ]);
  static const bellOff = LineIconData([
    PathShape('M6 8a6 6 0 0 1 9.3-5M18 8c0 7 3 9 3 9H9M3 17s3-2 3-9'),
    PathShape('M10.3 21a1.94 1.94 0 0 0 3.4 0M2 2l20 20'),
  ]);

  /// Full Adhan: a speaker with two waves.
  static const soundFull = LineIconData([
    PathShape('M11 5 6 9H2v6h4l5 4z'),
    PathShape('M15.5 8.5a5 5 0 0 1 0 7M19 5a10 10 0 0 1 0 14'),
  ]);

  /// Short Adhan: one wave.
  static const soundShort = LineIconData([
    PathShape('M11 5 6 9H2v6h4l5 4z'),
    PathShape('M15.5 8.5a5 5 0 0 1 0 7'),
  ]);

  /// Silent: a notification card with no sound.
  static const silent = LineIconData([
    RectShape(3, 5, 18, 14, radius: 2),
    PathShape('M7 10h10M7 14h6'),
  ]);
  static const pin = LineIconData([
    PathShape(
      'M20 10c0 5-5.5 10.2-7.4 11.8a1 1 0 0 1-1.2 0C9.5 20.2 4 15 4 10a8 8 0 0 1 16 0',
    ),
    CircleShape(12, 10, 3),
  ]);
  static const pause = LineIconData([
    RectShape(6, 4, 4, 16, radius: 1),
    RectShape(14, 4, 4, 16, radius: 1),
  ]);
  static const info = LineIconData([
    CircleShape(12, 12, 9),
    PathShape('M12 16v-4M12 8h.01'),
  ]);
  static const clock = LineIconData([
    CircleShape(12, 12, 9),
    PathShape('M12 7v5l3 2'),
  ]);
  static const minus = LineIconData([PathShape('M5 12h14')]);
  static const plus = LineIconData([PathShape('M5 12h14M12 5v14')]);
  static const globe = LineIconData([
    CircleShape(12, 12, 9),
    PathShape('M3 12h18M12 3a14 14 0 0 1 0 18M12 3a14 14 0 0 0 0 18'),
  ]);
}

/// Draws a [LineIconData] at [size] in [color].
class LineIcon extends StatelessWidget {
  const LineIcon(
    this.icon, {
    this.size = 20,
    this.color,
    this.strokeWidth = 1.8,
    this.semanticLabel,
    super.key,
  });

  final LineIconData icon;
  final double size;
  final Color? color;
  final double strokeWidth;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? const Color(0xFF000000);
    final paint = CustomPaint(
      size: Size.square(size),
      painter: _LineIconPainter(icon, c, strokeWidth),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: semanticLabel, image: true, child: paint);
  }
}

class _LineIconPainter extends CustomPainter {
  _LineIconPainter(this.icon, this.color, this.strokeWidth);

  final LineIconData icon;
  final Color color;
  final double strokeWidth;

  static final _cache = <String, Path>{};

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    for (final shape in icon.shapes) {
      switch (shape) {
        case PathShape(:final d):
          canvas.drawPath(_cache[d] ??= parseSvgPath(d), stroke);
        case CircleShape(:final cx, :final cy, :final r):
          canvas.drawCircle(Offset(cx, cy), r, stroke);
        case RectShape(
          :final x,
          :final y,
          :final width,
          :final height,
          :final radius,
          :final filled,
        ):
          final rect = RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, width, height),
            Radius.circular(radius),
          );
          canvas.drawRRect(rect, filled ? (Paint()..color = color) : stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_LineIconPainter old) =>
      old.icon != icon || old.color != color || old.strokeWidth != strokeWidth;
}

/// A small SVG path-data parser: M L H V C S Q T A Z, absolute and relative,
/// which is all the icon set uses.
Path parseSvgPath(String d) {
  final tokens = RegExp(
    r'[MmLlHhVvCcSsQqTtAaZz]|-?(?:\d+\.?\d*|\.\d+)(?:[eE][-+]?\d+)?',
  ).allMatches(d).map((m) => m.group(0)!).toList();
  final path = Path();
  var i = 0;
  var cmd = '';
  var cur = Offset.zero, start = Offset.zero;
  Offset? lastControl;
  var lastCmd = '';

  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  double num() => double.parse(tokens[i++]);
  // Arc flags may be written without separators ("0 0 1"), which the
  // tokenizer already splits.
  bool flag() => num() != 0;

  while (i < tokens.length) {
    if (isCmd(tokens[i])) {
      cmd = tokens[i++];
    } else if (cmd == 'M') {
      cmd = 'L';
    } else if (cmd == 'm') {
      cmd = 'l';
    }
    final rel = cmd == cmd.toLowerCase();
    Offset pt(double x, double y) => rel ? cur + Offset(x, y) : Offset(x, y);
    switch (cmd.toUpperCase()) {
      case 'M':
        cur = pt(num(), num());
        start = cur;
        path.moveTo(cur.dx, cur.dy);
        lastControl = null;
      case 'L':
        cur = pt(num(), num());
        path.lineTo(cur.dx, cur.dy);
        lastControl = null;
      case 'H':
        final x = num();
        cur = Offset(rel ? cur.dx + x : x, cur.dy);
        path.lineTo(cur.dx, cur.dy);
        lastControl = null;
      case 'V':
        final y = num();
        cur = Offset(cur.dx, rel ? cur.dy + y : y);
        path.lineTo(cur.dx, cur.dy);
        lastControl = null;
      case 'C':
        final c1 = pt(num(), num());
        final c2 = pt(num(), num());
        final end = pt(num(), num());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastControl = c2;
        cur = end;
      case 'S':
        final c1 = (lastControl != null && 'CcSs'.contains(lastCmd))
            ? cur * 2 - lastControl
            : cur;
        final c2 = pt(num(), num());
        final end = pt(num(), num());
        path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
        lastControl = c2;
        cur = end;
      case 'Q':
        final c = pt(num(), num());
        final end = pt(num(), num());
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastControl = c;
        cur = end;
      case 'T':
        final c = (lastControl != null && 'QqTt'.contains(lastCmd))
            ? cur * 2 - lastControl
            : cur;
        final end = pt(num(), num());
        path.quadraticBezierTo(c.dx, c.dy, end.dx, end.dy);
        lastControl = c;
        cur = end;
      case 'A':
        final rx = num(), ry = num(), rotation = num();
        final large = flag(), sweep = flag();
        final end = pt(num(), num());
        path.arcToPoint(
          end,
          radius: Radius.elliptical(rx, ry),
          rotation: rotation,
          largeArc: large,
          clockwise: sweep,
        );
        cur = end;
        lastControl = null;
      case 'Z':
        path.close();
        cur = start;
        lastControl = null;
      default:
        i++;
    }
    lastCmd = cmd;
  }
  return path;
}
