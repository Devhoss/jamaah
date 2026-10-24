import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/place.dart';
import '../components/line_icon.dart';
import '../settings/settings_kit.dart';
import 'city_list_page.dart';
import 'location_controller.dart';
import 'place_copy.dart';
import 'preview_city_page.dart';

/// The place question, asked the way AGENTS.md requires: explain first, then ask.
///
/// Nothing here touches the device until the user taps "Use my location", so the
/// system dialog always arrives after the explanation has been read. Every failure
/// keeps "Choose a city" on screen — a denied permission is a change of route, not
/// a dead end (spec §4.10: one quiet line plus the next useful action).
Future<void> showLocationSheet(BuildContext context) =>
    showSettingsSheet<void>(context, builder: (_) => const _LocationSheet());

class _LocationSheet extends ConsumerWidget {
  const _LocationSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final state = ref.watch(locationRequestProvider);
    final controller = ref.read(locationRequestProvider.notifier);
    final place = ref.watch(currentPlaceProvider);

    return SettingsSheetBody(
      title: l10n.locationSheetTitle,
      children: [
        SettingsNote(l10n.locationSheetBody, top: 0),
        SettingsNote(l10n.locationSheetPrecise),
        if (place != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
            decoration: BoxDecoration(
              color: s.well,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.currentPlaceLabel(placeDescription(l10n, place)),
                  style: type.row.copyWith(color: s.onSurface),
                ),
                SettingsTextButton(
                  label: l10n.placeRenameAction,
                  onPressed: () => _rename(context, controller, l10n, place),
                ),
              ],
            ),
          ),
        ],
        if (state.failure case final failure?) ...[
          const SizedBox(height: 14),
          _FailureNotice(failure: failure),
        ],
        const SizedBox(height: 20),
        if (state.isRequesting)
          _RequestingRow(label: l10n.locationRequesting)
        else
          SettingsButton(
            label: l10n.locationUseDevice,
            icon: LineIcons.pin,
            filled: true,
            wide: true,
            onPressed: () async {
              final acquired = await controller.useDeviceLocation();
              if (acquired != null && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
        const SizedBox(height: 10),
        SettingsButton(
          label: l10n.locationChooseCity,
          wide: true,
          onPressed: () async {
            final chosen = await Navigator.of(context).push<Place>(
              MaterialPageRoute(builder: (_) => const CityListPage()),
            );
            if (chosen == null) return;
            await controller.choose(chosen);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        if (place != null) ...[
          const SizedBox(height: 6),
          Center(
            child: SettingsTextButton(
              label: l10n.previewCity,
              // Looks somewhere else without moving the saved place.
              onPressed: () {
                final navigator = Navigator.of(context);
                navigator.pop();
                previewAnotherCity(navigator.context);
              },
            ),
          ),
        ],
      ],
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
  final name = await showSettingsSheet<String>(
    context,
    builder: (_) => _RenameSheet(l10n: l10n, current: current),
  );
  if (name == null) return;
  await controller.rename(name);
  if (context.mounted) Navigator.of(context).pop();
}

class _RenameSheet extends StatefulWidget {
  const _RenameSheet({required this.l10n, required this.current});

  final AppLocalizations l10n;
  final Place current;

  @override
  State<_RenameSheet> createState() => _RenameSheetState();
}

class _RenameSheetState extends State<_RenameSheet> {
  late final TextEditingController _text = TextEditingController(
    text: widget.current.userName ?? '',
  );

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return SettingsSheetBody(
      title: l10n.placeRenameTitle,
      children: [
        TextField(
          controller: _text,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: l10n.placeRenameHint),
          onSubmitted: (value) => Navigator.of(context).pop(value),
        ),
        const SizedBox(height: 20),
        SheetActions(
          cancelLabel: l10n.cancel,
          saveLabel: l10n.save,
          onCancel: () => Navigator.of(context).pop(),
          onSave: () => Navigator.of(context).pop(_text.text),
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
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            placeFailureMessage(l10n, failure),
            style: type.body.copyWith(color: s.onSurface),
          ),
          if (failure == PlaceFailure.permanentlyDenied)
            SettingsTextButton(
              label: l10n.locationOpenSettings,
              onPressed: () => ref
                  .read(locationRequestProvider.notifier)
                  .openSystemSettings(),
            ),
        ],
      ),
    );
  }
}

class _RequestingRow extends StatelessWidget {
  const _RequestingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    return Semantics(
      liveRegion: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 52),
        child: Row(
          children: [
            const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: type.body.copyWith(color: s.onSurfaceMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
