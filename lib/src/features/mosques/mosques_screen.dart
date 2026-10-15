import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';
import '../components/app_widgets.dart';
import 'mosque_detail_page.dart';
import 'mosque_details_sheet.dart';
import 'nearby_mosques_page.dart';

/// The Mosques tab: the user's saved mosques, and the ways to add one.
///
/// Every mosque here is one the user saved. There is no sample data: a mosque
/// gets here by being found nearby and confirmed, or by being added by hand.
class MosquesScreen extends ConsumerWidget {
  const MosquesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final saved = ref.watch(savedMosquesProvider);
    final activeId = ref.watch(appSettingsProvider).value?.activeMosqueId;
    final day = ref.watch(scheduleDayProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xxl,
        AppSpace.lg,
        AppSpace.xxl,
        AppSpace.xxl,
      ),
      children: [
        PageTitle(l10n.mosquesTitle),
        const SizedBox(height: AppSpace.xs),
        Text(
          l10n.mosquesSubtitle,
          style: theme.textTheme.bodyMedium?.copyWith(color: ink.muted),
        ),
        const SizedBox(height: AppSpace.lg),
        FilledButton.icon(
          onPressed: () => openNearbyMosques(context),
          icon: const Icon(Icons.search),
          label: Text(l10n.findNearbyMosques),
        ),
        const SizedBox(height: AppSpace.md),
        OutlinedButton.icon(
          onPressed: () async {
            final added = await showAddMosqueSheet(context);
            if (added != null && context.mounted) {
              await openMosqueDetail(context, added.id);
            }
          },
          icon: const Icon(Icons.add),
          label: Text(l10n.addMosqueManually),
        ),
        AppSectionHeader(l10n.savedMosquesHeader),
        switch (saved) {
          AsyncValue(:final value?) when value.isNotEmpty => AppRows(
            children: [
              for (final mosque in value)
                _MosqueRow(
                  mosque: mosque,
                  isActive: mosque.id == activeId,
                  status: mosqueIqamaStatus(mosque, day),
                ),
            ],
          ),
          AsyncValue(:final value?) when value.isEmpty => AppPrompt(
            children: [
              Text(l10n.noSavedMosques, style: theme.textTheme.bodyMedium),
            ],
          ),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

class _MosqueRow extends StatelessWidget {
  const _MosqueRow({
    required this.mosque,
    required this.isActive,
    required this.status,
  });

  final Mosque mosque;
  final bool isActive;
  final IqamaStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);

    return AppRow(
      leading: null,
      onTap: () => openMosqueDetail(context, mosque.id),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                mosque.name,
                style: const TextStyle(
                  fontSize: AppType.rowSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isActive) AppTag(l10n.tagActive),
              if (mosque.remindersPaused)
                AppTag(l10n.tagRemindersPaused, tone: AppTagTone.warning),
            ],
          ),
          Text(switch (status) {
            IqamaStatusAll() => l10n.iqamaStatusAll,
            IqamaStatusPartial(:final configured, :final of) =>
              l10n.iqamaStatusPartial(configured, of),
            IqamaStatusNone() => l10n.iqamaStatusNone,
          }, style: TextStyle(fontSize: 13, color: ink.muted)),
        ],
      ),
      trailing: Icon(Icons.chevron_right, color: ink.muted),
    );
  }
}
