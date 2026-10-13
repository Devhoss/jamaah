import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
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
  const MosqueDetailsSheet({this.editing, super.key});

  /// Null when adding.
  final Mosque? editing;

  @override
  ConsumerState<MosqueDetailsSheet> createState() => _MosqueDetailsSheetState();
}

class _MosqueDetailsSheetState extends ConsumerState<MosqueDetailsSheet> {
  late final _name = TextEditingController(text: widget.editing?.name ?? '');
  late final _address = TextEditingController(
    text: widget.editing?.address ?? '',
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
    if (editing == null) {
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
    final adding = widget.editing == null;

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
                adding ? l10n.addMosqueSheetTitle : l10n.editMosqueTitle,
                style: theme.textTheme.headlineSmall,
              ),
              if (adding) ...[
                const SizedBox(height: AppSpace.xs),
                Text(
                  l10n.addMosqueSheetBody,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppInk.of(context).muted,
                  ),
                ),
              ],
              const SizedBox(height: AppSpace.lg),
              TextField(
                controller: _name,
                autofocus: adding,
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
