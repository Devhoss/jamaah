import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/components/app_widgets.dart';
import '../features/location/location_sheet.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'theme/theme.dart';
import 'theme/tokens.dart';

/// Theme mode is a real setting; Settings gets its own switch in step 6.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setMode(ThemeMode mode) => state = mode;

  void toggle() =>
      state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// True while the user picked dark mode.
final isDarkThemeProvider = Provider<bool>(
  (ref) => ref.watch(themeModeProvider) == ThemeMode.dark,
);

class AwqaityApp extends ConsumerWidget {
  const AwqaityApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const ScaffoldPlaceholder(),
    );
  }
}

/// Temporary shell for the scaffold commit; the real bottom navigation lands
/// with the Today screen.
class ScaffoldPlaceholder extends ConsumerWidget {
  const ScaffoldPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final place = ref.watch(currentPlaceProvider);
    final placeLabel = place == null
        ? null
        : l10n.currentPlaceLabel(
            place.fromDevice ? l10n.locationThisDevice : place.displayName,
          );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.wordmark)),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  l10n.nextStepPlaceholder,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            // The location flow is the first thing a fresh install has to answer,
            // so it is reachable from here until the Today screen owns it.
            AppPrompt(
              onTap: () => showLocationSheet(context),
              children: [
                Text(
                  l10n.locationSheetTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  placeLabel ?? l10n.locationSheetBody,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xxl),
          ],
        ),
      ),
    );
  }
}
