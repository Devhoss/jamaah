import 'package:flutter/material.dart';

import '../../app/theme/horizon_tokens.dart';
import 'line_icon.dart';

/// The colours the bar is drawn in: sky ink on Today, surface tokens elsewhere.
@immutable
class BottomNavColors {
  const BottomNavColors({
    required this.ink,
    required this.muted,
    required this.line,
    required this.background,
    this.selectedBackground,
    this.backdrop,
  });

  /// The surface version, for pages whose controls sit on a solid surface.
  factory BottomNavColors.surface(HorizonSurfaces s) => BottomNavColors(
    ink: s.onSurface,
    muted: s.onSurfaceMuted,
    line: s.divider,
    background: s.surface,
    selectedBackground: s.well,
  );

  final Color ink;
  final Color muted;
  final Color line;
  final Color background;
  final Color? selectedBackground;

  /// On the sky: the sky's own colours sampled right behind the bar, at the
  /// top of its fade, at its line and at the bottom. The bar draws them back
  /// over the rows, transparent at the top and [backdropOpacity] under the
  /// labels, so nothing legible shows through and no band of another colour
  /// appears (owner, 2026-10-16).
  final ({Color top, Color line, Color bottom})? backdrop;

  static const backdropOpacity = 0.96;
}

/// Four text tabs with a small dot under the one you are on (spec §2.5):
/// Today · Mosques · Qibla · Settings. No icons, no pill indicator.
class BottomNav extends StatelessWidget {
  const BottomNav({
    required this.labels,
    required this.current,
    required this.onSelect,
    this.colors,
    super.key,
  });

  /// One per tab, in order.
  final List<String> labels;
  final int current;
  final ValueChanged<int> onSelect;

  /// Defaults to the theme's surface tokens.
  final BottomNavColors? colors;

  /// Each tab's key, for tests and for the shell's own finders.
  static Key tabKey(int index) => ValueKey('bottom-nav-$index');

  static const settingsIndex = 3;

  @override
  Widget build(BuildContext context) {
    final c =
        colors ?? BottomNavColors.surface(HorizonTheme.of(context).surfaces);
    final type = HorizonTheme.typeOf(context);
    final back = c.backdrop;
    const o = BottomNavColors.backdropOpacity;

    final bar = Material(
      color: back == null ? c.background : Colors.transparent,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
          gradient: back == null
              ? null
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    back.line.withValues(alpha: o),
                    back.bottom.withValues(alpha: o),
                  ],
                ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    flex: i == current ? 6 : 4,
                    child: _Tab(
                      key: tabKey(i),
                      label: labels[i],
                      selected: i == current,
                      icon: _tabIcons[i],
                      colors: c,
                      style: type.meta,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (back == null) return bar;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The fade above the bar lets taps through to the rows under it.
        IgnorePointer(
          child: Container(
            height: fadeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  back.top.withValues(alpha: 0),
                  back.line.withValues(alpha: o),
                ],
              ),
            ),
          ),
        ),
        bar,
      ],
    );
  }

  /// How far above its line the bar fades the sky in.
  static const fadeHeight = 24.0;
}

const _tabIcons = <LineIconData>[
  LineIcons.home,
  LineIcons.mosque,
  LineIcons.qibla,
  LineIcons.settings,
];

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.icon,
    required this.colors,
    required this.style,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final LineIconData icon;
  final BottomNavColors colors;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      selected: selected,
      container: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        child: SizedBox(
          height: 48,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeInOutCubic,
              constraints: BoxConstraints(
                minWidth: selected ? 92 : 44,
                minHeight: 40,
                maxWidth: double.infinity,
              ),
              padding: EdgeInsets.symmetric(horizontal: selected ? 14 : 12),
              decoration: BoxDecoration(
                color: selected
                    ? (colors.selectedBackground ??
                          colors.ink.withValues(alpha: 0.14))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ExcludeSemantics(
                    child: LineIcon(
                      icon,
                      size: 24,
                      color: selected ? colors.ink : colors.muted,
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: style.copyWith(
                          color: colors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
