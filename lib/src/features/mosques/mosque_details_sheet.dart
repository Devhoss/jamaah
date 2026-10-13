import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/discovery.dart';
import '../../domain/iqama_editing.dart';
import '../../domain/mosque.dart';

/// Adds a mosque by hand. Resolves to the new mosque, or null when cancelled.
Future<Mosque?> showAddMosqueSheet(BuildContext context) =>
    showModalBottomSheet<Mosque>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const MosqueDetailsSheet(),
    );

/// Saves a search result, after the user has checked its name and address.
/// Resolves to the new mosque, or null when cancelled.
Future<Mosque?> showSaveDiscoveredSheet(
  BuildContext context,
  DiscoveredMosque discovered,
) => showModalBottomSheet<Mosque>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (_) => MosqueDetailsSheet(discovered: discovered),
);

/// Changes a saved mosque's name and address.
Future<void> showEditMosqueSheet(BuildContext context, Mosque mosque) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => MosqueDetailsSheet(editing: mosque),
    );

/// Name (required) and address (optional), for a new mosque or a saved one.
///
/// A new mosque gets no Iqama times here: its schedule starts "Not configured"
/// and the user enters each time on the mosque itself (AGENTS.md).
class MosqueDetailsSheet extends ConsumerStatefulWidget {
  const MosqueDetailsSheet({this.editing, this.discovered, super.key})
    : assert(editing == null || discovered == null);

  /// Set when changing a saved mosque.
  final Mosque? editing;

  /// Set when saving a search result. Its name and address are only a starting
  /// point: the user confirms or corrects them, and what they confirm is what
  /// is stored (AGENTS.md: the user's own saved name and address).
  final DiscoveredMosque? discovered;

  @override
  ConsumerState<MosqueDetailsSheet> createState() => _MosqueDetailsSheetState();
}

class _MosqueDetailsSheetState extends ConsumerState<MosqueDetailsSheet> {
  late final _name = TextEditingController(
    text: widget.editing?.name ?? widget.discovered?.name ?? '',
  );
  late final _address = TextEditingController(
    text: widget.editing?.address ?? widget.discovered?.address ?? '',
  );
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    super.dispose();
  }

  bool get _canSave => !_saving && MosqueDetailsInput.name(_name.text) != null;

  Future<void> _submit() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final repo = ref.read(mosqueRepositoryProvider);
    final editing = widget.editing;
    final discovered = widget.discovered;
    if (discovered != null) {
      // Google's terms allow keeping a place id indefinitely but coordinates for
      // 30 days at most, so a Google mosque keeps its id and the user's name and
      // address only. OpenStreetMap data (ODbL) may be kept, coordinates too.
      final keepPosition = discovered.source == MosqueSource.osm;
      final added = await repo.add(
        name: _name.text,
        address: _address.text,
        source: discovered.source,
        placeId: discovered.placeId,
        latitude: keepPosition ? discovered.latitude : null,
        longitude: keepPosition ? discovered.longitude : null,
      );
      if (mounted) Navigator.of(context).pop(added);
    } else if (editing == null) {
      final added = await repo.add(
        name: _name.text,
        address: _address.text,
        source: MosqueSource.manual,
      );
      if (mounted) Navigator.of(context).pop(added);
    } else {
      await repo.updateDetails(
        editing.id,
        name: _name.text,
        address: _address.text,
      );
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final adding = widget.editing == null && widget.discovered == null;
    final discovered = widget.discovered;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.xxl,
            0,
            AppSpace.xxl,
            AppSpace.xxl,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                discovered != null
                    ? l10n.saveMosqueTitle
                    : adding
                    ? l10n.addMosqueSheetTitle
                    : l10n.editMosqueTitle,
                style: theme.textTheme.headlineSmall,
              ),
              if (adding || discovered != null) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  discovered != null
                      ? l10n.saveMosqueBody(
                          providerName(l10n, discovered.source),
                        )
                      : l10n.addMosqueSheetBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppInk.of(context).muted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _name,
                // A search result with no name needs one typed before saving.
                autofocus: adding || (discovered != null && discovered.name == null),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(labelText: l10n.mosqueNameLabel),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpace.md),
              TextField(
                controller: _address,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(labelText: l10n.mosqueAddressLabel),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving
                          ? null
                          : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: FilledButton(
                      onPressed: _canSave ? _submit : null,
                      child: Text(adding ? l10n.add : l10n.save),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The name of the service a result came from, as the UI writes it.
String providerName(AppLocalizations l10n, MosqueSource source) =>
    switch (source) {
      MosqueSource.google => l10n.providerGoogle,
      MosqueSource.osm => l10n.providerOsm,
      MosqueSource.manual => l10n.mosqueSourceManual,
    };
