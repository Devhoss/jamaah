import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/branding.g.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/location_follower.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/place.dart';
import '../../domain/place_near.dart';
import '../../domain/prayer.dart';
import '../location/city_list_page.dart';
import '../location/location_controller.dart';
import '../location/place_copy.dart';
import '../mosques/mosque_details_sheet.dart';
import '../mosques/nearby_mosques_page.dart';
import '../settings/settings_page.dart' show languageName, updateAdhanAlerts;

/// Opens the introduction again from Settings; finishing returns there.
Future<void> replayOnboarding(BuildContext context) => Navigator.of(context)
    .push(
      MaterialPageRoute<void>(
        builder: (_) => const OnboardingPage(replay: true),
      ),
    );

/// The first-run introduction (2026-10-14): language, place, mosque, alerts
/// and travel, each permission asked at the step that needs it, after its
/// reason is on screen. Every step but the language can be left for later.
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({this.replay = false, super.key});

  /// Opened from Settings rather than on first run: finishing pops back.
  final bool replay;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

const _steps = 5;

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int _step = 0;
  bool? _alertsOn;
  bool? _travelOn;

  /// On a first run alerts start on; replayed, the switch shows whether the
  /// five are already on, so walking through again changes nothing.
  bool _alertsDefault() {
    if (!widget.replay) return true;
    final alerts =
        (ref.read(appSettingsProvider).value ?? SettingsRepository.defaults)
            .adhanAlerts;
    return Prayer.iqamaPrayers.every((p) => alerts.alertFor(p).enabled);
  }

  void _next() => setState(() => _step = (_step + 1).clamp(0, _steps - 1));
  void _back() => setState(() => _step = (_step - 1).clamp(0, _steps - 1));

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
      // screen.
      await ref.read(notificationPermissionRequestProvider)();
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
    final theme = Theme.of(context);
    final ink = AppInk.of(context);

    final (content, primary) = switch (_step) {
      0 => (_welcome(context), (l10n.onbContinue, _next)),
      1 => (_place(context), (l10n.onbContinue, _next)),
      2 => (_mosque(context), (l10n.onbContinue, _next)),
      3 => (_alerts(context), (l10n.onbContinue, _finishAlerts)),
      _ => (_travel(context), (l10n.onbStart, _finish)),
    };

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xxl,
                AppSpace.lg,
                AppSpace.xxl,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.onbStep(_step + 1, _steps),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: ink.muted,
                      ),
                    ),
                  ),
                  for (var i = 0; i < _steps; i++)
                    Container(
                      margin: const EdgeInsetsDirectional.only(
                        start: AppSpace.xs,
                      ),
                      width: i == _step ? 18 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: i <= _step
                            ? theme.colorScheme.primary
                            : ink.muted.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpace.xxl),
                children: content,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xxl,
                0,
                AppSpace.xxl,
                AppSpace.lg,
              ),
              // Side by side when they fit; stacked at a large text size.
              child: OverflowBar(
                alignment: _step > 0
                    ? MainAxisAlignment.spaceBetween
                    : MainAxisAlignment.end,
                overflowAlignment: OverflowBarAlignment.end,
                overflowSpacing: AppSpace.sm,
                children: [
                  if (_step > 0)
                    TextButton(onPressed: _back, child: Text(l10n.onbBack)),
                  FilledButton(onPressed: primary.$2, child: Text(primary.$1)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _welcome(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final language =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .language;
    return [
      const SizedBox(height: AppSpace.xl),
      Text(
        kWordmark,
        style: theme.textTheme.displaySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: AppSpace.md),
      Text(l10n.onbWelcomeTagline, style: theme.textTheme.titleLarge),
      const SizedBox(height: AppSpace.md),
      Text(l10n.onbWelcomeBody, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpace.xl),
      Text(l10n.onbLanguage, style: theme.textTheme.titleSmall),
      RadioGroup<AppLanguage>(
        groupValue: language,
        onChanged: (l) {
          if (l != null) ref.read(appLocaleProvider.notifier).choose(l);
        },
        child: Column(
          children: [
            for (final l in AppLanguage.values)
              RadioListTile<AppLanguage>(
                value: l,
                title: Text(languageName(l10n, l)),
              ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _place(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(locationRequestProvider);
    final controller = ref.read(locationRequestProvider.notifier);
    final place = ref.watch(currentPlaceProvider);
    return [
      Text(l10n.locationSheetTitle, style: theme.textTheme.headlineMedium),
      const SizedBox(height: AppSpace.md),
      Text(l10n.locationSheetBody, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpace.sm),
      Text(
        l10n.locationSheetCoarse,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppInk.of(context).muted,
        ),
      ),
      const SizedBox(height: AppSpace.xl),
      if (place != null && !state.isRequesting) ...[
        _Done(switch ((place.fromDevice, _foundNear(place))) {
          (true, final city?) => l10n.onbPlaceFound(city),
          _ => l10n.onbPlaceDone(placeDescription(l10n, place)),
        }),
        const SizedBox(height: AppSpace.md),
      ],
      if (state.failure case final failure?) ...[
        Text(
          placeFailureMessage(l10n, failure),
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpace.md),
      ],
      if (state.isRequesting)
        Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                l10n.locationRequesting,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        )
      else
        FilledButton.tonal(
          onPressed: controller.useDeviceLocation,
          child: Text(l10n.locationUseDevice),
        ),
      const SizedBox(height: AppSpace.sm),
      OutlinedButton(
        onPressed: () async {
          final chosen = await Navigator.of(context).push<Place>(
            MaterialPageRoute(builder: (_) => const CityListPage()),
          );
          if (chosen != null) await controller.choose(chosen);
        },
        child: Text(l10n.locationChooseCity),
      ),
      if (place == null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: _next, child: Text(l10n.onbNotNow)),
        ),
    ];
  }

  List<Widget> _mosque(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final active = ref.watch(activeMosqueProvider);
    return [
      Text(l10n.onbMosqueTitle, style: theme.textTheme.headlineMedium),
      const SizedBox(height: AppSpace.md),
      Text(l10n.onbMosqueBody, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpace.xl),
      if (active != null) ...[
        _Done(l10n.onbMosqueDone(active.name)),
        const SizedBox(height: AppSpace.md),
      ],
      FilledButton.tonal(
        onPressed: () => openNearbyMosques(context),
        child: Text(l10n.findNearbyMosques),
      ),
      const SizedBox(height: AppSpace.sm),
      OutlinedButton(
        onPressed: () => showAddMosqueSheet(context),
        child: Text(l10n.addMosqueManually),
      ),
      if (active == null)
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton(onPressed: _next, child: Text(l10n.onbNotNow)),
        ),
    ];
  }

  List<Widget> _alerts(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return [
      Text(l10n.onbAlertsTitle, style: theme.textTheme.headlineMedium),
      const SizedBox(height: AppSpace.md),
      Text(l10n.onbAlertsBody, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpace.lg),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.onbAlertsSwitch),
        subtitle: Text(l10n.onbAlertsSwitchHint),
        value: _alertsOn ?? _alertsDefault(),
        onChanged: (on) => setState(() => _alertsOn = on),
      ),
      const SizedBox(height: AppSpace.md),
      Text(
        l10n.onbAlertsBattery,
        style: theme.textTheme.bodySmall?.copyWith(
          color: AppInk.of(context).muted,
        ),
      ),
    ];
  }

  List<Widget> _travel(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final current =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .travel
            .travelMode;
    return [
      Text(l10n.onbTravelTitle, style: theme.textTheme.headlineMedium),
      const SizedBox(height: AppSpace.md),
      Text(l10n.onbTravelBody, style: theme.textTheme.bodyMedium),
      const SizedBox(height: AppSpace.lg),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        secondary: const Icon(Icons.flight),
        title: Text(l10n.onbTravelSwitch),
        subtitle: Text(l10n.onbTravelHint),
        value: _travelOn ?? current,
        onChanged: (on) => setState(() => _travelOn = on),
      ),
    ];
  }
}

String? _foundNear(Place place) => nearName(
  latitude: place.latitude,
  longitude: place.longitude,
  ianaZone: place.ianaZone,
);

class _Done extends StatelessWidget {
  const _Done(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.check_circle, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpace.sm),
        Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}
