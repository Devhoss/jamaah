import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/sky/ink_rule.dart';
import 'package:jamaah/src/domain/sky/sky_color.dart';
import 'package:jamaah/src/domain/sky/sky_model.dart';
import 'package:jamaah/src/domain/sky/sun_path_geometry.dart';

import 'sample_days.dart';

/// Contrast across every minute of real days (spec §3.2, as amended
/// 2026-10-15): the ink in each region keeps 4.5:1 against the sky behind it
/// (3:1 for the hero), with a faint shade only where no ink could.
void main() {
  final days = sampleDays();

  for (final sample in days) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';

      test('${sample.name} ($theme): every region keeps its contrast', () {
        final model = SkyModel.forDay(sample.day);
        final shaded = {for (final r in SkyRegion.all) r: 0};
        final maxShade = {for (final r in SkyRegion.all) r: 0.0};
        for (var m = 0; m < 1440; m++) {
          final frame = model.frameAt(m.toDouble(), dark: dark);
          for (final region in SkyRegion.all) {
            final ink = SkyInk.forRegion(frame, region);
            expect(
              ink.contrast,
              greaterThanOrEqualTo(region.minContrast),
              reason: 'minute $m, region ${region.top}-${region.bottom}',
            );
            // Recheck independently against the shaded sky.
            for (final y in region.samples) {
              for (final c in [frame.colorAt(y), frame.colorWithGlowAt(y)]) {
                expect(
                  ink.ink.contrastWith(ink.shade.over(c)),
                  greaterThanOrEqualTo(region.minContrast - 1e-9),
                );
              }
            }
            if (ink.shade.alpha > 0) shaded[region] = shaded[region]! + 1;
            if (ink.shade.alpha > maxShade[region]!) {
              maxShade[region] = ink.shade.alpha;
            }
          }
        }
        // The shade is a rare, faint fix, not a second background. Measured
        // 2026-10-15: dark theme never needs it; light theme at most 17% under
        // the top bar (blue morning sky), 4% hero, 11% rows.
        for (final region in SkyRegion.all) {
          expect(maxShade[region], lessThanOrEqualTo(0.2));
        }
        expect(shaded[SkyRegion.topBar], lessThan(240));
        expect(shaded[SkyRegion.hero], lessThan(15));
        expect(shaded[SkyRegion.content], lessThan(30));
        if (dark) expect(shaded.values.every((n) => n == 0), isTrue);
      });

      test('${sample.name} ($theme): the label under the sun keeps 4.5:1', () {
        final model = SkyModel.forDay(sample.day);
        final path = SunPathGeometry(
          sunrise: sample.day.timeOf(Prayer.sunrise)!,
          sunset: sample.day.timeOf(Prayer.maghrib)!,
        );
        var shaded = 0;
        for (var m = 0; m < 1440; m++) {
          final frame = model.frameAt(m.toDouble(), dark: dark);
          final sun = path.positionAt(m.toDouble()).point;
          // The label sits under the sun, or above it near the top (§3.4).
          final labelY = sun.y < 70 ? sun.y + 29 : sun.y - 37;
          final ink = SkyInk.forPoint(
            frame,
            sun.x / SunPathGeometry.width,
            SkyRegion.sunPathTop +
                labelY / SunPathGeometry.height * SkyRegion.sunPathHeight,
          );
          expect(ink.contrast, greaterThanOrEqualTo(4.5), reason: 'minute $m');
          expect(ink.shade.alpha, lessThanOrEqualTo(0.2));
          if (ink.shade.alpha > 0) shaded++;
        }
        expect(shaded, lessThan(120));
      });
    }
  }

  test('text on an ink fill (the ticket) keeps 4.5:1 all day', () {
    for (final sample in days) {
      final model = SkyModel.forDay(sample.day);
      for (final dark in [false, true]) {
        for (var m = 0; m < 1440; m += 5) {
          final frame = model.frameAt(m.toDouble(), dark: dark);
          for (final region in SkyRegion.all) {
            final ink = SkyInk.forRegion(frame, region);
            expect(ink.deep.contrastWith(ink.ink), greaterThanOrEqualTo(4.5));
          }
        }
      }
    }
  });

  test('a dark sky gets light ink and a pale one gets dark ink', () {
    final night = SkyModel.reference.frameAt(60);
    final noon = SkyModel.reference.frameAt(689);
    expect(SkyInk.forRegion(night, SkyRegion.content).isLight, isTrue);
    expect(SkyInk.forRegion(noon, SkyRegion.content).isLight, isFalse);
    expect(SkyInk.forRegion(night, SkyRegion.content).ink, SkyInk.lightInk);
    expect(
      SkyInk.forRegion(noon, SkyRegion.content).deep,
      SkyRgb.hex('#FBFAF7'),
    );
  });

  test('the shade is the opposite tone of the ink', () {
    final night = SkyInk.forRegion(
      SkyModel.reference.frameAt(60),
      SkyRegion.content,
    );
    expect(night.shade.rgb, SkyInk.darkInkBase);
    expect(night.shade.alpha, 0);
  });

  test('derived tokens are the ink at the spec alphas', () {
    final ink = SkyInk.forRegion(
      SkyModel.reference.frameAt(689),
      SkyRegion.content,
    );
    expect(ink.mute.alpha, 0.76);
    expect(ink.line.alpha, 0.22);
    expect(ink.halo.alpha, 0.12);
    expect(ink.trail.alpha, 0.85);
    expect(ink.mute.rgb, ink.ink);
  });
}
