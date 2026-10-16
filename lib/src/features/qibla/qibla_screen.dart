import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../app/compass.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/place.dart';
import '../../domain/qibla.dart' as qibla;
import '../../domain/qibla_words.dart';
import '../location/location_sheet.dart';
import '../location/place_copy.dart';
import '../settings/settings_kit.dart';

/// The Qibla (Horizon spec §4.7): a supporting tab, never dominant
/// (AGENTS.md). The sky header names the place and the distance; on the
/// surface below, the dial.
///
/// The bearing is worked out on the device from the saved place, so it is
/// always shown, compass or not. With a compass the dial turns with the phone,
/// corrected from magnetic to true north; without one, the bearing stands on
/// its own with the direction in words and a line on how to use it.
class QiblaScreen extends ConsumerWidget {
  const QiblaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final place = ref.watch(currentPlaceProvider);
    if (place == null) return const _NeedsPlace();
    // Keyed by the place, so a new place starts a fresh compass session.
    return _QiblaView(
      key: ValueKey((place.latitude, place.longitude)),
      place: place,
    );
  }
}

/// How long the compass may stay silent before the screen says there is none.
const _noCompassAfter = Duration(seconds: 3);

/// Within this many degrees the phone faces the Qibla.
const _alignedWithin = 3;

class _QiblaView extends ConsumerStatefulWidget {
  const _QiblaView({required this.place, super.key});

  final Place place;

  @override
  ConsumerState<_QiblaView> createState() => _QiblaViewState();
}

class _QiblaViewState extends ConsumerState<_QiblaView> {
  StreamSubscription<CompassReading>? _sub;
  Timer? _silence;
  CompassReading? _reading;
  double? _declination;
  bool _noCompass = false;
  bool _wasAligned = false;

  /// The compass needed calibrating and no longer does: say it is steady.
  bool _steadyAgain = false;

  /// The dial's angle as one continuous number, so turning past north spins
  /// the short way instead of all the way round.
  double _dialTurns = 0;

  @override
  void initState() {
    super.initState();
    final source = ref.read(compassSourceProvider);
    source
        .declination(
          latitude: widget.place.latitude,
          longitude: widget.place.longitude,
        )
        .then((d) {
          if (mounted) setState(() => _declination = d);
        });
    _silence = Timer(_noCompassAfter, () {
      if (mounted && _reading == null) setState(() => _noCompass = true);
    });
    _sub = source.readings().listen(
      _onReading,
      onError: (_) {
        if (mounted && _reading == null) setState(() => _noCompass = true);
      },
    );
  }

  void _onReading(CompassReading reading) {
    _silence?.cancel();
    final heading = qibla.trueHeading(reading.heading, _declination ?? 0);
    final current = (-_dialTurns * 360) % 360;
    final step = _shortest(current, heading);
    final wasUnsteady = _reading?.needsCalibration ?? false;
    setState(() {
      if (reading.needsCalibration) {
        _steadyAgain = false;
      } else if (wasUnsteady) {
        _steadyAgain = true;
      }
      _reading = reading;
      _noCompass = false;
      _dialTurns -= step / 360;
    });
    // One gentle tap on arriving at the Qibla, not a buzz on every reading.
    final bearing = qibla.qiblaBearingRounded(
      latitude: widget.place.latitude,
      longitude: widget.place.longitude,
    );
    final aligned = qibla.isAligned(heading.round() % 360, bearing);
    if (aligned && !_wasAligned) HapticFeedback.mediumImpact();
    _wasAligned = aligned;
  }

  @override
  void dispose() {
    _silence?.cancel();
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final place = widget.place;
    final bearing = qibla.qiblaBearingRounded(
      latitude: place.latitude,
      longitude: place.longitude,
    );
    final reading = _reading;
    final heading = reading == null
        ? null
        : qibla.trueHeading(reading.heading, _declination ?? 0);
    final turn = heading == null
        ? null
        : qibla.angleDifference(heading.round() % 360, bearing);
    final aligned = turn != null && turn.abs() <= _alignedWithin;
    final unsteady = reading?.needsCalibration ?? false;

    final distance =
        NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag(),
        ).format(
          qibla
              .distanceKm(latitude: place.latitude, longitude: place.longitude)
              .round(),
        );
    final placeName = placeLabel(l10n, place);
    final big = type.display.copyWith(
      fontSize: 56,
      color: s.onSurface,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    // From the screen, not a LayoutBuilder: the panel is measured by its
    // intrinsic height, which a LayoutBuilder cannot answer.
    final dialSize = math.min(
      MediaQuery.sizeOf(context).width - 2 * HorizonShape.gutterSurface,
      280.0,
    );
    Widget dial({required bool turning}) => Center(
      child: Semantics(
        label: l10n.qiblaDialLabel('$bearing'),
        excludeSemantics: true,
        child: _Dial(
          size: dialSize,
          bearing: bearing.toDouble(),
          dialTurns: turning ? _dialTurns : 0,
          aligned: aligned,
        ),
      ),
    );

    return SettingsScaffold(
      title: l10n.tabQibla,
      lead: l10n.qiblaLead(placeName, distance),
      onTab: true,
      children: [
        const SizedBox(height: 12),
        if (_noCompass) ...[
          dial(turning: false),
          const SizedBox(height: 14),
          Center(child: Text(l10n.qiblaDegrees('$bearing'), style: big)),
          Center(
            child: Text(
              compassWordsText(l10n, CompassWords.of(bearing.toDouble())),
              textAlign: TextAlign.center,
              style: type.row.copyWith(color: s.onSurface),
            ),
          ),
          const SizedBox(height: 14),
          SettingsHeading(l10n.qiblaNoCompassTitle, top: 0),
          SettingsNote(l10n.qiblaNoCompassHint, top: 0),
        ] else ...[
          dial(turning: true),
          const SizedBox(height: 14),
          Center(child: Text(l10n.qiblaDegrees('$bearing'), style: big)),
          Semantics(
            liveRegion: aligned,
            child: Center(
              child: Text(
                switch (turn) {
                  null => l10n.qiblaFromNorth('$bearing'),
                  _ when aligned => l10n.qiblaAligned,
                  final t when t > 0 => l10n.qiblaTurnRight('$t'),
                  final t => l10n.qiblaTurnLeft('${-t}'),
                },
                textAlign: TextAlign.center,
                style: type.row.copyWith(
                  color: s.onSurface,
                  fontWeight: aligned ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
          if (unsteady) ...[
            const SizedBox(height: 18),
            const _CalibrationCard(),
          ] else if (_steadyAgain) ...[
            const SizedBox(height: 10),
            Semantics(
              liveRegion: true,
              child: Center(
                child: Text(
                  l10n.qiblaSteadyNow,
                  style: type.meta.copyWith(color: s.onSurfaceMuted),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          SettingsNote(l10n.qiblaHoldFlat, top: 0),
          SettingsNote(
            _declination == null
                ? l10n.qiblaMagneticNote
                : l10n.qiblaDeclinationNote(
                    _declination!.abs().toStringAsFixed(1),
                  ),
            top: 4,
          ),
          const SizedBox(height: 4),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SettingsTextButton(
              label: l10n.qiblaCalibrate,
              onPressed: () => _showCalibration(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// "South-west, a little more west than south".
String compassWordsText(AppLocalizations l10n, CompassWords w) {
  final point = compassPointName(l10n, w.point);
  final toward = w.toward;
  if (toward == null) return point;
  final away = w.away;
  return away == null
      ? l10n.compassLeanToward(point, compassLowerName(l10n, toward))
      : l10n.compassLeanMore(
          point,
          compassLowerName(l10n, toward),
          compassLowerName(l10n, away),
        );
}

String compassPointName(AppLocalizations l10n, CompassPoint p) => switch (p) {
  CompassPoint.north => l10n.compassPointNorth,
  CompassPoint.northEast => l10n.compassPointNorthEast,
  CompassPoint.east => l10n.compassPointEast,
  CompassPoint.southEast => l10n.compassPointSouthEast,
  CompassPoint.south => l10n.compassPointSouth,
  CompassPoint.southWest => l10n.compassPointSouthWest,
  CompassPoint.west => l10n.compassPointWest,
  CompassPoint.northWest => l10n.compassPointNorthWest,
};

/// A cardinal inside a sentence: "west".
String compassLowerName(AppLocalizations l10n, CompassPoint p) => switch (p) {
  CompassPoint.north => l10n.compassLowerNorth,
  CompassPoint.east => l10n.compassLowerEast,
  CompassPoint.south => l10n.compassLowerSouth,
  _ => l10n.compassLowerWest,
};

/// Degrees to add to [from] to reach [to] the short way: within ±180.
double _shortest(double from, double to) {
  final d = ((to - from) % 360 + 360) % 360;
  return d > 180 ? d - 360 : d;
}

Future<void> _showCalibration(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showSettingsSheet<void>(
    context,
    builder: (sheetContext) => SettingsSheetBody(
      title: l10n.qiblaCalibrateTitle,
      children: [
        const _FigureEight(size: 120),
        const SizedBox(height: 12),
        SettingsNote(l10n.qiblaCalibrateBody, top: 0),
        const SizedBox(height: 16),
        SettingsButton(
          label: l10n.qiblaCalibrateDone,
          filled: true,
          onPressed: () => Navigator.of(sheetContext).pop(),
        ),
      ],
    ),
  );
}

/// "The compass needs a moment", with the figure-eight to draw.
class _CalibrationCard extends StatelessWidget {
  const _CalibrationCard();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: s.well,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const _FigureEight(size: 72),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.qiblaNeedsMoment,
                  style: type.row.copyWith(color: s.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.qiblaCalibrateBody,
                  style: type.meta.copyWith(
                    height: 1.4,
                    color: s.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A figure-eight with a short stroke travelling along it (still under
/// reduce motion).
class _FigureEight extends StatefulWidget {
  const _FigureEight({required this.size});

  final double size;

  @override
  State<_FigureEight> createState() => _FigureEightState();
}

class _FigureEightState extends State<_FigureEight>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size * 0.6,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _FigureEightPainter(
              t: _controller.value,
              track: s.divider,
              stroke: s.accent,
              moving: _controller.isAnimating,
            ),
          ),
        ),
      ),
    );
  }
}

class _FigureEightPainter extends CustomPainter {
  _FigureEightPainter({
    required this.t,
    required this.track,
    required this.stroke,
    required this.moving,
  });

  final double t;
  final Color track;
  final Color stroke;
  final bool moving;

  @override
  void paint(Canvas canvas, Size size) {
    // A lemniscate of Gerono, sampled.
    final path = Path();
    for (var i = 0; i <= 64; i++) {
      final a = i / 64 * 2 * math.pi;
      final p = Offset(
        size.width / 2 + math.sin(a) * (size.width / 2 - 4),
        size.height / 2 + math.sin(a) * math.cos(a) * (size.height - 8),
      );
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    canvas.drawPath(path, line..color = moving ? track : stroke);
    if (!moving) return;
    final PathMetric metric = path.computeMetrics().first;
    final start = metric.length * t;
    final piece = metric.length * 0.18;
    canvas.drawPath(
      metric.extractPath(start, math.min(start + piece, metric.length)),
      line..color = stroke,
    );
    if (start + piece > metric.length) {
      canvas.drawPath(
        metric.extractPath(0, start + piece - metric.length),
        line,
      );
    }
  }

  @override
  bool shouldRepaint(_FigureEightPainter old) =>
      old.t != t || old.stroke != stroke || old.moving != moving;
}

/// The compass card (spec §4.7): it turns with the phone so north stays
/// north, with the Kaaba's square at the Qibla bearing on it. The notch at the
/// top is where the phone points; it never turns.
class _Dial extends StatelessWidget {
  const _Dial({
    required this.size,
    required this.bearing,
    required this.dialTurns,
    required this.aligned,
  });

  final double size;
  final double bearing;
  final double dialTurns;
  final bool aligned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final still = MediaQuery.disableAnimationsOf(context);
    return SizedBox.square(
      dimension: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: dialTurns),
        duration: still ? Duration.zero : const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        builder: (context, turns, _) => CustomPaint(
          painter: _DialPainter(
            rotation: turns * 2 * math.pi,
            bearing: bearing,
            aligned: aligned,
            ring: s.divider,
            ink: s.onSurface,
            muted: s.onSurfaceMuted,
            mark: s.accent,
            labels: [
              l10n.compassNorth,
              l10n.compassEast,
              l10n.compassSouth,
              l10n.compassWest,
            ],
            labelStyle: type.meta,
            textDirection: Directionality.of(context),
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.rotation,
    required this.bearing,
    required this.aligned,
    required this.ring,
    required this.ink,
    required this.muted,
    required this.mark,
    required this.labels,
    required this.labelStyle,
    required this.textDirection,
  });

  /// The dial's turn in radians, clockwise.
  final double rotation;
  final double bearing;
  final bool aligned;
  final Color ring;
  final Color ink;
  final Color muted;
  final Color mark;

  /// N, E, S, W.
  final List<String> labels;
  final TextStyle labelStyle;
  final TextDirection textDirection;

  Offset _at(Offset c, double radius, double radians) =>
      c + Offset(math.sin(radians) * radius, -math.cos(radians) * radius);

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 14;

    if (aligned) {
      canvas.drawCircle(
        c,
        r + 8,
        Paint()
          ..color = mark.withValues(alpha: 0.16)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = aligned ? mark : ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = aligned ? 4 : 1.5,
    );

    // 36 ticks, every third longer.
    final tick = Paint()
      ..color = muted
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 36; i++) {
      final major = i % 3 == 0;
      tick.strokeWidth = major ? 2 : 1.2;
      final a = rotation + i * 10 * math.pi / 180;
      canvas.drawLine(_at(c, r - (major ? 16 : 10), a), _at(c, r - 4, a), tick);
    }

    // N, E, S, W stay upright as the dial turns; N is bold.
    for (var i = 0; i < 4; i++) {
      final painter = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: labelStyle.copyWith(
            fontSize: i == 0 ? 16 : 14,
            fontWeight: i == 0 ? FontWeight.w700 : FontWeight.w500,
            color: i == 0 ? ink : muted,
          ),
        ),
        textDirection: textDirection,
      )..layout();
      final at = _at(c, r - 32, rotation + i * math.pi / 2);
      painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
    }

    // The line to the Kaaba's small square, at the Qibla bearing.
    final a = rotation + bearing * math.pi / 180;
    final square = _at(c, r - 54, a);
    canvas.drawLine(
      c,
      square,
      Paint()
        ..color = mark
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
    canvas.save();
    canvas.translate(square.dx, square.dy);
    canvas.rotate(a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 16),
        const Radius.circular(3),
      ),
      Paint()..color = mark,
    );
    canvas.restore();
    canvas.drawCircle(c, 4, Paint()..color = ink);

    // The phone's forward notch, fixed at the top.
    final notch = Path()
      ..moveTo(c.dx, c.dy - r + 2)
      ..lineTo(c.dx - 8, c.dy - r - 12)
      ..lineTo(c.dx + 8, c.dy - r - 12)
      ..close();
    canvas.drawPath(notch, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.rotation != rotation ||
      old.bearing != bearing ||
      old.aligned != aligned ||
      old.ring != ring ||
      old.ink != ink ||
      old.mark != mark ||
      old.labels[0] != labels[0];
}

class _NeedsPlace extends StatelessWidget {
  const _NeedsPlace();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.tabQibla,
      onTab: true,
      children: [
        SettingsHeading(l10n.qiblaNeedsPlaceTitle, top: 4),
        SettingsNote(l10n.qiblaNeedsPlaceBody, top: 0),
        const SizedBox(height: 14),
        SettingsButton(
          label: l10n.todayChoosePlace,
          filled: true,
          onPressed: () => showLocationSheet(context),
        ),
      ],
    );
  }
}
