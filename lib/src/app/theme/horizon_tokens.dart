import 'package:flutter/material.dart';

/// Font family names, as declared in pubspec.yaml (spec §2.1).
abstract final class HorizonFonts {
  /// Latin display: big times, prayer names, page and section titles.
  static const fraunces = 'Fraunces';

  /// Latin UI: rows, labels, buttons, body.
  static const instrumentSans = 'InstrumentSans';

  /// Arabic display (no italic; 500 stands in for Fraunces italic).
  static const notoNaskhArabic = 'NotoNaskhArabic';

  /// Arabic UI.
  static const notoSansArabic = 'NotoSansArabic';

  /// The app-wide default text font. Arabic letters and Arabic-Indic digits
  /// fall back to Noto Sans Arabic, so both scripts read as one UI face.
  static const uiFamily = instrumentSans;
  static const uiFallback = [notoSansArabic];
}

/// Static surface colours for sheets and the "ground" panel of secondary pages
/// (spec §2.3 B). Everything drawn on the sky uses the computed sky ink instead.
@immutable
class HorizonSurfaces {
  const HorizonSurfaces({
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.divider,
    required this.well,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.scrim,
  });

  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;
  final Color divider;

  /// Segmented-control tracks and highlighted rows.
  final Color well;

  /// Filled buttons and switches that are on. There is no brand colour.
  final Color accent;
  final Color onAccent;

  /// Remove and Clear.
  final Color danger;

  /// Behind sheets.
  final Color scrim;

  static const light = HorizonSurfaces(
    surface: Color(0xFFFBF9F6),
    onSurface: Color(0xFF15161C),
    onSurfaceMuted: Color(0xFF575A66),
    divider: Color(0xFFE2DED7),
    well: Color(0xFFEFEBE4),
    accent: Color(0xFF15161C),
    onAccent: Color(0xFFFBF9F6),
    danger: Color(0xFFB3261E),
    scrim: Color(0x8004060E),
  );

  static const dark = HorizonSurfaces(
    surface: Color(0xFF14151C),
    onSurface: Color(0xFFECEDF2),
    onSurfaceMuted: Color(0xFFA3A6B3),
    divider: Color(0xFF2A2C36),
    well: Color(0xFF1E2029),
    accent: Color(0xFFECEDF2),
    onAccent: Color(0xFF14151C),
    danger: Color(0xFFF2B8B5),
    scrim: Color(0x8004060E),
  );

  static HorizonSurfaces lerp(HorizonSurfaces a, HorizonSurfaces b, double t) =>
      HorizonSurfaces(
        surface: Color.lerp(a.surface, b.surface, t)!,
        onSurface: Color.lerp(a.onSurface, b.onSurface, t)!,
        onSurfaceMuted: Color.lerp(a.onSurfaceMuted, b.onSurfaceMuted, t)!,
        divider: Color.lerp(a.divider, b.divider, t)!,
        well: Color.lerp(a.well, b.well, t)!,
        accent: Color.lerp(a.accent, b.accent, t)!,
        onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
        danger: Color.lerp(a.danger, b.danger, t)!,
        scrim: Color.lerp(a.scrim, b.scrim, t)!,
      );
}

/// The Horizon type scale (spec §2.2), without colours: text on the sky takes
/// the sky ink, text on surfaces takes [HorizonSurfaces.onSurface].
///
/// Kicker text is uppercased by the caller (Flutter has no text transform);
/// Arabic has no case, so it is left as it is.
@immutable
class HorizonType {
  const HorizonType({
    required this.hero,
    required this.display,
    required this.onboardingTitle,
    required this.prayerName,
    required this.section,
    required this.kicker,
    required this.row,
    required this.body,
    required this.meta,
    required this.rowTime,
  });

  /// Next Adhan time on Today.
  final TextStyle hero;

  /// Page titles: Mosques, Qibla, Settings, the mosque name.
  final TextStyle display;

  final TextStyle onboardingTitle;

  /// The name beside the hero, sheet titles.
  final TextStyle prayerName;

  /// Section titles on surfaces.
  final TextStyle section;

  /// "NEXT PRAYER · ADHAN", "YOUR MOSQUE".
  final TextStyle kicker;

  /// Prayer rows, list titles.
  final TextStyle row;

  /// Paragraphs.
  final TextStyle body;

  /// Sub-lines, captions.
  final TextStyle meta;

  /// Times in rows (tabular figures).
  final TextStyle rowTime;

  static const _tabular = [FontFeature.tabularFigures()];

  /// Fraunces display, Instrument Sans UI; Arabic letters fall back to the
  /// Arabic family of the same role.
  static const latin = HorizonType(
    hero: TextStyle(
      fontFamily: HorizonFonts.fraunces,
      fontFamilyFallback: [HorizonFonts.notoNaskhArabic],
      fontWeight: FontWeight.w300,
      fontSize: 108,
      letterSpacing: -0.04 * 108,
      height: 0.92,
      fontFeatures: _tabular,
    ),
    display: TextStyle(
      fontFamily: HorizonFonts.fraunces,
      fontFamilyFallback: [HorizonFonts.notoNaskhArabic],
      fontWeight: FontWeight.w400,
      fontSize: 38,
      letterSpacing: -0.02 * 38,
      height: 1.1,
    ),
    onboardingTitle: TextStyle(
      fontFamily: HorizonFonts.fraunces,
      fontFamilyFallback: [HorizonFonts.notoNaskhArabic],
      fontWeight: FontWeight.w400,
      fontSize: 40,
      height: 1.08,
    ),
    prayerName: TextStyle(
      fontFamily: HorizonFonts.fraunces,
      fontFamilyFallback: [HorizonFonts.notoNaskhArabic],
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      fontSize: 26,
    ),
    section: TextStyle(
      fontFamily: HorizonFonts.fraunces,
      fontFamilyFallback: [HorizonFonts.notoNaskhArabic],
      fontWeight: FontWeight.w400,
      fontStyle: FontStyle.italic,
      fontSize: 22,
    ),
    kicker: TextStyle(
      fontFamily: HorizonFonts.instrumentSans,
      fontFamilyFallback: HorizonFonts.uiFallback,
      fontWeight: FontWeight.w600,
      fontSize: 12,
      letterSpacing: 0.13 * 12,
    ),
    row: TextStyle(
      fontFamily: HorizonFonts.instrumentSans,
      fontFamilyFallback: HorizonFonts.uiFallback,
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    body: TextStyle(
      fontFamily: HorizonFonts.instrumentSans,
      fontFamilyFallback: HorizonFonts.uiFallback,
      fontWeight: FontWeight.w400,
      fontSize: 15,
      height: 1.45,
    ),
    meta: TextStyle(
      fontFamily: HorizonFonts.instrumentSans,
      fontFamilyFallback: HorizonFonts.uiFallback,
      fontWeight: FontWeight.w400,
      fontSize: 13,
    ),
    rowTime: TextStyle(
      fontFamily: HorizonFonts.instrumentSans,
      fontFamilyFallback: HorizonFonts.uiFallback,
      fontWeight: FontWeight.w500,
      fontSize: 15,
      fontFeatures: _tabular,
    ),
  );

  /// Noto Naskh Arabic display (500, never italic), Noto Sans Arabic UI; Latin
  /// text (an English mosque name) falls back to the Latin family of the same
  /// role. Arabic gets no letter-spacing: tracking breaks the joined script.
  static const arabic = HorizonType(
    hero: TextStyle(
      fontFamily: HorizonFonts.notoNaskhArabic,
      fontFamilyFallback: [HorizonFonts.fraunces],
      fontWeight: FontWeight.w500,
      fontSize: 108,
      height: 0.92,
      fontFeatures: _tabular,
    ),
    display: TextStyle(
      fontFamily: HorizonFonts.notoNaskhArabic,
      fontFamilyFallback: [HorizonFonts.fraunces],
      fontWeight: FontWeight.w500,
      fontSize: 38,
      height: 1.1,
    ),
    onboardingTitle: TextStyle(
      fontFamily: HorizonFonts.notoNaskhArabic,
      fontFamilyFallback: [HorizonFonts.fraunces],
      fontWeight: FontWeight.w500,
      fontSize: 40,
      height: 1.08,
    ),
    prayerName: TextStyle(
      fontFamily: HorizonFonts.notoNaskhArabic,
      fontFamilyFallback: [HorizonFonts.fraunces],
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      fontSize: 26,
    ),
    section: TextStyle(
      fontFamily: HorizonFonts.notoNaskhArabic,
      fontFamilyFallback: [HorizonFonts.fraunces],
      fontWeight: FontWeight.w500,
      fontStyle: FontStyle.normal,
      fontSize: 22,
    ),
    kicker: TextStyle(
      fontFamily: HorizonFonts.notoSansArabic,
      fontFamilyFallback: [HorizonFonts.instrumentSans],
      fontWeight: FontWeight.w600,
      fontSize: 12,
    ),
    row: TextStyle(
      fontFamily: HorizonFonts.notoSansArabic,
      fontFamilyFallback: [HorizonFonts.instrumentSans],
      fontWeight: FontWeight.w600,
      fontSize: 16,
    ),
    body: TextStyle(
      fontFamily: HorizonFonts.notoSansArabic,
      fontFamilyFallback: [HorizonFonts.instrumentSans],
      fontWeight: FontWeight.w400,
      fontSize: 15,
      height: 1.5,
    ),
    meta: TextStyle(
      fontFamily: HorizonFonts.notoSansArabic,
      fontFamilyFallback: [HorizonFonts.instrumentSans],
      fontWeight: FontWeight.w400,
      fontSize: 13,
    ),
    rowTime: TextStyle(
      fontFamily: HorizonFonts.notoSansArabic,
      fontFamilyFallback: [HorizonFonts.instrumentSans],
      fontWeight: FontWeight.w500,
      fontSize: 15,
      fontFeatures: _tabular,
    ),
  );

  static HorizonType lerp(HorizonType a, HorizonType b, double t) =>
      HorizonType(
        hero: TextStyle.lerp(a.hero, b.hero, t)!,
        display: TextStyle.lerp(a.display, b.display, t)!,
        onboardingTitle: TextStyle.lerp(
          a.onboardingTitle,
          b.onboardingTitle,
          t,
        )!,
        prayerName: TextStyle.lerp(a.prayerName, b.prayerName, t)!,
        section: TextStyle.lerp(a.section, b.section, t)!,
        kicker: TextStyle.lerp(a.kicker, b.kicker, t)!,
        row: TextStyle.lerp(a.row, b.row, t)!,
        body: TextStyle.lerp(a.body, b.body, t)!,
        meta: TextStyle.lerp(a.meta, b.meta, t)!,
        rowTime: TextStyle.lerp(a.rowTime, b.rowTime, t)!,
      );
}

/// Page gutters, radii and row heights (spec §2.4).
abstract final class HorizonShape {
  static const gutterSky = 24.0;
  static const gutterSurface = 20.0;
  static const rowMin = 48.0;
  static const prayerRowMin = 52.0;
  static const twoLineRowMin = 68.0;
  static const panelTopRadius = 28.0;
  static const sheetRadius = 24.0;
  static const ticketRadius = 16.0;
  static const segmentedRadius = 14.0;
  static const segmentedInnerRadius = 11.0;
  static const chipRadius = 14.0;
}

/// The Horizon tokens on the theme: the surface colours for the theme's
/// brightness and the type scale for both scripts.
///
/// They sit beside the prototype palette until each screen is rebuilt in its
/// phase (decided 2026-10-15); then the old palette goes.
@immutable
class HorizonTheme extends ThemeExtension<HorizonTheme> {
  const HorizonTheme({
    required this.surfaces,
    this.latinType = HorizonType.latin,
    this.arabicType = HorizonType.arabic,
  });

  static const light = HorizonTheme(surfaces: HorizonSurfaces.light);
  static const dark = HorizonTheme(surfaces: HorizonSurfaces.dark);

  final HorizonSurfaces surfaces;
  final HorizonType latinType;
  final HorizonType arabicType;

  /// The type scale for [locale]: Arabic pairs Naskh/Noto Sans Arabic by role.
  HorizonType typeFor(Locale locale) =>
      locale.languageCode == 'ar' ? arabicType : latinType;

  static HorizonTheme of(BuildContext context) =>
      Theme.of(context).extension<HorizonTheme>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  /// The type scale for the current locale.
  static HorizonType typeOf(BuildContext context) =>
      of(context).typeFor(Localizations.localeOf(context));

  @override
  HorizonTheme copyWith({
    HorizonSurfaces? surfaces,
    HorizonType? latinType,
    HorizonType? arabicType,
  }) => HorizonTheme(
    surfaces: surfaces ?? this.surfaces,
    latinType: latinType ?? this.latinType,
    arabicType: arabicType ?? this.arabicType,
  );

  @override
  HorizonTheme lerp(ThemeExtension<HorizonTheme>? other, double t) {
    if (other is! HorizonTheme) return this;
    return HorizonTheme(
      surfaces: HorizonSurfaces.lerp(surfaces, other.surfaces, t),
      latinType: HorizonType.lerp(latinType, other.latinType, t),
      arabicType: HorizonType.lerp(arabicType, other.arabicType, t),
    );
  }
}
