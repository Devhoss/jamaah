import 'dart:math' as math;

/// An sRGB colour with channels in 0..255, kept as doubles so blends stay
/// smooth. Pure Dart: the sky engine has no Flutter imports, and the painter
/// turns these into `Color`s with [argb].
class SkyRgb {
  const SkyRgb(this.r, this.g, this.b);

  /// Parses `#RRGGBB`.
  factory SkyRgb.hex(String hex) {
    final h = hex.startsWith('#') ? hex.substring(1) : hex;
    if (h.length != 6) throw FormatException('Expected #RRGGBB', hex);
    return SkyRgb(
      int.parse(h.substring(0, 2), radix: 16).toDouble(),
      int.parse(h.substring(2, 4), radix: 16).toDouble(),
      int.parse(h.substring(4, 6), radix: 16).toDouble(),
    );
  }

  final double r;
  final double g;
  final double b;

  static const black = SkyRgb(0, 0, 0);
  static const white = SkyRgb(255, 255, 255);

  /// Linear blend in sRGB, as the prototype does: [f] 0 is this, 1 is [other].
  SkyRgb mix(SkyRgb other, double f) => SkyRgb(
    r + (other.r - r) * f,
    g + (other.g - g) * f,
    b + (other.b - b) * f,
  );

  /// Dims toward [night] in a perceptual space (OKLCH): the lightness moves
  /// [amount] of the way to [night]'s, while chroma and hue are kept, so a
  /// dark-theme noon still reads as deep blue rather than grey (owner,
  /// 2026-10-16). Where the dimmed colour would fall outside sRGB, chroma is
  /// reduced just enough to bring it back.
  ///
  /// A pale stop has almost no colour of its own, so dimming it alone would
  /// leave grey (and a dimmed peach reads as brown). With [skyHue], the
  /// colour of the sky above, each stop turns toward that sky's hue and
  /// chroma by [amount], never through green, so a dark noon is deep blue and
  /// a dark sunrise dusky rose.
  SkyRgb dimToward(SkyRgb night, double amount, {SkyRgb? skyHue}) {
    final lab = _OkLab.fromRgb(this);
    final targetL = _OkLab.fromRgb(night).l;
    final l = lab.l + (targetL - lab.l) * amount;
    var c = math.sqrt(lab.a * lab.a + lab.b * lab.b);
    var h = math.atan2(lab.b, lab.a);
    if (skyHue != null) {
      // In polar form, so a warm stop turning toward a blue sky passes
      // through violet rather than grey.
      final ref = _OkLab.fromRgb(skyHue);
      final refC = math.sqrt(ref.a * ref.a + ref.b * ref.b);
      final refH = math.atan2(ref.b, ref.a);
      final w = amount.clamp(0.0, 1.0);
      var dh = refH - h;
      while (dh > math.pi) {
        dh -= 2 * math.pi;
      }
      while (dh < -math.pi) {
        dh += 2 * math.pi;
      }
      // Never turn through green: a pale yellow going to blue takes the long
      // way round, through rose and violet, like a real sky.
      if (_crosses(h, dh, _green)) dh -= dh.sign * 2 * math.pi;
      // A stop with no colour of its own simply takes the sky's hue.
      final hw = c < 0.02 ? 1.0 : w;
      h += dh * hw;
      c = math.max(c, c + (refC - c) * w);
    }
    SkyRgb? at(double chroma) =>
        _OkLab(l, chroma * math.cos(h), chroma * math.sin(h)).toRgbInGamut();
    final full = at(c);
    if (full != null) return full;
    var lo = 0.0, hi = c;
    for (var i = 0; i < 16; i++) {
      final mid = (lo + hi) / 2;
      if (at(mid) != null) {
        lo = mid;
      } else {
        hi = mid;
      }
    }
    return at(lo) ?? _OkLab(l, 0, 0).toRgbClamped();
  }

  /// OKLab hue of green, in radians (about 145°).
  static const _green = 145 * math.pi / 180;

  /// Whether turning from [from] by [delta] passes [hue].
  static bool _crosses(double from, double delta, double hue) {
    double norm(double x) => (x % (2 * math.pi) + 2 * math.pi) % (2 * math.pi);
    final start = norm(from), target = norm(hue);
    final d = delta >= 0 ? norm(target - start) : norm(start - target);
    return d > 0 && d < delta.abs();
  }

  /// WCAG 2 relative luminance.
  double get luminance {
    double channel(double v) {
      final c = (v / 255).clamp(0.0, 1.0);
      return c <= 0.03928
          ? c / 12.92
          : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
    }

    return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b);
  }

  /// WCAG 2 contrast ratio, 1..21.
  double contrastWith(SkyRgb other) {
    final a = luminance, b = other.luminance;
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
  }

  /// Opaque ARGB, as `Color(argb)` expects.
  int get argb {
    int c(double v) => v.round().clamp(0, 255);
    return 0xFF000000 | (c(r) << 16) | (c(g) << 8) | c(b);
  }

  String get hex {
    String c(double v) =>
        v.round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
    return '#${c(r)}${c(g)}${c(b)}'.toUpperCase();
  }

  @override
  bool operator ==(Object other) =>
      other is SkyRgb && other.r == r && other.g == g && other.b == b;

  @override
  int get hashCode => Object.hash(r, g, b);

  @override
  String toString() => 'SkyRgb($hex)';
}

/// A colour with an alpha in 0..1 (the horizon glow).
class SkyRgba {
  const SkyRgba(this.rgb, this.alpha);

  final SkyRgb rgb;
  final double alpha;

  SkyRgba mix(SkyRgba other, double f) =>
      SkyRgba(rgb.mix(other.rgb, f), alpha + (other.alpha - alpha) * f);

  /// [rgb] drawn over [under] at [alpha] (source-over).
  SkyRgb over(SkyRgb under) => under.mix(rgb, alpha);
}

/// Björn Ottosson's OKLab, for perceptual dimming.
class _OkLab {
  const _OkLab(this.l, this.a, this.b);

  factory _OkLab.fromRgb(SkyRgb c) {
    double lin(double v) {
      final x = (v / 255).clamp(0.0, 1.0);
      return x <= 0.04045
          ? x / 12.92
          : math.pow((x + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = lin(c.r), g = lin(c.g), b = lin(c.b);
    final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
    final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
    final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
    return _OkLab(
      0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
      1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
      0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
    );
  }

  final double l;
  final double a;
  final double b;

  static double _cbrt(double x) =>
      x < 0 ? -math.pow(-x, 1 / 3).toDouble() : math.pow(x, 1 / 3).toDouble();

  (double, double, double) _linear() {
    final l1 = l + 0.3963377774 * a + 0.2158037573 * b;
    final m1 = l - 0.1055613458 * a - 0.0638541728 * b;
    final s1 = l - 0.0894841775 * a - 1.2914855480 * b;
    final l3 = l1 * l1 * l1, m3 = m1 * m1 * m1, s3 = s1 * s1 * s1;
    return (
      4.0767416621 * l3 - 3.3077115913 * m3 + 0.2309699292 * s3,
      -1.2684380046 * l3 + 2.6097574011 * m3 - 0.3413193965 * s3,
      -0.0041960863 * l3 - 0.7034186147 * m3 + 1.7076147010 * s3,
    );
  }

  static double _encode(double x) => x <= 0.0031308
      ? 12.92 * x
      : 1.055 * math.pow(x, 1 / 2.4).toDouble() - 0.055;

  /// The sRGB colour, or null when this lies outside sRGB.
  SkyRgb? toRgbInGamut() {
    final (r, g, b) = _linear();
    const eps = 1e-4;
    if ([r, g, b].any((v) => v < -eps || v > 1 + eps)) return null;
    return SkyRgb(
      _encode(r.clamp(0.0, 1.0)) * 255,
      _encode(g.clamp(0.0, 1.0)) * 255,
      _encode(b.clamp(0.0, 1.0)) * 255,
    );
  }

  SkyRgb toRgbClamped() {
    final (r, g, b) = _linear();
    return SkyRgb(
      _encode(r.clamp(0.0, 1.0)) * 255,
      _encode(g.clamp(0.0, 1.0)) * 255,
      _encode(b.clamp(0.0, 1.0)) * 255,
    );
  }
}
