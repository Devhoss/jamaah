import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/place.dart';
import '../components/app_widgets.dart';
import 'city_list_page.dart';
import 'location_controller.dart';
import 'preview_city_page.dart';
import 'place_copy.dart';

/// The place question, asked the way AGENTS.md requires: explain first, then ask.
///
/// Nothing here touches the device until the user taps "Use my location", so the
/// system dialog always arrives after the explanation has been read. Every failure
/// keeps "Choose a city" on screen — a denied permission is a change of route, not
/// a dead end.
Future<void> showLocationSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const _LocationSheet(),
    );

class _LocationSheet extends ConsumerWidget {
  const _LocationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(locationRequestProvider);
    final controller = ref.read(locationRequestProvider.notifier);
    final place = ref.watch(currentPlaceProvider);

    // Scrolls when it does not fit: a phone screen at a large text size, or
    // with a saved place (rename and preview add rows).
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          0,
          AppSpace.xxl,
          AppSpace.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.locationSheetTitle,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpace.md),
            Text(l10n.locationSheetBody),
            const SizedBox(height: AppSpace.md),
            Text(
              l10n.locationSheetCoarse,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (place != null) ...[
              const SizedBox(height: AppSpace.lg),
              AppPrompt(
                children: [
                  Text(l10n.currentPlaceLabel(placeDescription(l10n, place))),
                  const SizedBox(height: AppSpace.sm),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton(
                      onPressed: () => _rename(context, controller, l10n, place),
                      child: Text(l10n.placeRenameAction),
                    ),
                  ),
                ],
              ),
            ],
            if (state.failure case final failure?) ...[
              const SizedBox(height: AppSpace.lg),
              _FailureNotice(failure: failure),
            ],
            const SizedBox(height: AppSpace.xl),
            if (state.isRequesting)
              _RequestingRow(label: l10n.locationRequesting)
            else
              FilledButton(
                onPressed: () async {
                  final acquired = await controller.useDeviceLocation();
                  if (acquired != null && context.mounted) {
                    Navigator.of(context).pop();
                  }
                },
                child: Text(l10n.locationUseDevice),
              ),
            const SizedBox(height: AppSpace.sm),
            OutlinedButton(
              onPressed: () async {
                final chosen = await Navigator.of(context).push<Place>(
                  MaterialPageRoute(builder: (_) => const CityListPage()),
                );
                if (chosen == null) return;
                await controller.choose(chosen);
                if (context.mounted) Navigator.of(context).pop();
              },
              child: Text(l10n.locationChooseCity),
            ),
            if (place != null) ...[
              const SizedBox(height: AppSpace.sm),
              TextButton.icon(
                // Looks somewhere else without moving the saved place.
                onPressed: () {
                  final navigator = Navigator.of(context);
                  navigator.pop();
                  previewAnotherCity(navigator.context);
                },
                icon: const Icon(Icons.travel_explore),
                label: Text(l10n.previewCity),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one part of a place the user owns is its name, so it is the one edit the
/// sheet offers. Saving closes the flow the same way acquiring or choosing does;
/// Today's chip is the way back in.
Future<void> _rename(
  BuildContext context,
  LocationRequestController controller,
  AppLocalizations l10n,
  Place current,
) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _RenameDialog(l10n: l10n, current: current),
  );
  if (name == null) return;
  await controller.rename(name);
  if (context.mounted) Navigator.of(context).pop();
}

class _RenameDialog extends StatefulWidget {
  const _RenameDialog({required this.l10n, required this.current});

  final AppLocalizations l10n;
  final Place current;

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  late final TextEditingController _text =
      TextEditingController(text: widget.current.userName ?? '');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return AlertDialog(
      title: Text(l10n.placeRenameTitle),
      content: TextField(
        controller: _text,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: l10n.placeRenameHint),
        onSubmitted: (value) => Navigator.of(context).pop(value),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_text.text),
          child: Text(l10n.save),
        ),
      ],
    );
  }
}

/// The calm message for one failure, plus the extra action that helps with it.
class _FailureNotice extends ConsumerWidget {
  const _FailureNotice({required this.failure});

  final PlaceFailure failure;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final message = placeFailureMessage(l10n, failure);

    return AppPrompt(
      children: [
        Text(message),
        if (failure == PlaceFailure.permanentlyDenied) ...[
          const SizedBox(height: AppSpace.md),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: () => ref
                  .read(locationRequestProvider.notifier)
                  .openSystemSettings(),
              icon: const Icon(Icons.settings_outlined, size: 20),
              label: Text(l10n.locationOpenSettings),
            ),
          ),
        ],
      ],
    );
  }
}

class _RequestingRow extends StatelessWidget {
  const _RequestingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.md),
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
