import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../components/line_icon.dart';
import '../sky/sky_palette.dart';

/// What the ticket shows for the selected prayer at the active mosque.
sealed class TicketContent {
  const TicketContent();
}

/// An Iqama the user has set.
final class TicketSet extends TicketContent {
  const TicketSet({
    required this.mosque,
    required this.time,
    required this.relative,
    required this.rule,
    required this.reminder,
    required this.reminderOn,
    this.isJumuah = false,
    this.note,
  });

  final String mosque;

  /// "3:09 PM"
  final String time;

  /// "in 1 h 10 min" / "5 min ago"
  final String relative;

  /// "Adhan + 20 min · set by you" / "Fixed time · set by you"
  final String rule;

  /// "Reminder 2:59" / "No reminder"
  final String reminder;
  final bool reminderOn;

  /// This ticket is a Friday Khutbah time and arrival reminder.
  final bool isJumuah;

  /// Fridays with no Jumu'ah time: "Jumu’ah time not set · Dhuhr Iqama 11:45".
  final String? note;
}

/// The mosque has no Iqama for this prayer: a dashed outline and "Set time".
/// Calm, never error-coloured. The app never fills one in (AGENTS.md).
final class TicketNotConfigured extends TicketContent {
  const TicketNotConfigured({
    required this.mosque,
    required this.onSet,
    this.isJumuah = false,
  });

  final String mosque;
  final VoidCallback onSet;
  final bool isJumuah;
}

/// Sunrise is not a prayer: it has no Iqama.
final class TicketSunrise extends TicketContent {
  const TicketSunrise();
}

/// No active mosque yet.
final class TicketNoMosque extends TicketContent {
  const TicketNoMosque({required this.onAdd});

  final VoidCallback onAdd;
}

/// The mosque's Iqama as a separate solid "ticket" under the hero (spec §2.5):
/// a box in `ink` with `deep` text, so it never reads as part of the Adhan.
class IqamaTicket extends StatelessWidget {
  const IqamaTicket({required this.content, required this.palette, super.key});

  final TicketContent content;
  final SkyPalette palette;

  static const minHeight = 62.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final radius = BorderRadius.circular(14);

    switch (content) {
      case final TicketSet set:
        final deep = palette.deep;
        final soft = palette.deepSoft;
        return Semantics(
          container: true,
          label: set.isJumuah
              ? l10n.jumuahTicketSemantics(
                  set.mosque,
                  set.time,
                  set.relative,
                  set.rule,
                  set.reminder,
                )
              : l10n.ticketSemantics(
                  set.mosque,
                  set.time,
                  set.relative,
                  set.rule,
                  set.reminder,
                ),
          excludeSemantics: true,
          child: Container(
            constraints: const BoxConstraints(minHeight: minHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: palette.fill,
              borderRadius: radius,
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final kickerStyle = type.kicker.copyWith(color: soft);
                final reminderStyle = type.meta.copyWith(
                  fontWeight: FontWeight.w500,
                  color: deep,
                );
                final reminder = Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (set.reminderOn) ...[
                      LineIcon(
                        LineIcons.bell,
                        size: 15,
                        strokeWidth: 2,
                        color: deep,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Flexible(child: Text(set.reminder, style: reminderStyle)),
                  ],
                );
                // When the mosque's name would wrap beside the reminder, the
                // reminder takes its own line under the time and the kicker
                // gets the full width (owner, 2026-10-16).
                final scaler = MediaQuery.textScalerOf(context);
                final direction = Directionality.of(context);
                double widthOf(InlineSpan span) {
                  final painter = TextPainter(
                    text: span,
                    textDirection: direction,
                    textScaler: scaler,
                    maxLines: 1,
                  )..layout();
                  final w = painter.width;
                  painter.dispose();
                  return w;
                }

                final kickerWidth = widthOf(
                  _kickerSpan(
                    context,
                    l10n,
                    set.mosque,
                    kickerStyle,
                    isJumuah: set.isJumuah,
                  ),
                );
                final reminderWidth =
                    widthOf(
                      TextSpan(text: set.reminder, style: reminderStyle),
                    ) +
                    (set.reminderOn ? 21 : 0);
                final stacked =
                    kickerWidth + 14 + reminderWidth > constraints.maxWidth;

                final details = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _kicker(
                      context,
                      l10n,
                      set.mosque,
                      kickerStyle,
                      isJumuah: set.isJumuah,
                    ),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: set.time,
                            style: type.rowTime.copyWith(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: deep,
                            ),
                          ),
                          const TextSpan(text: ' '),
                          TextSpan(
                            text: l10n.ticketWhen(set.relative),
                            style: type.meta.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: soft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (stacked)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: reminder,
                      ),
                    Text(set.rule, style: type.meta.copyWith(color: soft)),
                    if (set.note != null)
                      Text(set.note!, style: type.meta.copyWith(color: soft)),
                  ],
                );
                if (stacked) return details;
                return Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 14),
                    reminder,
                  ],
                );
              },
            ),
          ),
        );

      case final TicketNotConfigured unset:
        return Semantics(
          button: true,
          label: unset.isJumuah
              ? l10n.jumuahTicketUnsetSemantics(unset.mosque)
              : l10n.ticketUnsetSemantics(unset.mosque),
          excludeSemantics: true,
          child: InkWell(
            onTap: unset.onSet,
            borderRadius: radius,
            child: CustomPaint(
              painter: _DashedBorder(color: palette.mute, radius: 14),
              child: Container(
                constraints: const BoxConstraints(minHeight: minHeight),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _kicker(
                            context,
                            l10n,
                            unset.mosque,
                            type.kicker.copyWith(color: palette.mute),
                            isJumuah: unset.isJumuah,
                          ),
                          Text(
                            l10n.notConfigured,
                            style: type.row.copyWith(
                              fontWeight: FontWeight.w500,
                              color: palette.ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 44),
                      child: Center(
                        widthFactor: 1,
                        child: Text(
                          l10n.ticketSetTime,
                          style: type.body.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: palette.ink,
                            decoration: TextDecoration.underline,
                            decorationColor: palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

      case TicketSunrise():
        return Container(
          constraints: const BoxConstraints(minHeight: minHeight),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: palette.line),
          ),
          child: Text(
            l10n.ticketSunrise,
            style: type.body.copyWith(fontSize: 14, color: palette.mute),
          ),
        );

      case final TicketNoMosque none:
        return Semantics(
          button: true,
          child: InkWell(
            onTap: none.onAdd,
            borderRadius: radius,
            child: Container(
              constraints: const BoxConstraints(minHeight: minHeight),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: radius,
                border: Border.all(color: palette.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.addMosqueTitle,
                          style: type.row.copyWith(color: palette.ink),
                        ),
                        Text(
                          l10n.ticketNoMosque,
                          style: type.meta.copyWith(color: palette.mute),
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
        );
    }
  }

  /// "IQAMA · Masjid al-Nour": the label in capitals, the mosque's name as
  /// the user typed it, with ordinary letter spacing so a long name neither
  /// shouts nor wraps early (owner, 2026-10-16). Arabic has no case.
  static Widget _kicker(
    BuildContext context,
    AppLocalizations l10n,
    String mosque,
    TextStyle style, {
    bool isJumuah = false,
  }) => Text.rich(
    _kickerSpan(context, l10n, mosque, style, isJumuah: isJumuah),
    maxLines: 2,
    overflow: TextOverflow.ellipsis,
  );

  static TextSpan _kickerSpan(
    BuildContext context,
    AppLocalizations l10n,
    String mosque,
    TextStyle style, {
    bool isJumuah = false,
  }) {
    const mark = '\u0000';
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final template = isJumuah
        ? l10n.jumuahTicketKicker(mark)
        : l10n.ticketKicker(mark);
    final parts = (arabic ? template : template.toUpperCase()).split(mark);
    return TextSpan(
      style: style,
      children: [
        TextSpan(text: parts.first),
        TextSpan(text: mosque, style: style.copyWith(letterSpacing: 0.2)),
        if (parts.length > 1) TextSpan(text: parts.sublist(1).join()),
      ],
    );
  }
}

/// A 1.5 px dashed rounded outline: "not configured" is a shape plus words,
/// never a colour (spec §6).
class _DashedBorder extends CustomPainter {
  _DashedBorder({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      (Offset.zero & size).deflate(0.75),
      Radius.circular(radius),
    );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (final metric in (Path()..addRRect(rrect)).computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 5), paint);
        d += 9;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) =>
      old.color != color || old.radius != radius;
}
