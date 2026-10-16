import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/l10n/prayer_labels.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../data/settings_repository.dart';
import '../../domain/prayer.dart';
import '../../domain/prayer_times_parameters.dart';
import '../components/app_widgets.dart';

String methodName(AppLocalizations l10n, CalculationMethod m) => switch (m) {
  CalculationMethod.auto => l10n.methodAuto,
  CalculationMethod.custom => l10n.methodCustom,
  CalculationMethod.egyptian => l10n.methodEgyptian,
  CalculationMethod.isna => l10n.methodIsna,
  CalculationMethod.moonsightingCommittee => l10n.methodMoonsightingCommittee,
  CalculationMethod.muslimWorldLeague => l10n.methodMuslimWorldLeague,
  CalculationMethod.ummAlQura => l10n.methodUmmAlQura,
  CalculationMethod.karachi => l10n.methodKarachi,
  CalculationMethod.jakim => l10n.methodJakim,
  CalculationMethod.singapore => l10n.methodSingapore,
  CalculationMethod.indonesia => l10n.methodIndonesia,
  CalculationMethod.turkiye => l10n.methodTurkiye,
  CalculationMethod.france => l10n.methodFrance,
  CalculationMethod.kuwait => l10n.methodKuwait,
  CalculationMethod.qatar => l10n.methodQatar,
  CalculationMethod.dubai => l10n.methodDubai,
  CalculationMethod.gulfRegion => l10n.methodGulfRegion,
  CalculationMethod.jordan => l10n.methodJordan,
  CalculationMethod.algeria => l10n.methodAlgeria,
  CalculationMethod.morocco => l10n.methodMorocco,
  CalculationMethod.tunisia => l10n.methodTunisia,
  CalculationMethod.russia => l10n.methodRussia,
  CalculationMethod.portugal => l10n.methodPortugal,
  CalculationMethod.tehran => l10n.methodTehran,
  CalculationMethod.jafari => l10n.methodJafari,
};

String? methodRegion(AppLocalizations l10n, CalculationMethod m) => switch (m) {
  CalculationMethod.auto || CalculationMethod.custom => null,
  CalculationMethod.egyptian => l10n.methodRegionEgyptian,
  CalculationMethod.isna => l10n.methodRegionIsna,
  CalculationMethod.moonsightingCommittee =>
    l10n.methodRegionMoonsightingCommittee,
  CalculationMethod.muslimWorldLeague => l10n.methodRegionMuslimWorldLeague,
  CalculationMethod.ummAlQura => l10n.methodRegionUmmAlQura,
  CalculationMethod.karachi => l10n.methodRegionKarachi,
  CalculationMethod.jakim => l10n.methodRegionJakim,
  CalculationMethod.singapore => l10n.methodRegionSingapore,
  CalculationMethod.indonesia => l10n.methodRegionIndonesia,
  CalculationMethod.turkiye => l10n.methodRegionTurkiye,
  CalculationMethod.france => l10n.methodRegionFrance,
  CalculationMethod.kuwait => l10n.methodRegionKuwait,
  CalculationMethod.qatar => l10n.methodRegionQatar,
  CalculationMethod.dubai => l10n.methodRegionDubai,
  CalculationMethod.gulfRegion => l10n.methodRegionGulfRegion,
  CalculationMethod.jordan => l10n.methodRegionJordan,
  CalculationMethod.algeria => l10n.methodRegionAlgeria,
  CalculationMethod.morocco => l10n.methodRegionMorocco,
  CalculationMethod.tunisia => l10n.methodRegionTunisia,
  CalculationMethod.russia => l10n.methodRegionRussia,
  CalculationMethod.portugal => l10n.methodRegionPortugal,
  CalculationMethod.tehran => l10n.methodRegionTehran,
  CalculationMethod.jafari => l10n.methodRegionJafari,
};

/// "Fajr 19.5° · Isha 17.5°", or with Isha in minutes after Maghrib.
String methodAnglesLine(
  AppLocalizations l10n,
  CalculationMethod m, {
  CustomAngles custom = const CustomAngles(),
}) {
  final a = methodAngles(m, custom: custom);
  String deg(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(1) : v.toString();
  final minutes = a.ishaMinutes;
  return minutes != null
      ? l10n.methodAnglesInterval(deg(a.fajrAngle), minutes)
      : l10n.methodAngles(deg(a.fajrAngle), deg(a.ishaAngle ?? 0));
}

String asrName(AppLocalizations l10n, Madhab m) =>
    m == Madhab.standard ? l10n.asrStandard : l10n.asrHanafi;

String ruleTitle(AppLocalizations l10n, HighLatitudeRule r) => switch (r) {
  HighLatitudeRule.middleOfTheNight => l10n.ruleMiddleOfTheNightTitle,
  HighLatitudeRule.seventhOfTheNight => l10n.ruleSeventhOfTheNightTitle,
  HighLatitudeRule.twilightAngle => l10n.ruleTwilightAngleTitle,
};

String ruleHint(AppLocalizations l10n, HighLatitudeRule r) => switch (r) {
  HighLatitudeRule.middleOfTheNight => l10n.ruleMiddleOfTheNightHint,
  HighLatitudeRule.seventhOfTheNight => l10n.ruleSeventhOfTheNightHint,
  HighLatitudeRule.twilightAngle => l10n.ruleTwilightAngleHint,
};

/// "0, 0, 0, 0, 0, 0" in the order of the day, or "None".
String adjustmentsSummary(AppLocalizations l10n, Map<Prayer, int> offsets) {
  if (offsets.values.every((m) => m == 0)) return l10n.adjustmentsNone;
  return [
    for (final p in Prayer.adhanPrayers)
      switch (offsets[p] ?? 0) {
        final m when m > 0 => '+$m',
        final m => '$m',
      },
  ].join(', ');
}

/// Every method: name, angles and where it is used, like the reference app.
class MethodListPage extends ConsumerWidget {
  const MethodListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final settings =
        ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
    final place = ref.watch(currentPlaceProvider);
    final selected = settings.calculationMethod;
    final small = TextStyle(fontSize: 13, color: ink.muted);

    List<String> details(CalculationMethod m) => switch (m) {
      CalculationMethod.auto => [
        if (place == null)
          l10n.methodAutoNoPlace
        else ...[
          methodName(l10n, m.resolvedFor(place.ianaZone)),
          methodAnglesLine(l10n, m.resolvedFor(place.ianaZone)),
        ],
      ],
      CalculationMethod.custom => [
        methodAnglesLine(l10n, m, custom: settings.customAngles),
      ],
      _ => [
        methodAnglesLine(l10n, m),
        if (m == CalculationMethod.ummAlQura) l10n.methodUmmAlQuraRamadan,
        if (m == CalculationMethod.moonsightingCommittee)
          l10n.methodMoonsightingNote,
        ?methodRegion(l10n, m),
      ],
    };

    Future<void> choose(CalculationMethod m) async {
      if (m == CalculationMethod.custom) {
        final saved = await showCustomAnglesSheet(
          context,
          settings.customAngles,
        );
        if (saved == null) return;
        await ref
            .read(settingsRepositoryProvider)
            .setPrayerTimesPreferences(
              calculationMethod: m,
              customAngles: saved,
            );
      } else {
        await ref
            .read(settingsRepositoryProvider)
            .setPrayerTimesPreferences(calculationMethod: m);
      }
      if (context.mounted) Navigator.of(context).pop();
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsMethod)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          0,
          AppSpace.lg,
          AppSpace.xxl,
        ),
        children: [
          AppRows(
            children: [
              for (final m in CalculationMethod.values)
                Semantics(
                  selected: m == selected,
                  child: AppRow(
                    selected: m == selected,
                    leading: Icon(
                      Icons.check,
                      size: 20,
                      color: m == selected
                          ? theme.colorScheme.primary
                          : Colors.transparent,
                    ),
                    onTap: () => choose(m),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          methodName(l10n, m),
                          style: const TextStyle(
                            fontSize: AppType.bodySize + 2,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        for (final line in details(m)) Text(line, style: small),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Edits the custom angles; resolves to them, or null when cancelled.
Future<CustomAngles?> showCustomAnglesSheet(
  BuildContext context,
  CustomAngles current,
) => showModalBottomSheet<CustomAngles>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => _CustomAnglesSheet(current: current),
);

class _CustomAnglesSheet extends StatefulWidget {
  const _CustomAnglesSheet({required this.current});

  final CustomAngles current;

  @override
  State<_CustomAnglesSheet> createState() => _CustomAnglesSheetState();
}

class _CustomAnglesSheetState extends State<_CustomAnglesSheet> {
  late final _fajr = TextEditingController(text: '${widget.current.fajrAngle}');
  late final _isha = TextEditingController(text: '${widget.current.ishaAngle}');
  late final _minutes = TextEditingController(
    text: '${widget.current.ishaMinutesAfterMaghrib ?? 90}',
  );
  late bool _byMinutes = widget.current.ishaMinutesAfterMaghrib != null;

  @override
  void dispose() {
    _fajr.dispose();
    _isha.dispose();
    _minutes.dispose();
    super.dispose();
  }

  double? _angle(TextEditingController c) {
    final v = double.tryParse(c.text.trim().replaceAll(',', '.'));
    return v != null && CustomAngles.validAngle(v) ? v : null;
  }

  int? _ishaMinutes() {
    final v = int.tryParse(_minutes.text.trim());
    return v != null && v >= 1 && v <= 180 ? v : null;
  }

  bool get _valid =>
      _angle(_fajr) != null &&
      (_byMinutes ? _ishaMinutes() != null : _angle(_isha) != null);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    String? angleError(TextEditingController c) =>
        c.text.isEmpty || _angle(c) != null ? null : l10n.customAngleError;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            0,
            AppSpace.xxl,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.customTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _fajr,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.customFajr,
                  errorText: angleError(_fajr),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.customIshaByMinutes),
                value: _byMinutes,
                onChanged: (on) => setState(() => _byMinutes = on),
              ),
              if (_byMinutes)
                TextField(
                  controller: _minutes,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: l10n.customIshaMinutes,
                    errorText: _minutes.text.isEmpty || _ishaMinutes() != null
                        ? null
                        : l10n.customMinutesError,
                  ),
                  onChanged: (_) => setState(() {}),
                )
              else
                TextField(
                  controller: _isha,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.customIsha,
                    errorText: angleError(_isha),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _valid
                          ? () => Navigator.of(context).pop(
                              CustomAngles(
                                fajrAngle: _angle(_fajr)!,
                                ishaAngle:
                                    _angle(_isha) ?? widget.current.ishaAngle,
                                ishaMinutesAfterMaghrib: _byMinutes
                                    ? _ishaMinutes()
                                    : null,
                              ),
                            )
                          : null,
                      child: Text(l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Minutes added to or taken from each calculated time.
class AdjustmentsPage extends ConsumerWidget {
  const AdjustmentsPage({super.key});

  static const limit = 30;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final offsets =
        (ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults)
            .minuteOffsets;

    Future<void> set(Prayer p, int minutes) => ref
        .read(settingsRepositoryProvider)
        .setPrayerTimesPreferences(
          minuteOffsets: {...offsets, p: minutes.clamp(-limit, limit)},
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAdjustments)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(
            l10n.adjustmentsHint,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: ink.muted),
          ),
          const SizedBox(height: AppSpace.md),
          AppRows(
            children: [
              for (final p in Prayer.adhanPrayers)
                AppRow(
                  leading: null,
                  title: Text(
                    prayerName(l10n, p),
                    style: const TextStyle(fontSize: AppType.rowSize),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: l10n.adjustmentsMinus(prayerName(l10n, p)),
                        onPressed: (offsets[p] ?? 0) > -limit
                            ? () => set(p, (offsets[p] ?? 0) - 1)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      SizedBox(
                        width: 64,
                        child: Text(
                          l10n.adjustmentsValue(offsets[p] ?? 0),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      IconButton(
                        tooltip: l10n.adjustmentsPlus(prayerName(l10n, p)),
                        onPressed: (offsets[p] ?? 0) < limit
                            ? () => set(p, (offsets[p] ?? 0) + 1)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: offsets.values.any((m) => m != 0)
                  ? () => ref
                        .read(settingsRepositoryProvider)
                        .setPrayerTimesPreferences(minuteOffsets: const {})
                  : null,
              child: Text(l10n.adjustmentsReset),
            ),
          ),
        ],
      ),
    );
  }
}
