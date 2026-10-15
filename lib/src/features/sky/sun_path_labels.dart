import 'dart:math' as math;
import 'dart:ui';

/// Where the labels on the sun's path go, in the path's 390 × 168 design box
/// (owner, 2026-10-16): clear of the prayer markers, of the arcs and of each
/// other, or merged into one when the sun is close to the selected marker.
abstract final class SunPathLabels {
  /// Closer than this (in screen pixels), the time under the sun and the
  /// selected prayer's name become one label: "Dhuhr · 12:42 PM".
  static const mergeDistance = 48.0;

  /// A marker's keep-out radius around its centre.
  static const markerRadius = 11.0;

  /// The gap between a label and the point it names.
  static const gap = 14.0;

  static bool shouldMerge(Offset sun, Offset? selected, double scale) =>
      selected != null && (sun - selected).distance * scale < mergeDistance;

  /// The top-left of a [size] label for [anchor], picked from the positions
  /// around it (sides, then corners, then a step further out): the first
  /// that touches nothing, else the one that touches least. [markers] are
  /// marker centres, [arc] points along both arcs, [taken] labels already
  /// placed.
  static Offset place({
    required Offset anchor,
    required Size size,
    required List<Offset> markers,
    required List<Offset> arc,
    List<Rect> taken = const [],
    Size bounds = const Size(390, 168),
    bool preferAbove = false,
  }) {
    // Below, above, right and left first; then the corners; then the same
    // again a step further out.
    List<Offset> ring(double g) {
      final below = Offset(anchor.dx - size.width / 2, anchor.dy + g);
      final above = Offset(
        anchor.dx - size.width / 2,
        anchor.dy - g - size.height,
      );
      final right = Offset(anchor.dx + g, anchor.dy - size.height / 2);
      final left = Offset(
        anchor.dx - g - size.width,
        anchor.dy - size.height / 2,
      );
      final belowRight = Offset(anchor.dx + g * 0.7, anchor.dy + g * 0.7);
      final belowLeft = Offset(
        anchor.dx - g * 0.7 - size.width,
        anchor.dy + g * 0.7,
      );
      final aboveRight = Offset(
        anchor.dx + g * 0.7,
        anchor.dy - g * 0.7 - size.height,
      );
      final aboveLeft = Offset(
        anchor.dx - g * 0.7 - size.width,
        anchor.dy - g * 0.7 - size.height,
      );
      return preferAbove
          ? [
              above,
              below,
              right,
              left,
              aboveRight,
              aboveLeft,
              belowRight,
              belowLeft,
            ]
          : [
              below,
              above,
              right,
              left,
              belowRight,
              belowLeft,
              aboveRight,
              aboveLeft,
            ];
    }

    final candidates = [...ring(gap), ...ring(gap * 2)];

    Offset? best;
    var bestScore = double.infinity;
    for (final c in candidates) {
      final score = cost(
        c & size,
        markers: markers,
        arc: arc,
        taken: taken,
        bounds: bounds,
      );
      if (score == 0) return c;
      if (score < bestScore) {
        bestScore = score;
        best = c;
      }
    }
    return best!;
  }

  /// How badly [rect] collides: markers weigh most, then other labels, then
  /// the arcs; leaving the box counts too.
  static double cost(
    Rect rect, {
    required List<Offset> markers,
    required List<Offset> arc,
    List<Rect> taken = const [],
    Size bounds = const Size(390, 168),
  }) {
    var score = 0.0;
    for (final m in markers) {
      if (_distanceToRect(m, rect) < markerRadius) score += 10;
    }
    for (final t in taken) {
      if (t.overlaps(rect)) score += 8;
    }
    final inner = rect.deflate(1);
    for (final p in arc) {
      if (inner.contains(p)) score += 1;
    }
    final outside =
        math.max(0.0, -rect.left) +
        math.max(0.0, rect.right - bounds.width) +
        math.max(0.0, -rect.top) +
        math.max(0.0, rect.bottom - bounds.height);
    return score + outside / 4;
  }

  static double _distanceToRect(Offset p, Rect r) {
    final dx = math.max(0.0, math.max(r.left - p.dx, p.dx - r.right));
    final dy = math.max(0.0, math.max(r.top - p.dy, p.dy - r.bottom));
    return math.sqrt(dx * dx + dy * dy);
  }
}
