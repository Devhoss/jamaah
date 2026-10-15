import 'package:flutter/material.dart';

import 'horizon_tokens.dart';
import 'tokens.dart';

/// Builds the light and dark themes from the tokens in [AppColors]/[AppType].
///
/// Text uses the bundled Horizon UI font (Instrument Sans, Arabic falling back
/// to Noto Sans Arabic). The Horizon surface tokens and type scale ride along as
/// [HorizonTheme]; the colours here are still the prototype's until each screen
/// is rebuilt.
abstract final class AppTheme {
  static ThemeData light() => _base(
    colorScheme: const ColorScheme.light(
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.onPrimary,
      // Set explicitly: left out, Material falls back to its teal (#03DAC6), which
      // then fills selected chips and the time picker's AM/PM toggle.
      secondary: AppColors.lightPrimary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.lightSage,
      onSecondaryContainer: AppColors.lightInk,
      tertiary: AppColors.lightPrimary,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.lightSage,
      onTertiaryContainer: AppColors.lightInk,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightInk,
      error: AppColors.lightDestructive,
      outline: AppColors.lightLine,
      outlineVariant: AppColors.lightLine,
    ),
    bg: AppColors.lightBg,
    surface: AppColors.lightSurface,
    ink: AppColors.lightInk,
    muted: AppColors.lightMuted,
    line: AppColors.lightLine,
    sage: AppColors.lightSage,
    brightness: Brightness.light,
    horizon: HorizonTheme.light,
  );

  static ThemeData dark() => _base(
    colorScheme: const ColorScheme.dark(
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.onPrimary,
      // Set explicitly: left out, Material falls back to its teal (#03DAC6), which
      // then fills selected chips and the time picker's AM/PM toggle.
      secondary: AppColors.darkPrimary,
      onSecondary: AppColors.onPrimary,
      secondaryContainer: AppColors.darkSage,
      onSecondaryContainer: AppColors.darkInk,
      tertiary: AppColors.darkPrimary,
      onTertiary: AppColors.onPrimary,
      tertiaryContainer: AppColors.darkSage,
      onTertiaryContainer: AppColors.darkInk,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkInk,
      error: AppColors.darkDestructive,
      outline: AppColors.darkLine,
      outlineVariant: AppColors.darkLine,
    ),
    bg: AppColors.darkBg,
    surface: AppColors.darkSurface,
    ink: AppColors.darkInk,
    muted: AppColors.darkMuted,
    line: AppColors.darkLine,
    sage: AppColors.darkSage,
    brightness: Brightness.dark,
    horizon: HorizonTheme.dark,
  );

  static ThemeData _base({
    required ColorScheme colorScheme,
    required Color bg,
    required Color surface,
    required Color ink,
    required Color muted,
    required Color line,
    required Color sage,
    required Brightness brightness,
    required HorizonTheme horizon,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: HorizonFonts.uiFamily,
      fontFamilyFallback: HorizonFonts.uiFallback,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
    );

    return base.copyWith(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      cardColor: surface,
      dividerColor: line,
      shadowColor: Colors.transparent,
      splashColor: sage.withValues(alpha: 0.4),
      highlightColor: sage.withValues(alpha: 0.3),
      textTheme: _textTheme(base.textTheme, ink, muted),
      extensions: [AppInk(muted: muted, sage: sage), horizon],
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _ui.copyWith(
          color: ink,
          fontSize: AppType.titleSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.02 * AppType.titleSize / 28,
        ),
      ),
      dividerTheme: DividerThemeData(color: line, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: ink, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: ink,
        textColor: ink,
        minVerticalPadding: AppSpace.lg,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        indicatorColor: sage,
        elevation: 0,
        height: 56 + AppSpace.sm,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStatePropertyAll(
          _ui.copyWith(fontSize: AppType.bodySize, color: muted),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: _inputBorder(line),
        enabledBorder: _inputBorder(line),
        focusedBorder: _inputBorder(colorScheme.primary, width: 2),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: AppColors.onPrimary,
          minimumSize: const Size(0, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: _ui.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: surface,
          foregroundColor: ink,
          minimumSize: const Size(0, 50),
          side: BorderSide(color: line),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: _ui.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: ink,
          minimumSize: const Size(0, AppSpace.touchTarget),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((_) => null),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: ink,
        contentTextStyle: _ui.copyWith(color: bg),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
      ),
    );
  }

  /// Explicit text styles replace the theme's, so they name the UI font too.
  static const _ui = TextStyle(
    fontFamily: HorizonFonts.uiFamily,
    fontFamilyFallback: HorizonFonts.uiFallback,
  );

  static OutlineInputBorder _inputBorder(Color color, {double width = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.input),
        borderSide: BorderSide(color: color, width: width),
      );
  static TextTheme _textTheme(TextTheme base, Color ink, Color muted) => base
      .copyWith(
        headlineLarge: base.headlineLarge?.copyWith(
          fontSize: AppType.titleSize,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.56,
          color: ink,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: AppType.rowSize,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: AppType.rowSize,
          fontWeight: FontWeight.w500,
          color: ink,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: AppType.bodySize,
          color: ink,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: AppType.bodySize,
          color: muted,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: AppType.bodySize,
          fontWeight: FontWeight.w600,
          color: ink,
        ),
      )
      .apply(bodyColor: ink, displayColor: ink);
}

/// The two prototype tones a [ColorScheme] does not carry: the muted ink used for
/// secondary text and sunrise, and the sage wash behind the prayer in force.
///
/// Widgets read these through [of] so they stay correct in the dark theme instead
/// of reaching for [AppColors] directly.
@immutable
class AppInk extends ThemeExtension<AppInk> {
  const AppInk({required this.muted, required this.sage});

  final Color muted;
  final Color sage;

  static AppInk of(BuildContext context) =>
      Theme.of(context).extension<AppInk>() ??
      const AppInk(muted: AppColors.lightMuted, sage: AppColors.lightSage);

  @override
  AppInk copyWith({Color? muted, Color? sage}) => AppInk(
    muted: muted ?? this.muted,
    sage: sage ?? this.sage,
  );

  @override
  AppInk lerp(ThemeExtension<AppInk>? other, double t) {
    if (other is! AppInk) return this;
    return AppInk(
      muted: Color.lerp(muted, other.muted, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
    );
  }
}
