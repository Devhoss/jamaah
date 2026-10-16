import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/l10n/generated/app_localizations.dart';
import 'package:jamaah/src/features/components/brand_mark.dart';

/// The mark and its lockup (docs/design-brief/brand/saff-mihrab-a/README.md).
void main() {
  Future<void> show(WidgetTester tester, Locale locale) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Scaffold(
          body: Center(child: BrandLockup(fontSize: 30, ink: Colors.black)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('English: the mark, then the name, read as the name alone', (
    tester,
  ) async {
    await show(tester, const Locale('en'));
    final mark = tester.getRect(find.byType(BrandMark));
    final name = tester.getRect(find.text('Jama’ah'));
    expect(mark.right, lessThan(name.left));
    // 1.3 × the cap height (0.7 em), and 0.35 × that apart.
    expect(mark.height, closeTo(1.3 * 0.7 * 30, 0.01));
    expect(name.left - mark.right, closeTo(0.35 * mark.height, 0.01));
    expect(find.bySemanticsLabel('Jama’ah'), findsOneWidget);
  });

  testWidgets('Arabic: mirrored, the mark on the right of «جماعة»', (
    tester,
  ) async {
    await show(tester, const Locale('ar'));
    final mark = tester.getRect(find.byType(BrandMark));
    final name = tester.getRect(find.text('جماعة'));
    expect(mark.left, greaterThan(name.right));
  });

  testWidgets('the mark keeps its proportions at any height', (tester) async {
    await tester.pumpWidget(
      const Center(child: BrandMark(height: 116, ink: Colors.white)),
    );
    final size = tester.getSize(find.byType(BrandMark));
    expect(size.height, 116);
    expect(size.width, closeTo(116 * 56 / 58, 0.01));
  });
}
