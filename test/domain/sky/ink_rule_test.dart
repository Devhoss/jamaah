import 'dart:math' show min;

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

  // Muted text (spec §3.2, owner 2026-10-15): starts at 76% of the ink and is
  // raised only as far as the sky behind its block needs, never past 100%.
  // Today's muted blocks sit in the top bar, the hero's small lines, the
  // middle (notes, ticket line, flight row) and the rows; the label under
  // the sun is checked at its own point.
  const mutedBlocks = [
    SkyRegion(0, 0.08, minContrast: 4.5),
    SkyRegion(0.28, 0.45, minContrast: 4.5),
    SkyRegion(0.45, 0.58, minContrast: 4.5),
    SkyRegion(0.58, 1, minContrast: 4.5),
  ];

  List<SkyRgb> behind(SkyFrame frame, SkyInk ink, Iterable<double> ys) => [
    for (final y in ys)
      for (final c in [frame.colorAt(y), frame.colorWithGlowAt(y)])
        ink.shade.over(c),
  ];

  void expectMuted(SkyInk ink, List<SkyRgb> under, String where) {
    for (final (alpha, target) in [
      (ink.muteAlpha, 4.5),
      (ink.muteLargeAlpha, 3.0),
    ]) {
      expect(alpha, inInclusiveRange(SkyInk.muteBaseAlpha, 1.0), reason: where);
      final worst = SkyInk.worstMuted(ink.ink, under, alpha);
      if (alpha < 1) {
        expect(worst, greaterThanOrEqualTo(target - 1e-9), reason: where);
      } else {
        // At full ink it is the ink itself, which the region guarantees.
        expect(worst, greaterThanOrEqualTo(min(target, ink.contrast) - 1e-9));
      }
      if (alpha > SkyInk.muteBaseAlpha + 1e-9) {
        // Raised no further than needed.
        expect(
          SkyInk.worstMuted(ink.ink, under, alpha - 0.01),
          lessThan(target),
          reason: '$where: $alpha',
        );
      }
    }
  }

  for (final sample in days) {
    for (final dark in [false, true]) {
      final theme = dark ? 'dark' : 'light';
      test('${sample.name} ($theme): muted text keeps 4.5:1 (3:1 large)', () {
        final model = SkyModel.forDay(sample.day);
        final path = SunPathGeometry(
          sunrise: sample.day.timeOf(Prayer.sunrise)!,
          sunset: sample.day.timeOf(Prayer.maghrib)!,
        );
        var raised = 0;
        for (var m = 0; m < 1440; m++) {
          final frame = model.frameAt(m.toDouble(), dark: dark);
          for (final block in mutedBlocks) {
            final ink = SkyInk.forRegion(frame, block);
            expectMuted(
              ink,
              behind(frame, ink, block.samples),
              'minute $m, ${block.top}-${block.bottom}',
            );
            if (ink.muteAlpha > SkyInk.muteBaseAlpha) raised++;
          }
          final sun = path.positionAt(m.toDouble()).point;
          final labelY = sun.y < 70 ? sun.y + 29 : sun.y - 37;
          final x = sun.x / SunPathGeometry.width;
          final y =
              SkyRegion.sunPathTop +
              labelY / SunPathGeometry.height * SkyRegion.sunPathHeight;
          final label = SkyInk.forPoint(frame, x, y);
          expectMuted(label, [
            for (var i = -2; i <= 2; i++)
              for (var j = -2; j <= 2; j++)
                label.shade.over(
                  frame.colorAtPoint(x + 0.1 * i / 2, y + 0.012 * j / 2),
                ),
          ], 'label at minute $m');
        }
        // Most of the day muted text keeps its 76%.
        expect(raised, lessThan(1440 * mutedBlocks.length));
      });
    }
  }

  test('the ticket\'s quieter lines keep 4.5:1 on the ink fill', () {
    for (final sample in days) {
      final model = SkyModel.forDay(sample.day);
      for (final dark in [false, true]) {
        for (var m = 0; m < 1440; m += 5) {
          final frame = model.frameAt(m.toDouble(), dark: dark);
          final ink = SkyInk.forRegion(frame, mutedBlocks[2]);
          // deep at 80% over the ticket's fill, raised where needed.
          expect(ink.deepSoftAlpha, inInclusiveRange(0.8, 1.0));
          final soft = ink.fill.mix(ink.deep, ink.deepSoftAlpha);
          expect(ink.deep.contrastWith(ink.fill), greaterThanOrEqualTo(4.5));
          expect(
            soft.contrastWith(ink.fill),
            greaterThanOrEqualTo(4.5),
            reason: '${sample.name} dark=$dark minute $m',
          );
        }
      }
    }
  });

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

  test('at night in the dark theme the ticket is softer, but solid', () {
    final light = SkyInk.forRegion(
      SkyModel.reference.frameAt(60),
      SkyRegion.content,
    );
    final dark = SkyInk.forRegion(
      SkyModel.reference.frameAt(60, dark: true),
      SkyRegion.content,
    );
    // The light theme keeps the plain ink box.
    expect(light.fill, light.ink);
    // The dark theme draws ink at about 88% over the sky: dimmer than the
    // ink, much brighter than the sky.
    expect(dark.fill.luminance, lessThan(dark.ink.luminance));
    expect(dark.fill.luminance, greaterThan(0.5));
    expect(dark.deep.contrastWith(dark.fill), greaterThanOrEqualTo(4.5));
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
    expect(ink.mute.alpha, inInclusiveRange(0.76, 1.0));
    expect(ink.line.alpha, 0.22);
    expect(ink.halo.alpha, 0.12);
    expect(ink.trail.alpha, 0.85);
    expect(ink.mute.rgb, ink.ink);
  });
}
