import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/sky/sky_color.dart';
import 'package:jamaah/src/domain/sky/sky_model.dart';

import 'sample_days.dart';

void main() {
  group('SkyRgb', () {
    test('parses, mixes and reports contrast like WCAG', () {
      final white = SkyRgb.hex('#FFFFFF'), black = SkyRgb.hex('#000000');
      expect(white.contrastWith(black), closeTo(21, 0.01));
      expect(white.luminance, closeTo(1, 1e-9));
      expect(black.mix(white, 0.5).hex, '#808080');
      expect(SkyRgb.hex('#4C9BE0').argb, 0xFF4C9BE0);
    });
  });

  group('reference day', () {
    test('every keyframe is hit exactly at its minute', () {
      for (final k in SkyModel.reference.keyframes.take(11)) {
        final frame = SkyModel.reference.frameAt(k.minute.toDouble());
        expect(frame.stops, k.look.stops, reason: k.moment.name);
        expect(frame.stars, k.look.stars);
        expect(frame.glow.alpha, closeTo(k.look.glow.alpha, 1e-9));
      }
    });

    test(
      'halfway between two keyframes is the plain midpoint (smoothstep)',
      () {
        // Noon 689 to Asr 889: f = 0.5 and smoothstep(0.5) = 0.5.
        final frame = SkyModel.reference.frameAt(789);
        final noon = SkyModel.looks[SkyMoment.noon]!.stops[0];
        final asr = SkyModel.looks[SkyMoment.asr]!.stops[0];
        expect(frame.stops[0], noon.mix(asr, 0.5));
      },
    );

    test('smoothstep eases near the keyframes', () {
      // A quarter of the way: smoothstep(0.25) = 0.15625.
      final frame = SkyModel.reference.frameAt(689 + 50);
      final noon = SkyModel.looks[SkyMoment.noon]!.stops[2];
      final asr = SkyModel.looks[SkyMoment.asr]!.stops[2];
      expect(frame.stops[2], noon.mix(asr, 0.15625));
    });

    test('stars fade in at night and are gone by day', () {
      expect(SkyModel.reference.frameAt(1300).stars, 1);
      expect(SkyModel.reference.frameAt(689).stars, 0);
      expect(
        SkyModel.reference.frameAt(1090).stars,
        inExclusiveRange(0.4, 0.85),
      );
    });

    test('the clock wraps', () {
      expect(
        SkyModel.reference.frameAt(1440 + 689).stops,
        SkyModel.reference.frameAt(689).stops,
      );
      expect(
        SkyModel.reference.frameAt(-60).stops,
        SkyModel.reference.frameAt(1380).stops,
      );
    });

    test('dark dims every stop and the glow to 60%', () {
      final light = SkyModel.reference.frameAt(689);
      final dark = SkyModel.reference.frameAt(689, dark: true);
      for (var i = 0; i < 5; i++) {
        expect(dark.stops[i].luminance, lessThan(light.stops[i].luminance));
      }
      expect(dark.glow.alpha, closeTo(light.glow.alpha * 0.6, 1e-9));
    });

    test('a dark noon is deep blue, not grey (dimmed in OKLCH)', () {
      final dark = SkyModel.reference.frameAt(689, dark: true);
      for (final c in dark.stops) {
        expect(c.b, greaterThan(c.r + 30), reason: c.hex);
        expect(c.b, greaterThan(c.g), reason: c.hex);
      }
    });

    test('dark daytime is never grey, brown or green', () {
      for (final m in [342.0, 430.0, 689.0, 889.0, 990.0, 1035.0]) {
        final dark = SkyModel.reference.frameAt(m, dark: true);
        for (final c in dark.stops) {
          final hi = [c.r, c.g, c.b].reduce((a, b) => a > b ? a : b);
          final lo = [c.r, c.g, c.b].reduce((a, b) => a < b ? a : b);
          expect(hi - lo, greaterThan(18), reason: 'grey at $m: ${c.hex}');
          expect(c.g, lessThan(hi), reason: 'green at $m: ${c.hex}');
          // Brown is a dark orange: red over green over blue, and dull.
          final brown = c.r > c.g && c.g > c.b && c.b < 0.6 * c.r;
          expect(brown, isFalse, reason: 'brown at $m: ${c.hex}');
        }
      }
    });

    test('night is the same in both themes, give or take its dimming', () {
      final light = SkyModel.reference.frameAt(0);
      final dark = SkyModel.reference.frameAt(0, dark: true);
      for (var i = 0; i < 5; i++) {
        expect(
          (dark.stops[i].luminance - light.stops[i].luminance).abs(),
          lessThan(0.01),
        );
      }
    });

    test('the glow is strongest at the horizon and gone far from it', () {
      final frame = SkyModel.reference.frameAt(342);
      expect(frame.glowAlphaAt(0.22), closeTo(0.75, 1e-9));
      expect(frame.glowAlphaAt(0.5), 0);
      expect(frame.colorAtPoint(0.5, 0.22), frame.colorWithGlowAt(0.22));
      expect(
        frame.colorAtPoint(0.02, 0.22),
        isNot(frame.colorWithGlowAt(0.22)),
      );
    });
  });

  group('anchored to the day', () {
    test('derived points follow sunrise, noon and sunset', () {
      final m = SkyModel.anchored(
        fajr: 300,
        sunrise: 400,
        dhuhr: 720,
        asr: 900,
        sunset: 1040,
        isha: 1120,
      );
      int at(SkyMoment s) =>
          m.keyframes.firstWhere((k) => k.moment == s).minute;
      expect(at(SkyMoment.morning), 560);
      expect(at(SkyMoment.golden), 995);
      expect(at(SkyMoment.dusk), 1075);
      expect(at(SkyMoment.night), 1270);
      expect(m.keyframes.first.minute, 0);
      expect(m.keyframes.last.minute, 1440);
    });

    test('a computed day keeps its real events and stays in order', () {
      for (final sample in sampleDays()) {
        final m = SkyModel.forDay(sample.day);
        final minutes = m.keyframes.map((k) => k.minute).toList();
        for (var i = 1; i < minutes.length; i++) {
          expect(minutes[i], greaterThan(minutes[i - 1]), reason: sample.name);
        }
        final moments = m.keyframes.map((k) => k.moment);
        expect(moments, containsAll([SkyMoment.sunrise, SkyMoment.sunset]));
        int at(SkyMoment s) =>
            m.keyframes.firstWhere((k) => k.moment == s).minute;
        expect(at(SkyMoment.sunrise), sample.day.timeOf(Prayer.sunrise));
        expect(at(SkyMoment.sunset), sample.day.timeOf(Prayer.maghrib));
        // Every minute yields a frame.
        for (var t = 0; t < 1440; t += 7) {
          final f = m.frameAt(t.toDouble());
          expect(f.stops, hasLength(5));
          expect(f.stars, inInclusiveRange(0, 1));
        }
      }
    });

    test('Kuwait in summer keeps all twelve keyframes', () {
      final kuwait = sampleDays().firstWhere((d) => d.name == 'Kuwait summer');
      expect(SkyModel.forDay(kuwait.day).keyframes, hasLength(12));
    });

    test('a long northern dusk drops Isha and deep night past midnight', () {
      final oslo = sampleDays().firstWhere((d) => d.name == 'Oslo summer');
      final moments = SkyModel.forDay(oslo.day).keyframes.map((k) => k.moment);
      expect(moments, isNot(contains(SkyMoment.night)));
    });

    test('a derived point that clashes with a prayer gives way', () {
      // Asr after "golden" (sunset − 45): golden is dropped, Asr kept.
      final m = SkyModel.anchored(
        sunrise: 480,
        dhuhr: 720,
        asr: 930,
        sunset: 960,
        isha: 1060,
      );
      final moments = m.keyframes.map((k) => k.moment);
      expect(moments, contains(SkyMoment.asr));
      expect(moments, isNot(contains(SkyMoment.golden)));
    });

    test(
      'a missing Fajr is skipped; no sunrise falls back to the reference',
      () {
        final m = SkyModel.anchored(sunrise: 400, sunset: 1040);
        expect(
          m.keyframes.map((k) => k.moment),
          isNot(contains(SkyMoment.fajr)),
        );
        expect(
          SkyModel.anchored(sunrise: null, sunset: 1040),
          same(SkyModel.reference),
        );
      },
    );
  });
}
