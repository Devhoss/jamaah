import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_shell.dart';
import 'foreground_clock.dart';
import 'location_follower.dart';
import 'notification_scheduler.dart';
import 'l10n/app_locale.dart';
import 'l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'theme/theme.dart';
import '../data/settings_repository.dart';

/// The theme the user chose in Settings → Appearance; the phone's own choice
/// until they pick one, and while the settings are still being read.
///
/// [choose] applies the new theme on the tap itself and saves it after, so the
/// switch never waits for the database round trip.
class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() =>
      _toThemeMode(ref.watch(appSettingsProvider).value?.themeMode);

  Future<void> choose(AppThemeMode mode) async {
    state = _toThemeMode(mode);
    await ref.read(settingsRepositoryProvider).setThemeMode(mode);
  }
}

ThemeMode _toThemeMode(AppThemeMode? mode) => switch (mode) {
  AppThemeMode.light => ThemeMode.light,
  AppThemeMode.dark => ThemeMode.dark,
  AppThemeMode.system || null => ThemeMode.system,
};

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

/// The language chosen in Settings, or null to follow the phone. Like the
/// theme, [choose] applies it on the tap and saves it after.
class AppLocaleController extends Notifier<Locale?> {
  @override
  Locale? build() =>
      _toLocale(ref.watch(appSettingsProvider).value?.language);

  Future<void> choose(AppLanguage language) async {
    state = _toLocale(language);
    await ref.read(settingsRepositoryProvider).setLanguage(language);
  }
}

Locale? _toLocale(AppLanguage? language) => switch (language) {
  AppLanguage.en => kEnglishLocale,
  AppLanguage.ar => kArabicLocale,
  AppLanguage.system || null => null,
};

final appLocaleProvider = NotifierProvider<AppLocaleController, Locale?>(
  AppLocaleController.new,
);

class JamaahApp extends ConsumerWidget {
  const JamaahApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(appLocaleProvider);

    return ForegroundClock(
      child: FollowLocationKeeper(
        child: NotificationsKeeper(
          child: MaterialApp(
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            // Switch at once. Blending every colour of the app over 200 ms, while
            // the sheet that chose the theme is still closing, is what made the
            // switch feel laggy.
            themeAnimationDuration: Duration.zero,
            debugShowCheckedModeBanner: false,
            locale: locale,
            localizationsDelegates: kLocalizationsDelegates,
            supportedLocales: kSupportedLocales,
            // Any Arabic the phone asks for gets the app's Arabic; any other
            // language, English.
            localeResolutionCallback: (requested, _) =>
                resolveAppLocale(requested),
            home: const AppShell(),
          ),
        ),
      ),
    );
  }
}
