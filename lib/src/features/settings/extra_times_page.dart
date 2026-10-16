import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../data/settings_repository.dart';
import '../../domain/extra_times.dart';
import 'settings_kit.dart';

Future<void> openExtraTimes(BuildContext context) =>
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ExtraTimesPage()));

/// What Settings says under "Extra times": the ones on Today, or none.
String extraTimesSummary(AppLocalizations l10n, ExtraTimesSettings extra) {
  final names = [
    for (final t in ExtraTime.values)
      if (extra.shown.contains(t)) extraTimeName(l10n, t),
  ];
  return names.isEmpty ? l10n.extraNoneShown : names.join(l10n.listSeparator);
}

/// When an extra time falls: "10 min before Fajr", or the last third's rule.
String extraRuleLine(
  AppLocalizations l10n,
  ExtraTimesSettings extra,
  ExtraTime t,
) => switch (t) {
  ExtraTime.imsak => l10n.extraImsakRule(extra.imsakMinutes),
  ExtraTime.duha => l10n.extraDuhaRule(extra.duhaMinutes),
  ExtraTime.qiyam => l10n.extraQiyamRule,
};

/// Which extra times alert, or none.
String extraAlertsSummary(AppLocalizations l10n, ExtraTimesSettings extra) {
  final names = [
    for (final t in ExtraTime.values)
      if (extra.alerts.contains(t)) extraTimeName(l10n, t),
  ];
  return names.isEmpty
      ? l10n.extraNoAlerts
      : l10n.extraAlertsFor(names.join(l10n.listSeparator));
}

/// Settings → Prayer times → Alerts and timing (2026-10-14): Imsak, Duha and
/// the last third of the night. For each, whether Today shows it and whether
/// it alerts; for Imsak and Duha, their minutes.
class ExtraTimesPage extends ConsumerWidget {
  const ExtraTimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final extra =
        ref.watch(appSettingsProvider).value?.extraTimes ??
        SettingsRepository.defaults.extraTimes;

    Future<void> save(ExtraTimesSettings next) =>
        ref.read(settingsRepositoryProvider).saveExtraTimes(next);

    Future<void> setShown(ExtraTime t, bool on) =>
        save(extra.copyWith(shown: {...extra.shown}..toggle(t, on)));

    Future<void> setAlert(ExtraTime t, bool on) async {
      await save(extra.copyWith(alerts: {...extra.alerts}..toggle(t, on)));
      if (on) await ref.read(notificationPermissionRequestProvider)();
    }

    Widget rule(ExtraTime t) => switch (t) {
      ExtraTime.imsak => SettingsLinkRow(
        title: l10n.extraImsakRule(extra.imsakMinutes),
        onTap: () async {
          final m = await _chooseMinutes(
            context,
            title: l10n.extraImsak,
            current: extra.imsakMinutes,
            choices: const [0, 5, 10, 15, 20],
            label: l10n.extraImsakRule,
          );
          if (m != null) await save(extra.copyWith(imsakMinutes: m));
        },
      ),
      ExtraTime.duha => SettingsLinkRow(
        title: l10n.extraDuhaRule(extra.duhaMinutes),
        onTap: () async {
          final m = await _chooseMinutes(
            context,
            title: l10n.extraDuha,
            current: extra.duhaMinutes,
            choices: const [10, 15, 20, 25, 30],
            label: l10n.extraDuhaRule,
          );
          if (m != null) await save(extra.copyWith(duhaMinutes: m));
        },
      ),
      ExtraTime.qiyam => SettingsNote(l10n.extraQiyamRule, top: 0),
    };

    return SettingsScaffold(
      title: l10n.settingsExtraTimes,
      lead: l10n.extraTimesIntro,
      children: [
        for (final (i, t) in ExtraTime.values.indexed) ...[
          SettingsHeading(extraTimeName(l10n, t), top: i == 0 ? 4 : 22),
          rule(t),
          SettingsSwitchRow(
            key: ValueKey('show-${t.name}'),
            title: l10n.extraShowOnToday,
            value: extra.shown.contains(t),
            onChanged: (on) => setShown(t, on),
          ),
          SettingsSwitchRow(
            key: ValueKey('alert-${t.name}'),
            title: l10n.extraAlert,
            hint: l10n.extraAlertHint,
            value: extra.alerts.contains(t),
            divider: false,
            onChanged: (on) => setAlert(t, on),
          ),
        ],
      ],
    );
  }
}

Future<int?> _chooseMinutes(
  BuildContext context, {
  required String title,
  required int current,
  required List<int> choices,
  required String Function(int) label,
}) => showSettingsSheet<int>(
  context,
  builder: (sheetContext) => SettingsSheetBody(
    title: title,
    children: [
      RadioList<int>(
        options: [for (final m in choices) RadioOption(m, label(m))],
        selected: current,
        onChanged: (m) => Navigator.of(sheetContext).pop(m),
      ),
    ],
  ),
);

/// Adds or removes one extra time.
extension ExtraTimeToggle on Set<ExtraTime> {
  void toggle(ExtraTime t, bool on) => on ? add(t) : remove(t);
}
