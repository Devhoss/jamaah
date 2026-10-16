import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

import '../helpers/test_app.dart';
import 'phase6_screens.dart';

/// Horizon Phase 6 (spec §5, §6): every screen in English and Arabic, at the
/// usual and twice the text size, in the light and the dark theme. Each one
/// must lay out without an overflow or any other error, and pass Flutter's
/// TalkBack guidelines: every control at least 48 dp, and every one labelled.
void main() {
  setUpAll(loadTimeZoneDatabase);

  for (final language in [AppLanguage.en, AppLanguage.ar]) {
    for (final scale in [1.0, 2.0]) {
      for (final theme in [AppThemeMode.light, AppThemeMode.dark]) {
        final config = '${language.name} · ${scale}x · ${theme.name}';
        group(config, () {
          for (final MapEntry(key: name, value: open)
              in phase6Screens.entries) {
            testApp(name, (tester) async {
              final mosqueId = await startPhase6App(
                tester,
                language: language,
                scale: scale,
                theme: theme,
              );
              await open(tester, mosqueId);
              expect(tester.takeException(), isNull, reason: '$name, $config');
              await expectLater(
                tester,
                meetsGuideline(androidTapTargetGuideline),
              );
              await expectLater(
                tester,
                meetsGuideline(labeledTapTargetGuideline),
              );
            });
          }
        });
      }
    }
  }
}
