import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../app/app.dart';
import '../../app/branding.g.dart';
import '../../app/clock_format.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/location_follower.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../../domain/place.dart';
import '../../domain/place_near.dart';
import '../../domain/prayer.dart';
import '../../domain/sky/ink_rule.dart';
import '../../domain/sky/sky_model.dart';
import '../../domain/sky/sun_path_geometry.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';
import '../components/travel_switch.dart';
import '../location/city_list_page.dart';
import '../location/location_controller.dart';
import '../location/place_copy.dart';
import '../mosques/mosque_details_sheet.dart';
import '../mosques/nearby_mosques_page.dart';
import '../settings/prayer_time_settings.dart' show methodName;
import '../settings/settings_page.dart' show updateAdhanAlerts;
import '../sky/sky_background.dart';
import '../sky/sky_palette.dart';
import '../sky/sun_path.dart';

/// Opens the introduction again from Settings; finishing returns there.
Future<void> replayOnboarding(BuildContext context) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingPage(replay: true),
      ),
    );

/// The first-run introduction (Horizon spec §4.6): one day in five steps.
/// Each step glides the sky to its moment of the place's own day (dawn,
/// sunrise, midday, late afternoon, sunset), with the sun path as a picture.
/// Language, place, mosque, alerts and travel; each permission is asked at the
/// step that needs it, after its reason is on screen. The place is required
/// (owner, 2026-10-16: the bundled city list always works offline); the rest
/// can be left for later.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({this.replay = false, super.key});

  /// Opened from Settings rather than on first run: finishing pops back.
  final bool replay;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

const _steps = 5;

/// The moments the steps glide to, in the prayers of the day.
const _stepPrayers = [
  Prayer.fajr,
  Prayer.sunrise,
  Prayer.dhuhr,
  Prayer.asr,
  Prayer.maghrib,
];

/// The content's band of the screen, under the sun path.
const _contentBand = SkyRegion(0.3, 1, minContrast: 4.5);
const _pathBand = SkyRegion(0.06, 0.3, minContrast: 3);

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  bool? _alertsOn;
  bool _ringInSilent = false;
  bool? _travelOn;
  bool? _notificationsAllowed;
  bool _askedNotifications = false;

  /// On a first run alerts start on; replayed, the switch shows whether the
  /// five are already on, so walking through again changes nothing.
  bool _alertsDefault() {
    if (!widget.replay) return true;
    final alerts =
        (ref.read(appSettingsProvider).value ?? SettingsRepository.defaults)
            .adhanAlerts;
    return Prayer.iqamaPrayers.every((p) => alerts.alertFor(p).enabled);
  }

  void _go(int step) {
    setState(() => _step = step.clamp(0, _steps - 1));
    if (_step == 3) unawaited(_checkNotifications());
  }

  void _next() => _go(_step + 1);
  void _back() => _go(_step - 1);

  Future<void> _checkNotifications() async {
    final allowed = await ref
        .read(notificationGatewayProvider)
        .notificationsEnabled();
    if (mounted) setState(() => _notificationsAllowed = allowed);
  }

  Future<void> _askNotifications() async {
    _askedNotifications = true;
    await ref.read(notificationPermissionRequestProvider)();
    await _checkNotifications();
  }

  Future<void> _finishAlerts() async {
    // Only ever turns alerts on; leaving the switch off changes nothing.
    if (_alertsOn ?? _alertsDefault()) {
      await updateAdhanAlerts(ref, (all) {
        var next = all;
        for (final p in Prayer.iqamaPrayers) {
          next = next.withAlert(p, all.alertFor(p).copyWith(enabled: true));
        }
        return next;
      });
      // Asked here, right after the user chose alerts, with the reason on
      // screen; once is enough.
      if (!_askedNotifications) await _askNotifications();
    }
    // Only ever turns ringing on silent on (2026-10-14): left off, the user's
    // own settings stay as they are.
    if (_ringInSilent) {
      await updateAdhanAlerts(
        ref,
        (a) => a
            .withRingInSilentForAll(RingTarget.adhan, on: true)
            .withRingInSilentForAll(RingTarget.preAdhan, on: true),
      );
      final reminders =
          (ref.read(appSettingsProvider).value ?? SettingsRepository.defaults)
              .jamaahReminders;
      await ref
          .read(settingsRepositoryProvider)
          .saveJamaahReminders(reminders.copyWith(ringInSilent: true));
    }
    _next();
  }

  Future<void> _finish() async {
    final settings =
        ref.read(appSettingsProvider).value ?? SettingsRepository.defaults;
    final travelOn = _travelOn ?? settings.travel.travelMode;
    if (travelOn != settings.travel.travelMode) {
      await ref.read(locationFollowerProvider).setTravelMode(travelOn);
    }
    await ref.read(settingsRepositoryProvider).setOnboardingDone(true);
    if (widget.replay && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final still = MediaQuery.disableAnimationsOf(context);
    final today = ref.watch(todayProvider);
    final day = today != null && today.areTimesAvailable ? today.day : null;
    final model = day == null ? SkyModel.reference : SkyModel.forDay(day);
    final sunrise = day?.timeOf(Prayer.sunrise);
    final sunset = day?.timeOf(Prayer.maghrib);
    final geometry = sunrise != null && sunset != null
        ? SunPathGeometry(sunrise: sunrise, sunset: sunset)
        : SunPathGeometry.reference;
    final times = day?.times ?? _referenceTimes;
    final target = (times[_stepPrayers[_step]] ?? 720).toDouble();
    final place = ref.watch(currentPlaceProvider);
    final active = ref.watch(activeMosqueProvider);

    final (primaryLabel, VoidCallback? primary) = switch (_step) {
      0 => (l10n.onbContinue, _next),
      // The place is required: Choose a city always works, offline too.
      1 => (l10n.onbContinue, place == null ? null : _next),
      2 => (active == null ? l10n.onbNotNow : l10n.onbContinue, _next),
      3 => (l10n.onbContinue, _finishAlerts),
      _ => (l10n.onbStart, _finish),
    };

    return Scaffold(
      body: TweenAnimationBuilder<double>(
        tween: Tween(end: target),
        duration: still ? Duration.zero : const Duration(milliseconds: 1400),
        curve: Curves.easeInOutCubic,
        builder: (context, minute, _) {
          final frame = model.frameAt(minute, dark: dark);
          final contentInk = SkyInk.forRegion(frame, _contentBand);
          final pathInk = SkyInk.forRegion(frame, _pathBand);
          final p = SkyPalette.of(contentInk);
          final pathPalette = SkyPalette.of(pathInk);
          return AnnotatedRegion<SystemUiOverlayStyle>(
            value:
                (pathInk.isLight
                        ? SystemUiOverlayStyle.light
                        : SystemUiOverlayStyle.dark)
                    .copyWith(statusBarColor: Colors.transparent),
            child: SkyBackground(
              frame: frame,
              dark: dark,
              shades: [
                SkyShade(
                  _contentBand.top,
                  _contentBand.bottom,
                  contentInk.shade,
                ),
              ],
              child: SafeArea(
                child: DefaultTextStyle.merge(
                  style: TextStyle(color: p.ink),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
                          child: AspectRatio(
                            aspectRatio: 390 / 168,
                            child: SunPath(
                              geometry: geometry,
                              minute: minute,
                              markers: [
                                for (final prayer in Prayer.adhanPrayers)
                                  if (times[prayer] case final t?)
                                    SunPathMarker(prayer: prayer, minute: t),
                              ],
                              ink: SunPathInk(
                                ink: pathPalette.ink,
                                labelInk: pathPalette.ink,
                                labelMuteAlpha: pathPalette.muteAlpha,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        // Every part built, not only what is on screen, so
                        // each step reads in one go to TalkBack.
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _kicker(
                                  context,
                                  l10n.onbStep(_step + 1, _steps),
                                ),
                                style: HorizonTheme.typeOf(context).kicker
                                    .copyWith(color: p.mute),
                              ),
                              const SizedBox(height: 10),
                              ...switch (_step) {
                                0 => _welcome(context, p),
                                1 => _place(context, p),
                                2 => _mosque(context, p),
                                3 => _alerts(context, p),
                                _ => _travel(context, p),
                              },
                            ],
                          ),
                        ),
                      ),
                      _BottomBar(
                        step: _step,
                        palette: p,
                        primaryLabel: primaryLabel,
                        onPrimary: primary,
                        onBack: _step > 0 ? _back : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _kicker(BuildContext context, String text) =>
      Localizations.localeOf(context).languageCode == 'ar'
      ? text
      : text.toUpperCase();

  Widget _title(BuildContext context, String text, SkyPalette p) => Semantics(
    header: true,
    child: Text(
      text,
      style: HorizonTheme.typeOf(context).onboardingTitle
          .copyWith(color: p.ink),
    ),
  );

  Widget _body(BuildContext context, String text, SkyPalette p) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Text(
      text,
      style: HorizonTheme.typeOf(context).body
          .copyWith(fontSize: 16, height: 1.5, color: p.mute),
    ),
  );

  Widget _note(BuildContext context, String text, SkyPalette p) => Text(
    text,
    style: HorizonTheme.typeOf(context).meta
        .copyWith(fontSize: 13, height: 1.5, color: p.mute),
  );

  Widget _wide(Widget button) =>
      SizedBox(width: double.infinity, child: button);

  List<Widget> _welcome(BuildContext context, SkyPalette p) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final shown = Localizations.localeOf(context).languageCode == 'ar'
        ? AppLanguage.ar
        : AppLanguage.en;
    return [
      Text(kWordmark, style: type.section.copyWith(color: p.mute)),
      const SizedBox(height: 6),
      _title(context, l10n.onbWelcomeTagline, p),
      _body(context, l10n.onbWelcomeBody, p),
      const SizedBox(height: 26),
      Text(
        l10n.onbLanguageLabel,
        style: type.meta.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.mute,
        ),
      ),
      const SizedBox(height: 8),
      _SkySegmented<AppLanguage>(
        palette: p,
        selected: settings.language == AppLanguage.system
            ? shown
            : settings.language,
        options: const [AppLanguage.en, AppLanguage.ar],
        // Each language by its own name, so it can be found in either.
        label: (l) => l == AppLanguage.en ? 'English' : 'العربية',
        onChanged: (l) => ref.read(appLocaleProvider.notifier).choose(l),
      ),
      const SizedBox(height: 8),
      _note(context, l10n.onbLanguageLater, p),
    ];
  }

  List<Widget> _place(BuildContext context, SkyPalette p) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final state = ref.watch(locationRequestProvider);
    final controller = ref.read(locationRequestProvider.notifier);
    final place = ref.watch(currentPlaceProvider);
    final today = ref.watch(todayProvider);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final clock = ClockFormat.of(context);

    Future<void> chooseCity() async {
      final chosen = await Navigator.of(context)
          .push<Place>(MaterialPageRoute(builder: (_) => const CityListPage()));
      if (chosen != null) await controller.choose(chosen);
    }

    final next = today?.next;
    final method = place == null
        ? null
        : methodName(
            l10n,
            settings.calculationMethod.resolvedFor(place.ianaZone),
          );
    return [
      _title(context, l10n.locationSheetTitle, p),
      _body(context, l10n.onbPlaceBody, p),
      const SizedBox(height: 24),
      if (state.isRequesting)
        Semantics(
          liveRegion: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Row(
              children: [
                SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: p.ink,
                    backgroundColor: p.line,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.locationRequesting,
                    style: type.body.copyWith(fontSize: 16, color: p.ink),
                  ),
                ),
              ],
            ),
          ),
        )
      else if (place != null) ...[
        _StatusCard(
          palette: p,
          check: true,
          title: switch ((place.fromDevice, _foundNear(place))) {
            (true, final city?) => l10n.onbPlaceFound(city),
            _ => l10n.onbPlaceDone(placeDescription(l10n, place)),
          },
          body: next == null || method == null
              ? null
              : l10n.onbPlaceDetails(
                  method,
                  prayerName(l10n, next.prayer),
                  clock.time(next.at),
                ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(
            onPressed: chooseCity,
            style: TextButton.styleFrom(
              foregroundColor: p.ink,
              padding: EdgeInsets.zero,
              minimumSize: const Size(48, 44),
              textStyle: type.body.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
              ),
            ),
            child: Text(l10n.onbPlaceNotRight),
          ),
        ),
      ] else ...[
        if (state.failure case final failure?) ...[
          Semantics(
            liveRegion: true,
            child: Text(
              placeFailureMessage(l10n, failure),
              style: type.body.copyWith(fontSize: 15, color: p.ink),
            ),
          ),
          const SizedBox(height: 14),
        ],
        _wide(
          PillButton(
            label: l10n.locationUseDevice,
            icon: LineIcons.pin,
            filled: true,
            ink: p.fill,
            onInk: p.deep,
            line: p.line,
            onPressed: controller.useDeviceLocation,
          ),
        ),
        const SizedBox(height: 10),
        _wide(
          PillButton(
            label: l10n.locationChooseCity,
            ink: p.ink,
            onInk: p.deep,
            line: p.line,
            onPressed: chooseCity,
          ),
        ),
      ],
    ];
  }

  List<Widget> _mosque(BuildContext context, SkyPalette p) {
    final l10n = AppLocalizations.of(context);
    final active = ref.watch(activeMosqueProvider);
    return [
      _title(context, l10n.onbMosqueTitle, p),
      _body(context, l10n.onbMosqueBody, p),
      const SizedBox(height: 22),
      Semantics(
        label: active == null ? l10n.onbMosqueRowOpen : l10n.onbMosqueRowFull,
        excludeSemantics: true,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: CongregationFigures(
            color: p.ink,
            filled: active == null ? 4 : 5,
          ),
        ),
      ),
      const SizedBox(height: 22),
      if (active == null) ...[
        _wide(
          PillButton(
            label: l10n.mosquesEmptyFind,
            filled: true,
            ink: p.fill,
            onInk: p.deep,
            line: p.line,
            onPressed: () => openNearbyMosques(context),
          ),
        ),
        const SizedBox(height: 10),
        _wide(
          PillButton(
            label: l10n.mosquesEmptyAdd,
            ink: p.ink,
            onInk: p.deep,
            line: p.line,
            onPressed: () => showAddMosqueSheet(context),
          ),
        ),
      ] else
        _StatusCard(
          palette: p,
          title: l10n.onbMosqueAdded(active.name),
          body: l10n.onbMosqueAddedBody,
        ),
    ];
  }

  List<Widget> _alerts(BuildContext context, SkyPalette p) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final on = _alertsOn ?? _alertsDefault();
    return [
      _title(context, l10n.onbAlertsTitle, p),
      _body(context, l10n.onbAlertsBody, p),
      const SizedBox(height: 22),
      _SwitchCard(
        palette: p,
        title: l10n.onbAlertsSwitch,
        hint: l10n.onbAlertsFiveHint,
        value: on,
        onChanged: (v) => setState(() => _alertsOn = v),
      ),
      if (on && _notificationsAllowed == false) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.halo,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.onbAllowNote,
                style: type.body.copyWith(
                  fontSize: 14,
                  height: 1.45,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              PillButton(
                label: l10n.scheduledAllowNotifications,
                filled: true,
                ink: p.fill,
                onInk: p.deep,
                line: p.line,
                onPressed: _askNotifications,
              ),
            ],
          ),
        ),
      ] else if (on && _notificationsAllowed == true) ...[
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Row(
            children: [
              LineIcon(LineIcons.check, size: 16, strokeWidth: 3, color: p.ink),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  l10n.onbNotificationsAllowed,
                  style: type.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: p.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 12),
      _SwitchCard(
        palette: p,
        title: l10n.onbRingInSilent,
        hint: l10n.onbRingInSilentHint,
        value: _ringInSilent,
        onChanged: (v) => setState(() => _ringInSilent = v),
      ),
      const SizedBox(height: 14),
      _note(context, l10n.onbAlertsBattery, p),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: TextButton(
          onPressed: () => Geolocator.openAppSettings(),
          style: TextButton.styleFrom(
            foregroundColor: p.ink,
            padding: EdgeInsets.zero,
            minimumSize: const Size(48, 44),
            textStyle: type.meta.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
          child: Text(l10n.onbBatterySettings),
        ),
      ),
    ];
  }

  List<Widget> _travel(BuildContext context, SkyPalette p) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final current =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .travel
            .travelMode;
    final on = _travelOn ?? current;
    return [
      _title(context, l10n.onbTravelTitle, p),
      _body(context, l10n.onbTravelBody, p),
      const SizedBox(height: 22),
      InkWell(
        // The whole card switches it, like the alerts cards.
        onTap: () => setState(() => _travelOn = !on),
        borderRadius: BorderRadius.circular(16),
        child: _Card(
          palette: p,
          child: Row(
            children: [
              Expanded(
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.onbTravelSwitch,
                        style: type.row.copyWith(color: p.ink),
                      ),
                      Text(
                        on ? l10n.onbTravelOnSub : l10n.onbTravelOffSub,
                        style: type.meta.copyWith(fontSize: 13, color: p.mute),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              TravelSwitch(
                value: on,
                onChanged: (v) => setState(() => _travelOn = v),
                label: l10n.onbTravelSwitch,
                colors: TravelSwitchColors(
                  ink: p.ink,
                  deep: p.deep,
                  outline: p.line,
                  fill: p.fill,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      _note(context, l10n.onbTravelSame, p),
    ];
  }
}

/// The sample day's prayer times, for a sky without a place yet.
const _referenceTimes = <Prayer, int>{
  Prayer.fajr: 261,
  Prayer.sunrise: 342,
  Prayer.dhuhr: 689,
  Prayer.asr: 889,
  Prayer.maghrib: 1035,
  Prayer.isha: 1111,
};

String? _foundNear(Place place) => nearName(
  latitude: place.latitude,
  longitude: place.longitude,
  ianaZone: place.ianaZone,
);

/// Five segments, Back, and the main button: dashed and disabled while the
/// step cannot go on.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.step,
    required this.palette,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onBack,
  });

  final int step;
  final SkyPalette palette;
  final String primaryLabel;
  final VoidCallback? onPrimary;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    final primary = onPrimary == null
        ? CustomPaint(
            painter: DashedOutline(color: p.mute, radius: 26),
            child: Semantics(
              button: true,
              enabled: false,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52, minWidth: 120),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Center(
                    widthFactor: 1,
                    child: Text(
                      primaryLabel,
                      style: type.row.copyWith(fontSize: 16, color: p.mute),
                    ),
                  ),
                ),
              ),
            ),
          )
        : PillButton(
            label: primaryLabel,
            filled: true,
            ink: p.fill,
            onInk: p.deep,
            line: p.line,
            onPressed: onPrimary,
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ExcludeSemantics(
            child: Row(
              children: [
                for (var i = 0; i < _steps; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      decoration: BoxDecoration(
                        color: i <= step ? p.ink : p.line,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          // Side by side when they fit; stacked at a large text size.
          OverflowBar(
            alignment: onBack != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            overflowAlignment: OverflowBarAlignment.end,
            overflowSpacing: 8,
            children: [
              if (onBack != null)
                TextButton(
                  onPressed: onBack,
                  style: TextButton.styleFrom(
                    foregroundColor: p.ink,
                    minimumSize: const Size(64, 48),
                    textStyle: type.row.copyWith(fontSize: 16),
                  ),
                  child: Text(l10n.onbBack),
                ),
              primary,
            ],
          ),
        ],
      ),
    );
  }
}

/// A rounded, outlined box on the sky.
class _Card extends StatelessWidget {
  const _Card({required this.palette, required this.child});

  final SkyPalette palette;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: palette.line),
    ),
    child: child,
  );
}

/// "Found you near …" and the like: a check, a line, and a quieter line.
class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.palette,
    required this.title,
    this.body,
    this.check = false,
  });

  final SkyPalette palette;
  final String title;
  final String? body;
  final bool check;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    return Semantics(
      liveRegion: true,
      child: _Card(
        palette: p,
        child: Row(
          children: [
            if (check) ...[
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: p.fill,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: LineIcon(
                    LineIcons.check,
                    size: 16,
                    strokeWidth: 3,
                    color: p.deep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: type.row.copyWith(
                      fontWeight: FontWeight.w600,
                      color: p.ink,
                    ),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      body!,
                      style: type.meta.copyWith(
                        fontSize: 13,
                        height: 1.45,
                        color: p.mute,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A switch in a card on the sky; the whole card toggles it.
class _SwitchCard extends StatelessWidget {
  const _SwitchCard({
    required this.palette,
    required this.title,
    required this.hint,
    required this.value,
    required this.onChanged,
  });

  final SkyPalette palette;
  final String title;
  final String hint;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(16),
      child: _Card(
        palette: p,
        child: Row(
          children: [
            Expanded(
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: type.row.copyWith(color: p.ink)),
                    const SizedBox(height: 2),
                    Text(
                      hint,
                      style: type.meta.copyWith(
                        fontSize: 13,
                        height: 1.4,
                        color: p.mute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            AppSwitch(
              value: value,
              onChanged: onChanged,
              semanticLabel: title,
              colors: AppSwitchColors(
                trackOn: p.fill,
                trackOff: p.line,
                knobOn: p.deep,
                knobOff: p.ink,
                outline: p.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two choices on the sky in an outlined track; the chosen one is filled.
class _SkySegmented<T> extends StatelessWidget {
  const _SkySegmented({
    required this.palette,
    required this.options,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final SkyPalette palette;
  final List<T> options;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          for (final o in options)
            Expanded(
              child: Semantics(
                inMutuallyExclusiveGroup: true,
                checked: o == selected,
                button: true,
                child: Material(
                  color: o == selected ? p.fill : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onChanged(o),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 48),
                      child: Center(
                        child: Text(
                          label(o),
                          style: type.row.copyWith(
                            fontWeight: o == selected
                                ? FontWeight.w600
                                : FontWeight.w500,
                            color: o == selected ? p.deep : p.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
