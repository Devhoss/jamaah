import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'foreground_clock.dart';
import 'notification_scheduler.dart';
import 'l10n/generated/app_localizations.dart';
import 'theme/theme.dart';

/// The device's own light/dark choice is the default, the same way its 12/24-hour
/// choice is. Settings gets its own switch in step 6, and that switch overrules
/// this — until then the app has no say.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

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

class JamaahApp extends ConsumerWidget {
  const JamaahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ForegroundClock(
      child: NotificationsKeeper(
        child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
          home: const AppShell(),
        ),
      ),
    );
  }
}
