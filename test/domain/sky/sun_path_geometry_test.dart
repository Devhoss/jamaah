import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/sky/sky_color.dart';
import 'package:jamaah/src/domain/sky/sun_path_geometry.dart';

void main() {
  const path = SunPathGeometry.reference; // 342 .. 1035

  group('positions', () {
    test('sunrise on the left, noon at the top, sunset on the right', () {
      final rise = path.positionAt(342).point;
      expect(rise.x, closeTo(45, 1e-9));
      expect(rise.y, closeTo(118, 1e-9));
      final mid = path.positionAt((342 + 1035) / 2);
      expect(mid.point.x, closeTo(195, 1e-9));
      expect(mid.point.y, closeTo(118 - 96, 1e-9));
      expect(mid.altitude, closeTo(1, 1e-9));
      final set = path.positionAt(1035).point;
      expect(set.x, closeTo(345, 1e-9));
    });

    test('at night the sun sits on the shallow arc below the horizon', () {
      // Halfway through the night (sunset + 373.5 min, past midnight).
      final p = path.positionAt((1035 + 747 / 2) - 1440);
      expect(p.point.x, closeTo(195, 1e-6));
      expect(p.point.y, closeTo(118 + 36, 1e-6));
      expect(p.altitude, closeTo(-1, 1e-6));
      expect(p.isUp, isFalse);
      expect(SunPathGeometry.sunOpacity(p.altitude), 0.28);
    });
  });

  group('dragging', () {
    test('position → time → position round trip on both arcs', () {
      for (final t in [400.0, 689.0, 1000.0, 1100.0, 1300.0, 60.0, 300.0]) {
        final p = path.positionAt(t).point;
        expect(path.timeAt(p.x, p.y), closeTo(t, 1e-6), reason: '$t');
      }
    });

    test('touches outside the arc clamp to its ends', () {
      expect(path.timeAt(-50, 50), closeTo(342, 1e-9));
      expect(path.timeAt(500, 50), closeTo(1035, 1e-9));
    });

    test('a little below the horizon still reads the day arc', () {
      expect(path.isDay(path.timeAt(195, 118 + 5)), isTrue);
      expect(path.isDay(path.timeAt(195, 118 + 10)), isFalse);
    });
  });

  group('trail', () {
    test('by day the trail runs from sunrise to now', () {
      final t = path.trailAt((342 + 1035) / 2);
      expect(t.day, closeTo(0.5, 1e-9));
      expect(t.night, 0);
    });

    test('after sunset the whole day arc plus the night so far', () {
      final t = path.trailAt(1035 + 747 / 4);
      expect(t.day, 1);
      expect(t.night, closeTo(0.25, 1e-9));
    });

    test('after midnight only the night arc', () {
      final t = path.trailAt(300);
      expect(t.day, 0);
      expect(t.night, closeTo((300 + 1440 - 1035) / 747, 1e-9));
    });
  });

  test('the sun is amber at the horizon and near white high up', () {
    final low = SunPathGeometry.sunColours(0);
    final high = SunPathGeometry.sunColours(1);
    expect(low.core, SkyRgb.hex('#FFB062'));
    expect(high.core, SkyRgb.hex('#FFF4DC'));
    expect(high.disc, SkyRgb.hex('#FFF8EA'));
    expect(SunPathGeometry.sunColours(-0.5).core, low.core);
  });

  group('glides', () {
    test('take the short way round the clock', () {
      expect(SunPathGeometry.shortestDelta(1400, 20), 60);
      expect(SunPathGeometry.shortestDelta(20, 1400), -60);
      expect(SunPathGeometry.shortestDelta(300, 900), 600);
    });

    test('last 380 ms + 0.9 ms a minute, at most 1.2 s', () {
      expect(SunPathGeometry.glideDuration(600, 700).inMilliseconds, 470);
      expect(SunPathGeometry.glideDuration(0, 700).inMilliseconds, 1010);
      expect(SunPathGeometry.glideDuration(0, 719).inMilliseconds, 1027);
      expect(SunPathGeometry.glideDuration(100, 1100).inMilliseconds, 776);
    });

    test('ease in and out', () {
      expect(SunPathGeometry.glideEase(0), 0);
      expect(SunPathGeometry.glideEase(0.5), 0.5);
      expect(SunPathGeometry.glideEase(1), 1);
      expect(SunPathGeometry.glideEase(0.1), lessThan(0.1));
    });
  });
}
