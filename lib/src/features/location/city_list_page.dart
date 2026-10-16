import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../domain/place.dart';
import '../../domain/placeholder_places.dart';
import '../settings/settings_kit.dart';

/// The bundled city list — the offline answer to "where are you?".
///
/// Returns the chosen [Place] so the caller decides what to do with it; this page
/// owns no state. The list is labelled as the placeholder it is (AGENTS.md: never
/// present unverified data as more than its source).
class CityListPage extends ConsumerStatefulWidget {
  const CityListPage({super.key});

  @override
  ConsumerState<CityListPage> createState() => _CityListPageState();
}

class _CityListPageState extends ConsumerState<CityListPage> {
  String _query = '';

  List<Place> get _matches {
    if (_query.trim().isEmpty) return placeholderPlaces;
    final needle = _query.trim().toLowerCase();
    return [
      for (final place in placeholderPlaces)
        if (place.displayName.toLowerCase().contains(needle)) place,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final matches = _matches;

    return SettingsScaffold(
      title: l10n.cityListTitle,
      lead: l10n.cityListPlaceholderNote,
      children: [
        TextField(
          decoration: InputDecoration(hintText: l10n.cityListSearchHint),
          textCapitalization: TextCapitalization.words,
          onChanged: (value) => setState(() => _query = value),
        ),
        const SizedBox(height: 8),
        if (matches.isEmpty)
          SettingsNote(l10n.cityListNoMatches, top: 12)
        else
          for (final (i, place) in matches.indexed)
            SettingsLinkRow(
              title: place.displayName,
              // `Africa/Cairo` reads as `Cairo`: the zone is already inside
              // the choice, and the full name is never useful at this size.
              value: _shortZone(place.ianaZone),
              divider: i < matches.length - 1,
              onTap: () => Navigator.of(context).pop(place),
            ),
      ],
    );
  }

  static String _shortZone(String ianaZone) =>
      ianaZone.split('/').last.replaceAll('_', ' ');
}
