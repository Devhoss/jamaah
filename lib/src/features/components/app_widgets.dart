import 'package:flutter/material.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: 12),
      color: selected ? colorScheme.primaryContainer : null,
      child: Row(
        children: [
          ?leading,
          if (title != null) Expanded(child: title!),
          ?trailing,
        ],
      ),
    );

    if (onTap == null) return content;
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
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: AppType.bodySize,
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
