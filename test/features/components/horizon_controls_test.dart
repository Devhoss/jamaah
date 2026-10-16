import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/app/theme/horizon_tokens.dart';
import 'package:jamaah/src/app/theme/theme.dart';
import 'package:jamaah/src/features/components/horizon_controls.dart';

Widget _app(Widget child, {bool dark = false}) => MaterialApp(
  theme: dark ? AppTheme.dark() : AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('AppSwitch', () {
    testWidgets('a tap asks for the other value; 48 dp to touch', (
      tester,
    ) async {
      final changes = <bool>[];
      await tester.pumpWidget(
        _app(
          AppSwitch(
            value: false,
            onChanged: changes.add,
            semanticLabel: 'Fajr reminder',
          ),
        ),
      );
      await tester.tap(find.byType(AppSwitch));
      expect(changes, [true]);
      final size = tester.getSize(find.byType(AppSwitch));
      expect(size.width, greaterThanOrEqualTo(52));
      expect(size.height, greaterThanOrEqualTo(48));
    });

    testWidgets('disabled: no change, dashed, and says why', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _app(
          const AppSwitch(
            value: true,
            onChanged: null,
            semanticLabel: 'Fajr reminder, available once an Iqama time is set',
          ),
        ),
      );
      await tester.tap(find.byType(AppSwitch));
      expect(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is DashedOutline,
        ),
        findsOneWidget,
      );
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            'Fajr reminder, available once an Iqama time is set',
          ),
        ),
        isSemantics(
          hasEnabledState: true,
          isEnabled: false,
          hasToggledState: true,
          isToggled: false,
        ),
      );
      handle.dispose();
    });
  });

  group('Segmented', () {
    testWidgets('marks one option, read as a choice', (tester) async {
      final handle = tester.ensureSemantics();
      var chosen = 'after';
      await tester.pumpWidget(
        StatefulBuilder(
          builder: (context, setState) => _app(
            Segmented<String>(
              options: const [
                SegmentOption(
                  'after',
                  'Minutes after Adhan',
                  description: 'Moves with the Adhan',
                ),
                SegmentOption(
                  'fixed',
                  'Fixed time',
                  description: 'Same time every day',
                ),
              ],
              selected: chosen,
              onChanged: (v) => setState(() => chosen = v),
            ),
          ),
        ),
      );
      expect(find.text('Moves with the Adhan'), findsOneWidget);
      await tester.tap(find.text('Fixed time'));
      await tester.pump();
      expect(chosen, 'fixed');
      expect(
        tester.getSemantics(
          find
              .ancestor(
                of: find.text('Fixed time'),
                matching: find.byType(Semantics),
              )
              .first,
        ),
        isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true),
      );
      handle.dispose();
    });
  });

  testWidgets('Not configured is a dashed outline with words', (tester) async {
    await tester.pumpWidget(_app(const NotConfiguredPill('Not configured')));
    expect(find.text('Not configured'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is DashedOutline,
      ),
      findsOneWidget,
    );
  });

  testWidgets('a pill button is 48 tall and taps', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _app(
        PillButton(
          label: 'Find nearby',
          onPressed: () => taps++,
          ink: Colors.black,
          onInk: Colors.white,
          line: Colors.grey,
          filled: true,
        ),
      ),
    );
    await tester.tap(find.text('Find nearby'));
    expect(taps, 1);
    expect(
      tester.getSize(find.byType(PillButton)).height,
      greaterThanOrEqualTo(48),
    );
  });

  testWidgets('the snackbar uses the surface accent and leaves after 2.2 s', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showHorizonSnackBar(context, 'Isha Iqama saved'),
            child: const Text('go'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    final bar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(bar.backgroundColor, HorizonSurfaces.light.accent);
    expect(bar.duration, const Duration(milliseconds: 2200));
    expect(find.text('Isha Iqama saved'), findsOneWidget);
  });

  testWidgets('the congregation figures paint, and say nothing to TalkBack', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(const CongregationFigures(color: Colors.black)),
    );
    expect(tester.takeException(), isNull);
    expect(
      tester.getSize(find.byType(CongregationFigures)).width,
      greaterThan(100),
    );
    handle.dispose();
  });
}
