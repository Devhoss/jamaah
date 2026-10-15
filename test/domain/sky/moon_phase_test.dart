import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/sky/moon_phase.dart';
import 'package:jamaah/src/domain/sky/sun_path_geometry.dart';

void main() {
  const path = SunPathGeometry.reference; // sunrise 342, sunset 1035

  test('age is the Hijri day less half a day', () {
    expect(MoonPhase.fromHijriDay(4).age, 3.5);
  });

  test('lit fraction: new, quarter, full, last quarter', () {
    expect(const MoonPhase(0).illuminated, closeTo(0, 1e-9));
    expect(const MoonPhase(29.53 / 4).illuminated, closeTo(0.5, 1e-9));
    expect(const MoonPhase(29.53 / 2).illuminated, closeTo(1, 1e-9));
    expect(const MoonPhase(22.15).illuminated, closeTo(0.5, 0.01));
  });

  test('crescent before the first quarter, gibbous after', () {
    expect(MoonPhase.fromHijriDay(4).isCrescent, isTrue);
    expect(MoonPhase.fromHijriDay(12).isCrescent, isFalse);
    // A thin crescent has a terminator almost as wide as the disc.
    expect(MoonPhase.fromHijriDay(2).terminatorRadius(9), greaterThan(8.5));
    expect(MoonPhase.fromHijriDay(8).terminatorRadius(9), lessThan(1));
  });

  test('a young crescent hangs low in the west after Maghrib', () {
    final moon = MoonPhase.fromHijriDay(2);
    final p = moon.placeAt(path, 1035 + 20);
    expect(p.visible, isTrue);
    expect(p.opacity, MoonPhase.opacityAfterSunset);
    // West is the right-hand end of the arc, and it is close to the horizon.
    expect(p.point.x, greaterThan(300));
    expect(p.point.y, greaterThan(118 - 50));
    // Its lit side faces the sun, which has just set below and to the right.
    expect(p.rotationDegrees, inInclusiveRange(0, 135));
  });

  test('the moon trails the sun by about 50.5 min a day of age', () {
    final moon = MoonPhase.fromHijriDay(4);
    expect(moon.moonMinute(1000), closeTo(1000 - 3.5 * 50.5, 1e-9));
  });

  test('it is faint while the sun is up and hidden when it has set', () {
    final moon = MoonPhase.fromHijriDay(4);
    expect(moon.placeAt(path, 700).opacity, MoonPhase.opacityWhileSunUp);
    // Hours after Maghrib the moon has gone down too.
    expect(moon.placeAt(path, 1035 + 300).visible, isFalse);
  });
}
