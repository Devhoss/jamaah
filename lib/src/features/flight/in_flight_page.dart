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
import '../../app/theme/horizon_tokens.dart';
import '../../data/flight_gps.dart';
import '../../data/settings_repository.dart';
import '../../domain/in_flight.dart';
import '../../domain/notification_plan.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_calculator.dart';
import '../../domain/qibla.dart' as qibla;
import '../../domain/qibla_words.dart';
import '../../domain/sky/sky_model.dart';
import '../../domain/time_model.dart';
import '../../domain/zone_lookup.dart';
import '../../domain/zone_offsets.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';
import '../location/place_copy.dart';
import '../settings/settings_kit.dart';
import '../sky/sky_page.dart';
import '../sky/sky_palette.dart';
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
    final value = await showSettingsSheet<double>(
      context,
      builder: (_) => _HeadingSheet(initial: _manualHeading),
    );
    if (value != null && mounted) setState(() => _manualHeading = value);
  }

  void _cancel() {
    _routeRun++;
    final sub = _sub;
    _sub = null;
    unawaited(sub?.cancel());
    setState(() {
      _stage = _Stage.explain;
      _fix = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final fix = _fix;
    final now = ref.watch(minuteClockProvider);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;

    // The sky outside the aircraft, at its position (spec §4.8), once there
    // is a fix; until then the place's own.
    _Aboard? aboard;
    if (_stage == _Stage.live && fix != null) {
      final (:calculator, :zone) = _calculatorFor(fix, settings);
      final times = inFlightTimes(
        calculator: calculator,
        zone: zone,
        fix: fix,
        now: now,
      );
      final offset = zone.offsetMinutesAt(now.toUtc());
      int local(DateTime utc) {
        final l = utc.toUtc().add(Duration(minutes: offset));
        return l.hour * 60 + l.minute;
      }

      int? at(Prayer p) => switch (times.times[p]) {
        final t? => local(t),
        null => null,
      };
      final model = SkyModel.anchored(
        fajr: at(Prayer.fajr),
        sunrise: at(Prayer.sunrise),
        dhuhr: at(Prayer.dhuhr),
        asr: at(Prayer.asr),
        sunset: at(Prayer.maghrib),
        isha: at(Prayer.isha),
      );
      aboard = _Aboard(
        times: times,
        offsetMinutes: offset,
        localMinute: local(now),
        sky: model.frameAt(local(now).toDouble(), dark: dark),
      );
    }

    final (title, lead) = switch (_stage) {
      _Stage.explain ||
      _Stage.starting ||
      _Stage.failed => (l10n.inFlightStartTitle, l10n.inFlightStartLead),
      _Stage.live when fix == null => (
        l10n.inFlightLookingTitle,
        l10n.inFlightKeepLooking,
      ),
      _Stage.live => (
        l10n.inFlightTitle,
        l10n.inFlightAircraftTime(
          ClockFormat.of(context).time(LocalTime(aboard?.localMinute ?? 0)),
          'UTC${utcOffsetLabel(aboard?.offsetMinutes ?? 0)}',
        ),
      ),
    };

    final body = switch (_stage) {
      _Stage.explain || _Stage.starting => _explain(context),
      _Stage.failed => _failed(context),
      _Stage.live when fix == null => _waiting(context),
      _Stage.live => _live(context, fix!, aboard!),
    };

    return Scaffold(
      body: SkyPage(
        sky: aboard?.sky,
        header: (context, p) => _Header(palette: p, title: title, lead: lead),
        panel: [
          ...body,
          const SizedBox(height: 18),
          SettingsNote(l10n.inFlightCompassNote, top: 0),
        ],
      ),
    );
  }

  List<Widget> _explain(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = HorizonTheme.of(context).surfaces;
    return [
      const SizedBox(height: 8),
      ExcludeSemantics(
        child: SizedBox(
          height: 72,
          child: CustomPaint(
            painter: _RoutePainter(line: s.divider, plane: s.onSurface),
          ),
        ),
      ),
      const SizedBox(height: 10),
      SettingsNote(l10n.inFlightExplainBody, top: 0),
      const SizedBox(height: 16),
      SizedBox(
        width: double.infinity,
        child: PillButton(
          label: l10n.inFlightStart,
          icon: LineIcons.pin,
          filled: true,
          ink: s.accent,
          onInk: s.onAccent,
          line: s.divider,
          onPressed: _stage == _Stage.starting ? null : _start,
        ),
      ),
      const SizedBox(height: 10),
      SettingsNote(l10n.inFlightWindowNote, top: 0),
    ];
  }

  List<Widget> _failed(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return [
      Semantics(
        liveRegion: true,
        child: SettingsNote(switch (_failure!) {
          FlightGpsFailure.serviceDisabled => l10n.inFlightServiceOff,
          FlightGpsFailure.needsPrecise => l10n.inFlightNeedsPrecise,
          FlightGpsFailure.permanentlyDenied => l10n.inFlightPermanentlyDenied,
        }, top: 4),
      ),
      const SizedBox(height: 14),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          SettingsButton(
            label: l10n.inFlightTryAgain,
            filled: true,
            onPressed: _start,
          ),
          if (_failure == FlightGpsFailure.permanentlyDenied)
            SettingsButton(
              label: l10n.inFlightOpenSettings,
              onPressed: () => ref.read(flightGpsProvider).openSettings(),
            ),
        ],
      ),
    ];
  }

  List<Widget> _waiting(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return [
      const SizedBox(height: 8),
      const Center(child: _Rings(size: 120)),
      const SizedBox(height: 14),
      Semantics(
        liveRegion: true,
        child: Text(
          l10n.inFlightWaiting,
          textAlign: TextAlign.center,
          style: type.row.copyWith(color: s.onSurface),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: SettingsButton(label: l10n.cancel, onPressed: _cancel),
      ),
    ];
  }

  List<Widget> _live(BuildContext context, InFlightFix fix, _Aboard aboard) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final now = ref.watch(minuteClockProvider);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final clock = ClockFormat.of(context);
    final times = aboard.times;

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
    final muted = type.meta.copyWith(height: 1.45, color: s.onSurfaceMuted);
    final clockwise = fromNose == null
        ? null
        : (fromNose.round() % 360 + 360) % 360;

    return [
      // Where the aircraft is, and how fresh the fix is.
      Text(
        positionLabel(l10n, fix.latitude, fix.longitude),
        style: type.row.copyWith(
          color: s.onSurface,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
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
      const SizedBox(height: 16),
      // Now and Next, side by side when they fit.
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: s.well,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              times.current == null
                  ? l10n.inFlightNoneNow
                  : l10n.inFlightNow(prayerName(l10n, times.current!)),
              style: type.prayerName.copyWith(fontSize: 24, color: s.onSurface),
            ),
            if (times.next != null) ...[
              const SizedBox(height: 6),
              Text(
                l10n.inFlightNext(
                  prayerName(l10n, times.next!),
                  countdown(times.nextAt!),
                ),
                style: type.row.copyWith(color: s.onSurface),
              ),
              Text(l10n.inFlightOnPhone(onPhone(times.nextAt!)), style: muted),
            ],
          ],
        ),
      ),
      if (_route.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 22, 0, 6),
          child: Row(
            children: [
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    l10n.inFlightAlongTitle,
                    style: type.section.copyWith(color: s.onSurface),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              _Tag(label: l10n.inFlightEstimates),
            ],
          ),
        ),
        Text(
          l10n.inFlightAlongRoute(
            prayerName(l10n, _route.first.prayer),
            countdown(_route.first.at),
          ),
          style: type.row.copyWith(color: s.onSurface),
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
        const SizedBox(height: 4),
        Text(l10n.inFlightAssumesCourse, style: muted),
      ],
      if (settings.inFlight case final hold? when hold.activeAt(now)) ...[
        const SizedBox(height: 14),
        Text(
          l10n.inFlightAlertsHeld(switch (ref.watch(currentPlaceProvider)) {
            final p? => placeLabel(l10n, p),
            null => l10n.locationCurrentPlace,
          }, onPhone(hold.pausedUntil)),
          style: muted,
        ),
        const SizedBox(height: 8),
        SettingsButton(label: l10n.inFlightEnd, onPressed: _end),
      ],
      if (sunset > 0 || sunrise > 0) const SizedBox(height: 10),
      if (sunset > 0) Text(l10n.inFlightSunsetLater(sunset), style: muted),
      if (sunrise > 0) Text(l10n.inFlightSunriseEarlier(sunrise), style: muted),
      const SizedBox(height: 6),
      Text(l10n.inFlightMovingNote, style: muted),
      SettingsHeading(l10n.inFlightTimesHeader),
      for (final (i, prayer) in Prayer.adhanPrayers.indexed)
        if (times.times[prayer] case final at?)
          DecoratedBox(
            decoration: BoxDecoration(
              border: i < Prayer.adhanPrayers.length - 1
                  ? Border(bottom: BorderSide(color: s.divider))
                  : null,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: MergeSemantics(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        prayerName(l10n, prayer),
                        style: type.row.copyWith(
                          color: prayer == Prayer.sunrise
                              ? s.onSurfaceMuted
                              : s.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      onPhone(at),
                      style: type.row.copyWith(
                        color: s.onSurface,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      SettingsHeading(l10n.inFlightQiblaHeader),
      Center(
        child: Semantics(
          label: l10n.inFlightDiagramLabel,
          child: _SeatRing(fromNose: fromNose),
        ),
      ),
      const SizedBox(height: 12),
      if (clockwise != null)
        Text(
          l10n.inFlightQiblaWords(
            qiblaDirectionText(l10n, QiblaDirection.fromRelative(fromNose!)),
            '$clockwise',
          ),
          textAlign: TextAlign.center,
          style: type.row.copyWith(color: s.onSurface),
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
      const SizedBox(height: 10),
      SettingsNote(l10n.inFlightHeadingHint, top: 0),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 8,
        children: [
          SettingsButton(
            label: l10n.inFlightEnterHeading,
            onPressed: _enterHeading,
          ),
          if (_manualHeading != null)
            SettingsButton(
              label: l10n.inFlightUseGps,
              onPressed: () => setState(() => _manualHeading = null),
            ),
        ],
      ),
    ];
  }
}

/// What the screen knows aboard: the times at the fix and the aircraft's own
/// clock there.
class _Aboard {
  const _Aboard({
    required this.times,
    required this.offsetMinutes,
    required this.localMinute,
    required this.sky,
  });

  final InFlightTimes times;
  final int offsetMinutes;
  final int localMinute;
  final SkyFrame sky;
}

/// "21.5° N · 62.0° E".
String positionLabel(AppLocalizations l10n, double lat, double lon) {
  String deg(double v) => v.abs().toStringAsFixed(1);
  return l10n.inFlightPosition(
    lat >= 0
        ? l10n.inFlightLatNorth(deg(lat))
        : l10n.inFlightLatSouth(deg(lat)),
    lon >= 0 ? l10n.inFlightLonEast(deg(lon)) : l10n.inFlightLonWest(deg(lon)),
  );
}

/// The eight words for where the Qibla is from the aircraft's nose.
String qiblaDirectionText(AppLocalizations l10n, QiblaDirection d) =>
    switch (d) {
      QiblaDirection.straightAhead => l10n.qiblaDirStraightAhead,
      QiblaDirection.aheadRight => l10n.qiblaDirAheadRight,
      QiblaDirection.right => l10n.qiblaDirRight,
      QiblaDirection.behindRight => l10n.qiblaDirBehindRight,
      QiblaDirection.behind => l10n.qiblaDirBehind,
      QiblaDirection.behindLeft => l10n.qiblaDirBehindLeft,
      QiblaDirection.left => l10n.qiblaDirLeft,
      QiblaDirection.aheadLeft => l10n.qiblaDirAheadLeft,
    };

/// Back, "How it works", the kicker, the title and one line, on the sky.
class _Header extends StatelessWidget {
  const _Header({
    required this.palette,
    required this.title,
    required this.lead,
  });

  final SkyPalette palette;
  final String title;
  final String lead;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 0),
          child: Row(
            children: [
              Semantics(
                button: true,
                label: l10n.settingsBack,
                excludeSemantics: true,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => Navigator.of(context).maybePop(),
                  child: SizedBox.square(
                    dimension: 48,
                    child: Center(
                      child: Transform.flip(
                        flipX: Directionality.of(context) == TextDirection.rtl,
                        child: LineIcon(LineIcons.back, size: 22, color: p.ink),
                      ),
                    ),
                  ),
                ),
              ),
              // At the end of the bar, and free to wrap at a large text size.
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: Tooltip(
                    message: l10n.inFlightHelp,
                    child: PillButton(
                      label: l10n.inFlightHelp,
                      ink: p.ink,
                      onInk: p.deep,
                      line: p.line,
                      onPressed: () => openInFlightHelp(context),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 6, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                arabic ? l10n.inFlightTitle : l10n.inFlightTitle.toUpperCase(),
                style: type.kicker.copyWith(color: p.mute),
              ),
              const SizedBox(height: 4),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: type.display.copyWith(fontSize: 34, color: p.ink),
                ),
              ),
              const SizedBox(height: 6),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Text(
                  lead,
                  style: type.body.copyWith(fontSize: 14, color: p.mute),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: s.onSurfaceMuted),
      ),
      child: Text(
        label,
        style: type.meta.copyWith(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: s.onSurface,
        ),
      ),
    );
  }
}

/// A plane on a dotted route.
class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.line, required this.plane});

  final Color line;
  final Color plane;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = Paint()..color = line;
    final y = size.height * 0.62;
    final path = Path()
      ..moveTo(8, y + 10)
      ..quadraticBezierTo(size.width / 2, -6, size.width - 8, y + 10);
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        final t = metric.getTangentForOffset(d);
        if (t != null) canvas.drawCircle(t.position, 1.6, dot);
      }
      final at = metric.getTangentForOffset(metric.length * 0.58);
      if (at == null) continue;
      canvas.save();
      canvas.translate(at.position.dx, at.position.dy);
      canvas.rotate(-at.angle + math.pi / 2);
      canvas.scale(1.1);
      canvas.translate(-12, -12);
      final p = Paint()
        ..color = plane
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;
      // Lucide's plane, nose up.
      canvas.drawPath(
        Path()
          ..moveTo(12, 2)
          ..lineTo(13.5, 8.5)
          ..lineTo(21, 13)
          ..lineTo(21, 15)
          ..lineTo(13.5, 13)
          ..lineTo(13, 19)
          ..lineTo(15.5, 21)
          ..lineTo(8.5, 21)
          ..lineTo(11, 19)
          ..lineTo(10.5, 13)
          ..lineTo(3, 15)
          ..lineTo(3, 13)
          ..lineTo(10.5, 8.5)
          ..close(),
        p,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RoutePainter old) =>
      old.line != line || old.plane != plane;
}

/// Rings that slowly widen while the GPS looks for satellites; still under
/// reduce motion.
class _Rings extends StatefulWidget {
  const _Rings({required this.size});

  final double size;

  @override
  State<_Rings> createState() => _RingsState();
}

class _RingsState extends State<_Rings> with SingleTickerProviderStateMixin {
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
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => CustomPaint(
            painter: _RingsPainter(
              t: _controller.isAnimating ? _controller.value : 0.5,
              color: s.accent,
            ),
          ),
        ),
      ),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter({required this.t, required this.color});

  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final max = size.width / 2;
    for (var i = 0; i < 3; i++) {
      final f = (t + i / 3) % 1;
      canvas.drawCircle(
        c,
        max * (0.25 + 0.75 * f),
        Paint()
          ..color = color.withValues(alpha: (1 - f) * 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    canvas.drawCircle(c, 6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.t != t || old.color != color;
}

/// The Qibla from your seat (spec §4.8): a ring with the aircraft nose up and
/// the Qibla's line at its angle from the nose. No line until there is a
/// heading to measure from. Left and right are the aircraft's, whatever the
/// reading direction.
class _SeatRing extends StatelessWidget {
  const _SeatRing({required this.fromNose});

  final double? fromNose;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return CustomPaint(
      size: const Size.square(200),
      painter: _SeatRingPainter(
        fromNose: fromNose,
        ring: s.divider,
        body: s.onSurfaceMuted,
        mark: s.accent,
      ),
    );
  }
}

class _SeatRingPainter extends CustomPainter {
  _SeatRingPainter({
    required this.fromNose,
    required this.ring,
    required this.body,
    required this.mark,
  });

  final double? fromNose;
  final Color ring;
  final Color body;
  final Color mark;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 8;
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..color = ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    final s = size.width / 200;
    final fill = Paint()..color = body.withValues(alpha: 0.35);
    // Fuselage, wings and tail, nose up.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: c, width: 14 * s, height: 110 * s),
        Radius.circular(7 * s),
      ),
      fill,
    );
    final wing = Path()
      ..moveTo(c.dx, c.dy - 14 * s)
      ..lineTo(c.dx + 58 * s, c.dy + 8 * s)
      ..lineTo(c.dx + 58 * s, c.dy + 16 * s)
      ..lineTo(c.dx, c.dy + 6 * s)
      ..lineTo(c.dx - 58 * s, c.dy + 16 * s)
      ..lineTo(c.dx - 58 * s, c.dy + 8 * s)
      ..close();
    canvas.drawPath(wing, fill);
    final tail = Path()
      ..moveTo(c.dx, c.dy + 36 * s)
      ..lineTo(c.dx + 22 * s, c.dy + 50 * s)
      ..lineTo(c.dx + 22 * s, c.dy + 55 * s)
      ..lineTo(c.dx, c.dy + 47 * s)
      ..lineTo(c.dx - 22 * s, c.dy + 55 * s)
      ..lineTo(c.dx - 22 * s, c.dy + 50 * s)
      ..close();
    canvas.drawPath(tail, fill);

    final angle = fromNose;
    if (angle == null) return;
    final a = angle * math.pi / 180;
    final tip = c + Offset(math.sin(a) * (r - 14), -math.cos(a) * (r - 14));
    canvas.drawLine(
      c,
      tip,
      Paint()
        ..color = mark
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    canvas.rotate(a);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 16, height: 16),
        const Radius.circular(3),
      ),
      Paint()..color = mark,
    );
    canvas.restore();
    canvas.drawCircle(c, 4, Paint()..color = mark);
  }

  @override
  bool shouldRepaint(_SeatRingPainter old) =>
      old.fromNose != fromNose ||
      old.ring != ring ||
      old.body != body ||
      old.mark != mark;
}

/// The aircraft's heading from the seat-back map, 0–359°.
class _HeadingSheet extends StatefulWidget {
  const _HeadingSheet({required this.initial});

  final double? initial;

  @override
  State<_HeadingSheet> createState() => _HeadingSheetState();
}

class _HeadingSheetState extends State<_HeadingSheet> {
  late final _controller = TextEditingController(
    text: widget.initial?.round().toString() ?? '',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final parsed = int.tryParse(_controller.text.trim());
    final valid = parsed != null && parsed >= 0 && parsed <= 359;
    return SettingsSheetBody(
      title: l10n.inFlightEnterHeading,
      children: [
        SettingsNote(l10n.inFlightHeadingHint, top: 0),
        const SizedBox(height: 12),
        TextField(
          controller: _controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: l10n.inFlightHeadingLabel,
            errorText: _controller.text.isEmpty || valid
                ? null
                : l10n.inFlightHeadingError,
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        SheetActions(
          cancelLabel: l10n.cancel,
          saveLabel: l10n.save,
          onCancel: () => Navigator.of(context).pop(),
          onSave: valid
              ? () => Navigator.of(context).pop(parsed.toDouble())
              : null,
        ),
      ],
    );
  }
}
