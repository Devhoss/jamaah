import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/adhan_alerts.dart';
import '../today/alert_choice.dart';
import '../today/prayer_rows.dart';

/// One prayer's Adhan alert, chosen on a calm surface sheet (spec §2.5):
/// "Notify with sound" (Full Adhan, Short Adhan, Standard sound),
/// "Notify without sound" (Silent), a divider, then Off. The option that is
/// the global default says "· Default" (owner, 2026-10-15).
///
/// Each pick is applied at once through [onChoose]; Done closes the sheet.
Future<void> showAlertSheet(
  BuildContext context, {
  required String prayerName,
  required String adhanTime,
  required AlertChoice current,
  required AdhanSoundMode defaultMode,
  required Future<void> Function(AlertChoice) onChoose,
}) {
  final surfaces = HorizonTheme.of(context).surfaces;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: surfaces.surface,
    barrierColor: surfaces.scrim,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(HorizonShape.sheetRadius),
      ),
    ),
    builder: (context) => AlertSheet(
      prayerName: prayerName,
      adhanTime: adhanTime,
      current: current,
      defaultMode: defaultMode,
      onChoose: onChoose,
    ),
  );
}

class AlertSheet extends StatefulWidget {
  const AlertSheet({
    required this.prayerName,
    required this.adhanTime,
    required this.current,
    required this.defaultMode,
    required this.onChoose,
    super.key,
  });

  final String prayerName;
  final String adhanTime;
  final AlertChoice current;
  final AdhanSoundMode defaultMode;
  final Future<void> Function(AlertChoice) onChoose;

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  late AlertChoice _choice = widget.current;

  Future<void> _pick(AlertChoice choice) async {
    setState(() => _choice = choice);
    await widget.onChoose(choice);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final arabic = Localizations.localeOf(context).languageCode == 'ar';

    Widget group(String title) => Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 2),
      child: Semantics(
        header: true,
        child: Text(
          arabic ? title : title.toUpperCase(),
          style: type.kicker.copyWith(fontSize: 11, color: s.onSurfaceMuted),
        ),
      ),
    );

    Widget option(AlertChoice choice, String description) {
      final isDefault = choice.soundMode == widget.defaultMode;
      final label = alertLongLabel(l10n, choice);
      return _RadioRow(
        label: isDefault ? l10n.alertDefaultMark(label) : label,
        description: description,
        selected: _choice == choice,
        surfaces: s,
        type: type,
        onTap: () => _pick(choice),
      );
    }

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: 12,
              children: [
                Semantics(
                  header: true,
                  child: Text(
                    l10n.alertSheetTitle(widget.prayerName),
                    style: type.prayerName.copyWith(color: s.onSurface),
                  ),
                ),
                Text(
                  l10n.alertSheetAdhan(widget.adhanTime),
                  style: type.body.copyWith(
                    fontSize: 14,
                    color: s.onSurfaceMuted,
                  ),
                ),
              ],
            ),
            group(l10n.alertGroupSound),
            option(AlertChoice.full, l10n.alertFullHint),
            option(AlertChoice.short, l10n.alertShortHint),
            option(AlertChoice.standard, l10n.alertStandardHint),
            group(l10n.alertGroupQuiet),
            option(AlertChoice.silent, l10n.alertDescSilent),
            const SizedBox(height: 8),
            Divider(color: s.divider, height: 1),
            const SizedBox(height: 4),
            option(AlertChoice.off, l10n.alertDescOff),
            const SizedBox(height: 12),
            SizedBox(
              height: 52,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: s.accent,
                  foregroundColor: s.onAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: type.row.copyWith(fontWeight: FontWeight.w500),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.alertDone),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 20 px ring, filled thick when selected, with a label and one line of
/// description (spec §2.5 RadioList).
class _RadioRow extends StatelessWidget {
  const _RadioRow({
    required this.label,
    required this.description,
    required this.selected,
    required this.surfaces,
    required this.type,
    required this.onTap,
  });

  final String label;
  final String description;
  final bool selected;
  final HorizonSurfaces surfaces;
  final HorizonType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      label: label,
      hint: description,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 54),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected
                          ? surfaces.onSurface
                          : surfaces.onSurfaceMuted,
                      width: selected ? 6 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        label,
                        style: type.row.copyWith(
                          fontWeight: FontWeight.w500,
                          color: surfaces.onSurface,
                        ),
                      ),
                      Text(
                        description,
                        style: type.meta.copyWith(
                          color: surfaces.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
