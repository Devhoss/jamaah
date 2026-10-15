import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

/// Paints [painter] once into an image and then only draws that image, until
/// [painter] says it needs repainting or the size changes (owner, 2026-10-16).
///
/// For the sky's still layers (gradient, glow, grain, the sun path's arcs and
/// markers): with Impeller a [RepaintBoundary] saves recording them again, but
/// the GPU would still redraw every blur and the full-screen grain blend on
/// each tick of the motion clock. A ready image is one cheap blit.
class SnapshotPaint extends StatefulWidget {
  const SnapshotPaint({required this.painter, super.key});

  final CustomPainter painter;

  @override
  State<SnapshotPaint> createState() => _SnapshotPaintState();
}

class _SnapshotPaintState extends State<SnapshotPaint> {
  final _cache = _Snapshot();

  @override
  void dispose() {
    _cache.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SnapshotPainter(
      inner: widget.painter,
      cache: _cache,
      devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
    ),
  );
}

class _Snapshot {
  ui.Image? image;
  CustomPainter? painted;
  Size? size;
  double? ratio;

  void dispose() {
    image?.dispose();
    image = null;
  }
}

class _SnapshotPainter extends CustomPainter {
  _SnapshotPainter({
    required this.inner,
    required this.cache,
    required this.devicePixelRatio,
  });

  final CustomPainter inner;
  final _Snapshot cache;
  final double devicePixelRatio;

  bool _stale(Size size) {
    final painted = cache.painted;
    return cache.image == null ||
        cache.size != size ||
        cache.ratio != devicePixelRatio ||
        painted == null ||
        (!identical(painted, inner) && inner.shouldRepaint(painted));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    if (_stale(size)) {
      final recorder = ui.PictureRecorder();
      final c = Canvas(recorder)..scale(devicePixelRatio);
      inner.paint(c, size);
      final picture = recorder.endRecording();
      final image = picture.toImageSync(
        (size.width * devicePixelRatio).ceil(),
        (size.height * devicePixelRatio).ceil(),
      );
      picture.dispose();
      cache.image?.dispose();
      cache
        ..image = image
        ..painted = inner
        ..size = size
        ..ratio = devicePixelRatio;
    }
    final image = cache.image!;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.low,
    );
  }

  @override
  bool shouldRepaint(_SnapshotPainter old) =>
      old.devicePixelRatio != devicePixelRatio ||
      (!identical(old.inner, inner) && inner.shouldRepaint(old.inner));
}
