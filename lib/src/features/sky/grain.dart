import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

/// A small tile of greyscale fractal noise, made once and drawn as an image
/// shader over the sky so its gradients don't band on OLED screens
/// (spec §3.3). Never computed per frame.
abstract final class Grain {
  static const size = 128;

  /// 7% over the light sky, 10% over the dark one, blended as overlay.
  static const lightOpacity = 0.07;
  static const darkOpacity = 0.10;

  static Future<ui.Image>? _image;

  /// The shared tile, made on first use.
  static Future<ui.Image> image() => _image ??= _make();

  /// Two octaves of value noise: fine per-pixel grain plus a softer 2 px
  /// layer, roughly the prototype's feTurbulence at base frequency 0.85.
  static Uint8List pixels({int seed = 11}) {
    final random = math.Random(seed);
    final fine = List.generate(size * size, (_) => random.nextDouble());
    final coarse = List.generate(
      (size ~/ 2) * (size ~/ 2),
      (_) => random.nextDouble(),
    );
    final out = Uint8List(size * size * 4);
    for (var y = 0; y < size; y++) {
      for (var x = 0; x < size; x++) {
        final v =
            fine[y * size + x] * 0.65 +
            coarse[(y ~/ 2) * (size ~/ 2) + (x ~/ 2)] * 0.35;
        final g = (v * 255).round().clamp(0, 255);
        final i = (y * size + x) * 4;
        out[i] = g;
        out[i + 1] = g;
        out[i + 2] = g;
        out[i + 3] = 255;
      }
    }
    return out;
  }

  static Future<ui.Image> _make() {
    final done = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      pixels(),
      size,
      size,
      ui.PixelFormat.rgba8888,
      done.complete,
    );
    return done.future;
  }
}
