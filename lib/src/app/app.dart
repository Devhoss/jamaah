import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/generated/app_localizations.dart';
import 'theme/theme.dart';

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
    return Scaffold(
      appBar: AppBar(title: Text(l10n.wordmark)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            l10n.nextStepPlaceholder,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
