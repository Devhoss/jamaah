import 'package:flutter/material.dart';

import 'horizon_tokens.dart';

/// The app's Material theme, built from the Horizon surface tokens (spec
/// §2.3 B) so that every stock widget, its ripples, dialogs, fields, the time
/// picker and the progress spinner, reads in the same quiet ink as the pages.
/// There is no brand colour: "accent" is the ink itself (2026-10-16, the
/// prototype's green retired).
///
/// Text uses the bundled Horizon UI font (Instrument Sans, Arabic falling back
/// to Noto Sans Arabic). The surface tokens and type scale ride along as
/// [HorizonTheme].
abstract final class AppTheme {
  static ThemeData light() => _base(HorizonTheme.light, Brightness.light);

  static ThemeData dark() => _base(HorizonTheme.dark, Brightness.dark);

  static ThemeData _base(HorizonTheme horizon, Brightness brightness) {
    final s = horizon.surfaces;
    // Every role is named: left out, Material falls back to its own purples
    // and teal, which then fill selected chips and the time picker.
    final scheme = ColorScheme(
      brightness: brightness,
      primary: s.accent,
      onPrimary: s.onAccent,
      primaryContainer: s.well,
      onPrimaryContainer: s.onSurface,
      secondary: s.accent,
      onSecondary: s.onAccent,
      secondaryContainer: s.well,
      onSecondaryContainer: s.onSurface,
      tertiary: s.accent,
      onTertiary: s.onAccent,
      tertiaryContainer: s.well,
      onTertiaryContainer: s.onSurface,
      error: s.danger,
      onError: s.surface,
      surface: s.surface,
      onSurface: s.onSurface,
      onSurfaceVariant: s.onSurfaceMuted,
      surfaceContainerLowest: s.surface,
      surfaceContainerLow: s.surface,
      surfaceContainer: s.surface,
      surfaceContainerHigh: s.surface,
      surfaceContainerHighest: s.well,
      outline: s.onSurfaceMuted,
      outlineVariant: s.divider,
      shadow: Colors.transparent,
      scrim: s.scrim,
      inverseSurface: s.accent,
      onInverseSurface: s.onAccent,
      inversePrimary: s.well,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(
      useMaterial3: true,
      fontFamily: HorizonFonts.uiFamily,
      fontFamilyFallback: HorizonFonts.uiFallback,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: s.surface,
    );
    // A touch is a soft wash of the ink, on the sky and on surfaces alike.
    final wash = s.onSurface.withValues(alpha: 0.08);

    return base.copyWith(
      scaffoldBackgroundColor: s.surface,
      canvasColor: s.surface,
      cardColor: s.surface,
      dividerColor: s.divider,
      shadowColor: Colors.transparent,
      splashColor: wash,
      highlightColor: s.onSurface.withValues(alpha: 0.05),
      hoverColor: s.onSurface.withValues(alpha: 0.04),
      focusColor: s.onSurface.withValues(alpha: 0.12),
      textTheme: _textTheme(base.textTheme, s),
      extensions: [horizon],
      appBarTheme: AppBarTheme(
        backgroundColor: s.surface,
        foregroundColor: s.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: _ui.copyWith(
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      dividerTheme: DividerThemeData(color: s.divider, thickness: 1, space: 1),
      iconTheme: IconThemeData(color: s.onSurface, size: 22),
      listTileTheme: ListTileThemeData(
        iconColor: s.onSurface,
        textColor: s.onSurface,
        minVerticalPadding: 12,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: s.surface,
        modalBackgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: s.divider,
        modalBarrierColor: s.scrim,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(HorizonShape.sheetRadius),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: s.surface,
        surfaceTintColor: Colors.transparent,
        barrierColor: s.scrim,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: _ui.copyWith(
          color: s.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: _ui.copyWith(
          color: s.onSurfaceMuted,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: s.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: s.divider),
        ),
        textStyle: _ui.copyWith(color: s.onSurface, fontSize: 15),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: s.well,
        labelStyle: _ui.copyWith(color: s.onSurfaceMuted),
        floatingLabelStyle: _ui.copyWith(color: s.onSurface),
        hintStyle: _ui.copyWith(color: s.onSurfaceMuted),
        errorStyle: _ui.copyWith(color: s.danger),
        border: _inputBorder(Colors.transparent),
        enabledBorder: _inputBorder(Colors.transparent),
        focusedBorder: _inputBorder(s.onSurface, width: 1.5),
        errorBorder: _inputBorder(s.danger),
        focusedErrorBorder: _inputBorder(s.danger, width: 1.5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: s.onSurface,
        selectionColor: s.onSurface.withValues(alpha: 0.2),
        selectionHandleColor: s.onSurface,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: s.onSurface,
        linearTrackColor: s.divider,
        circularTrackColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: s.accent,
          foregroundColor: s.onAccent,
          disabledBackgroundColor: s.well,
          disabledForegroundColor: s.onSurfaceMuted,
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          textStyle: _ui.copyWith(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: s.onSurface,
          minimumSize: const Size(0, 52),
          side: BorderSide(color: s.divider, width: 1.5),
          shape: const StadiumBorder(),
          textStyle: _ui.copyWith(fontSize: 16, fontWeight: FontWeight.w500),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: s.onSurface,
          minimumSize: const Size(0, 48),
          textStyle: _ui.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(foregroundColor: s.onSurface),
      ),
      switchTheme: SwitchThemeData(
        thumbIcon: WidgetStateProperty.resolveWith((_) => null),
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.onAccent
              : s.onSurfaceMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.accent
              : s.divider,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.accent
              : s.onSurfaceMuted,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.accent
              : Colors.transparent,
        ),
        checkColor: WidgetStatePropertyAll(s.onAccent),
        side: BorderSide(color: s.onSurfaceMuted, width: 1.5),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: s.accent,
        labelStyle: _ui.copyWith(color: s.onSurface, fontSize: 14),
        secondaryLabelStyle: _ui.copyWith(color: s.onAccent, fontSize: 14),
        side: BorderSide(color: s.divider),
        shape: const StadiumBorder(),
        checkmarkColor: s.onAccent,
      ),
      timePickerTheme: TimePickerThemeData(
        backgroundColor: s.surface,
        dialBackgroundColor: s.well,
        dialHandColor: s.accent,
        dialTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.onAccent
              : s.onSurface,
        ),
        hourMinuteColor: WidgetStateColor.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? s.accent : s.well,
        ),
        hourMinuteTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.onAccent
              : s.onSurface,
        ),
        dayPeriodColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.accent
              : Colors.transparent,
        ),
        dayPeriodTextColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? s.onAccent
              : s.onSurface,
        ),
        dayPeriodBorderSide: BorderSide(color: s.divider),
        entryModeIconColor: s.onSurfaceMuted,
        helpTextStyle: _ui.copyWith(
          color: s.onSurfaceMuted,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        cancelButtonStyle: TextButton.styleFrom(foregroundColor: s.onSurface),
        confirmButtonStyle: TextButton.styleFrom(foregroundColor: s.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: s.accent,
        contentTextStyle: _ui.copyWith(color: s.onAccent, fontSize: 15),
        actionTextColor: s.onAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: s.accent,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: _ui.copyWith(color: s.onAccent, fontSize: 13),
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
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  static TextTheme _textTheme(TextTheme base, HorizonSurfaces s) => base
      .copyWith(
        headlineLarge: base.headlineLarge?.copyWith(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: s.onSurface,
        ),
        titleLarge: base.titleLarge?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: s.onSurface,
        ),
        titleMedium: base.titleMedium?.copyWith(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: s.onSurface,
        ),
        bodyMedium: base.bodyMedium?.copyWith(
          fontSize: 15,
          color: s.onSurface,
        ),
        bodySmall: base.bodySmall?.copyWith(
          fontSize: 13,
          color: s.onSurfaceMuted,
        ),
        labelLarge: base.labelLarge?.copyWith(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: s.onSurface,
        ),
      )
      .apply(bodyColor: s.onSurface, displayColor: s.onSurface);
}
