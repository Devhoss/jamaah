import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/prayer.dart';
import '../components/line_icon.dart';
import '../sky/sky_palette.dart';
import 'alert_choice.dart';

/// One of the six times on Today.
@immutable
class PrayerRowData {
  const PrayerRowData({
    required this.prayer,
    required this.name,
    required this.time,
    required this.alert,
    this.iqama,
    this.isNext = false,
    this.selected = false,
  });

  final Prayer prayer;

  /// "Jumu’ah" on Fridays.
  final String name;

  /// Null when the day has no time for it.
  final String? time;

  /// "Iqama 3:09", "Iqama not set", or null for Sunrise.
  final String? iqama;
  final AlertChoice alert;
  final bool isNext;
  final bool selected;
}

/// Imsak, Duha, the last third of the night: quieter, never selectable,
/// no alert button here (their alerts live in Settings).
@immutable
class ExtraRowData {
  const ExtraRowData({required this.name, required this.time});

  final String name;
  final String time;
}

sealed class TodayRow {
  const TodayRow();
}

final class PrayerTodayRow extends TodayRow {
  const PrayerTodayRow(this.data);

  final PrayerRowData data;
}

final class ExtraTodayRow extends TodayRow {
  const ExtraTodayRow(this.data);

  final ExtraRowData data;
}

/// The day's rows on the sky (spec §4.1): tapping a row glides the sun to it;
/// the alert button beside it opens that prayer's alert sheet.
class PrayerRows extends StatelessWidget {
  const PrayerRows({
    required this.rows,
    required this.palette,
    required this.onPick,
    required this.onAlert,
    super.key,
  });

  final List<TodayRow> rows;
  final SkyPalette palette;
  final ValueChanged<Prayer> onPick;
  final ValueChanged<Prayer> onAlert;

  static const alertWidth = 58.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final row in rows)
          switch (row) {
            PrayerTodayRow(:final data) => _PrayerRow(
              data: data,
              palette: palette,
              onPick: () => onPick(data.prayer),
              onAlert: () => onAlert(data.prayer),
            ),
            ExtraTodayRow(:final data) => _ExtraRow(
              data: data,
              palette: palette,
            ),
          },
      ],
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.data,
    required this.palette,
    required this.onPick,
    required this.onAlert,
  });

  final PrayerRowData data;
  final SkyPalette palette;
  final VoidCallback onPick;
  final VoidCallback onAlert;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final sunrise = data.prayer == Prayer.sunrise;
    final still = MediaQuery.disableAnimationsOf(context);

    final nameStyle = sunrise
        ? type.row.copyWith(
            fontWeight: FontWeight.w400,
            fontStyle: Localizations.localeOf(context).languageCode == 'ar'
                ? FontStyle.normal
                : FontStyle.italic,
            color: palette.mute,
          )
        : type.row.copyWith(color: palette.ink);
    final timeStyle = type.rowTime.copyWith(
      fontWeight: sunrise ? FontWeight.w400 : FontWeight.w500,
      color: sunrise ? palette.mute : palette.ink,
    );

    return AnimatedContainer(
      duration: still ? Duration.zero : const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: data.selected ? palette.halo : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Semantics(
                button: true,
                selected: data.selected,
                child: InkWell(
                  onTap: onPick,
                  borderRadius: BorderRadius.circular(12),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: HorizonShape.prayerRowMin,
                    ),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        10,
                        6,
                        4,
                        6,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 3,
                            height: 18,
                            decoration: BoxDecoration(
                              color: data.selected
                                  ? palette.ink
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(data.name, style: nameStyle),
                                if (data.isNext)
                                  _NextTag(
                                    label: l10n.tagNext,
                                    palette: palette,
                                    style: type.kicker,
                                  ),
                                if (data.iqama != null)
                                  Text(
                                    data.iqama!,
                                    style: type.meta.copyWith(
                                      fontSize: 12,
                                      color: palette.mute,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 70),
                            child: Text(
                              data.time ?? l10n.noTimeToday,
                              textAlign: TextAlign.end,
                              style: data.time == null
                                  ? type.meta.copyWith(color: palette.mute)
                                  : timeStyle,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _AlertButton(
              prayerName: data.name,
              choice: data.alert,
              palette: palette,
              onTap: onAlert,
            ),
          ],
        ),
      ),
    );
  }
}

class _NextTag extends StatelessWidget {
  const _NextTag({
    required this.label,
    required this.palette,
    required this.style,
  });

  final String label;
  final SkyPalette palette;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: palette.ink,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        arabic ? label : label.toUpperCase(),
        style: style.copyWith(
          fontSize: 10,
          letterSpacing: arabic ? 0 : 1,
          color: palette.deep,
        ),
      ),
    );
  }
}

/// The alert button: icon + word, never colour alone (spec §6).
class _AlertButton extends StatelessWidget {
  const _AlertButton({
    required this.prayerName,
    required this.choice,
    required this.palette,
    required this.onTap,
  });

  final String prayerName;
  final AlertChoice choice;
  final SkyPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final off = choice == AlertChoice.off;
    final color = off ? palette.mute : palette.ink;
    return Semantics(
      button: true,
      label: l10n.alertButtonSemantics(
        prayerName,
        alertLongLabel(l10n, choice),
      ),
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: PrayerRows.alertWidth,
          constraints: const BoxConstraints(
            minHeight: HorizonShape.prayerRowMin,
          ),
          decoration: BoxDecoration(
            border: BorderDirectional(start: BorderSide(color: palette.line)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              LineIcon(alertIcon(choice), size: 19, color: color),
              const SizedBox(height: 2),
              Text(
                alertShortLabel(l10n, choice),
                textAlign: TextAlign.center,
                style: type.meta.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExtraRow extends StatelessWidget {
  const _ExtraRow({required this.data, required this.palette});

  final ExtraRowData data;
  final SkyPalette palette;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final style = type.meta.copyWith(fontSize: 14, color: palette.mute);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 40),
      child: Padding(
        // Lined up with the prayers' names and times; the alert column is
        // left empty.
        padding: const EdgeInsetsDirectional.only(
          start: 22,
          end: 4 + PrayerRows.alertWidth,
        ),
        child: Row(
          children: [
            Expanded(child: Text(data.name, style: style)),
            Text(
              data.time,
              style: type.rowTime.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: palette.mute,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

LineIconData alertIcon(AlertChoice choice) => switch (choice) {
  AlertChoice.full => LineIcons.soundFull,
  AlertChoice.short => LineIcons.soundShort,
  AlertChoice.standard => LineIcons.bell,
  AlertChoice.silent => LineIcons.silent,
  AlertChoice.off => LineIcons.bellOff,
};

/// "Full", "Short", "Standard", "Silent", "Off": the word under the icon.
String alertShortLabel(AppLocalizations l10n, AlertChoice choice) =>
    switch (choice) {
      AlertChoice.full => l10n.alertShortFull,
      AlertChoice.short => l10n.alertShortShort,
      AlertChoice.standard => l10n.alertShortStandard,
      AlertChoice.silent => l10n.alertShortSilent,
      AlertChoice.off => l10n.alertShortOff,
    };

/// "Full Adhan", "Short Adhan", "Standard sound", "Silent", "Off".
String alertLongLabel(AppLocalizations l10n, AlertChoice choice) =>
    switch (choice) {
      AlertChoice.full => l10n.soundModeFull,
      AlertChoice.short => l10n.soundModeShort,
      AlertChoice.standard => l10n.soundModeStandard,
      AlertChoice.silent => l10n.soundModeSilent,
      AlertChoice.off => l10n.alertShortOff,
    };
