import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/sky/star_field.dart';

void main() {
  final stars = StarField.stars;

  test('46 stars in the top 300 px of the design frame', () {
    expect(stars, hasLength(46));
    for (final s in stars) {
      expect(s.x, inInclusiveRange(0, 390));
      expect(s.y, inInclusiveRange(0, 300));
      expect(s.size, inInclusiveRange(0.8, 2.4));
    }
  });

  test('fixed positions: the same field every time', () {
    expect(StarField.stars.first.x, stars.first.x);
    // The prototype's generator, seed 7: first x = ((7·9301+49297) % 233280)/233280·390.
    expect(
      stars.first.x,
      closeTo((7 * 9301 + 49297) % 233280 / 233280 * 390, 1e-9),
    );
  });

  test('brightness fades with height, never below a quarter', () {
    for (final s in stars) {
      expect(
        s.brightness,
        closeTo(s.y / 320 > 0.75 ? 0.25 : 1 - s.y / 320, 1e-9),
      );
    }
  });

  test('every twinkle fits the motion loop, so it never jumps', () {
    for (final s in stars) {
      expect(s.period, inInclusiveRange(2.6, 5.6));
      final cycles = StarField.loop / s.period;
      expect(cycles, closeTo(cycles.roundToDouble(), 1e-9));
      expect(s.opacityAt(0), closeTo(s.opacityAt(StarField.loop), 1e-9));
    }
  });

  test('twinkle stays between a quarter and full brightness', () {
    final s = stars.first;
    for (var t = 0.0; t < 10; t += 0.1) {
      expect(
        s.opacityAt(t),
        inInclusiveRange(0.25 * s.brightness - 1e-9, s.brightness + 1e-9),
      );
    }
  });

  test('with motion off a star is steady at its brightness', () {
    expect(stars.first.opacityAt(null), stars.first.brightness);
  });
}
