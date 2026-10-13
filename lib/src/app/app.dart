import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'foreground_clock.dart';
import 'location_follower.dart';
import 'notification_scheduler.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'theme/theme.dart';
import '../data/settings_repository.dart';

/// The theme the user chose in Settings → Appearance; the phone's own choice
/// until they pick one, and while the settings are still being read.
final themeModeProvider = Provider<ThemeMode>(
  (ref) => switch (ref.watch(appSettingsProvider).value?.themeMode) {
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
    AppThemeMode.system || null => ThemeMode.system,
  },
);

class JamaahApp extends ConsumerWidget {
  const JamaahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return ForegroundClock(
      child: FollowLocationKeeper(
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
      ),
    );
  }
}
