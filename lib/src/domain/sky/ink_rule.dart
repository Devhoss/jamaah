import 'sky_color.dart';
import 'sky_model.dart';

/// A band of the screen that text sits on, as fractions of screen height,
/// and the contrast its text must keep.
class SkyRegion {
  const SkyRegion(this.top, this.bottom, {required this.minContrast});

  final double top;
  final double bottom;
  final double minContrast;

  /// The top bar: place, date, travel switch. Text on the sun path (the label
  /// under the sun) takes its ink from [SkyInk.forPoint] instead, since the
  /// band around the horizon runs from glow to deep blue.
  static const topBar = SkyRegion(0, 0.08, minContrast: 4.5);

  /// Where the sun path sits under the top bar, as fractions of a 390 × 844
  /// screen (the designs' frame). The painter passes its real layout.
  static const sunPathTop = 0.08;
  static const sunPathHeight = 168 / 844;

  /// The big Adhan time: large text, 3:1 (spec §3.2).
  static const hero = SkyRegion(0.28, 0.45, minContrast: 3);

  /// Ticket, notes, prayer rows and the bottom nav.
  static const content = SkyRegion(0.45, 1, minContrast: 4.5);

  static const all = [topBar, hero, content];

  /// Sample points across the band, every 1% of the height.
  Iterable<double> get samples sync* {
    final n = ((bottom - top) * 100).round();
    for (var i = 0; i <= n; i++) {
      yield top + (bottom - top) * i / n;
    }
  }
}

/// The ink for text on the sky in one [SkyRegion] (spec §3.2, as amended on
/// 2026-10-15).
///
/// The spec's single luminance threshold left near-white text on mid-tone sky
/// (2.6:1 before sunrise, 2.3:1 for the hero at golden hour), so each region
/// picks whichever of the two inks reads better against the sky actually behind
/// it, glow included. For the few minutes when neither reaches the region's
/// contrast (the light-theme gradient runs from amber to plum just before
/// sunset), a faint [shade] of the opposite tone is laid under that region only.
class SkyInk {
  const SkyInk({
    required this.ink,
    required this.deep,
    required this.isLight,
    required this.shade,
    required this.contrast,
    this.muteAlpha = SkyInk.muteBaseAlpha,
    this.muteLargeAlpha = SkyInk.muteBaseAlpha,
  });

  /// Light ink, on a dark sky.
  static final lightInk = SkyRgb.hex('#F5F3FA');

  /// The dark ink is the top stop pushed toward this.
  static final darkInkBase = SkyRgb.hex('#05070F');
  static const darkInkAmount = 0.82;

  /// Text on an ink fill (the Iqama ticket, snackbar) when the ink is dark.
  static final deepOnDarkInk = SkyRgb.hex('#FBFAF7');

  /// Alphas of the derived tokens (spec §2.3 A). Muted text starts at
  /// [muteBaseAlpha] and is raised per block where the sky needs it.
  static const muteBaseAlpha = 0.76;

  /// Muted text 24 px or larger only needs 3:1 (spec §3.2, 2026-10-15).
  static const largeTextSize = 24.0;
  static const lineAlpha = 0.22;
  static const haloAlpha = 0.12;
  static const trailAlpha = 0.85;

  /// The shade stops here: if a region still fails, it says so in [contrast]
  /// rather than turning the sky into a block.
  static const maxShade = 0.6;

  final SkyRgb ink;

  /// Text on an [ink] fill.
  final SkyRgb deep;
  final bool isLight;

  /// The faint layer under the region: the opposite tone of [ink] at an
  /// alpha (0 for most of the day).
  final SkyRgba shade;

  /// The worst contrast of [ink] over the region, shade included.
  final double contrast;

  /// Muted (secondary) text: [ink] at 76%, raised only as far as needed to
  /// keep 4.5:1 against the sky behind the block, never above 100%
  /// (owner, 2026-10-15).
  final double muteAlpha;

  /// The same for muted text of 24 px or more, which needs 3:1.
  final double muteLargeAlpha;

  SkyRgba get mute => SkyRgba(ink, muteAlpha);
  SkyRgba get muteLarge => SkyRgba(ink, muteLargeAlpha);
  SkyRgba get line => SkyRgba(ink, lineAlpha);
  SkyRgba get halo => SkyRgba(ink, haloAlpha);
  SkyRgba get trail => SkyRgba(ink, trailAlpha);

  /// The ink for [region] of [frame].
  factory SkyInk.forRegion(SkyFrame frame, SkyRegion region) =>
      _choose(frame, _backgrounds(frame, region), region.minContrast);

  static SkyInk _choose(SkyFrame frame, List<SkyRgb> under, double target) {
    final dark = frame.stops[0].mix(darkInkBase, darkInkAmount);
    final light = lightInk;
    final lightWorst = _worst(light, under);
    final darkWorst = _worst(dark, under);
    final useLight = lightWorst > darkWorst;
    final ink = useLight ? light : dark;
    final shadeTone = useLight ? darkInkBase : deepOnDarkInk;

    var alpha = 0.0;
    var worst = useLight ? lightWorst : darkWorst;
    while (worst < target && alpha < maxShade - 1e-9) {
      alpha = (alpha + 0.01).clamp(0.0, maxShade);
      worst = _worst(ink, [for (final c in under) c.mix(shadeTone, alpha)]);
    }

    final shaded = [for (final c in under) c.mix(shadeTone, alpha)];
    return SkyInk(
      ink: ink,
      deep: useLight ? _deepOnLight(frame.stops[4], ink) : deepOnDarkInk,
      isLight: useLight,
      shade: SkyRgba(shadeTone, alpha),
      contrast: worst,
      muteAlpha: muteAlphaFor(ink, shaded, 4.5),
      muteLargeAlpha: muteAlphaFor(ink, shaded, 3),
    );
  }

  /// The lowest alpha from 76% up that keeps muted [ink] at [target]
  /// against every colour in [under] (the sky with its shade).
  static double muteAlphaFor(
    SkyRgb ink,
    List<SkyRgb> under,
    double target, {
    double base = muteBaseAlpha,
  }) {
    var a = base;
    while (a < 1 && _worstMuted(ink, under, a) < target) {
      a = (a + 0.01).clamp(base, 1.0);
    }
    return a;
  }

  /// The ticket's quieter lines: [deep] at 80% on the ink box, raised the
  /// same way where that box is too close in tone.
  static const deepSoftBaseAlpha = 0.8;

  double get deepSoftAlpha =>
      muteAlphaFor(deep, [ink], 4.5, base: deepSoftBaseAlpha);

  /// The worst contrast of [ink] drawn at [alpha] over [under].
  static double worstMuted(SkyRgb ink, List<SkyRgb> under, double alpha) =>
      _worstMuted(ink, under, alpha);

  static double _worstMuted(SkyRgb ink, List<SkyRgb> under, double alpha) {
    var worst = double.infinity;
    for (final c in under) {
      final r = c.mix(ink, alpha).contrastWith(c);
      if (r < worst) worst = r;
    }
    return worst;
  }

  /// The ink for a small label centred at ([x], [y]) (fractions of width and
  /// height), [halfWidth] × [halfHeight] around it.
  factory SkyInk.forPoint(
    SkyFrame frame,
    double x,
    double y, {
    double halfWidth = 0.1,
    double halfHeight = 0.012,
    double minContrast = 4.5,
  }) {
    final under = [
      for (var i = -2; i <= 2; i++)
        for (var j = -2; j <= 2; j++)
          frame.colorAtPoint(x + halfWidth * i / 2, y + halfHeight * j / 2),
    ];
    return _choose(frame, under, minContrast);
  }

  /// The inks for every standard region of [frame].
  static Map<SkyRegion, SkyInk> forFrame(SkyFrame frame) => {
    for (final r in SkyRegion.all) r: SkyInk.forRegion(frame, r),
  };

  /// The sky behind text in [region]: on the centre line (glow at its
  /// strongest) and at the edges (no glow).
  static List<SkyRgb> _backgrounds(SkyFrame frame, SkyRegion region) => [
    for (final y in region.samples) ...[
      frame.colorAt(y),
      frame.colorWithGlowAt(y),
    ],
  ];

  static double _worst(SkyRgb ink, List<SkyRgb> under) {
    var worst = double.infinity;
    for (final c in under) {
      final r = ink.contrastWith(c);
      if (r < worst) worst = r;
    }
    return worst;
  }

  /// The bottom stop darkened by 25% (spec), darker still if needed so text on
  /// a light-ink fill keeps 4.5:1.
  static SkyRgb _deepOnLight(SkyRgb bottom, SkyRgb ink) {
    var amount = 0.25;
    var deep = bottom.mix(SkyRgb.black, amount);
    while (deep.contrastWith(ink) < 4.5 && amount < 1) {
      amount = (amount + 0.05).clamp(0.0, 1.0);
      deep = bottom.mix(SkyRgb.black, amount);
    }
    return deep;
  }
}
