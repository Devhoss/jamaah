import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/clock.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/sky/ink_rule.dart';
import '../../domain/sky/sky_model.dart';
import 'sky_background.dart';
import 'sky_palette.dart';

/// A secondary page in the Horizon style (spec §1, §4.10): the sky for the
/// place's current minute as a header band, and the page's controls on a calm
/// solid surface below it ("sky above, ground below").
///
/// The sky here is still: no twinkle or breathing, so these pages cost
/// nothing while open (owner, 2026-10-16: CPU on idle pages).
class SkyPage extends ConsumerWidget {
  const SkyPage({required this.header, required this.panel, super.key});

  /// The header on the sky, given the sky's ink.
  final Widget Function(BuildContext context, SkyPalette palette) header;

  /// The rows, switches and notes of the page.
  final List<Widget> panel;

  /// The band of the screen the header's text sits in.
  static const headerBand = SkyRegion(0, 0.42, minContrast: 4.5);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final today = ref.watch(todayProvider);
    final frame = today != null && today.areTimesAvailable
        ? SkyModel.forDay(today.day)
              .frameAt(today.moment.minutesOfDay.toDouble(), dark: dark)
        : SkyModel.reference.frameAt(_deviceMinute(ref), dark: dark);
    final ink = SkyInk.forRegion(frame, headerBand);
    final palette = SkyPalette.of(ink);
    final s = HorizonTheme.of(context).surfaces;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value:
          (ink.isLight ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(statusBarColor: Colors.transparent),
      child: SkyBackground(
        frame: frame,
        dark: dark,
        shades: [SkyShade(headerBand.top, headerBand.bottom, ink.shade)],
        child: CustomScrollView(
          slivers: [
            SliverSafeArea(
              bottom: false,
              sliver: SliverToBoxAdapter(child: header(context, palette)),
            ),
            SliverFillRemaining(
              hasScrollBody: false,
              child: SurfacePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: panel,
                ),
              ),
            ),
          ],
        ),
      ),
    ).withSurfaceText(s);
  }

  static double _deviceMinute(WidgetRef ref) {
    final now = ref.watch(minuteClockProvider).toLocal();
    return now.hour * 60.0 + now.minute;
  }
}

extension on Widget {
  /// Default text on the panel reads in the surface's own colour.
  Widget withSurfaceText(HorizonSurfaces s) => DefaultTextStyle.merge(
    style: TextStyle(color: s.onSurface),
    child: this,
  );
}

/// The rounded-top panel that holds a page's controls under its sky header.
class SurfacePanel extends StatelessWidget {
  const SurfacePanel({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return Container(
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(HorizonShape.panelTopRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        HorizonShape.gutterSurface,
        6,
        HorizonShape.gutterSurface,
        MediaQuery.paddingOf(context).bottom + 20,
      ),
      child: child,
    );
  }
}
