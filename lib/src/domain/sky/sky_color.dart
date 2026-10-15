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
