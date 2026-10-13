import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/components/app_widgets.dart';
import '../features/mosques/mosque_detail_page.dart';
import '../features/mosques/mosques_screen.dart';
import '../features/settings/settings_page.dart';
import '../features/today/today_screen.dart';
import 'branding.g.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

/// The chrome around the screens: the wordmark and gear on top, three destinations
/// underneath.
///
/// Which tab is showing is nobody's business but the shell's, so it is local state
/// rather than a provider; the screens themselves stay unaware of each other. Qibla
/// is still an honest empty state — its feature comes in a later step, and AGENTS.md
/// would rather say so than show a screen that pretends to work.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _tab = 0;

  void _goTo(int index) => setState(() => _tab = index);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        // The name comes from branding.yaml, not from the strings file: it is a
        // brand, not a phrase to translate, and it must not be possible for the
        // store listing and the top bar to disagree.
        title: Text(
          kWordmark,
          style: theme.appBarTheme.titleTextStyle?.copyWith(
            fontSize: AppType.wordmarkSize,
            letterSpacing: AppType.wordmarkSpacing,
          ),
        ),
        actions: [
          _TravelModeButton(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settings,
            onPressed: () => openSettings(context),
          ),
        ],
      ),
      body: switch (_tab) {
        0 => TodayScreen(
          onOpenMosques: () => _goTo(1),
          onOpenMosque: (id) => openMosqueDetail(context, id),
        ),
        1 => const MosquesScreen(),
        _ => _ComingSoon(title: l10n.qiblaComingTitle, body: l10n.qiblaComingBody),
      },
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: _goTo,
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.today_outlined),
            selectedIcon: const Icon(Icons.today),
            label: l10n.tabToday,
          ),
          NavigationDestination(
            icon: const Icon(Icons.mosque_outlined),
            selectedIcon: const Icon(Icons.mosque),
            label: l10n.tabMosques,
          ),
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore),
            label: l10n.tabQibla,
          ),
        ],
      ),
    );
  }
}

/// Travel mode, one tap from every screen (2026-10-13). Its options live in
/// Settings → Travel.
class _TravelModeButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on =
        ref.watch(appSettingsProvider).value?.travel.travelMode ?? false;
    final scheme = Theme.of(context).colorScheme;
    // The top bar's own icon colour would hide the selected state, so both
    // states are spelled out: on is a sage disc with a green airplane, off a
    // muted one with nothing behind it.
    return IconButton(
      isSelected: on,
      icon: Icon(Icons.flight, color: AppInk.of(context).muted),
      selectedIcon: Icon(Icons.flight, color: scheme.onSecondaryContainer),
      style: IconButton.styleFrom(
        backgroundColor: on ? scheme.secondaryContainer : null,
      ),
      tooltip: on ? l10n.travelModeTurnOff : l10n.travelModeTurnOn,
      onPressed: () => setTravelMode(context, ref, !on),
    );
  }
}

/// The one screen a tab whose feature is not built yet can honestly be.
class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
      children: [
        const SizedBox(height: AppSpace.xxl),
        AppPrompt(
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpace.sm),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ],
    );
  }
}
