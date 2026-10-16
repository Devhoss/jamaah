import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/theme/tokens.dart';
import '../../domain/place.dart';
import '../../domain/placeholder_places.dart';
import '../components/app_widgets.dart';

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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.cityListTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          AppSpace.sm,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: [
          TextField(
            decoration: InputDecoration(
              hintText: l10n.cityListSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (value) => setState(() => _query = value),
          ),
          const SizedBox(height: AppSpace.lg),
          Text(
            l10n.cityListPlaceholderNote,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          if (matches.isEmpty)
            AppPrompt(children: [Text(l10n.cityListNoMatches)])
          else
            AppRows(
              children: [
                for (final place in matches)
                  AppRow(
                    leading: const Icon(Icons.location_city_outlined, size: 20),
                    title: Text(
                      place.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    // Capped, so a long zone at a large text size wraps
                    // instead of pushing the row past the screen.
                    trailing: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 104),
                      child: Text(
                        _shortZone(place.ianaZone),
                        textAlign: TextAlign.end,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(place),
                  ),
              ],
            ),
        ],
      ),
    );
  }

  /// `Africa/Cairo` reads as `Cairo` in the trailing slot; the full name is never
  /// useful at that size and the zone is already inside the choice.
  static String _shortZone(String ianaZone) =>
      ianaZone.split('/').last.replaceAll('_', ' ');
}
