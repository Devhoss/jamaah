import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/app/theme/tokens.dart';
import 'package:jamaah/src/features/components/app_widgets.dart';
import '../../helpers/test_app.dart';

/// The small status pill is the one component that paints its own background *and*
/// its own text, so it is where a colour scheme that disagrees with itself shows up
/// as writing nobody can read.
void main() {
  Future<void> open(WidgetTester tester, {required bool dark}) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: const Scaffold(body: AppTag('Next')),
      ),
    );
    await tester.pumpAndSettle();
  }

  (Color, Color) pillInk(WidgetTester tester) {
    final box = tester.widget<Container>(
      find.descendant(
        of: find.byType(AppTag),
        matching: find.byType(Container),
      ),
    );
    final text = tester.widget<Text>(
      find.descendant(of: find.byType(AppTag), matching: find.byType(Text)),
    );
    return ((box.decoration as BoxDecoration).color!, text.style!.color!);
  }

  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';

    testApp('the $theme theme\'s pill is ink the pill is not painted with', (
      tester,
    ) async {
      await open(tester, dark: dark);

      final (background, foreground) = pillInk(tester);
      expect(
        foreground,
        isNot(background),
        reason: 'the label is invisible when the theme answers a pill with the same '
            'colour on both sides: $background on $foreground',
      );
    });

    testApp('the $theme theme keeps white as the ink on its green', (
      tester,
    ) async {
      await open(tester, dark: dark);

      final scheme = Theme.of(
        tester.element(find.byType(AppTag)),
      ).colorScheme;
      expect(
        scheme.onPrimary,
        AppColors.onPrimary,
        reason: 'onPrimary is what to write on the brand green. Handing back the '
            'green itself is what made the pill unreadable.',
      );
    });
  }
}
