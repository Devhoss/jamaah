import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/notification_scheduler.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/extra_times.dart';
import '../components/app_widgets.dart';

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

/// Settings → Extra times (2026-10-14): Imsak, Duha and the last third of
/// the night. For each, whether Today shows it and whether it alerts; for
/// Imsak and Duha, their minutes.
class ExtraTimesPage extends ConsumerWidget {
  const ExtraTimesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
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
      ExtraTime.imsak => AppRow(
        leading: null,
        onTap: () async {
          final m = await _chooseMinutes(
            context,
            current: extra.imsakMinutes,
            choices: const [0, 5, 10, 15, 20],
            label: l10n.extraImsakRule,
          );
          if (m != null) await save(extra.copyWith(imsakMinutes: m));
        },
        title: Text(l10n.extraImsakRule(extra.imsakMinutes)),
        trailing: Icon(Icons.chevron_right, color: ink.muted),
      ),
      ExtraTime.duha => AppRow(
        leading: null,
        onTap: () async {
          final m = await _chooseMinutes(
            context,
            current: extra.duhaMinutes,
            choices: const [10, 15, 20, 25, 30],
            label: l10n.extraDuhaRule,
          );
          if (m != null) await save(extra.copyWith(duhaMinutes: m));
        },
        title: Text(l10n.extraDuhaRule(extra.duhaMinutes)),
        trailing: Icon(Icons.chevron_right, color: ink.muted),
      ),
      ExtraTime.qiyam => AppRow(
        leading: null,
        title: Text(l10n.extraQiyamRule),
      ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsExtraTimes)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          AppSpace.md,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.extraTimesIntro, style: theme.textTheme.bodyMedium),
          for (final t in ExtraTime.values) ...[
            AppSectionHeader(extraTimeName(l10n, t)),
            AppRows(
              children: [
                rule(t),
                SwitchListTile(
                  key: ValueKey('show-${t.name}'),
                  title: Text(l10n.extraShowOnToday),
                  value: extra.shown.contains(t),
                  onChanged: (on) => setShown(t, on),
                ),
                SwitchListTile(
                  key: ValueKey('alert-${t.name}'),
                  title: Text(l10n.extraAlert),
                  subtitle: Text(l10n.extraAlertHint),
                  value: extra.alerts.contains(t),
                  onChanged: (on) => setAlert(t, on),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

Future<int?> _chooseMinutes(
  BuildContext context, {
  required int current,
  required List<int> choices,
  required String Function(int) label,
}) => showModalBottomSheet<int>(
  context: context,
  showDragHandle: true,
  isScrollControlled: true,
  builder: (sheetContext) => SafeArea(
    child: SingleChildScrollView(
      child: RadioGroup<int>(
        groupValue: current,
        onChanged: (m) => Navigator.of(sheetContext).pop(m),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final m in choices)
              RadioListTile<int>(value: m, title: Text(label(m))),
          ],
        ),
      ),
    ),
  ),
);

/// Adds or removes one extra time.
extension ExtraTimeToggle on Set<ExtraTime> {
  void toggle(ExtraTime t, bool on) => on ? add(t) : remove(t);
}
