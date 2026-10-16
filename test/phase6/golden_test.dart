import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/test_app.dart';
import 'phase6_screens.dart';

/// Horizon Phase 6: a golden picture of every screen, in English on the light
/// theme and in Arabic on the dark one, drawn with the app's own fonts. A
/// change that moves any pixel shows up here; when it is meant, refresh them:
///
///     flutter test --update-goldens test/phase6/golden_test.dart
///
/// The pictures are drawn on this Windows machine; another platform's text
/// rendering differs slightly, so regenerate them there before comparing.
void main() {
  setUpAll(() async {
    loadTimeZoneDatabase();
    await _loadFonts();
  });

  for (final (language, theme) in [
    (AppLanguage.en, AppThemeMode.light),
    (AppLanguage.ar, AppThemeMode.dark),
  ]) {
    final folder = '${language.name}-${theme.name}';
    group(folder, () {
      for (final MapEntry(key: name, value: open) in phase6Screens.entries) {
        testApp(name, (tester) async {
          final mosqueId = await startPhase6App(
            tester,
            language: language,
            scale: 1,
            theme: theme,
            pixelRatio: 1,
          );
          await open(tester, mosqueId);
          await expectLater(
            find.byType(MaterialApp),
            matchesGoldenFile('goldens/$folder/${_slug(name)}.png'),
          );
        });
      }
    });
  }
}

String _slug(String name) =>
    name.toLowerCase().replaceAll(RegExp('[^a-z0-9]+'), '-');

/// The bundled families, as pubspec.yaml declares them, so the pictures show
/// the real type rather than the test font.
Future<void> _loadFonts() async {
  const families = {
    'Fraunces': [
      'Fraunces-Light.ttf',
      'Fraunces-Regular.ttf',
      'Fraunces-Italic.ttf',
    ],
    'InstrumentSans': [
      'InstrumentSans-Regular.ttf',
      'InstrumentSans-Medium.ttf',
      'InstrumentSans-SemiBold.ttf',
    ],
    'NotoNaskhArabic': [
      'NotoNaskhArabic-Medium.ttf',
      'NotoNaskhArabic-SemiBold.ttf',
    ],
    'NotoSansArabic': [
      'NotoSansArabic-Regular.ttf',
      'NotoSansArabic-Medium.ttf',
      'NotoSansArabic-SemiBold.ttf',
    ],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      final bytes = File('assets/fonts/$file').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
