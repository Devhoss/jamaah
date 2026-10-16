import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/mosque.dart';
import '../components/horizon_controls.dart';
import '../components/line_icon.dart';
import '../sky/sky_page.dart';
import '../sky/sky_palette.dart';
import 'mosque_copy.dart';
import 'mosque_detail_page.dart';
import 'mosque_details_sheet.dart';
import 'nearby_mosques_page.dart';

/// The Mosques tab (Horizon spec §4.3): the user's saved mosques on a calm
/// surface under the sky, and the ways to add one.
///
/// Every mosque here is one the user saved. There is no sample data: a mosque
/// gets here by being found nearby and confirmed, or by being added by hand.
class MosquesScreen extends ConsumerWidget {
  const MosquesScreen({super.key});

  Future<void> _addManually(BuildContext context) async {
    final added = await showAddMosqueSheet(context);
    if (added != null && context.mounted) {
      await openMosqueDetail(context, added.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final saved = ref.watch(savedMosquesProvider);
    final activeId = ref.watch(appSettingsProvider).value?.activeMosqueId;
    final day = ref.watch(scheduleDayProvider);
    final mosques = saved.value;
    final empty = mosques != null && mosques.isEmpty;
    Mosque? active;
    for (final m in mosques ?? const <Mosque>[]) {
      if (m.id == activeId) active = m;
    }

    return SkyPage(
      header: (context, p) => _Header(
        palette: p,
        lead: empty
            ? null
            : active == null
            ? l10n.mosquesLeadNoActive
            : l10n.mosquesLead(active.name),
        actions: empty
            ? null
            : [
                PillButton(
                  label: l10n.mosquesFindNearby,
                  icon: LineIcons.pin,
                  filled: true,
                  ink: p.ink,
                  onInk: p.deep,
                  line: p.line,
                  onPressed: () => openNearbyMosques(context),
                ),
                PillButton(
                  label: l10n.mosquesAddManually,
                  ink: p.ink,
                  onInk: p.deep,
                  line: p.line,
                  onPressed: () => _addManually(context),
                ),
              ],
      ),
      panel: [
        if (mosques == null)
          const SizedBox(height: 120)
        else if (empty)
          _EmptyState(
            onFind: () => openNearbyMosques(context),
            onAdd: () => _addManually(context),
          )
        else ...[
          const SizedBox(height: 6),
          for (final mosque in mosques)
            _MosqueRow(
              mosque: mosque,
              isActive: mosque.id == activeId,
              schedule: mosque.scheduleFor(day),
              onMakeActive: () async {
                await ref
                    .read(settingsRepositoryProvider)
                    .setActiveMosqueId(mosque.id);
                if (context.mounted) {
                  showHorizonSnackBar(
                    context,
                    l10n.mosqueMadeActive(mosque.name),
                  );
                }
              },
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
            child: Text(
              l10n.mosquesFooter,
              style: HorizonTheme.typeOf(context).meta.copyWith(
                height: 1.45,
                color: HorizonTheme.of(context).surfaces.onSurfaceMuted,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.palette, this.lead, this.actions});

  final SkyPalette palette;
  final String? lead;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              l10n.mosquesTitle,
              style: type.display.copyWith(fontSize: 40, color: palette.ink),
            ),
          ),
          if (lead != null) ...[
            const SizedBox(height: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Text(
                lead!,
                style: type.body.copyWith(fontSize: 14, color: palette.mute),
              ),
            ),
          ],
          if (actions != null) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: actions!),
          ],
        ],
      ),
    );
  }
}

class _MosqueRow extends StatelessWidget {
  const _MosqueRow({
    required this.mosque,
    required this.isActive,
    required this.schedule,
    required this.onMakeActive,
  });

  final Mosque mosque;
  final bool isActive;
  final Schedule? schedule;
  final VoidCallback onMakeActive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final source = mosqueSourceLine(l10n, mosque.source);
    final count = iqamaCountLine(l10n, schedule);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: isActive ? s.well : Colors.transparent,
        // Only the active row is a rounded well; the others end in a
        // straight hairline (a radius would curl its ends).
        borderRadius: isActive ? BorderRadius.circular(16) : null,
        border: isActive ? null : Border(bottom: BorderSide(color: s.divider)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            button: true,
            label: l10n.mosqueRowSemantics(mosque.name, source, count),
            excludeSemantics: true,
            child: InkWell(
              onTap: () => openMosqueDetail(context, mosque.id),
              borderRadius: BorderRadius.circular(12),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            mosque.name,
                            style: type.row.copyWith(
                              fontSize: 17,
                              color: s.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            source,
                            style: type.meta.copyWith(
                              fontSize: 12,
                              color: s.onSurfaceMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _Slots(slots: iqamaSlots(schedule), surfaces: s),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  count,
                                  style: type.meta.copyWith(
                                    fontSize: 12,
                                    color: s.onSurfaceMuted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    LineIcon(
                      LineIcons.chevronRight,
                      size: 20,
                      strokeWidth: 2,
                      color: s.onSurfaceMuted,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              if (isActive)
                _Tag(
                  label: l10n.mosqueActiveLong,
                  icon: LineIcons.check,
                  filled: true,
                  surfaces: s,
                ),
              if (mosque.remindersPaused)
                _Tag(
                  label: l10n.tagRemindersPaused,
                  icon: LineIcons.pause,
                  surfaces: s,
                ),
              if (!isActive)
                PillButton(
                  label: l10n.mosqueMakeActive,
                  ink: s.onSurface,
                  onInk: s.surface,
                  line: s.divider,
                  onPressed: onMakeActive,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Six small dots: the five prayers and Jumu'ah, filled when set, dashed
/// when not.
class _Slots extends StatelessWidget {
  const _Slots({required this.slots, required this.surfaces});

  final List<bool> slots;
  final HorizonSurfaces surfaces;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final set in slots)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: SizedBox.square(
              dimension: 9,
              child: set
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: surfaces.onSurface,
                      ),
                    )
                  : CustomPaint(
                      painter: DashedOutline(
                        color: surfaces.onSurfaceMuted,
                        radius: 4.5,
                        width: 1.2,
                      ),
                    ),
            ),
          ),
      ],
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.icon,
    required this.surfaces,
    this.filled = false,
  });

  final String label;
  final LineIconData icon;
  final HorizonSurfaces surfaces;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final fg = filled ? surfaces.onAccent : surfaces.onSurface;
    return Container(
      constraints: const BoxConstraints(minHeight: 28),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? surfaces.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        border: filled ? null : Border.all(color: surfaces.onSurfaceMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LineIcon(icon, size: 12, strokeWidth: 2.6, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: type.meta.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onFind, required this.onAdd});

  final VoidCallback onFind;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 24, 4, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CongregationFigures(color: s.onSurface),
          const SizedBox(height: 22),
          Semantics(
            header: true,
            child: Text(
              l10n.mosquesEmptyTitle,
              style: type.prayerName.copyWith(color: s.onSurface),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mosquesEmptyBody,
            style: type.body.copyWith(color: s.onSurfaceMuted),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              PillButton(
                label: l10n.mosquesEmptyFind,
                icon: LineIcons.pin,
                filled: true,
                ink: s.accent,
                onInk: s.onAccent,
                line: s.divider,
                onPressed: onFind,
              ),
              PillButton(
                label: l10n.mosquesEmptyAdd,
                ink: s.onSurface,
                onInk: s.surface,
                line: s.divider,
                onPressed: onAdd,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            l10n.mosquesEmptyNote,
            style: type.meta.copyWith(height: 1.45, color: s.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
