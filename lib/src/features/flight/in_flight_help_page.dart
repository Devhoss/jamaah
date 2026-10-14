import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../components/app_widgets.dart';

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
    final theme = Theme.of(context);
    final sections = [
      (
        Icons.flight_takeoff,
        l10n.inFlightHelpStartTitle,
        l10n.inFlightHelpStartBody,
      ),
      (Icons.schedule, l10n.inFlightHelpTimesTitle, l10n.inFlightHelpTimesBody),
      (Icons.route, l10n.inFlightHelpRouteTitle, l10n.inFlightHelpRouteBody),
      (
        Icons.explore_outlined,
        l10n.inFlightHelpQiblaTitle,
        l10n.inFlightHelpQiblaBody,
      ),
      (
        Icons.notifications_outlined,
        l10n.inFlightHelpAlertsTitle,
        l10n.inFlightHelpAlertsBody,
      ),
      (
        Icons.lightbulb_outline,
        l10n.inFlightHelpTipsTitle,
        l10n.inFlightHelpTipsBody,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.inFlightHelpTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          Text(l10n.inFlightHelpIntro, style: theme.textTheme.titleMedium),
          for (final (icon, title, body) in sections) ...[
            AppSectionHeader(title),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: AppInk.of(context).muted),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text(body, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
