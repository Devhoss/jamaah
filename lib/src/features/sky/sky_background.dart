import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../domain/sky/sky_color.dart';
import '../../domain/sky/sky_model.dart';
import '../../domain/sky/star_field.dart';
import 'grain.dart';
import 'sky_motion.dart';
import 'snapshot_paint.dart';

/// A faint band of shade under one block of text, for the few minutes when no
/// ink reads well enough on the bare sky (spec §3.2, amended 2026-10-15).
/// [top] and [bottom] are fractions of the height; the edges feather.
@immutable
class SkyShade {
  const SkyShade(this.top, this.bottom, this.color);

  final double top;
  final double bottom;
  final SkyRgba color;

  @override
  bool operator ==(Object other) =>
      other is SkyShade &&
      other.top == top &&
      other.bottom == bottom &&
      other.color.rgb == color.rgb &&
      other.color.alpha == color.alpha;

  @override
  int get hashCode => Object.hash(top, bottom, color.rgb, color.alpha);
}

Color skyColor(SkyRgb c, [double alpha = 1]) =>
    Color(c.argb).withValues(alpha: alpha.clamp(0.0, 1.0));

/// The sky: gradient, horizon glow, stars and grain (spec §3). It only draws
/// the [SkyFrame] it is given; the sky engine decides what that is.
class SkyBackground extends StatefulWidget {
  const SkyBackground({
    required this.frame,
    required this.dark,
    this.shades = const [],
    this.child,
    super.key,
  });

  final SkyFrame frame;
  final bool dark;
  final List<SkyShade> shades;
  final Widget? child;

  @override
  State<SkyBackground> createState() => _SkyBackgroundState();
}

class _SkyBackgroundState extends State<SkyBackground> {
  ui.Image? _grain;

  @override
  void initState() {
    super.initState();
    Grain.image().then((image) {
      if (mounted) setState(() => _grain = image);
    });
  }

  @override
  Widget build(BuildContext context) {
    final motion = SkyMotion.maybeOf(context);
    final stars = widget.frame.stars;
    // The gradient, glow, shades and grain change only with the minute or
    // the theme, so they sit in their own cached layer; only the small star
    // layer repaints with the motion clock (owner, 2026-10-16).
    return Stack(
      // The sky is a picture: it never mirrors.
      alignment: Alignment.topLeft,
      fit: StackFit.passthrough,
      children: [
        Positioned.fill(
          child: RepaintBoundary(
            child: SnapshotPaint(
              painter: SkyPainter(
                frame: widget.frame,
                dark: widget.dark,
                shades: widget.shades,
                grain: _grain,
              ),
            ),
          ),
        ),
        if (stars > 0.01)
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: StarField.height + 8,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: StarsPainter(opacity: stars, motion: motion),
                ),
              ),
            ),
          ),
        ?widget.child,
      ],
    );
  }
}

/// The twinkling stars: 46 small dots in the top 300 px, the only part of
/// the sky that moves on its own.
class StarsPainter extends CustomPainter {
  StarsPainter({required this.opacity, required this.motion})
    : super(repaint: motion?.clock);

  /// The keyframe's star opacity.
  final double opacity;
  final SkyMotion? motion;

  /// One soft star (a bright core with its glow), drawn for every star in a
  /// single atlas call instead of 46 blurs per tick.
  static final ui.Image _sprite = _makeSprite();
  static const _spriteSize = 32.0;

  static ui.Image _makeSprite() {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const c = Offset(_spriteSize / 2, _spriteSize / 2);
    canvas.drawCircle(
      c,
      _spriteSize / 2,
      Paint()
        ..shader = ui.Gradient.radial(
          c,
          _spriteSize / 2,
          [
            Colors.white,
            Colors.white,
            Colors.white.withValues(alpha: 0.35),
            Colors.white.withValues(alpha: 0),
          ],
          const [0, 0.42, 0.55, 1],
        ),
    );
    final picture = recorder.endRecording();
    final image = picture.toImageSync(_spriteSize.toInt(), _spriteSize.toInt());
    picture.dispose();
    return image;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final seconds = motion?.seconds;
    final scale = size.width / StarField.frameWidth;
    final transforms = <RSTransform>[];
    final colors = <Color>[];
    final rects = <Rect>[];
    const src = Rect.fromLTWH(0, 0, _spriteSize, _spriteSize);
    for (final star in StarField.stars) {
      final o = star.opacityAt(seconds) * opacity;
      if (o <= 0.01) continue;
      // The core covers 42% of the sprite: the star's own size; the glow
      // around it reaches about 2.4 times further.
      final k = star.size / (_spriteSize * 0.42);
      transforms.add(
        RSTransform.fromComponents(
          rotation: 0,
          scale: k,
          anchorX: _spriteSize / 2,
          anchorY: _spriteSize / 2,
          translateX: star.x * scale,
          translateY: star.y,
        ),
      );
      rects.add(src);
      colors.add(Colors.white.withValues(alpha: o));
    }
    if (transforms.isEmpty) return;
    canvas.drawAtlas(
      _sprite,
      transforms,
      rects,
      colors,
      BlendMode.modulate,
      null,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(StarsPainter old) =>
      old.opacity != opacity || old.motion?.still != motion?.still;
}

class SkyPainter extends CustomPainter {
  SkyPainter({
    required this.frame,
    required this.dark,
    required this.shades,
    required this.grain,
  });

  final SkyFrame frame;
  final bool dark;
  final List<SkyShade> shades;
  final ui.Image? grain;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Gradient, five stops.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = ui.Gradient.linear(rect.topCenter, rect.bottomCenter, [
          for (final s in frame.stops) skyColor(s),
        ], SkyModel.stopPositions),
    );

    // Horizon glow: an ellipse 75% × 16% at (50%, 22%), fading out at 70%.
    final rx = size.width * SkyModel.glowRadiusX;
    final ry = size.height * SkyModel.glowRadiusY;
    if (frame.glow.alpha > 0 && rx > 0 && ry > 0) {
      canvas.save();
      canvas.translate(size.width / 2, size.height * SkyModel.glowCentreY);
      canvas.scale(1, ry / rx);
      final glow = skyColor(frame.glow.rgb, frame.glow.alpha);
      canvas.drawCircle(
        Offset.zero,
        rx,
        Paint()
          ..shader = ui.Gradient.radial(
            Offset.zero,
            rx,
            [glow, glow.withValues(alpha: 0)],
            const [0, 0.7],
          ),
      );
      canvas.restore();
    }

    // Shade bands under text, when the ink needs them.
    for (final shade in shades) {
      if (shade.color.alpha <= 0) continue;
      final top = shade.top * size.height;
      final bottom = shade.bottom * size.height;
      final c = skyColor(shade.color.rgb, shade.color.alpha);
      const feather = 24.0;
      final band = Rect.fromLTRB(
        0,
        top - feather,
        size.width,
        bottom + feather,
      );
      final h = band.height;
      canvas.drawRect(
        band,
        Paint()
          ..shader = ui.Gradient.linear(
            band.topCenter,
            band.bottomCenter,
            [c.withValues(alpha: 0), c, c, c.withValues(alpha: 0)],
            [0, feather / h, 1 - feather / h, 1],
          ),
      );
    }

    // Grain.
    final g = grain;
    if (g != null) {
      canvas.drawRect(
        rect,
        Paint()
          ..shader = ImageShader(
            g,
            TileMode.repeated,
            TileMode.repeated,
            Matrix4.identity().storage,
          )
          ..blendMode = BlendMode.overlay
          ..color = Colors.black.withValues(
            alpha: dark ? Grain.darkOpacity : Grain.lightOpacity,
          ),
      );
    }
  }

  @override
  bool shouldRepaint(SkyPainter old) =>
      !_sameFrame(old.frame, frame) ||
      old.dark != dark ||
      old.grain != grain ||
      !_sameShades(old.shades, shades);

  static bool _sameFrame(SkyFrame a, SkyFrame b) {
    if (identical(a, b)) return true;
    if (a.glow.alpha != b.glow.alpha || a.glow.rgb != b.glow.rgb) return false;
    for (var i = 0; i < a.stops.length; i++) {
      if (a.stops[i] != b.stops[i]) return false;
    }
    return true;
  }

  static bool _sameShades(List<SkyShade> a, List<SkyShade> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
