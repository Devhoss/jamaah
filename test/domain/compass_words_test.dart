import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/qibla_words.dart';

void main() {
  CompassWords w(double b) => CompassWords.of(b);

  test('within 5 degrees of a point is that point alone', () {
    expect(w(0).point, CompassPoint.north);
    expect(w(355).point, CompassPoint.north);
    expect(w(225).point, CompassPoint.southWest);
    expect(w(225).toward, isNull);
    expect(w(91).point, CompassPoint.east);
    expect(w(91).toward, isNull);
  });

  test('near a cardinal, it leans toward the next one', () {
    final s = w(190);
    expect(s.point, CompassPoint.south);
    expect(s.toward, CompassPoint.west);
    expect(s.away, isNull);
    expect(w(350).toward, CompassPoint.west);
    expect(w(12).toward, CompassPoint.east);
  });

  test('near an intercardinal, it leans to the nearer cardinal', () {
    // Kuwait City: 224.6°, rounds to 225 (no lean); 235 leans west.
    final sw = w(235);
    expect(sw.point, CompassPoint.southWest);
    expect(sw.toward, CompassPoint.west);
    expect(sw.away, CompassPoint.south);
    final cairo = w(136);
    expect(cairo.point, CompassPoint.southEast);
    expect(cairo.toward, isNull);
    final ne = w(36);
    expect(ne.point, CompassPoint.northEast);
    expect(ne.toward, CompassPoint.north);
    expect(ne.away, CompassPoint.east);
  });

  test('any range of input is folded into 0-360', () {
    expect(w(-10).point, CompassPoint.north);
    expect(w(-10).toward, CompassPoint.west);
    expect(w(720 + 180).point, CompassPoint.south);
  });
}
