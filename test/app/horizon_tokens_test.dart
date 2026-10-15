import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/theme/horizon_tokens.dart';
import 'package:jamaah/src/app/theme/theme.dart';

double _luminance(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a), lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  group('HorizonTheme on the app theme', () {
    test('light and dark carry their own surface tokens', () {
      expect(
        AppTheme.light().extension<HorizonTheme>()!.surfaces,
        same(HorizonSurfaces.light),
      );
      expect(
        AppTheme.dark().extension<HorizonTheme>()!.surfaces,
        same(HorizonSurfaces.dark),
      );
    });

    test('the prototype palette still drives the colour scheme', () {
      // Horizon tokens sit beside it until each screen is rebuilt.
      expect(
        AppTheme.light().colorScheme.primary,
        isNot(HorizonSurfaces.light.accent),
      );
    });

    test('the default text font is the Horizon UI font', () {
      final style = AppTheme.light().textTheme.bodyMedium!;
      expect(style.fontFamily, HorizonFonts.instrumentSans);
      expect(style.fontFamilyFallback, contains(HorizonFonts.notoSansArabic));
      expect(
        AppTheme.dark().appBarTheme.titleTextStyle!.fontFamily,
        HorizonFonts.instrumentSans,
      );
    });

    test('surface values follow spec §2.3', () {
      expect(HorizonSurfaces.light.surface, const Color(0xFFFBF9F6));
      expect(HorizonSurfaces.dark.surface, const Color(0xFF14151C));
      expect(HorizonSurfaces.light.danger, const Color(0xFFB3261E));
      expect(HorizonSurfaces.dark.well, const Color(0xFF1E2029));
      expect(HorizonSurfaces.light.scrim.a, closeTo(0.5, 0.01));
    });

    for (final (name, s) in [
      ('light', HorizonSurfaces.light),
      ('dark', HorizonSurfaces.dark),
    ]) {
      test('$name surface text keeps at least 4.5:1', () {
        expect(_contrast(s.onSurface, s.surface), greaterThanOrEqualTo(4.5));
        expect(
          _contrast(s.onSurfaceMuted, s.surface),
          greaterThanOrEqualTo(4.5),
        );
        expect(_contrast(s.onSurface, s.well), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.onAccent, s.accent), greaterThanOrEqualTo(4.5));
        expect(_contrast(s.danger, s.surface), greaterThanOrEqualTo(4.5));
      });
    }

    test('lerp blends surfaces and keeps the type scales', () {
      final mid = HorizonTheme.light.lerp(HorizonTheme.dark, 0.5);
      expect(mid.surfaces.surface, isNot(HorizonSurfaces.light.surface));
      expect(mid.latinType.hero.fontSize, 108);
      expect(HorizonTheme.light.lerp(null, 0.5), same(HorizonTheme.light));
    });
  });

  group('type scale', () {
    test('Latin roles follow spec §2.2', () {
      const t = HorizonType.latin;
      expect(t.hero.fontFamily, HorizonFonts.fraunces);
      expect(t.hero.fontWeight, FontWeight.w300);
      expect(t.hero.fontSize, 108);
      expect(t.hero.letterSpacing, closeTo(-4.32, 0.001));
      expect(t.hero.height, 0.92);
      expect(t.prayerName.fontStyle, FontStyle.italic);
      expect(t.section.fontStyle, FontStyle.italic);
      expect(t.section.fontSize, 22);
      expect(t.kicker.fontFamily, HorizonFonts.instrumentSans);
      expect(t.kicker.fontWeight, FontWeight.w600);
      expect(t.row.fontSize, 16);
      expect(
        t.rowTime.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    test('Arabic pairs Naskh for display and Noto Sans Arabic for UI', () {
      const t = HorizonType.arabic;
      for (final s in [t.hero, t.display, t.prayerName, t.section]) {
        expect(s.fontFamily, HorizonFonts.notoNaskhArabic);
        expect(s.fontFamilyFallback, contains(HorizonFonts.fraunces));
      }
      for (final s in [t.kicker, t.row, t.body, t.meta, t.rowTime]) {
        expect(s.fontFamily, HorizonFonts.notoSansArabic);
        expect(s.fontFamilyFallback, contains(HorizonFonts.instrumentSans));
      }
    });

    test('Arabic has no italic, no tracking, and only bundled weights', () {
      const t = HorizonType.arabic;
      final all = [
        t.hero, t.display, t.onboardingTitle, t.prayerName, t.section,
        t.kicker, t.row, t.body, t.meta, t.rowTime,
      ];
      for (final s in all) {
        expect(s.fontStyle, isNot(FontStyle.italic));
        expect(s.letterSpacing ?? 0, 0);
      }
      for (final s in [t.hero, t.display, t.prayerName, t.section]) {
        expect([FontWeight.w500, FontWeight.w600], contains(s.fontWeight));
      }
    });

    testWidgets('typeOf follows the locale', (tester) async {
      Future<HorizonType> typeIn(Locale locale) async {
        late HorizonType type;
        await tester.pumpWidget(
          Localizations(
            locale: locale,
            delegates: const [
              DefaultWidgetsLocalizations.delegate,
              DefaultMaterialLocalizations.delegate,
            ],
            child: Theme(
              data: AppTheme.light(),
              child: Builder(
                builder: (context) {
                  type = HorizonTheme.typeOf(context);
                  return const SizedBox();
                },
              ),
            ),
          ),
        );
        return type;
      }

      expect(await typeIn(const Locale('en')), same(HorizonType.latin));
      expect(await typeIn(const Locale('ar')), same(HorizonType.arabic));
    });
  });

  test('every bundled font asset loads', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const assets = [
      'Fraunces-Light', 'Fraunces-Regular', 'Fraunces-Italic',
      'InstrumentSans-Regular', 'InstrumentSans-Medium',
      'InstrumentSans-SemiBold', 'NotoNaskhArabic-Medium',
      'NotoNaskhArabic-SemiBold', 'NotoSansArabic-Regular',
      'NotoSansArabic-Medium', 'NotoSansArabic-SemiBold',
    ];
    for (final name in assets) {
      final data = await rootBundle.load('assets/fonts/$name.ttf');
      // TrueType files start with the 0x00010000 version tag.
      expect(data.getUint32(0), 0x00010000, reason: name);
    }
  });
}
