import 'dart:math' as math;

import '../prayer.dart';
import '../time_model.dart';
import 'sky_color.dart';

/// The moments the sky is keyed to (spec §3.1).
enum SkyMoment {
  midnight,
  fajr,
  sunrise,
  morning,
  noon,
  asr,
  golden,
  sunset,
  dusk,
  isha,
  night,
  endOfDay,
}

/// One keyframe's look, independent of when it happens.
class SkyLook {
  const SkyLook({
    required this.stops,
    required this.glow,
    required this.stars,
    required this.darkDim,
  });

  /// Five colours, top to bottom, at [SkyModel.stopPositions].
  final List<SkyRgb> stops;

  /// The elliptical horizon highlight.
  final SkyRgba glow;

  /// Star layer opacity, 0..1.
  final double stars;

  /// How far the dark theme blends each stop toward [SkyModel.nightTone].
  final double darkDim;
}

/// A [SkyLook] placed at a minute of the day.
class SkyKeyframe {
  const SkyKeyframe(this.moment, this.minute, this.look);

  final SkyMoment moment;

  /// Minutes from midnight (0..1440).
  final int minute;
  final SkyLook look;

  @override
  String toString() => 'SkyKeyframe(${moment.name} @ $minute)';
}

/// The sky at one instant, after interpolation (and dark dimming).
class SkyFrame {
  const SkyFrame({
    required this.stops,
    required this.glow,
    required this.stars,
    this.dark = false,
  });

  /// Drawn for the dark theme.
  final bool dark;

  /// Five colours at [SkyModel.stopPositions] (fractions of screen height).
  final List<SkyRgb> stops;
  final SkyRgba glow;
  final double stars;

  /// The gradient colour at [y] (0 top .. 1 bottom), linear between stops as
  /// a CSS/Flutter linear gradient draws it.
  SkyRgb colorAt(double y) {
    final p = SkyModel.stopPositions;
    if (y <= p.first) return stops.first;
    for (var i = 0; i < p.length - 1; i++) {
      if (y <= p[i + 1]) {
        return stops[i].mix(stops[i + 1], (y - p[i]) / (p[i + 1] - p[i]));
      }
    }
    return stops.last;
  }

  /// The glow's alpha at [y] on the screen's centre line, where it is
  /// strongest: full at the horizon, fading to nothing at 70% of its radius.
  double glowAlphaAt(double y) {
    final d = (y - SkyModel.glowCentreY).abs() / SkyModel.glowRadiusY;
    final f = 1 - d / 0.7;
    return f <= 0 ? 0 : glow.alpha * f;
  }

  /// The colour behind text at [y] on the centre line, glow included.
  SkyRgb colorWithGlowAt(double y) =>
      SkyRgba(glow.rgb, glowAlphaAt(y)).over(colorAt(y));

  /// The colour at ([x], [y]) (fractions of width and height), with the
  /// elliptical glow as it falls there.
  SkyRgb colorAtPoint(double x, double y) {
    final dx = (x - 0.5) / SkyModel.glowRadiusX;
    final dy = (y - SkyModel.glowCentreY) / SkyModel.glowRadiusY;
    final d = math.sqrt(dx * dx + dy * dy);
    final f = 1 - d / 0.7;
    final a = f <= 0 ? 0.0 : glow.alpha * f;
    return SkyRgba(glow.rgb, a).over(colorAt(y));
  }
}

/// The sky that follows the clock: keyframes anchored to the day's real
/// events, interpolated with smoothstep in sRGB (spec §3.1).
///
/// Pure Dart; the painter only draws the [SkyFrame] it is given.
class SkyModel {
  SkyModel._(this.keyframes);

  /// Stop positions as fractions of the screen height.
  static const stopPositions = [0.0, 0.13, 0.22, 0.34, 1.0];

  /// The horizon line and the glow's centre, as a fraction of height.
  static const glowCentreY = 0.22;

  /// The glow's radii as fractions of width and height.
  static const glowRadiusX = 0.75;
  static const glowRadiusY = 0.16;

  /// The colour the dark theme dims toward.
  static final nightTone = SkyRgb.hex('#04050B');

  /// The dark theme draws the glow at 60%.
  static const darkGlowFactor = 0.6;

  /// Derived points (spec §3.1).
  static const goldenBeforeSunset = 45;
  static const duskAfterSunset = 35;
  static const nightAfterIsha = 150;

  final List<SkyKeyframe> keyframes;

  /// The reference day the keyframes were designed on (Kuwait City, mid
  /// October). Used whole when the sun does not rise or set.
  static final SkyModel reference = SkyModel._([
    for (final moment in SkyMoment.values)
      SkyKeyframe(moment, _referenceMinutes[moment]!, looks[moment]!),
  ]);

  /// Anchors the keyframes to one day's events (minutes from midnight).
  ///
  /// Morning is halfway between sunrise and noon, golden 45 min before
  /// sunset, dusk 35 min after it and deep night 2.5 h after Isha. A point
  /// that is missing, falls outside the day or would come before the one
  /// ahead of it (Isha after midnight, golden before a late Asr) is dropped,
  /// and its neighbours blend across the gap: sunrise and sunset win a clash,
  /// then the prayer times, then the derived points. With no sunrise or sunset the
  /// reference day is used.
  factory SkyModel.anchored({
    int? fajr,
    required int? sunrise,
    int? dhuhr,
    int? asr,
    required int? sunset,
    int? isha,
  }) {
    if (sunrise == null || sunset == null || sunset <= sunrise) {
      return reference;
    }
    final noon = dhuhr ?? (sunrise + sunset) ~/ 2;
    final wanted = <SkyMoment, int?>{
      SkyMoment.midnight: 0,
      SkyMoment.fajr: fajr,
      SkyMoment.sunrise: sunrise,
      SkyMoment.morning: (sunrise + noon) ~/ 2,
      SkyMoment.noon: noon,
      SkyMoment.asr: asr,
      SkyMoment.golden: sunset - goldenBeforeSunset,
      SkyMoment.sunset: sunset,
      SkyMoment.dusk: sunset + duskAfterSunset,
      SkyMoment.isha: (isha != null && isha > sunset) ? isha : null,
      SkyMoment.night: (isha != null && isha > sunset)
          ? isha + nightAfterIsha
          : null,
      SkyMoment.endOfDay: 1440,
    };
    final kept = <SkyKeyframe>[];
    for (final moment in SkyMoment.values) {
      final minute = wanted[moment];
      if (minute == null) continue;
      final isEnd = moment == SkyMoment.endOfDay;
      if (!isEnd && moment != SkyMoment.midnight && minute >= 1440) continue;
      if (kept.isNotEmpty && minute <= kept.last.minute) {
        // A clash: the stronger point wins. Sunrise and sunset carry the sky,
        // then the prayer times, then the derived points.
        while (kept.isNotEmpty &&
            kept.last.minute >= minute &&
            _rank(kept.last.moment) < _rank(moment)) {
          kept.removeLast();
        }
        if (kept.isNotEmpty && kept.last.minute >= minute) continue;
      }
      kept.add(SkyKeyframe(moment, minute, looks[moment]!));
    }
    return SkyModel._(List.unmodifiable(kept));
  }

  /// Anchors to a computed [PrayerDay] (Maghrib is sunset).
  factory SkyModel.forDay(PrayerDay day) => SkyModel.anchored(
    fajr: day.timeOf(Prayer.fajr),
    sunrise: day.timeOf(Prayer.sunrise),
    dhuhr: day.timeOf(Prayer.dhuhr),
    asr: day.timeOf(Prayer.asr),
    sunset: day.timeOf(Prayer.maghrib),
    isha: day.timeOf(Prayer.isha),
  );

  static int _rank(SkyMoment m) => switch (m) {
    SkyMoment.midnight ||
    SkyMoment.sunrise ||
    SkyMoment.sunset ||
    SkyMoment.endOfDay => 2,
    SkyMoment.fajr || SkyMoment.noon || SkyMoment.asr || SkyMoment.isha => 1,
    SkyMoment.morning ||
    SkyMoment.golden ||
    SkyMoment.dusk ||
    SkyMoment.night => 0,
  };

  /// The sky at [minute] (fractional minutes allowed; wraps around the day).
  SkyFrame frameAt(double minute, {bool dark = false}) {
    final t = ((minute % 1440) + 1440) % 1440;
    var i = 0;
    while (i < keyframes.length - 2 && keyframes[i + 1].minute <= t) {
      i++;
    }
    final a = keyframes[i], b = keyframes[i + 1];
    var f = (t - a.minute) / (b.minute - a.minute);
    f = f.clamp(0.0, 1.0);
    f = f * f * (3 - 2 * f);
    final dim = a.look.darkDim + (b.look.darkDim - a.look.darkDim) * f;
    // The sky's own colour, above the horizon, lends its hue to the pale
    // lower stops when the dark theme dims them.
    final top = a.look.stops[0].mix(b.look.stops[0], f);
    final stops = [
      for (var s = 0; s < a.look.stops.length; s++)
        () {
          final c = a.look.stops[s].mix(b.look.stops[s], f);
          return dark ? c.dimToward(nightTone, dim, skyHue: top) : c;
        }(),
    ];
    final glow = a.look.glow.mix(b.look.glow, f);
    return SkyFrame(
      stops: List.unmodifiable(stops),
      glow: dark ? SkyRgba(glow.rgb, glow.alpha * darkGlowFactor) : glow,
      stars: a.look.stars + (b.look.stars - a.look.stars) * f,
      dark: dark,
    );
  }

  static final Map<SkyMoment, int> _referenceMinutes = {
    SkyMoment.midnight: 0,
    SkyMoment.fajr: 261,
    SkyMoment.sunrise: 342,
    SkyMoment.morning: 430,
    SkyMoment.noon: 689,
    SkyMoment.asr: 889,
    SkyMoment.golden: 990,
    SkyMoment.sunset: 1035,
    SkyMoment.dusk: 1070,
    SkyMoment.isha: 1111,
    SkyMoment.night: 1260,
    SkyMoment.endOfDay: 1440,
  };

  static SkyLook _look(
    List<String> stops,
    int r,
    int g,
    int b,
    double a,
    double stars,
    double darkDim,
  ) => SkyLook(
    stops: List.unmodifiable(stops.map(SkyRgb.hex)),
    glow: SkyRgba(SkyRgb(r.toDouble(), g.toDouble(), b.toDouble()), a),
    stars: stars,
    darkDim: darkDim,
  );

  static final _night = _look(
    ['#03050D', '#070C1E', '#0E1430', '#0B1024', '#090D1C'],
    90,
    110,
    180,
    0.12,
    1,
    0.20,
  );

  /// The keyframe looks from the agreed design (spec §3.1 table).
  static final Map<SkyMoment, SkyLook> looks = {
    SkyMoment.midnight: _night,
    SkyMoment.fajr: _look(
      ['#070B24', '#1B2152', '#4E4176', '#27254C', '#121530'],
      236,
      150,
      140,
      0.45,
      0.6,
      0.30,
    ),
    SkyMoment.sunrise: _look(
      ['#5C79B5', '#B79AC0', '#F2B39A', '#F6D2B0', '#FBEBDD'],
      255,
      214,
      160,
      0.75,
      0,
      0.55,
    ),
    SkyMoment.morning: _look(
      ['#5E9BD6', '#9CC6EA', '#DCEBF3', '#EEF4F6', '#F7F9FA'],
      255,
      240,
      210,
      0.40,
      0,
      0.65,
    ),
    SkyMoment.noon: _look(
      ['#4C9BE0', '#7DB8EA', '#B9DBF4', '#DDEEF9', '#EEF6FB'],
      255,
      255,
      255,
      0.35,
      0,
      0.68,
    ),
    SkyMoment.asr: _look(
      ['#7FB1DA', '#B5CCDC', '#EBD3A6', '#F4E1C2', '#FBF1E2'],
      255,
      200,
      130,
      0.45,
      0,
      0.62,
    ),
    SkyMoment.golden: _look(
      ['#6E93C4', '#C9A9A6', '#F2B27A', '#F3D2AE', '#FAE8D8'],
      255,
      170,
      100,
      0.60,
      0,
      0.55,
    ),
    SkyMoment.sunset: _look(
      ['#232E66', '#C05A7A', '#F2925E', '#6A3050', '#1B1328'],
      255,
      150,
      90,
      0.55,
      0.1,
      0.40,
    ),
    SkyMoment.dusk: _look(
      ['#141A40', '#3A2A5E', '#8A4A6A', '#2E2040', '#140F22'],
      220,
      120,
      110,
      0.35,
      0.4,
      0.30,
    ),
    SkyMoment.isha: _look(
      ['#05081A', '#0E1534', '#22295A', '#141A38', '#0C1124'],
      110,
      120,
      190,
      0.20,
      0.85,
      0.20,
    ),
    SkyMoment.night: _night,
    SkyMoment.endOfDay: _night,
  };
}
