import 'dart:async';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/flight_gps.dart';
import '../../data/settings_repository.dart';
import '../../domain/in_flight.dart';
import '../../domain/notification_plan.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_calculator.dart';
import '../../domain/qibla.dart' as qibla;
import '../../domain/time_model.dart';
import '../../domain/zone_lookup.dart';
import '../../domain/zone_offsets.dart';
import '../location/place_copy.dart';
import '../components/app_widgets.dart';
import 'in_flight_help_page.dart';

Future<void> openInFlight(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const InFlightPage()));

/// A fix older than this counts as lost; the last one is still shown.
const _lostAfter = Duration(minutes: 2);

/// How long after the last fix the regular notifications stay held.
const _holdAfterFix = Duration(minutes: 90);

/// Projects along the route off the UI thread; overridden in tests to run
/// inline.
typedef RouteProjector = Future<List<ProjectedPrayer>> Function(
  PrayerTimesCalculator calculator,
  InFlightFix fix,
  DateTime now,
);

final routeProjectorProvider = Provider<RouteProjector>(
  (ref) =>
      (calculator, fix, now) => Isolate.run(
        () => projectAlongRoute(calculator: calculator, fix: fix, now: now),
      ),
);

/// In-flight mode, phase 1 (docs/in-flight-mode.md): where the aircraft is from
/// GPS, the prayer times there as seen from the aircraft, and the Qibla
/// relative to its nose. GPS runs only while this screen is open.
class InFlightPage extends ConsumerStatefulWidget {
  const InFlightPage({super.key});

  @override
  ConsumerState<InFlightPage> createState() => _InFlightPageState();
}

enum _Stage { explain, starting, live, failed }

class _InFlightPageState extends ConsumerState<InFlightPage> {
  _Stage _stage = _Stage.explain;
  FlightGpsFailure? _failure;
  StreamSubscription<InFlightFix>? _sub;
  InFlightFix? _fix;

  /// A heading typed in from the seat-back map; overrides the GPS course.
  double? _manualHeading;

  /// The prayers the aircraft is expected to meet, from the latest fix.
  List<ProjectedPrayer> _route = const [];
  int _routeRun = 0;

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    setState(() => _stage = _Stage.starting);
    final gps = ref.read(flightGpsProvider);
    final failure = await gps.prepare();
    if (!mounted) return;
    if (failure != null) {
      setState(() {
        _stage = _Stage.failed;
        _failure = failure;
      });
      return;
    }
    await _sub?.cancel();
    _sub = gps.fixes().listen((fix) {
      if (!mounted) return;
      setState(() => _fix = fix);
      unawaited(_onFix(fix));
    });
    setState(() => _stage = _Stage.live);
  }

  /// The calculator for [fix]'s position and zone, with the user's settings.
  ({PrayerTimesCalculator calculator, ZoneOffsets zone}) _calculatorFor(
    InFlightFix fix,
    AppSettingsSnapshot settings,
  ) {
    // The zone where the aircraft is, from the bundled map; never the phone's.
    final zoneName =
        zoneAt(latitude: fix.latitude, longitude: fix.longitude) ?? 'UTC';
    final zone = zoneOffsetsFor(zoneName);
    return (
      calculator: PrayerTimesCalculator(
        latitude: fix.latitude,
        longitude: fix.longitude,
        zone: zone,
        method: settings.calculationMethod.resolvedFor(zoneName),
        madhab: settings.madhab,
        highLatitudeRule: settings.highLatitudeRule,
        minuteOffsets: settings.minuteOffsets,
        customAngles: settings.customAngles,
        hijriAdjustDays: settings.hijriAdjustDays,
      ),
      zone: zone,
    );
  }

  /// Each fix: project along the route (off the UI thread), then keep the
  /// notification hold current (docs/in-flight-mode.md, phase 2).
  Future<void> _onFix(InFlightFix fix) async {
    final run = ++_routeRun;
    final settings =
        ref.read(appSettingsProvider).value ?? SettingsRepository.defaults;
    final now = ref.read(appClockProvider).nowUtc();
    final (:calculator, :zone) = _calculatorFor(fix, settings);
    final route = fix.hasCourse
        ? await ref.read(routeProjectorProvider)(calculator, fix, now)
        : const <ProjectedPrayer>[];
    if (!mounted || run != _routeRun) return;
    setState(() => _route = route);

    // Regular alerts are held only while the aircraft is moving: at home or
    // at the gate they are already for where the user is.
    if (!fix.hasCourse) return;

    // The next prayer along the route.
    final here = inFlightTimes(
      calculator: calculator,
      zone: zone,
      fix: fix,
      now: now,
    );
    final next = route.isNotEmpty
        ? (prayer: route.first.prayer, at: route.first.at)
        : (prayer: here.next, at: here.nextAt);
    final wanted = InFlightHold(
      pausedUntil: fix.at.add(_holdAfterFix),
      prayer: next.prayer,
      at: next.at,
    );
    final current = settings.inFlight;
    // Written only when it matters, so the notifications are not rebuilt on
    // every fix.
    final stale =
        current == null ||
        wanted.pausedUntil.difference(current.pausedUntil) >=
            const Duration(minutes: 15) ||
        current.prayer != wanted.prayer ||
        (current.at == null) != (wanted.at == null) ||
        (current.at != null &&
            wanted.at != null &&
            current.at!.difference(wanted.at!).abs() >=
                const Duration(minutes: 2));
    // Checked again: "End in-flight mode" may have been tapped meanwhile,
    // and must not be undone by a projection that was already running.
    if (stale && mounted && run == _routeRun) {
      await ref.read(settingsRepositoryProvider).saveInFlight(wanted);
    }
  }

  Future<void> _end() async {
    _routeRun++; // discards any projection still running
    // The hold is cleared first, so ending takes effect at once; the GPS
    // stops alongside.
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    await ref.read(settingsRepositoryProvider).saveInFlight(null);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _enterHeading() async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(
      text: _manualHeading?.round().toString() ?? '',
    );
    final value = await showDialog<double>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialog) {
          final parsed = int.tryParse(controller.text.trim());
          final valid = parsed != null && parsed >= 0 && parsed <= 359;
          return AlertDialog(
            title: Text(l10n.inFlightEnterHeading),
            content: TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: l10n.inFlightHeadingLabel,
                errorText: controller.text.isEmpty || valid
                    ? null
                    : l10n.inFlightHeadingError,
              ),
              onChanged: (_) => setDialog(() {}),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: valid
                    ? () => Navigator.of(dialogContext).pop(parsed.toDouble())
                    : null,
                child: Text(l10n.save),
              ),
            ],
          );
        },
      ),
    );
    if (value != null && mounted) setState(() => _manualHeading = value);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);

    final body = switch (_stage) {
      _Stage.explain || _Stage.starting => [
        AppPrompt(
          children: [
            Text(l10n.inFlightExplainBody, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpace.md),
            FilledButton(
              onPressed: _stage == _Stage.starting ? null : _start,
              child: Text(l10n.inFlightStart),
            ),
          ],
        ),
      ],
      _Stage.failed => [
        AppPrompt(
          children: [
            Text(switch (_failure!) {
              FlightGpsFailure.serviceDisabled => l10n.inFlightServiceOff,
              FlightGpsFailure.needsPrecise => l10n.inFlightNeedsPrecise,
              FlightGpsFailure.permanentlyDenied =>
                l10n.inFlightPermanentlyDenied,
            }, style: theme.textTheme.bodyMedium),
            const SizedBox(height: AppSpace.md),
            Wrap(
              spacing: AppSpace.sm,
              children: [
                FilledButton(
                  onPressed: _start,
                  child: Text(l10n.inFlightTryAgain),
                ),
                if (_failure == FlightGpsFailure.permanentlyDenied)
                  OutlinedButton(
                    onPressed: () => ref.read(flightGpsProvider).openSettings(),
                    child: Text(l10n.inFlightOpenSettings),
                  ),
              ],
            ),
          ],
        ),
      ],
      _Stage.live when _fix == null => [
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                l10n.inFlightWaiting,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ],
      _Stage.live => _live(context, _fix!),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.inFlightTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: l10n.inFlightHelp,
            onPressed: () => openInFlightHelp(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          ...body,
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.inFlightCompassNote,
            style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
          ),
        ],
      ),
    );
  }

  List<Widget> _live(BuildContext context, InFlightFix fix) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final now = ref.watch(minuteClockProvider);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final clock = ClockFormat.of(context);

    final (:calculator, :zone) = _calculatorFor(fix, settings);
    final times = inFlightTimes(
      calculator: calculator,
      zone: zone,
      fix: fix,
      now: now,
    );

    String onPhone(DateTime utc) {
      final local = utc.toLocal();
      return clock.time(LocalTime.of(local.hour, local.minute));
    }

    String countdown(DateTime at) {
      final minutes = math.max(0, at.difference(now).inMinutes);
      return minutes >= 60
          ? l10n.countdownHours(minutes ~/ 60, minutes % 60)
          : l10n.countdownMinutes(minutes);
    }

    final lost = now.difference(fix.at) > _lostAfter;
    final heading =
        _manualHeading ?? (fix.hasCourse ? fix.courseDegrees : null);
    final bearing = qibla.qiblaBearingRounded(
      latitude: fix.latitude,
      longitude: fix.longitude,
    );
    final fromNose = heading == null
        ? null
        : qiblaFromNose(
            latitude: fix.latitude,
            longitude: fix.longitude,
            heading: heading,
          );
    final sunset = times.sunsetShift?.inMinutes ?? 0;
    final sunrise = times.sunriseShift?.inMinutes ?? 0;
    final muted = theme.textTheme.bodySmall?.copyWith(color: ink.muted);

    return [
      const SizedBox(height: AppSpace.md),
      Text(
        lost
            ? l10n.inFlightFixLost(agoLabel(l10n, fix.at, now))
            : l10n.inFlightFixAge(agoLabel(l10n, fix.at, now)),
        style: muted,
      ),
      Text(
        l10n.inFlightAltitudeSpeed(
          '${math.max(0, fix.altitudeMeters).round()}',
          '${((fix.speedMetersPerSecond ?? 0) * 3.6).round()}',
        ),
        style: muted,
      ),
      const SizedBox(height: AppSpace.lg),
      Text(
        times.current == null
            ? l10n.inFlightNoneNow
            : l10n.inFlightNow(prayerName(l10n, times.current!)),
        style: theme.textTheme.titleMedium,
      ),
      if (times.next != null) ...[
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.inFlightNext(
            prayerName(l10n, times.next!),
            countdown(times.nextAt!),
          ),
          style: theme.textTheme.headlineSmall,
        ),
        Text(l10n.inFlightOnPhone(onPhone(times.nextAt!)), style: muted),
      ],
      if (_route.isNotEmpty) ...[
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.inFlightAlongRoute(
            prayerName(l10n, _route.first.prayer),
            countdown(_route.first.at),
          ),
          style: theme.textTheme.titleMedium,
        ),
        Text(l10n.inFlightAboutOnPhone(onPhone(_route.first.at)), style: muted),
        for (final later in _route.skip(1))
          Text(
            l10n.inFlightAlongRouteThen(
              prayerName(l10n, later.prayer),
              onPhone(later.at),
            ),
            style: muted,
          ),
        Text(l10n.inFlightAssumesCourse, style: muted),
      ],
      if (settings.inFlight case final hold? when hold.activeAt(now)) ...[
        const SizedBox(height: AppSpace.md),
        Text(
          l10n.inFlightAlertsHeld(switch (ref.watch(currentPlaceProvider)) {
            final p? => placeLabel(l10n, p),
            null => l10n.locationCurrentPlace,
          }, onPhone(hold.pausedUntil)),
          style: muted,
        ),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: _end, child: Text(l10n.inFlightEnd)),
        ),
      ],
      if (sunset > 0) ...[
        const SizedBox(height: AppSpace.sm),
        Text(l10n.inFlightSunsetLater(sunset), style: muted),
      ],
      if (sunrise > 0) Text(l10n.inFlightSunriseEarlier(sunrise), style: muted),
      const SizedBox(height: AppSpace.sm),
      Text(l10n.inFlightMovingNote, style: muted),
      AppSectionHeader(l10n.inFlightTimesHeader),
      AppRows(
        children: [
          for (final prayer in Prayer.adhanPrayers)
            if (times.times[prayer] case final at?)
              AppRow(
                leading: null,
                muted: prayer == Prayer.sunrise,
                title: Text(prayerName(l10n, prayer)),
                trailing: Text(onPhone(at)),
              ),
        ],
      ),
      AppSectionHeader(l10n.inFlightQiblaHeader),
      Center(
        child: Semantics(
          label: l10n.inFlightDiagramLabel,
          child: _AircraftDiagram(fromNose: fromNose),
        ),
      ),
      const SizedBox(height: AppSpace.md),
      if (fromNose != null)
        Text(
          switch (fromNose.round()) {
            final d when d.abs() <= 3 => l10n.inFlightQiblaAhead,
            final d when d.abs() >= 177 => l10n.inFlightQiblaBehind,
            final d when d > 0 => l10n.inFlightQiblaRight('$d'),
            final d => l10n.inFlightQiblaLeft('${-d}'),
          },
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
      Text(
        heading == null
            ? l10n.inFlightNoCourse
            : _manualHeading != null
            ? l10n.inFlightHeadingManual('${_manualHeading!.round()}')
            : l10n.inFlightHeadingGps('${heading.round()}'),
        style: muted,
        textAlign: TextAlign.center,
      ),
      Text(
        l10n.inFlightQiblaBearing('$bearing'),
        style: muted,
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: AppSpace.sm),
      Wrap(
        alignment: WrapAlignment.center,
        spacing: AppSpace.sm,
        children: [
          OutlinedButton(
            onPressed: _enterHeading,
            child: Text(l10n.inFlightEnterHeading),
          ),
          if (_manualHeading != null)
            TextButton(
              onPressed: () => setState(() => _manualHeading = null),
              child: Text(l10n.inFlightUseGps),
            ),
        ],
      ),
    ];
  }
}

/// An aircraft seen from above, nose up, with an arrow from its centre
/// towards the Qibla. No arrow until there is a heading to measure from.
class _AircraftDiagram extends StatelessWidget {
  const _AircraftDiagram({required this.fromNose});

  final double? fromNose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: const Size.square(200),
      painter: _AircraftPainter(
        fromNose: fromNose,
        body: AppInk.of(context).muted,
        arrow: scheme.primary,
        // Left and right are the aircraft's, whatever the reading direction.
        textDirection: TextDirection.ltr,
      ),
    );
  }
}

class _AircraftPainter extends CustomPainter {
  _AircraftPainter({
    required this.fromNose,
    required this.body,
    required this.arrow,
    required this.textDirection,
  });

  final double? fromNose;
  final Color body;
  final Color arrow;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final s = size.width / 200;
    final fill = Paint()..color = body.withValues(alpha: 0.35);
    // Fuselage, wings and tail, nose up.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 18 * s, height: 150 * s),
        Radius.circular(9 * s),
      ),
      fill,
    );
    final wing = Path()
      ..moveTo(c.dx, c.dy - 18 * s)
      ..lineTo(c.dx + 80 * s, c.dy + 12 * s)
      ..lineTo(c.dx + 80 * s, c.dy + 22 * s)
      ..lineTo(c.dx, c.dy + 8 * s)
      ..lineTo(c.dx - 80 * s, c.dy + 22 * s)
      ..lineTo(c.dx - 80 * s, c.dy + 12 * s)
      ..close();
    canvas.drawPath(wing, fill);
    final tail = Path()
      ..moveTo(c.dx, c.dy + 50 * s)
      ..lineTo(c.dx + 30 * s, c.dy + 68 * s)
      ..lineTo(c.dx + 30 * s, c.dy + 74 * s)
      ..lineTo(c.dx, c.dy + 64 * s)
      ..lineTo(c.dx - 30 * s, c.dy + 74 * s)
      ..lineTo(c.dx - 30 * s, c.dy + 68 * s)
      ..close();
    canvas.drawPath(tail, fill);

    final angle = fromNose;
    if (angle == null) return;
    final a = angle * math.pi / 180;
    final r = 92 * s;
    final tip = c + Offset(math.sin(a) * r, -math.cos(a) * r);
    final paint = Paint()
      ..color = arrow
      ..strokeWidth = 4 * s
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(c, tip, paint);
    final head = 12 * s;
    for (final side in [-1, 1]) {
      final back = a + math.pi + side * 0.45;
      canvas.drawLine(
        tip,
        tip + Offset(math.sin(back) * head, -math.cos(back) * head),
        paint,
      );
    }
    canvas.drawCircle(c, 5 * s, Paint()..color = arrow);
  }

  @override
  bool shouldRepaint(_AircraftPainter old) =>
      old.fromNose != fromNose || old.body != body || old.arrow != arrow;
}
