import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/tokens.dart';
import '../../domain/place.dart';
import '../components/app_widgets.dart';
import 'city_list_page.dart';
import 'location_controller.dart';

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

    return SafeArea(
      child: Padding(
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
                  Text(
                    l10n.currentPlaceLabel(
                      place.fromDevice
                          ? l10n.locationThisDevice
                          : place.displayName,
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
          ],
        ),
      ),
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
    final message = switch (failure) {
      PlaceFailure.denied => l10n.locationDenied,
      PlaceFailure.permanentlyDenied => l10n.locationPermanentlyDenied,
      PlaceFailure.serviceDisabled => l10n.locationServiceDisabled,
      PlaceFailure.timeout => l10n.locationTimeout,
      PlaceFailure.unavailable => l10n.locationUnavailable,
    };

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
