import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../settings/settings_kit.dart';

Future<void> openInFlightHelp(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const InFlightHelpPage()));

/// "How it works" for in-flight mode: what it does, in the user's words, so
/// it can be read aboard with no network. The same text is in
/// docs/user-guide/in-flight-mode.md.
class InFlightHelpPage extends StatelessWidget {
  const InFlightHelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final sections = [
      (l10n.inFlightHelpStartTitle, l10n.inFlightHelpStartBody),
      (l10n.inFlightHelpTimesTitle, l10n.inFlightHelpTimesBody),
      (l10n.inFlightHelpRouteTitle, l10n.inFlightHelpRouteBody),
      (l10n.inFlightHelpQiblaTitle, l10n.inFlightHelpQiblaBody),
      (l10n.inFlightHelpAlertsTitle, l10n.inFlightHelpAlertsBody),
      (l10n.inFlightHelpTipsTitle, l10n.inFlightHelpTipsBody),
    ];

    return SettingsScaffold(
      title: l10n.inFlightHelpTitle,
      lead: l10n.inFlightHelpIntro,
      children: [
        // Numbered points, one after another (spec §4.8).
        for (final (i, (title, body)) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 4 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: s.well,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      NumberFormat.decimalPattern(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(i + 1),
                      style: type.meta.copyWith(
                        fontWeight: FontWeight.w700,
                        color: s.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          title,
                          style: type.row.copyWith(color: s.onSurface),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        body,
                        style: type.body.copyWith(
                          fontSize: 15,
                          height: 1.5,
                          color: s.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
