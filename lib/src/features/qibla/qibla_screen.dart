import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../app/compass.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/place.dart';
import '../../domain/qibla.dart' as qibla;
import '../components/app_widgets.dart';
import '../location/location_sheet.dart';
import '../location/place_copy.dart';

/// The Qibla: a supporting feature, never dominant (AGENTS.md).
///
/// The bearing is worked out on the device from the saved place, so it is
/// always shown, compass or not. With a compass the dial turns with the phone,
/// corrected from magnetic to true north; without one, the bearing stands on
/// its own with a line on how to use it.
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
    setState(() {
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
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
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
    final aligned = turn != null && turn.abs() <= 3;

    final distance =
        NumberFormat.decimalPattern(
          Localizations.localeOf(context).toLanguageTag(),
        ).format(
          qibla
              .distanceKm(latitude: place.latitude, longitude: place.longitude)
              .round(),
        );
    final placeName = placeLabel(l10n, place);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.lg,
        AppSpace.xxl,
        AppSpace.xxl,
      ),
      children: [
        Text(l10n.tabQibla, style: theme.textTheme.headlineLarge),
        Text(
          l10n.qiblaFrom(placeName),
          style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
        ),
        if (_noCompass)
          AppPrompt(
            children: [
              Text(
                l10n.qiblaNoCompassTitle,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.qiblaDegrees('$bearing'),
                style: theme.textTheme.displayMedium,
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                l10n.qiblaNoCompassBody('$bearing', placeName),
                style: theme.textTheme.bodyMedium,
              ),
            ],
          )
        else ...[
          const SizedBox(height: AppSpace.lg),
          Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = math.min(constraints.maxWidth, 300.0);
                return Semantics(
                  label: l10n.qiblaDialLabel('$bearing'),
                  excludeSemantics: true,
                  child: _Dial(
                    size: size,
                    bearing: bearing.toDouble(),
                    dialTurns: _dialTurns,
                    aligned: aligned,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpace.lg),
          Center(
            child: Text(
              l10n.qiblaDegrees('$bearing'),
              style: theme.textTheme.displayMedium,
            ),
          ),
          Center(
            child: Text(
              switch (turn) {
                null => l10n.qiblaFromNorth('$bearing'),
                _ when aligned => l10n.qiblaAligned,
                final t when t > 0 => l10n.qiblaTurnRight('$t'),
                final t => l10n.qiblaTurnLeft('${-t}'),
              },
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: aligned ? theme.colorScheme.primary : null,
              ),
            ),
          ),
          if (reading?.needsCalibration ?? false) ...[
            const SizedBox(height: AppSpace.md),
            _CalibrationNote(onHow: () => _showCalibration(context)),
          ],
        ],
        const SizedBox(height: AppSpace.lg),
        Text(l10n.qiblaDistance(distance), style: theme.textTheme.bodyMedium),
        if (!_noCompass) ...[
          const SizedBox(height: AppSpace.xs),
          Text(
            l10n.qiblaHoldFlat,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            _declination == null
                ? l10n.qiblaMagneticNote
                : l10n.qiblaDeclinationNote(
                    _declination!.abs().toStringAsFixed(1),
                  ),
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => _showCalibration(context),
              child: Text(l10n.qiblaCalibrate),
            ),
          ),
        ],
      ],
    );
  }
}

/// Degrees to add to [from] to reach [to] the short way: within ±180.
double _shortest(double from, double to) {
  final d = ((to - from) % 360 + 360) % 360;
  return d > 180 ? d - 360 : d;
}

Future<void> _showCalibration(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.qiblaCalibrateTitle,
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              l10n.qiblaCalibrateBody,
              style: Theme.of(sheetContext).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpace.lg),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(l10n.qiblaCalibrateDone),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CalibrationNote extends StatelessWidget {
  const _CalibrationNote({required this.onHow});

  final VoidCallback onHow;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.explore_off_outlined, color: AppInk.of(context).muted),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            l10n.qiblaNeedsCalibration,
            style: theme.textTheme.bodyMedium,
          ),
        ),
        TextButton(onPressed: onHow, child: Text(l10n.qiblaCalibrate)),
      ],
    );
  }
}

/// The compass card: it turns with the phone so north stays north, and the
/// Qibla mark sits at its bearing on it. The pointer at the top is where the
/// phone points.
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
    final scheme = Theme.of(context).colorScheme;
    final ink = AppInk.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final colors = _DialColors(
      face: aligned ? ink.sage : scheme.surface,
      line: scheme.outlineVariant,
      ink: scheme.onSurface,
      muted: ink.muted,
      mark: scheme.primary,
      onMark: scheme.onPrimary,
    );

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedRotation(
            turns: dialTurns,
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 200),
            child: CustomPaint(
              size: Size.square(size),
              painter: _DialPainter(
                bearing: bearing,
                colors: colors,
                textDirection: Directionality.of(context),
              ),
            ),
          ),
          Positioned(
            top: 0,
            child: CustomPaint(
              size: const Size(20, 16),
              painter: _PointerPainter(scheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialColors {
  const _DialColors({
    required this.face,
    required this.line,
    required this.ink,
    required this.muted,
    required this.mark,
    required this.onMark,
  });

  final Color face;
  final Color line;
  final Color ink;
  final Color muted;
  final Color mark;
  final Color onMark;
}

class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.bearing,
    required this.colors,
    required this.textDirection,
  });

  final double bearing;
  final _DialColors colors;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;

    canvas.drawCircle(c, r, Paint()..color = colors.face);
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = colors.line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tick = Paint()
      ..color = colors.muted
      ..strokeCap = StrokeCap.round;
    for (var deg = 0; deg < 360; deg += 10) {
      final major = deg % 90 == 0;
      tick.strokeWidth = major ? 2 : 1;
      final a = _radians(deg.toDouble());
      final outer = r - 6;
      final inner = r - (major ? 18 : 12);
      canvas.drawLine(
        c + Offset(math.sin(a) * inner, -math.cos(a) * inner),
        c + Offset(math.sin(a) * outer, -math.cos(a) * outer),
        tick,
      );
    }

    _label(canvas, c, r - 36, 0, 'N', colors.ink, 16, FontWeight.w700);
    _label(canvas, c, r - 36, 180, 'S', colors.muted, 14, FontWeight.w400);

    // The Qibla mark: a filled disc at the bearing, with a small square.
    final a = _radians(bearing);
    final markR = r - 52;
    final at = c + Offset(math.sin(a) * markR, -math.cos(a) * markR);
    canvas.drawLine(
      c,
      at,
      Paint()
        ..color = colors.mark.withValues(alpha: 0.35)
        ..strokeWidth = 2,
    );
    canvas.drawCircle(at, 16, Paint()..color = colors.mark);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: at, width: 14, height: 14),
        const Radius.circular(2),
      ),
      Paint()..color = colors.onMark,
    );
    canvas.drawCircle(c, 4, Paint()..color = colors.muted);
  }

  void _label(
    Canvas canvas,
    Offset c,
    double radius,
    double deg,
    String text,
    Color color,
    double fontSize,
    FontWeight weight,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: fontSize, fontWeight: weight),
      ),
      textDirection: textDirection,
    )..layout();
    final a = _radians(deg);
    final at = c + Offset(math.sin(a) * radius, -math.cos(a) * radius);
    painter.paint(canvas, at - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.bearing != bearing ||
      old.colors.face != colors.face ||
      old.colors.mark != colors.mark ||
      old.colors.ink != colors.ink;
}

class _PointerPainter extends CustomPainter {
  _PointerPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..lineTo(0, 0)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.color != color;
}

double _radians(double degrees) => degrees * math.pi / 180;

class _NeedsPlace extends StatelessWidget {
  const _NeedsPlace();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      children: [
        const SizedBox(height: AppSpace.xxl),
        AppPrompt(
          children: [
            Text(l10n.qiblaNeedsPlaceTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpace.sm),
            Text(l10n.qiblaNeedsPlaceBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              onPressed: () => showLocationSheet(context),
              child: Text(l10n.todayChoosePlace),
            ),
          ],
        ),
      ],
    );
  }
}
