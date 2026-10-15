import 'package:flutter/material.dart';

import '../../app/theme/horizon_tokens.dart';

/// The colours the bar is drawn in: sky ink on Today, surface tokens elsewhere.
@immutable
class BottomNavColors {
  const BottomNavColors({
    required this.ink,
    required this.muted,
    required this.line,
    required this.background,
  });

  /// The surface version, for pages whose controls sit on a solid surface.
  factory BottomNavColors.surface(HorizonSurfaces s) => BottomNavColors(
    ink: s.onSurface,
    muted: s.onSurfaceMuted,
    line: s.divider,
    background: s.surface,
  );

  final Color ink;
  final Color muted;
  final Color line;
  final Color background;
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

    return Material(
      color: c.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
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
                    child: _Tab(
                      key: tabKey(i),
                      label: labels[i],
                      selected: i == current,
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
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.label,
    required this.selected,
    required this.colors,
    required this.style,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final BottomNavColors colors;
  final TextStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      container: true,
      child: InkResponse(
        onTap: onTap,
        containedInkWell: true,
        highlightShape: BoxShape.rectangle,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: style.copyWith(
                    color: selected ? colors.ink : colors.muted,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 5),
                ExcludeSemantics(
                  child: Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: selected ? colors.ink : Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
