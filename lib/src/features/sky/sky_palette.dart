import 'package:flutter/material.dart';

import '../../domain/sky/ink_rule.dart';

/// The sky tokens for one block of text, as Flutter colours (spec §2.3 A).
@immutable
class SkyPalette {
  const SkyPalette({
    required this.ink,
    required this.deep,
    this.muteAlpha = SkyInk.muteBaseAlpha,
    this.muteLargeAlpha = SkyInk.muteBaseAlpha,
    this.deepSoftAlpha = SkyInk.deepSoftBaseAlpha,
  });

  factory SkyPalette.of(SkyInk ink) => SkyPalette(
    ink: Color(ink.ink.argb),
    deep: Color(ink.deep.argb),
    muteAlpha: ink.muteAlpha,
    muteLargeAlpha: ink.muteLargeAlpha,
    deepSoftAlpha: ink.deepSoftAlpha,
  );

  /// Text and marks on the sky.
  final Color ink;

  /// Text on an [ink] fill: the Iqama ticket, the Next tag, the snackbar.
  final Color deep;

  /// How strong muted text is drawn: 76%, raised where the sky needs it
  /// (spec §3.2). Hierarchy then rests on size and weight, never a colour.
  final double muteAlpha;

  /// The same for muted text of 24 px or more (3:1).
  final double muteLargeAlpha;

  /// The quieter lines on an [ink] fill (the ticket): [deep] at 80%, raised
  /// where needed to keep 4.5:1.
  final double deepSoftAlpha;

  Color get deepSoft => deep.withValues(alpha: deepSoftAlpha);

  Color get mute => ink.withValues(alpha: muteAlpha);
  Color get muteLarge => ink.withValues(alpha: muteLargeAlpha);
  Color get line => ink.withValues(alpha: SkyInk.lineAlpha);
  Color get halo => ink.withValues(alpha: SkyInk.haloAlpha);
  Color get trail => ink.withValues(alpha: SkyInk.trailAlpha);

  static SkyPalette lerp(SkyPalette a, SkyPalette b, double t) => SkyPalette(
    ink: Color.lerp(a.ink, b.ink, t)!,
    deep: Color.lerp(a.deep, b.deep, t)!,
    muteAlpha: a.muteAlpha + (b.muteAlpha - a.muteAlpha) * t,
    muteLargeAlpha:
        a.muteLargeAlpha + (b.muteLargeAlpha - a.muteLargeAlpha) * t,
    deepSoftAlpha: a.deepSoftAlpha + (b.deepSoftAlpha - a.deepSoftAlpha) * t,
  );

  @override
  bool operator ==(Object other) =>
      other is SkyPalette &&
      other.ink == ink &&
      other.deep == deep &&
      other.muteAlpha == muteAlpha &&
      other.muteLargeAlpha == muteLargeAlpha &&
      other.deepSoftAlpha == deepSoftAlpha;

  @override
  int get hashCode =>
      Object.hash(ink, deep, muteAlpha, muteLargeAlpha, deepSoftAlpha);
}

class SkyPaletteTween extends Tween<SkyPalette> {
  SkyPaletteTween({super.begin, super.end});

  @override
  SkyPalette lerp(double t) => SkyPalette.lerp(begin!, end!, t);
}

/// Animates a palette change over ~400 ms, so an ink flip during a drag is
/// not abrupt (spec §3.2). Instant under reduce motion.
class AnimatedSkyPalette extends StatelessWidget {
  const AnimatedSkyPalette({
    required this.palette,
    required this.builder,
    super.key,
  });

  final SkyPalette palette;
  final Widget Function(BuildContext context, SkyPalette palette) builder;

  static const duration = Duration(milliseconds: 400);

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<SkyPalette>(
      tween: SkyPaletteTween(end: palette),
      duration: still ? Duration.zero : duration,
      curve: Curves.easeInOut,
      builder: (context, p, _) => builder(context, p),
    );
  }
}
