import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/sky/sun_path_geometry.dart';
import 'package:jamaah/src/features/sky/sun_path_labels.dart';

/// The labels on the sun's path stay clear of the markers and each other, or
/// merge when the sun is near the selected prayer (owner, 2026-10-16).
void main() {
  const geometry = SunPathGeometry.reference; // 342 .. 1035
  const prayers = [261, 342, 689, 889, 1035, 1111];
  Offset at(num minute) {
    final p = geometry.positionAt(minute.toDouble()).point;
    return Offset(p.x, p.y);
  }

  final markers = [for (final t in prayers) at(t)];
  final arc = [for (var t = 0; t < 1440; t += 12) at(t)];
  // About the size of "12:42 PM" at 11 px and "Dhuhr" in 14 px italic.
  const sunSize = Size(56, 14);
  const nameSize = Size(44, 18);

  bool touches(Rect r, Offset m) {
    final dx = (m.dx.clamp(r.left, r.right) - m.dx).abs();
    final dy = (m.dy.clamp(r.top, r.bottom) - m.dy).abs();
    return dx * dx + dy * dy <
        SunPathLabels.markerRadius * SunPathLabels.markerRadius;
  }

  test('merges only when the sun is within 48 px of the selected marker', () {
    expect(SunPathLabels.shouldMerge(at(689), at(689), 1), isTrue);
    expect(SunPathLabels.shouldMerge(at(689), at(700), 1), isTrue);
    expect(SunPathLabels.shouldMerge(at(689), at(889), 1), isFalse);
    expect(SunPathLabels.shouldMerge(at(689), null, 1), isFalse);
    expect(SunPathLabels.shouldMerge(at(689), at(800), 1), isFalse);
    expect(SunPathLabels.shouldMerge(at(689), at(735), 1), isTrue);
    // A wider phone draws the same box bigger, so the pixels are scaled.
    expect(SunPathLabels.shouldMerge(at(689), at(735), 2), isFalse);
  });

  for (final selected in [689, 889, 1111]) {
    test(
      'all day, neither label lands on a marker (selected at $selected)',
      () {
        for (var t = 0; t < 1440; t += 5) {
          final sun = at(t);
          final sel = at(selected);
          if (SunPathLabels.shouldMerge(sun, sel, 1)) continue;
          final sunAt = SunPathLabels.place(
            anchor: sun,
            size: sunSize,
            markers: markers,
            arc: arc,
            preferAbove: sun.dy >= 70,
          );
          final sunRect = sunAt & sunSize;
          for (final m in markers) {
            expect(
              touches(sunRect, m),
              isFalse,
              reason: 'sun label at minute $t',
            );
          }
          final nameAt = SunPathLabels.place(
            anchor: sel,
            size: nameSize,
            markers: [...markers.where((m) => m != sel), sun],
            arc: arc,
            taken: [sunRect],
          );
          final nameRect = nameAt & nameSize;
          expect(nameRect.overlaps(sunRect), isFalse, reason: 'minute $t');
          for (final m in markers.where((m) => m != sel)) {
            expect(touches(nameRect, m), isFalse, reason: 'name at minute $t');
          }
        }
      },
    );
  }

  test('a free slot is used as it is, below first', () {
    final p = SunPathLabels.place(
      anchor: at(689),
      size: sunSize,
      markers: const [],
      arc: const [],
    );
    expect(p.dy, greaterThan(at(689).dy));
  });
}
