import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app.dart';
import '../../app/build_info.dart';
import '../../app/l10n/generated/app_localizations.dart';
import '../../app/location_follower.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/adhan_alerts.dart';
import '../components/brand_mark.dart';
import '../components/travel_switch.dart';
import '../flight/in_flight_page.dart';
import '../onboarding/onboarding_page.dart';
import 'scheduled_notifications_page.dart';
import 'diagnostics_page.dart';
import 'settings_kit.dart';
import 'settings_page.dart';

/// "Off", "On", or "On · following your location".
String travelSummary(AppLocalizations l10n, TravelSettings travel) =>
    !travel.travelMode
    ? l10n.travelSummaryOff
    : travel.followLocation
    ? l10n.travelSummaryFollowing
    : l10n.travelSummaryOn;

/// Travel (spec §4.9): the switch, following the location, and in flight.
class TravelPage extends ConsumerWidget {
  const TravelPage({super.key});

  /// The option is the user's tap, so the location dialog may show now; if the
  /// device says no, the option stays off and the reason is shown.
  Future<void> _setFollow(BuildContext context, WidgetRef ref, bool on) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final failure = await ref
        .read(locationFollowerProvider)
        .setFollowLocation(on);
    if (failure != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(followFailure(l10n, failure))),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final travel =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .travel;

    return SettingsScaffold(
      title: l10n.settingsTravelSection,
      lead: l10n.settingsTravelLead,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: s.divider)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.settingsTravelMode,
                          style: type.row.copyWith(color: s.onSurface),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.settingsTravelModeHint,
                          style: type.meta.copyWith(
                            height: 1.4,
                            color: s.onSurfaceMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                TravelSwitch(
                  value: travel.travelMode,
                  onChanged: (on) => setTravelMode(context, ref, on),
                  label: l10n.settingsTravelMode,
                  // On a surface it uses the accent (spec §2.5).
                  colors: TravelSwitchColors(
                    ink: s.accent,
                    deep: s.onAccent,
                    outline: s.divider,
                  ),
                ),
              ],
            ),
          ),
        ),
        SettingsSwitchRow(
          title: l10n.settingsFollowLocation,
          hint: travel.travelMode
              ? l10n.settingsFollowLocationHint
              : l10n.followNeedsTravel,
          value: travel.followLocation,
          onChanged: travel.travelMode
              ? (on) => _setFollow(context, ref, on)
              : null,
        ),
        SettingsLinkRow(
          title: l10n.inFlightHelpTitle,
          value: l10n.travelInFlightValue,
          onTap: () => openInFlight(context),
          divider: false,
        ),
      ],
    );
  }
}

/// "English · Dark".
String languageLookSummary(
  AppLocalizations l10n,
  AppSettingsSnapshot settings,
) => l10n.settingsSummaryPair(
  languageName(l10n, settings.language),
  themeModeName(l10n, settings.themeMode),
);

/// Language and look (spec §4.9).
class LanguageLookPage extends ConsumerWidget {
  const LanguageLookPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;

    return SettingsScaffold(
      title: l10n.settingsLanguageLook,
      lead: l10n.settingsLanguageLookLead,
      children: [
        SettingsHeading(l10n.settingsLanguage, top: 4),
        RadioList<AppLanguage>(
          options: [
            for (final language in AppLanguage.values)
              RadioOption(language, languageName(l10n, language)),
          ],
          selected: settings.language,
          onChanged: (l) {
            if (l != settings.language) {
              ref.read(appLocaleProvider.notifier).choose(l);
            }
          },
        ),
        SettingsHeading(l10n.settingsTheme),
        RadioList<AppThemeMode>(
          options: [
            for (final mode in const [
              AppThemeMode.system,
              AppThemeMode.light,
              AppThemeMode.dark,
            ])
              RadioOption(mode, themeModeName(l10n, mode)),
          ],
          selected: settings.themeMode,
          onChanged: (mode) {
            if (mode != settings.themeMode) {
              ref.read(themeModeProvider.notifier).choose(mode);
            }
          },
        ),
        SettingsNote(l10n.themeSkyNote),
      ],
    );
  }
}

/// Help and about (spec §4.9).
class HelpAboutPage extends StatelessWidget {
  const HelpAboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.settingsHelpAbout,
      lead: l10n.settingsHelpLead,
      children: [
        SettingsLinkRow(
          title: l10n.settingsShowIntro,
          onTap: () => replayOnboarding(context),
        ),
        SettingsLinkRow(
          title: l10n.helpLateAlerts,
          onTap: () => pushSettingsPage(context, const LateAlertsPage()),
        ),
        SettingsLinkRow(
          title: l10n.diagnosticsTitle,
          onTap: () => pushSettingsPage(context, const DiagnosticsPage()),
        ),
        SettingsLinkRow(
          title: l10n.scheduledTitle,
          onTap: () => openScheduledNotifications(context),
          divider: false,
        ),
        SettingsHeading(l10n.helpAbout),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 10),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: BrandLockup(
              fontSize: 22,
              ink: HorizonTheme.of(context).surfaces.onSurface,
            ),
          ),
        ),
        SettingsNote(l10n.aboutBody, top: 0),
        // Which build this is, for testers' reports; left to right in
        // either language.
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            buildLabel(),
            textDirection: TextDirection.ltr,
            style: HorizonTheme.typeOf(context).meta.copyWith(
              color: HorizonTheme.of(context).surfaces.onSurfaceMuted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Why an alert may come late, and what to do about it.
class LateAlertsPage extends StatelessWidget {
  const LateAlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SettingsScaffold(
      title: l10n.helpLateAlerts,
      lead: l10n.helpLateAlertsLead,
      children: [
        SettingsHeading(l10n.helpBatteryTitle, top: 4),
        SettingsNote(l10n.scheduledBatteryHint, top: 0),
        SettingsHeading(l10n.helpCheckTitle),
        SettingsNote(l10n.helpCheckBody, top: 0),
        const SizedBox(height: 12),
        SettingsButton(
          label: l10n.scheduledTitle,
          onPressed: () => openScheduledNotifications(context),
        ),
      ],
    );
  }
}
