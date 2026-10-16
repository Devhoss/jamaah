import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';
import '../sky/sky_page.dart';
import '../sky/sky_palette.dart';

/// The parts every Settings page is built from (Horizon spec §4.9): a sky
/// header with back, title and a one-line lead, and rows, switches and radio
/// lists on the surface below.

/// Opens a Settings page.
Future<void> pushSettingsPage(BuildContext context, Widget page) =>
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));

/// A Settings page under the sky. [onTab] drops the back button and the
/// Scaffold, for the hub that is itself a tab.
class SettingsScaffold extends StatelessWidget {
  const SettingsScaffold({
    required this.title,
    required this.children,
    this.lead,
    this.onTab = false,
    super.key,
  });

  final String title;
  final String? lead;
  final List<Widget> children;
  final bool onTab;

  @override
  Widget build(BuildContext context) {
    final page = SkyPage(
      header: (context, p) =>
          _SettingsHeader(title: title, lead: lead, palette: p, back: !onTab),
      panel: children,
    );
    return onTab ? page : Scaffold(body: page);
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.title,
    required this.lead,
    required this.palette,
    required this.back,
  });

  final String title;
  final String? lead;
  final SkyPalette palette;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final p = palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (back)
          Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 16, 0),
            child: Semantics(
              button: true,
              label: l10n.settingsBack,
              excludeSemantics: true,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox.square(
                  dimension: 48,
                  child: Center(
                    child: Transform.flip(
                      // Back points the way the page came from.
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: LineIcon(LineIcons.back, size: 22, color: p.ink),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: EdgeInsets.fromLTRB(24, back ? 4 : 28, 24, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: type.display.copyWith(
                    fontSize: back ? 34 : 40,
                    color: p.ink,
                  ),
                ),
              ),
              if (lead != null) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 340),
                  child: Text(
                    lead!,
                    style: type.body.copyWith(fontSize: 14, color: p.mute),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// A group's name on the hub, or a section's on a page.
class SettingsHeading extends StatelessWidget {
  const SettingsHeading(this.text, {this.top = 22, super.key});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Padding(
      padding: EdgeInsets.fromLTRB(0, top, 0, 6),
      child: Semantics(
        header: true,
        child: Text(text, style: type.section.copyWith(color: s.onSurface)),
      ),
    );
  }
}

/// A quiet line under a section.
class SettingsNote extends StatelessWidget {
  const SettingsNote(this.text, {this.top = 8, super.key});

  final String text;
  final double top;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: Text(
        text,
        style: type.meta.copyWith(height: 1.45, color: s.onSurfaceMuted),
      ),
    );
  }
}

/// A row that opens something: its title, what it is set to now, and a
/// chevron. The value sits under the title, so a large text size wraps it
/// rather than pushing the row off the screen.
class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    required this.title,
    required this.onTap,
    this.value,
    this.muted = false,
    this.divider = true,
    super.key,
  });

  final String title;
  final String? value;
  final VoidCallback? onTap;

  /// Sunrise is not a prayer: its row reads quieter.
  final bool muted;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return _RowFrame(
      divider: divider,
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: type.row.copyWith(
                              color: muted ? s.onSurfaceMuted : s.onSurface,
                            ),
                          ),
                          if (value != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              value!,
                              style: type.meta.copyWith(
                                color: s.onSurfaceMuted,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Transform.flip(
                      flipX: Directionality.of(context) == TextDirection.rtl,
                      child: LineIcon(
                        LineIcons.chevronRight,
                        size: 20,
                        strokeWidth: 2,
                        color: s.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A switch with its title and one line saying what it does. The whole row
/// toggles it. [onChanged] null greys it out; [hint] then says why.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.hint,
    this.divider = true,
    super.key,
  });

  final String title;
  final String? hint;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final enabled = onChanged != null;
    return _RowFrame(
      divider: divider,
      child: InkWell(
        onTap: enabled ? () => onChanged!(!value) : null,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: ExcludeSemantics(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: type.row.copyWith(
                            color: enabled ? s.onSurface : s.onSurfaceMuted,
                          ),
                        ),
                        if (hint != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            hint!,
                            style: type.meta.copyWith(
                              height: 1.4,
                              color: s.onSurfaceMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                AppSwitch(
                  value: value,
                  onChanged: onChanged,
                  semanticLabel: hint == null ? title : '$title. $hint',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// One choice of a [RadioList].
class RadioOption<T> {
  const RadioOption(
    this.value,
    this.label, {
    this.description,
    this.more = const [],
    this.trailing,
  });

  final T value;
  final String label;
  final String? description;

  /// Further quiet lines under the description, one each.
  final List<String> more;

  /// Beside the choice, such as a preview button.
  final Widget? trailing;
}

/// Choices with a 20 px ring each, filled when chosen, and a line under each
/// label (spec §2.5).
class RadioList<T> extends StatelessWidget {
  const RadioList({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<RadioOption<T>> options;
  final T selected;
  final ValueChanged<T>? onChanged;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, o) in options.indexed)
          _RowFrame(
            divider: i < options.length - 1,
            child: Row(
              children: [
                Expanded(
                  child: Semantics(
                    inMutuallyExclusiveGroup: true,
                    checked: o.value == selected,
                    button: true,
                    child: InkWell(
                      onTap: onChanged == null
                          ? null
                          : () => onChanged!(o.value),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 1),
                                child: _Ring(
                                  on: o.value == selected,
                                  color: o.value == selected
                                      ? s.accent
                                      : s.onSurfaceMuted,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.label,
                                      style: type.row.copyWith(
                                        color: s.onSurface,
                                      ),
                                    ),
                                    for (final line in [
                                      ?o.description,
                                      ...o.more,
                                    ]) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        line,
                                        style: type.meta.copyWith(
                                          height: 1.4,
                                          color: s.onSurfaceMuted,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (o.trailing != null) ...[
                  const SizedBox(width: 8),
                  o.trailing!,
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _Ring extends StatelessWidget {
  const _Ring({required this.on, required this.color});

  final bool on;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 20,
    height: 20,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: color, width: on ? 6 : 1.6),
    ),
  );
}

/// A small text button on the surface, such as Preview or Stop.
class SettingsTextButton extends StatelessWidget {
  const SettingsTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: s.onSurface,
        minimumSize: const Size(48, 48),
        textStyle: type.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      child: Text(label),
    );
  }
}

/// A pill button on the surface.
class SettingsButton extends StatelessWidget {
  const SettingsButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: PillButton(
        label: label,
        filled: filled,
        ink: filled ? s.accent : s.onSurface,
        onInk: filled ? s.onAccent : s.surface,
        line: s.divider,
        onPressed: onPressed,
      ),
    );
  }
}

/// A part of a page that stays folded until asked for, such as Advanced.
class SettingsDisclosure extends StatefulWidget {
  const SettingsDisclosure({
    required this.title,
    required this.children,
    super.key,
  });

  final String title;
  final List<Widget> children;

  @override
  State<SettingsDisclosure> createState() => _SettingsDisclosureState();
}

class _SettingsDisclosureState extends State<SettingsDisclosure> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: type.section.copyWith(color: s.onSurface),
                      ),
                    ),
                    AnimatedRotation(
                      turns: _open ? 0.5 : 0,
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 160),
                      child: LineIcon(
                        LineIcons.chevronDown,
                        size: 20,
                        strokeWidth: 2,
                        color: s.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_open) ...widget.children,
      ],
    );
  }
}

/// The hairline under a row, straight to the panel's edges.
class _RowFrame extends StatelessWidget {
  const _RowFrame({required this.child, required this.divider});

  final Widget child;
  final bool divider;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: s.divider)) : null,
      ),
      child: child,
    );
  }
}

/// A bottom sheet on the surface (spec §2.5: sheets are always on `surface`).
Future<T?> showSettingsSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) {
  final s = HorizonTheme.of(context).surfaces;
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: s.surface,
    builder: builder,
  );
}

/// A sheet's title and, under it, its choices or fields, scrolling when the
/// text is large.
class SettingsSheetBody extends StatelessWidget {
  const SettingsSheetBody({required this.children, this.title, super.key});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return SafeArea(
      child: Padding(
        // Lift the sheet above the keyboard while a number is typed.
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Semantics(
                  header: true,
                  child: Text(
                    title!,
                    style: type.prayerName.copyWith(color: s.onSurface),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}

/// Cancel and Save at the foot of a sheet: 52 tall, rounded 14. Save waits
/// for a valid value.
class SheetActions extends StatelessWidget {
  const SheetActions({
    required this.cancelLabel,
    required this.saveLabel,
    required this.onCancel,
    required this.onSave,
    super.key,
  });

  final String cancelLabel;
  final String saveLabel;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final text = type.row.copyWith(fontWeight: FontWeight.w500);
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: s.onSurface,
                side: BorderSide(color: s.divider, width: 1.5),
                shape: shape,
                textStyle: text,
              ),
              child: Text(cancelLabel),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: onSave,
              style: FilledButton.styleFrom(
                backgroundColor: s.accent,
                foregroundColor: s.onAccent,
                disabledBackgroundColor: s.well,
                disabledForegroundColor: s.onSurfaceMuted,
                shape: shape,
                textStyle: text,
              ),
              child: Text(saveLabel),
            ),
          ),
        ),
      ],
    );
  }
}

/// A choice chip on the surface: `accent` when chosen, outlined otherwise.
class SettingsChip extends StatelessWidget {
  const SettingsChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? s.accent : Colors.transparent,
        shape: StadiumBorder(
          side: selected ? BorderSide.none : BorderSide(color: s.divider),
        ),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 56, minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                widthFactor: 1,
                child: Text(
                  label,
                  style: type.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: selected ? s.onAccent : s.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
