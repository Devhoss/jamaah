import 'package:flutter/material.dart';

import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';

/// The prototype's `.row`: a 56dp-minimum list row inside a bordered, rounded
/// container. Used for prayer times, Iqama entries and settings lists.
class AppRows extends StatelessWidget {
  const AppRows({required this.children, super.key});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final divider = Theme.of(context).dividerColor;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: divider),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// A single row inside [AppRows], at least [AppSpace.touchTarget] tall.
class AppRow extends StatelessWidget {
  const AppRow({
    required this.leading,
    this.title,
    this.trailing,
    this.onTap,
    this.selected = false,
    this.muted = false,
    super.key,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? trailing;
  final VoidCallback? onTap;

  /// Highlights the current prayer row in sage, as the prototype does.
  final bool selected;

  /// Renders the row in the muted colour, used for sunrise.
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final ink = AppInk.of(context);
    Widget body = Row(
      children: [
        if (leading != null) ...[
          leading!,
          // The prototype's `.row{gap:12px}`. The gap belongs to the row rather than
          // to each call site, so a marker never ends up touching the name beside it.
          const SizedBox(width: AppSpace.md),
        ],
        if (title != null) Expanded(child: title!),
        ?trailing,
      ],
    );

    if (muted) {
      // The row's own texts inherit their colour, so one merge mutes name, time and
      // icon together instead of each call site picking a grey.
      body = DefaultTextStyle.merge(
        style: TextStyle(color: ink.muted),
        child: IconTheme.merge(
          data: IconThemeData(color: ink.muted),
          child: body,
        ),
      );
    }

    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 12),
      color: selected ? ink.sage : null,
      child: body,
    );

    // One row, one announcement. A tappable row already merges through InkResponse;
    // a static row would otherwise leave its name, times and bell to be merged into
    // whatever enclosing node the list builds.
    if (onTap == null) return Semantics(container: true, child: content);
    return InkWell(
      onTap: onTap,
      child: content,
    );
  }
}

/// The prototype's uppercase, muted section header above a list.
class AppSectionHeader extends StatelessWidget {
  const AppSectionHeader(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xxl, bottom: AppSpace.sm),
      child: Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontSize: AppType.sectionSize,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.08 * AppType.sectionSize,
        ),
      ),
    );
  }
}

/// The prototype's small pill, e.g. the location chip.
class AppChip extends StatelessWidget {
  const AppChip({required this.label, this.icon, this.onTap, super.key});

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16),
              const SizedBox(width: 5),
            ],
            // A pill keeps its shape: a long place name at a large text size
            // truncates here and reads in full in the sheet it opens.
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: AppType.bodySize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The prototype's dashed-border prompt: an empty-state call to action.
class AppPrompt extends StatelessWidget {
  const AppPrompt({required this.children, this.onTap, super.key});

  final List<Widget> children;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: AppSpace.md),
        padding: const EdgeInsets.all(AppSpace.lg),
        decoration: BoxDecoration(
          border: Border.all(color: muted),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// The prototype's `.tag`: a small status pill, e.g. "Not configured".
class AppTag extends StatelessWidget {
  const AppTag(this.label, {this.tone = AppTagTone.neutral, super.key});

  final String label;
  final AppTagTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground) = switch (tone) {
      AppTagTone.neutral => (scheme.primaryContainer, scheme.onPrimaryContainer),
      AppTagTone.warning => (
        AppColors.lightWarnBg,
        AppColors.lightWarnInk,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 11,
          height: 1.3,
        ),
      ),
    );
  }
}

enum AppTagTone { neutral, warning }
