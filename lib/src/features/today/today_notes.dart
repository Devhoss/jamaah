import 'package:flutter/material.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/horizon_tokens.dart';
import '../components/line_icon.dart';
import '../sky/sky_palette.dart';

/// One quiet admission about the day: a time moved by the high-latitude rule,
/// an estimate, a clock mismatch, paused reminders, the in-flight hold.
@immutable
class TodayNote {
  const TodayNote(
    this.text, {
    this.icon = LineIcons.info,
    this.actionLabel,
    this.onAction,
  });

  final String text;
  final LineIconData icon;

  /// The in-flight hold's "End".
  final String? actionLabel;
  final VoidCallback? onAction;
}

/// At most two notes as single quiet lines; more collapse into "2 more notes"
/// (spec §4.1). Never boxed or coloured.
class TodayNotes extends StatelessWidget {
  const TodayNotes({required this.notes, required this.palette, super.key});

  final List<TodayNote> notes;
  final SkyPalette palette;

  static const shown = 2;

  @override
  Widget build(BuildContext context) {
    if (notes.isEmpty) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    // With three or more, the second line makes room for the "more" link.
    final visible = notes.length <= shown ? notes : notes.take(shown - 1);
    final hidden = notes.length - visible.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final note in visible)
          _NoteLine(note: note, palette: palette, style: type.meta),
        if (hidden > 0)
          Semantics(
            button: true,
            child: InkWell(
              onTap: () => _showAll(context),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.moreNotes(hidden),
                      style: type.meta.copyWith(
                        color: palette.ink,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: palette.line,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showAll(BuildContext context) {
    final surfaces = HorizonTheme.of(context).surfaces;
    final type = HorizonTheme.typeOf(context);
    final l10n = AppLocalizations.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: surfaces.surface,
      barrierColor: surfaces.scrim,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(HorizonShape.sheetRadius),
        ),
      ),
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            HorizonShape.gutterSurface,
            0,
            HorizonShape.gutterSurface,
            HorizonShape.gutterSurface,
          ),
          children: [
            Text(
              l10n.notesTitle,
              style: type.prayerName.copyWith(color: surfaces.onSurface),
            ),
            const SizedBox(height: 8),
            for (final note in notes)
              _NoteLine(
                note: note,
                palette: SkyPalette(
                  ink: surfaces.onSurface,
                  deep: surfaces.surface,
                ),
                style: type.body,
                wrap: true,
              ),
          ],
        ),
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({
    required this.note,
    required this.palette,
    required this.style,
    this.wrap = false,
  });

  final TodayNote note;
  final SkyPalette palette;
  final TextStyle style;

  /// In the sheet every note is read in full.
  final bool wrap;

  @override
  Widget build(BuildContext context) {
    final action = note.onAction;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: LineIcon(note.icon, size: 14, color: palette.mute),
          ),
          Expanded(
            child: Text(
              note.text,
              maxLines: wrap ? null : 2,
              overflow: wrap ? null : TextOverflow.ellipsis,
              style: style.copyWith(color: palette.mute),
            ),
          ),
          if (action != null && note.actionLabel != null)
            // In the note's own size, and free to wrap beside a long note.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 150),
              child: TextButton(
                onPressed: action,
                style: TextButton.styleFrom(
                  foregroundColor: palette.ink,
                  minimumSize: const Size(48, 48),
                  textStyle: style.copyWith(fontWeight: FontWeight.w600),
                ),
                child: Text(note.actionLabel!, textAlign: TextAlign.end),
              ),
            ),
        ],
      ),
    );
  }
}
