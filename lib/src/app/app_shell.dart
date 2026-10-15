import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/components/bottom_nav.dart';
import '../features/mosques/mosque_detail_page.dart';
import '../features/mosques/mosques_screen.dart';
import '../features/qibla/qibla_screen.dart';
import '../features/settings/settings_page.dart';
import '../features/today/today_screen.dart';
import 'l10n/generated/app_localizations.dart';

/// The chrome around the screens: four destinations along the bottom,
/// Today · Mosques · Qibla · Settings (Horizon spec §2.5). There is no top bar:
/// each screen draws its own header. Today draws the sky edge to edge, and the
/// bar sits on it in the sky's own ink.
///
/// Which tab is showing is nobody's business but the shell's, so it is local state
/// rather than a provider; the screens themselves stay unaware of each other. Only
/// the showing tab is built, so the compass runs only while Qibla is open.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  /// The sky ink at the bottom of Today, reported by Today itself.
  BottomNavColors? _skyNav;

  void _goTo(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final onSky = _tab == 0;

    return Scaffold(
      extendBody: onSky,
      body: switch (_tab) {
        0 => TodayScreen(
          onOpenMosques: () => _goTo(1),
          onOpenMosque: (id) => openMosqueDetail(context, id),
          onNavColors: (colors) => setState(() => _skyNav = colors),
        ),
        1 => const SafeArea(bottom: false, child: MosquesScreen()),
        2 => const SafeArea(bottom: false, child: QiblaScreen()),
        _ => const SafeArea(bottom: false, child: SettingsPage(asTab: true)),
      },
      bottomNavigationBar: BottomNav(
        labels: [
          l10n.tabToday,
          l10n.tabMosques,
          l10n.tabQibla,
          l10n.settingsTitle,
        ],
        current: _tab,
        onSelect: _goTo,
        colors: onSky ? _skyNav : null,
      ),
    );
  }
}
