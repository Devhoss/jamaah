import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import 'line_icon.dart' show parseSvgPath;

/// The amber of the lit figure: you, taking your place in the row.
const kBrandAmber = Color(0xFFFFC979);

/// The Jama’ah mark, Saff + Mihrab (A), approved 2026-10-16: a row of five
/// worshippers inside the arch of their mosque, the last one lit amber. Drawn
/// from the geometry in docs/design-brief/brand/saff-mihrab-a/README.md (the
/// 108-unit grid, shown through the mark's own 56 × 58 box), with the same
/// SVG path parser as the line icons.
class BrandMark extends StatelessWidget {
  const BrandMark({
    required this.height,
    required this.ink,
    this.mono = false,
    super.key,
  });

  final double height;

  /// The arch and four figures: the current ink.
  final Color ink;

  /// The fifth figure in [ink] too, where one colour is required. Never any
  /// colour but amber or the ink (README).
  final bool mono;

  static const _box = Rect.fromLTWH(26, 22, 56, 58);

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(
      size: Size(height * _box.width / _box.height, height),
      painter: _MarkPainter(ink: ink, lit: mono ? ink : kBrandAmber),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  _MarkPainter({required this.ink, required this.lit});

  final Color ink;
  final Color lit;

  static const _arch = 'M30,76 V52 C30,40 44,31 54,26 C64,31 78,40 78,52 V76';

  /// A head (circle r 3.1 at y 52) and a body (capsule 7.4 × 15 from y 57).
  static String _figure(double x) =>
      'M${x - 3.1},52 a3.1,3.1 0 1,0 6.2,0 a3.1,3.1 0 1,0 -6.2,0 Z '
      'M${x - 3.7},60.7 A3.7,3.7 0 0,1 ${x + 3.7},60.7 V68.3 '
      'A3.7,3.7 0 0,1 ${x - 3.7},68.3 Z';

  static final _archPath = parseSvgPath(_arch);
  static final _figures = [
    for (final x in const [37.0, 45.5, 54.0, 62.5, 71.0])
      parseSvgPath(_figure(x)),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.height / BrandMark._box.height;
    canvas.save();
    canvas.scale(s);
    canvas.translate(-BrandMark._box.left, -BrandMark._box.top);
    canvas.drawPath(
      _archPath,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final fill = Paint()..color = ink;
    for (var i = 0; i < 4; i++) {
      canvas.drawPath(_figures[i], fill);
    }
    canvas.drawPath(_figures[4], Paint()..color = lit);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.ink != ink || old.lit != lit;
}

/// The mark with the name (README lockup rules). English: the mark, then
/// “Jama’ah” in Fraunces 400; the mark is 1.3 × the text's cap height and
/// sits 0.35 × its height from the name. Arabic: mirrored, the mark on the
/// right, «جماعة» in Noto Naskh Arabic 600.
class BrandLockup extends StatelessWidget {
  const BrandLockup({required this.fontSize, required this.ink, super.key});

  final double fontSize;
  final Color ink;

  /// Fraunces' cap height, as a share of its size; Naskh is set to match.
  static const _capHeight = 0.7;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final arabic = Localizations.localeOf(context).languageCode == 'ar';
    final markHeight = 1.3 * _capHeight * fontSize;
    return Semantics(
      label: l10n.appTitle,
      excludeSemantics: true,
      child: Row(
        // The layout direction puts the mark first: left in English, right
        // in Arabic.
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(height: markHeight, ink: ink),
          SizedBox(width: 0.35 * markHeight),
          Flexible(
            child: Text(
              l10n.appTitle,
              style: TextStyle(
                fontFamily: arabic
                    ? HorizonFonts.notoNaskhArabic
                    : HorizonFonts.fraunces,
                fontWeight: arabic ? FontWeight.w600 : FontWeight.w400,
                fontSize: fontSize,
                height: 1.2,
                color: ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
