import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/clock_format.dart';
import '../../app/date_labels.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/extra_times.dart';
import '../../domain/hijri.dart';
import '../../domain/mosque.dart';
import '../../domain/place.dart';
import '../../domain/prayer.dart';
import '../../domain/sky/ink_rule.dart';
import '../../domain/sky/moon_phase.dart';
import '../../domain/sky/sky_model.dart';
import '../../domain/sky/sun_path_geometry.dart';
import '../../domain/time_model.dart';
import '../../domain/today.dart';
import '../../domain/zone_lookup.dart';
import '../components/alert_sheet.dart';
import '../components/bottom_nav.dart';
import '../components/line_icon.dart';
import '../flight/in_flight_page.dart';
import '../location/location_controller.dart';
import '../location/location_sheet.dart';
import '../location/place_copy.dart';
import '../settings/settings_page.dart';
import '../sky/sky_background.dart';
import '../sky/sky_motion.dart';
import '../sky/sky_palette.dart';
import '../sky/sun_path.dart';
import 'alert_choice.dart';
import 'iqama_ticket.dart';
import 'prayer_rows.dart';
import 'today_hero.dart';
import 'today_notes.dart';
import 'today_text.dart';
import 'today_top_bar.dart';
import 'today_view.dart';

/// The day at the place the user saved, as a window onto its sky (Horizon,
/// spec §4.1).
///
/// Everything here is a reading of the domain's `TodayReading`, built from the
/// saved place's own zone and the injected clock, so "today" is the place's
/// date, never the device's. The only state of its own is where the user is
/// looking ([TodayView]): at rest, dragged along the sun's path, or pinned to a
/// prayer from its row.
class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({
    this.onOpenMosques,
    this.onOpenMosque,
    this.onNavColors,
    super.key,
  });

  /// Where the "add a mosque" ticket leads. The shell owns the destination.
  final VoidCallback? onOpenMosques;

  /// Opens one mosque, for "Set time": Iqama times are entered on the mosque.
  final ValueChanged<String>? onOpenMosque;

  /// The sky ink at the bottom, for the shell's nav bar drawn over the sky.
  final ValueChanged<BottomNavColors>? onNavColors;

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

/// Bands of the screen as fractions of its height, measured after layout.
class _Bands {
  const _Bands({
    required this.top,
    required this.hero,
    required this.middle,
    required this.rows,
    required this.pathTop,
    required this.pathHeight,
  });

  static const initial = _Bands(
    top: (0, 0.08),
    hero: (0.28, 0.45),
    middle: (0.45, 0.58),
    rows: (0.58, 1),
    pathTop: SkyRegion.sunPathTop,
    pathHeight: SkyRegion.sunPathHeight,
  );

  final (double, double) top;
  final (double, double) hero;
  final (double, double) middle;
  final (double, double) rows;
  final double pathTop;
  final double pathHeight;

  bool closeTo(_Bands o) {
    bool near((double, double) a, (double, double) b) =>
        (a.$1 - b.$1).abs() < 0.004 && (a.$2 - b.$2).abs() < 0.004;
    return near(top, o.top) &&
        near(hero, o.hero) &&
        near(middle, o.middle) &&
        near(rows, o.rows) &&
        (pathTop - o.pathTop).abs() < 0.004 &&
        (pathHeight - o.pathHeight).abs() < 0.004;
  }
}

/// The inks for one frame, one per band.
class _Inks {
  _Inks(SkyFrame frame, _Bands b, {required double sunX, required double sunY})
    : top = SkyInk.forRegion(
        frame,
        SkyRegion(b.top.$1, b.top.$2, minContrast: 4.5),
      ),
      label = SkyInk.forPoint(frame, sunX, sunY),
      path = SkyInk.forRegion(
        frame,
        SkyRegion(b.pathTop, b.pathTop + b.pathHeight, minContrast: 3),
      ),
      heroTime = SkyInk.forRegion(
        frame,
        SkyRegion(b.hero.$1, b.hero.$2, minContrast: 3),
      ),
      heroText = SkyInk.forRegion(
        frame,
        SkyRegion(b.hero.$1, b.hero.$2, minContrast: 4.5),
      ),
      middle = SkyInk.forRegion(
        frame,
        SkyRegion(b.middle.$1, b.middle.$2, minContrast: 4.5),
      ),
      rows = SkyInk.forRegion(
        frame,
        SkyRegion(b.rows.$1, b.rows.$2, minContrast: 4.5),
      );

  final SkyInk top;
  final SkyInk label;
  final SkyInk path;
  final SkyInk heroTime;
  final SkyInk heroText;
  final SkyInk middle;
  final SkyInk rows;

  List<SkyShade> shades(_Bands b) => [
    SkyShade(b.top.$1, b.top.$2, top.shade),
    SkyShade(b.hero.$1, b.hero.$2, heroText.shade),
    SkyShade(b.middle.$1, b.middle.$2, middle.shade),
    SkyShade(b.rows.$1, b.rows.$2, rows.shade),
  ];
}

class _TodayScreenState extends ConsumerState<TodayScreen>
    with SingleTickerProviderStateMixin {
  TodayView _view = TodayView.atRest;
  late final AnimationController _glide = AnimationController(vsync: this);
  SkyGlide? _glideCurve;
  VoidCallback? _afterGlide;

  _Bands _bands = _Bands.initial;
  final _rootKey = GlobalKey();
  final _topKey = GlobalKey();
  final _pathKey = GlobalKey();
  final _heroKey = GlobalKey();
  final _middleKey = GlobalKey();
  final _rowsKey = GlobalKey();

  SkyModel? _sky;
  Object? _skyFor;
  BottomNavColors? _lastNav;

  @override
  void initState() {
    super.initState();
    _glide.addListener(() {
      final g = _glideCurve;
      if (g == null) return;
      setState(
        () => _view = TodayView(
          viewMinute: g.at(_glide.value),
          pinned: _view.pinned,
        ),
      );
    });
    _glide.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        final done = _afterGlide;
        _afterGlide = null;
        _glideCurve = null;
        done?.call();
      }
    });
  }

  @override
  void dispose() {
    _glide.dispose();
    super.dispose();
  }

  /// Glides the viewed minute to [to] (spec §3.6), then calls [then].
  void _glideTo(double from, double to, {Prayer? pin, VoidCallback? then}) {
    _glide.stop();
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _view = TodayView(viewMinute: to, pinned: pin));
      then?.call();
      return;
    }
    final g = SkyGlide(from: from, to: to);
    _glideCurve = g;
    _afterGlide = then;
    setState(() => _view = TodayView(viewMinute: from, pinned: pin));
    _glide.duration = g.duration;
    _glide.forward(from: 0);
  }

  void _scrub(double minute) {
    _glide.stop();
    _glideCurve = null;
    _afterGlide = null;
    setState(() => _view = _view.scrubTo(minute));
  }

  void _backToNow(double now) {
    final from = _view.viewMinute;
    if (from == null) return;
    _glideTo(from, now, then: () => setState(() => _view = TodayView.atRest));
  }

  void _pick(Prayer prayer, int minute, double now) {
    // The pin is what selects the prayer, even mid-glide.
    _glideTo(_view.viewMinute ?? now, minute.toDouble(), pin: prayer);
  }

  /// After layout, reads where each block of text actually sits, so its ink
  /// is chosen against the sky behind it rather than a guess.
  void _measure() {
    final root = _rootKey.currentContext?.findRenderObject() as RenderBox?;
    if (root == null || !root.hasSize || root.size.height == 0) return;
    final h = root.size.height;
    (double, double)? band(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null || !box.hasSize) return null;
      final top = box.localToGlobal(Offset.zero, ancestor: root).dy;
      return (
        (top / h).clamp(0.0, 1.0),
        ((top + box.size.height) / h).clamp(0.0, 1.0),
      );
    }

    final top = band(_topKey), path = band(_pathKey), hero = band(_heroKey);
    final middle = band(_middleKey), rows = band(_rowsKey);
    if (top == null || path == null || hero == null || rows == null) return;
    final next = _Bands(
      top: top,
      hero: hero,
      middle: middle ?? (hero.$2, rows.$1),
      rows: (rows.$1, 1),
      pathTop: path.$1,
      pathHeight: path.$2 - path.$1,
    );
    if (!next.closeTo(_bands)) setState(() => _bands = next);
  }

  SkyModel _skyModelFor(PrayerDay day) {
    final key = (day.day, day.times[Prayer.sunrise], day.times[Prayer.maghrib]);
    if (_sky == null || _skyFor != key) {
      _sky = SkyModel.forDay(day);
      _skyFor = key;
    }
    return _sky!;
  }

  void _reportNav(SkyPalette rows, [Color? fade]) {
    final colors = BottomNavColors(
      ink: rows.ink,
      muted: rows.mute,
      line: rows.line,
      background: Colors.transparent,
      fade: fade,
    );
    final last = _lastNav;
    if (last != null &&
        last.ink == colors.ink &&
        last.muted == colors.muted &&
        last.line == colors.line &&
        last.fade == colors.fade) {
      return;
    }
    _lastNav = colors;
    final report = widget.onNavColors;
    if (report == null) return;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) report(colors);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(appSettingsProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final clockNow = ref.watch(minuteClockProvider);

    // Before a place exists the sky still follows the phone's own clock.
    double deviceMinute() {
      final local = clockNow.toLocal();
      return local.hour * 60.0 + local.minute;
    }

    if (settings.hasError) {
      return _SkyNotice(
        minute: deviceMinute(),
        dark: dark,
        title: l10n.todayErrorTitle,
        body: l10n.todayErrorBody,
        actionLabel: l10n.locationTryAgain,
        onAction: () => ref.invalidate(appSettingsProvider),
        onPalette: _reportNav,
      );
    }
    if (!settings.hasValue) {
      return _SkyNotice(
        minute: deviceMinute(),
        dark: dark,
        title: l10n.todayLoading,
        onPalette: _reportNav,
      );
    }
    final place = ref.watch(currentPlaceProvider);
    if (place == null) {
      final failure = ref.watch(locationRequestProvider).failure;
      return _SkyNotice(
        minute: deviceMinute(),
        dark: dark,
        title: l10n.todayNeedsPlaceTitle,
        body: failure == null
            ? l10n.todayNeedsPlaceBody
            : placeFailureMessage(l10n, failure),
        actionLabel: l10n.todayChoosePlace,
        onAction: () => showLocationSheet(context),
        onPalette: _reportNav,
      );
    }

    final snapshot = settings.requireValue;
    final today = ref.watch(todayProvider)!;
    final clock = ClockFormat.of(context);
    final day = today.day;
    final times = day.times;
    final now = today.moment.minutesOfDay.toDouble();
    final shown = _view.minuteShown(now);
    final mosque = ref.watch(activeMosqueProvider);
    final mosquesRead = ref.watch(savedMosquesProvider).hasValue;
    final iqama = ref.watch(nextIqamaProvider);
    final travel = snapshot.travel;
    final alerts = snapshot.adhanAlerts;

    final sunrise = times[Prayer.sunrise], sunset = times[Prayer.maghrib];
    final geometry = (sunrise != null && sunset != null && sunset > sunrise)
        ? SunPathGeometry(sunrise: sunrise, sunset: sunset)
        : SunPathGeometry.reference;
    final sky = _skyModelFor(day);
    final frame = sky.frameAt(shown, dark: dark);

    final held = TodayView.heldPrayer(
      today: today,
      iqama: iqama,
      awayFromMosque: travel.pauseAllIqamaReminders || travel.followsLocation,
    );
    final selection = _view.select(times: times, next: today.next, held: held);

    // Where the label under the sun sits, for its own ink.
    final sunPoint = geometry.positionAt(shown).point;
    final labelY = sunPoint.y < 70 ? sunPoint.y + 29 : sunPoint.y - 37;
    final inks = _Inks(
      frame,
      _bands,
      sunX: sunPoint.x / SunPathGeometry.width,
      sunY:
          _bands.pathTop + labelY / SunPathGeometry.height * _bands.pathHeight,
    );
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) _measure();
    });

    final sunLabel = _view.moved
        ? clock.time(LocalTime(shown.round() % 1440))
        : l10n.sunNow(clock.parts(LocalTime(now.round())).clock);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    String upper(String s) => arabic ? s : s.toUpperCase();
    final hijri = hijriFor(
      DateTime(day.day.year, day.day.month, day.day.day),
      adjustDays: snapshot.hijriAdjustDays,
    );

    final content = !today.areTimesAvailable || selection == null
        ? null
        : _content(
            l10n: l10n,
            clock: clock,
            today: today,
            selection: selection,
            now: now,
            mosque: mosque,
            mosquesRead: mosquesRead,
            iqama: iqama,
            upper: upper,
          );

    return AnimatedSkyPalette(
      palette: SkyPalette.of(inks.rows),
      builder: (context, rowsPalette) {
        // The bar fades in the sky at the bottom, shade included.
        _reportNav(
          rowsPalette,
          Color(inks.rows.shade.over(frame.colorAt(1)).argb),
        );
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _overlayFor(inks.top.isLight),
          child: SkyMotionScope(
            child: SkyBackground(
              key: _rootKey,
              frame: frame,
              dark: dark,
              shades: inks.shades(_bands),
              child: SafeArea(
                bottom: false,
                // One scroll for the whole day: at a large text size or on a
                // short screen the header and the rows scroll together rather
                // than overflow. Each scroll re-measures the ink bands.
                child: NotificationListener<ScrollUpdateNotification>(
                  onNotification: (_) {
                    _measure();
                    return false;
                  },
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context)
                        .copyWith(scrollbars: false),
                    child: SingleChildScrollView(
                      padding: EdgeInsets.only(
                        bottom: MediaQuery.paddingOf(context).bottom + 8,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AnimatedSkyPalette(
                            palette: SkyPalette.of(inks.top),
                            builder: (context, p) => KeyedSubtree(
                              key: _topKey,
                              child: TodayTopBar(
                                place: placeShortLabel(l10n, place),
                                subline: _subline(
                                  context,
                                  l10n,
                                  snapshot,
                                  day.day,
                                  clockNow,
                                ),
                                onPlace: () => showLocationSheet(context),
                                travelOn: travel.travelMode,
                                onTravel: (on) =>
                                    setTravelMode(context, ref, on),
                                palette: p,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSkyPalette(
                            palette: SkyPalette.of(inks.path),
                            builder: (context, p) => KeyedSubtree(
                              key: _pathKey,
                              child: SunPath(
                                geometry: geometry,
                                minute: shown,
                                markers: [
                                  for (final prayer in Prayer.adhanPrayers)
                                    if (times[prayer] case final t?)
                                      SunPathMarker(
                                        prayer: prayer,
                                        minute: t,
                                        selected: selection?.prayer == prayer,
                                        next: today.next?.prayer == prayer,
                                      ),
                                ],
                                ink: SunPathInk(
                                  ink: p.ink,
                                  labelInk: Color(inks.label.ink.argb),
                                  labelMuteAlpha: inks.label.muteAlpha,
                                ),
                                moon: MoonPhase.fromHijriDay(hijri.hDay),
                                sunLabel: sunLabel,
                                combinedLabel: selection == null
                                    ? null
                                    : l10n.sunLabelCombined(
                                        prayerNameOn(
                                          l10n,
                                          selection.prayer,
                                          day.day,
                                        ),
                                        sunLabel,
                                      ),
                                labelStyle: HorizonTheme.typeOf(context).kicker
                                    .copyWith(
                                      fontSize: 11,
                                      letterSpacing: 0.66,
                                    ),
                                selectedLabel: selection == null
                                    ? null
                                    : prayerNameOn(
                                        l10n,
                                        selection.prayer,
                                        day.day,
                                      ),
                                selectedLabelStyle: HorizonTheme.typeOf(context)
                                    .prayerName
                                    .copyWith(fontSize: 14),
                                onScrub: today.areTimesAvailable
                                    ? _scrub
                                    : null,
                                semanticLabel: l10n.sunPathLabel,
                                semanticValue: l10n.sunPathValue(
                                  clock.time(LocalTime(shown.round() % 1440)),
                                  selection == null
                                      ? ''
                                      : prayerNameOn(
                                          l10n,
                                          selection.prayer,
                                          day.day,
                                        ),
                                ),
                                semanticStep: (
                                  up: clock.time(
                                    LocalTime((shown + 15).round() % 1440),
                                  ),
                                  down: clock.time(
                                    LocalTime(
                                      (shown - 15 + 1440).round() % 1440,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (content == null)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                              child: _Unavailable(
                                palette: SkyPalette.of(inks.heroText),
                              ),
                            )
                          else ...[
                            AnimatedSkyPalette(
                              palette: SkyPalette.of(inks.heroTime),
                              builder: (context, timeP) => AnimatedSkyPalette(
                                palette: SkyPalette.of(inks.heroText),
                                builder: (context, textP) => Padding(
                                  key: _heroKey,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),
                                  child: TodayHero(
                                    kicker: content.kicker,
                                    time: content.time,
                                    name: content.name,
                                    meta: content.meta,
                                    palette: timeP,
                                    kickerPalette: textP,
                                    onBackToNow: _view.moved
                                        ? () => _backToNow(now)
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                            AnimatedSkyPalette(
                              palette: SkyPalette.of(inks.middle),
                              builder: (context, p) => Padding(
                                key: _middleKey,
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  8,
                                  24,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TodayNotes(
                                      notes: _notes(
                                        context,
                                        l10n,
                                        today,
                                        place,
                                      ),
                                      palette: p,
                                    ),
                                    const SizedBox(height: 6),
                                    if (content.ticket case final ticket?)
                                      IqamaTicket(content: ticket, palette: p)
                                    else
                                      const SizedBox(
                                        height: IqamaTicket.minHeight,
                                      ),
                                    if (travel.travelMode)
                                      _FlightRow(
                                        palette: p,
                                        onTap: () => openInFlight(context),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          if (content != null)
                            Padding(
                              key: _rowsKey,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: PrayerRows(
                                rows: _rows(
                                  l10n,
                                  clock,
                                  today,
                                  mosque,
                                  selection,
                                ),
                                palette: rowsPalette,
                                onPick: (p) {
                                  final t = times[p];
                                  if (t != null) _pick(p, t, now);
                                },
                                onAlert: (p) => _openAlert(
                                  context,
                                  l10n,
                                  clock,
                                  day,
                                  p,
                                  alerts,
                                ),
                              ),
                            )
                          else
                            SizedBox(key: _rowsKey, height: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  _HeroContent _content({
    required AppLocalizations l10n,
    required ClockFormat clock,
    required TodayReading today,
    required TodaySelection selection,
    required double now,
    required Mosque? mosque,
    required bool mosquesRead,
    required NextIqama? iqama,
    required String Function(String) upper,
  }) {
    final day = today.day;
    final prayer = selection.prayer;
    final tomorrow = selection.kicker == HeroKicker.nextPrayerTomorrow;
    final next = today.next;
    final adhanDay = tomorrow && next != null ? next.on : day.day;
    final adhanMinute = tomorrow && next != null
        ? next.at.minutes
        : day.timeOf(prayer);
    // Real minutes to the next Adhan come from the domain (clock changes);
    // any other time is read against the wall clock.
    final until =
        selection.kicker == HeroKicker.nextPrayer ||
            selection.kicker == HeroKicker.nextPrayerTomorrow
        ? (next?.minutesUntil ?? 0)
        : (adhanMinute ?? now.round()) - now.round();
    final parts = clock.parts(LocalTime((adhanMinute ?? 0) % 1440));
    final relative = relativeText(l10n, until);

    final kicker = switch (selection.kicker) {
      HeroKicker.nextPrayer => l10n.nextPrayerAdhan,
      HeroKicker.nextPrayerTomorrow => l10n.heroKickerTomorrow,
      HeroKicker.heldForIqama => l10n.heroKickerHeld(
        prayerNameOn(l10n, prayer, day.day),
        switch (iqama) {
          IqamaUpcoming(:final minutesUntil) => relativeText(
            l10n,
            minutesUntil,
          ),
          _ => '',
        },
      ),
      HeroKicker.adhan => l10n.heroKickerAdhan,
      HeroKicker.inForceAt => l10n.heroKickerInForce(
        clock.time(LocalTime(_view.minuteShown(now).round() % 1440)),
      ),
      HeroKicker.sunrise => l10n.heroKickerSunrise,
    };
    final meta = selection.kicker == HeroKicker.heldForIqama
        ? l10n.heroAdhanAgo(relative)
        : (parts.period == null
              ? relative
              : l10n.heroMeta(parts.period!, relative));

    final calculator = ref.read(prayerTimesCalculatorProvider);
    final ticket = !mosquesRead
        ? null
        : ticketFor(
            l10n: l10n,
            clock: clock,
            prayer: prayer,
            day: adhanDay,
            adhanTimes: adhanDay == day.day
                ? day.times
                : (calculator?.forDay(adhanDay).times ?? const {}),
            mosque: mosque,
            nowMinute: now.round() - (adhanDay == day.day ? 0 : 1440),
            onSet: () {
              final open = widget.onOpenMosque;
              if (mosque != null && open != null) {
                open(mosque.id);
              } else {
                widget.onOpenMosques?.call();
              }
            },
            onAdd: () => widget.onOpenMosques?.call(),
          );

    return _HeroContent(
      kicker: upper(kicker),
      time: adhanMinute == null ? l10n.noTimeToday : parts.clock,
      name: prayerNameOn(l10n, prayer, adhanDay),
      meta: adhanMinute == null ? '' : meta,
      ticket: ticket,
    );
  }

  List<TodayRow> _rows(
    AppLocalizations l10n,
    ClockFormat clock,
    TodayReading today,
    Mosque? mosque,
    TodaySelection? selection,
  ) {
    final day = today.day;
    final extras = ref.watch(todayExtraTimesProvider);
    final alerts =
        ref.watch(appSettingsProvider).value?.adhanAlerts ??
        AdhanAlertSettings.defaults();
    final schedule = mosque?.scheduleFor(day.day);

    List<TodayRow> extra(ExtraTime time) => [
      for (final e in extras)
        if (e.time == time)
          ExtraTodayRow(
            ExtraRowData(
              name: extraTimeName(l10n, e.time),
              time: clock.time(e.at),
            ),
          ),
    ];

    String? iqamaLine(Prayer prayer) {
      if (!prayer.canHaveIqama || mosque == null) return null;
      final resolved = schedule?.iqamaOn(day.day, prayer);
      if (resolved == null) return l10n.rowIqamaNotSet;
      if (resolved.jumuahNotSet) return l10n.jumuahRowNotSet;
      final at = resolved.entry.timeOfDay(day.timeOf(prayer));
      return at == null ? l10n.rowIqamaNotSet : l10n.rowIqama(clock.time(at));
    }

    return [
      for (final prayer in Prayer.adhanPrayers) ...[
        if (prayer == Prayer.fajr) ...extra(ExtraTime.imsak),
        PrayerTodayRow(
          PrayerRowData(
            prayer: prayer,
            name: prayerNameOn(l10n, prayer, day.day),
            time: switch (day.timeOf(prayer)) {
              final m? => clock.time(LocalTime(m)),
              null => null,
            },
            iqama: iqamaLine(prayer),
            alert: alertChoiceFor(alerts, prayer),
            isNext: today.next?.prayer == prayer,
            selected: selection?.prayer == prayer,
          ),
        ),
        if (prayer == Prayer.sunrise) ...extra(ExtraTime.duha),
        if (prayer == Prayer.isha) ...extra(ExtraTime.qiyam),
      ],
    ];
  }

  Future<void> _openAlert(
    BuildContext context,
    AppLocalizations l10n,
    ClockFormat clock,
    PrayerDay day,
    Prayer prayer,
    AdhanAlertSettings alerts,
  ) {
    final t = day.timeOf(prayer);
    return showAlertSheet(
      context,
      prayerName: prayerNameOn(l10n, prayer, day.day),
      adhanTime: t == null ? l10n.noTimeToday : clock.time(LocalTime(t)),
      current: alertChoiceFor(alerts, prayer),
      defaultMode: alerts.defaultSoundMode,
      onChoose: (choice) async {
        final current =
            ref.read(appSettingsProvider).value?.adhanAlerts ?? alerts;
        final askPermission = turnsAlertOn(current, prayer, choice);
        await updateAdhanAlerts(
          ref,
          (all) => applyAlertChoice(all, prayer, choice),
        );
        if (askPermission) {
          await ref.read(notificationPermissionRequestProvider)();
        }
      },
    );
  }

  List<TodayNote> _notes(
    BuildContext context,
    AppLocalizations l10n,
    TodayReading today,
    Place place,
  ) {
    final snapshot = ref.watch(appSettingsProvider).requireValue;
    final now = ref.watch(minuteClockProvider);
    final notes = <TodayNote>[];
    if (snapshot.inFlight case final hold? when hold.activeAt(now)) {
      notes.add(
        TodayNote(
          l10n.inFlightHeldNote(_phoneClock(context, hold.pausedUntil)),
          icon: LineIcons.plane,
          actionLabel: l10n.inFlightEnd,
          onAction: () =>
              ref.read(settingsRepositoryProvider).saveInFlight(null),
        ),
      );
    }
    final active = ref.watch(activeMosqueProvider);
    if (active != null) {
      if (snapshot.travel.pauseAllIqamaReminders) {
        notes.add(TodayNote(l10n.pausedAllNote, icon: LineIcons.pause));
      } else if (active.remindersPaused) {
        notes.add(
          TodayNote(l10n.pausedMosqueNote(active.name), icon: LineIcons.pause),
        );
      }
    }
    final moved = today.prayersMovedByRule;
    if (moved.isNotEmpty) {
      notes.add(
        TodayNote(
          l10n.highLatitudeNote(
            movedPrayerNames(l10n, moved),
            highLatitudeRuleName(l10n, snapshot.highLatitudeRule),
          ),
        ),
      );
    }
    if (today.estimatedFromLatitude case final lat?) {
      final value = lat.abs().toStringAsFixed(1);
      notes.add(
        TodayNote(
          l10n.estimatedFromLatitudeNote(
            lat >= 0 ? l10n.latitudeNorth(value) : l10n.latitudeSouth(value),
          ),
        ),
      );
    }
    if (_zoneNote(l10n, place) case final note?) {
      notes.add(TodayNote(note, icon: LineIcons.globe));
    }
    return notes;
  }

  /// When the place's clock and the phone's clock disagree (a phone left on
  /// home time after a flight), says which one the times are in.
  String? _zoneNote(AppLocalizations l10n, Place place) {
    final phone = ref.watch(phoneUtcOffsetProvider);
    final zone = ref.watch(placeZoneProvider);
    if (phone == null || zone == null) return null;
    final now = ref.watch(minuteClockProvider);
    final placeMinutes = zone.offsetMinutesAt(now);
    if (placeMinutes == phone.inMinutes) return null;
    // Isolated so "UTC+3" keeps its sign in a right-to-left line.
    String utc(int minutes) => '\u2066UTC${utcOffsetLabel(minutes)}\u2069';
    return place.fromDevice && place.userName == null
        ? l10n.zoneNoteHere(utc(placeMinutes), utc(phone.inMinutes))
        : l10n.zoneNotePlace(
            placeLabel(l10n, place),
            utc(placeMinutes),
            utc(phone.inMinutes),
          );
  }

  /// "Thu 15 Oct · 4 Jumada al-Awwal 1448", or how fresh the followed
  /// location is in travel mode.
  String _subline(
    BuildContext context,
    AppLocalizations l10n,
    AppSettingsSnapshot snapshot,
    LocalDay day,
    DateTime now,
  ) {
    final travel = snapshot.travel;
    final checked = snapshot.placeCheckedAt;
    final failed = snapshot.placeCheckFailed;
    if (travel.followsLocation && (checked != null || failed)) {
      final ago = checked == null ? '' : agoLabel(l10n, checked, now);
      return failed ? l10n.followingStale(ago) : l10n.followingUpdated(ago);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = day.midnightUtc();
    return l10n.placeSubline(
      DateLabels.weekdayDate(date, locale),
      DateLabels.hijri(date, locale, adjustDays: snapshot.hijriAdjustDays),
    );
  }

  static SystemUiOverlayStyle _overlayFor(bool lightInk) =>
      (lightInk ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
          .copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarContrastEnforced: false,
          );
}

/// What the hero and the ticket say for the selected prayer.
class _HeroContent {
  const _HeroContent({
    required this.kicker,
    required this.time,
    required this.name,
    required this.meta,
    required this.ticket,
  });

  final String kicker;
  final String time;
  final String name;
  final String meta;

  /// Null while the saved mosques are still being read: saying "Add your
  /// mosque" then would be wrong for a user who has one.
  final TicketContent? ticket;
}

/// [utc] on the phone's own clock.
String _phoneClock(BuildContext context, DateTime utc) {
  final local = utc.toLocal();
  return ClockFormat.of(context).time(LocalTime.of(local.hour, local.minute));
}

/// "On a flight?": the ruled row that leads to in-flight mode (travel on).
class _FlightRow extends StatelessWidget {
  const _FlightRow({required this.palette, required this.onTap});

  final SkyPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Semantics(
        button: true,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: BoxDecoration(
              border: Border.symmetric(
                horizontal: BorderSide(color: palette.line),
              ),
            ),
            child: Row(
              children: [
                LineIcon(
                  LineIcons.planeTakeoff,
                  size: 22,
                  strokeWidth: 1.6,
                  color: palette.ink,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.inFlightCardTitle,
                        style: type.section.copyWith(
                          fontSize: 17,
                          color: palette.ink,
                        ),
                      ),
                      Text(
                        l10n.inFlightCardBody,
                        style: type.meta.copyWith(
                          fontSize: 12,
                          color: palette.mute,
                        ),
                      ),
                    ],
                  ),
                ),
                LineIcon(
                  LineIcons.chevronRight,
                  size: 18,
                  strokeWidth: 2,
                  color: palette.ink,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A day the sun does not cross here: no times, said plainly.
class _Unavailable extends StatelessWidget {
  const _Unavailable({required this.palette});

  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.timesUnavailableTitle,
          style: type.prayerName.copyWith(color: palette.ink),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.timesUnavailableBody,
          style: type.body.copyWith(color: palette.mute),
        ),
      ],
    );
  }
}

/// Loading, no place, or settings that couldn't be read: the sky at the
/// phone's minute, no hero, one quiet message and the next useful action.
class _SkyNotice extends StatelessWidget {
  const _SkyNotice({
    required this.minute,
    required this.dark,
    required this.title,
    required this.onPalette,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final double minute;
  final bool dark;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;
  final ValueChanged<SkyPalette> onPalette;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final frame = SkyModel.reference.frameAt(minute, dark: dark);
    final ink = SkyInk.forRegion(
      frame,
      const SkyRegion(0.1, 1, minContrast: 4.5),
    );
    final p = SkyPalette.of(ink);
    onPalette(p);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _TodayScreenState._overlayFor(ink.isLight),
      child: SkyMotionScope(
        child: SkyBackground(
          frame: frame,
          dark: dark,
          shades: [SkyShade(0.1, 1, ink.shade)],
          child: SafeArea(
            bottom: false,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
              children: [
                Text(title, style: type.prayerName.copyWith(color: p.ink)),
                if (body != null) ...[
                  const SizedBox(height: 8),
                  Text(body!, style: type.body.copyWith(color: p.mute)),
                ],
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 20),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: p.ink,
                        foregroundColor: p.deep,
                        minimumSize: const Size(0, 52),
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        shape: const StadiumBorder(),
                        textStyle: type.row,
                      ),
                      onPressed: onAction,
                      child: Text(actionLabel!),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
