import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/qibla_words.dart';

void main() {
  QiblaDirection at(double d) => QiblaDirection.fromRelative(d);

  test('the eight sectors of spec §4.8', () {
    expect(at(0), QiblaDirection.straightAhead);
    expect(at(45), QiblaDirection.aheadRight);
    expect(at(90), QiblaDirection.right);
    expect(at(135), QiblaDirection.behindRight);
    expect(at(180), QiblaDirection.behind);
    expect(at(225), QiblaDirection.behindLeft);
    expect(at(270), QiblaDirection.left);
    expect(at(315), QiblaDirection.aheadLeft);
  });

  test('boundaries fall to the next sector', () {
    expect(at(14.9), QiblaDirection.straightAhead);
    expect(at(15), QiblaDirection.aheadRight);
    expect(at(75), QiblaDirection.right);
    expect(at(105), QiblaDirection.behindRight);
    expect(at(165), QiblaDirection.behind);
    expect(at(195), QiblaDirection.behindLeft);
    expect(at(255), QiblaDirection.left);
    expect(at(285), QiblaDirection.aheadLeft);
    expect(at(345), QiblaDirection.aheadLeft);
    expect(at(345.1), QiblaDirection.straightAhead);
  });

  test('negative (anticlockwise) angles from qiblaFromNose', () {
    expect(at(-10), QiblaDirection.straightAhead);
    expect(at(-90), QiblaDirection.left);
    expect(at(-180), QiblaDirection.behind);
    expect(at(-120), QiblaDirection.behindLeft);
    expect(at(720 + 90), QiblaDirection.right);
  });

  test('the design example: heading 120, Qibla 274 → behind, to the right', () {
    expect(at(274 - 120), QiblaDirection.behindRight);
  });
}
