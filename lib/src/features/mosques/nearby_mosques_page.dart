import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/theme.dart';
import '../../app/theme/tokens.dart';
import '../../domain/discovery.dart';
import '../../domain/mosque.dart';
import '../../domain/place.dart';
import '../components/app_widgets.dart';
import '../location/city_list_page.dart';
import 'mosque_detail_page.dart';
import 'mosque_details_sheet.dart';

/// Opens "Find nearby mosques".
Future<void> openNearbyMosques(BuildContext context) => Navigator.of(context)
    .push(MaterialPageRoute<void>(builder: (_) => const NearbyMosquesPage()));

/// Finding a mosque to save: around the phone's precise position, or around a
/// city from the bundled list.
///
/// Nothing is requested until the user taps: the explanation comes first, and it
/// says the position is sent to the provider for the search (AGENTS.md). Results
/// are labelled by source and never as verified.
class NearbyMosquesPage extends ConsumerStatefulWidget {
  const NearbyMosquesPage({super.key});

  @override
  ConsumerState<NearbyMosquesPage> createState() => _NearbyMosquesPageState();
}

enum _Stage { explain, locating, searching, done }

class _NearbyMosquesPageState extends ConsumerState<NearbyMosquesPage> {
  _Stage _stage = _Stage.explain;
  PlaceFailure? _locationFailure;
  DiscoveryQuery? _query;

  /// The city searched around, or null for the phone's own position.
  String? _cityName;

  /// False when the phone shared only approximate location.
  bool _precise = true;

  DiscoveryResult? _result;

  /// Set once the user asked for OpenStreetMap after the configured provider
  /// could not answer.
  bool _useOsm = false;

  final _filter = TextEditingController();

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  MosqueDiscoveryProvider get _provider => _useOsm
      ? ref.read(osmDiscoveryProvider)
      : ref.read(mosqueDiscoveryProvider);

  MosqueSource get _source =>
      _useOsm ? MosqueSource.osm : ref.read(mosqueDiscoveryProvider).source;

  Future<void> _useMyLocation() async {
    setState(() {
      _stage = _Stage.locating;
      _locationFailure = null;
    });
    final reading = await ref
        .read(nearbyLocationSourceProvider)
        .requestPosition();
    if (!mounted) return;
    switch (reading) {
      case NearbyRejected(:final failure):
        setState(() {
          _stage = _Stage.explain;
          _locationFailure = failure;
        });
      case NearbyFound(:final latitude, :final longitude, :final precise):
        _precise = precise;
        _cityName = null;
        await _search(DiscoveryQuery(latitude: latitude, longitude: longitude));
    }
  }

  Future<void> _searchAroundCity() async {
    final city = await Navigator.of(context)
        .push<Place>(MaterialPageRoute(builder: (_) => const CityListPage()));
    if (city == null || !mounted) return;
    _precise = true;
    _cityName = city.displayName;
    await _search(
      DiscoveryQuery(latitude: city.latitude, longitude: city.longitude),
    );
  }

  Future<void> _search(DiscoveryQuery query) async {
    setState(() {
      _stage = _Stage.searching;
      _query = query;
      _locationFailure = null;
    });
    final result = await _provider.nearby(query);
    if (!mounted) return;
    setState(() {
      _stage = _Stage.done;
      _result = result;
    });
  }

  Future<void> _switchToOsm() async {
    _useOsm = true;
    final query = _query;
    if (query != null) await _search(query);
  }

  Future<void> _open(DiscoveredMosque found, Mosque? saved) async {
    if (saved != null) {
      await openMosqueDetail(context, saved.id);
      return;
    }
    final added = await showSaveDiscoveredSheet(context, found);
    if (added != null && mounted) await openMosqueDetail(context, added.id);
  }

  Future<void> _addByHand() async {
    final added = await showAddMosqueSheet(context);
    if (added != null && mounted) await openMosqueDetail(context, added.id);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.nearbyTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.xxl,
          AppSpace.sm,
          AppSpace.xxl,
          AppSpace.xxl,
        ),
        children: switch (_stage) {
          _Stage.explain => _explain(l10n),
          _Stage.locating => _working(l10n.nearbyLocating),
          _Stage.searching => _working(l10n.nearbySearching),
          _Stage.done => _answer(l10n),
        },
      ),
    );
  }

  List<Widget> _explain(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final failure = _locationFailure;
    return [
      Text(l10n.nearbyExplainTitle, style: theme.textTheme.headlineSmall),
      const SizedBox(height: AppSpace.sm),
      Text(l10n.nearbyExplainBody, style: theme.textTheme.bodyLarge),
      const SizedBox(height: AppSpace.sm),
      Text(
        l10n.nearbyExplainSent(providerName(l10n, _source)),
        style: theme.textTheme.bodyMedium?.copyWith(color: ink.muted),
      ),
      if (failure != null) ...[
        const SizedBox(height: AppSpace.lg),
        AppPrompt(
          children: [
            Text(
              _locationMessage(l10n, failure),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        if (failure == PlaceFailure.permanentlyDenied) ...[
          const SizedBox(height: AppSpace.sm),
          TextButton(
            onPressed: () =>
                ref.read(nearbyLocationSourceProvider).openSystemSettings(),
            child: Text(l10n.locationOpenSettings),
          ),
        ],
      ],
      const SizedBox(height: AppSpace.lg),
      FilledButton.icon(
        onPressed: _useMyLocation,
        icon: const Icon(Icons.my_location),
        label: Text(
          failure == PlaceFailure.timeout
              ? l10n.locationTryAgain
              : l10n.nearbyUseLocation,
        ),
      ),
      const SizedBox(height: AppSpace.md),
      OutlinedButton.icon(
        onPressed: _searchAroundCity,
        icon: const Icon(Icons.location_city),
        label: Text(l10n.nearbySearchCity),
      ),
    ];
  }

  List<Widget> _working(String label) => [
    const SizedBox(height: AppSpace.xxl),
    const Center(child: CircularProgressIndicator()),
    const SizedBox(height: AppSpace.lg),
    Center(child: Text(label, style: Theme.of(context).textTheme.bodyMedium)),
  ];

  List<Widget> _answer(AppLocalizations l10n) {
    final theme = Theme.of(context);
    final ink = AppInk.of(context);
    final query = _query!;
    final km = query.radiusMeters ~/ 1000;
    final source = _source;

    final header = Text(
      _cityName == null
          ? l10n.nearbyHeaderHere(km)
          : l10n.nearbyHeaderCity(km, _cityName!),
      style: theme.textTheme.titleMedium,
    );

    final addByHand = OutlinedButton.icon(
      onPressed: _addByHand,
      icon: const Icon(Icons.add),
      label: Text(l10n.nearbyAddManually),
    );

    final result = _result;
    if (result is! DiscoveryFound) {
      final canTryOsm =
          !_useOsm &&
          source == MosqueSource.google &&
          (result is DiscoveryNoKey ||
              result is DiscoveryLimitReached ||
              (result is DiscoveryFailed &&
                  result.reason != DiscoveryFailure.network));
      final canRetry =
          result is DiscoveryFailed &&
          result.reason != DiscoveryFailure.keyRejected;
      return [
        header,
        AppPrompt(
          children: [
            Text(
              _failureMessage(l10n, result, source),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.lg),
        if (canTryOsm) ...[
          FilledButton(onPressed: _switchToOsm, child: Text(l10n.nearbyTryOsm)),
          const SizedBox(height: AppSpace.md),
        ],
        if (canRetry) ...[
          OutlinedButton(
            onPressed: () => _search(query),
            child: Text(l10n.locationTryAgain),
          ),
          const SizedBox(height: AppSpace.md),
        ],
        addByHand,
      ];
    }

    final saved = {
      for (final m in ref.watch(savedMosquesProvider).value ?? const <Mosque>[])
        if (m.placeId != null) m.placeId!: m,
    };
    final needle = _filter.text.trim().toLowerCase();
    final shown = [
      for (final m in result.mosques)
        if (needle.isEmpty || (m.name ?? '').toLowerCase().contains(needle)) m,
    ];

    return [
      header,
      if (!_precise) ...[
        const SizedBox(height: AppSpace.sm),
        Text(
          l10n.nearbyApproximateNote,
          style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
        ),
      ],
      const SizedBox(height: AppSpace.md),
      if (result.mosques.isEmpty)
        AppPrompt(
          children: [
            Text(l10n.nearbyEmpty(km), style: theme.textTheme.bodyMedium),
          ],
        )
      else ...[
        TextField(
          controller: _filter,
          decoration: InputDecoration(
            hintText: l10n.nearbyFilterHint,
            prefixIcon: const Icon(Icons.search),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: AppSpace.md),
        if (shown.isEmpty)
          AppPrompt(
            children: [
              Text(l10n.nearbyNoMatches, style: theme.textTheme.bodyMedium),
            ],
          )
        else
          AppRows(
            children: [
              for (final m in shown)
                _ResultRow(
                  mosque: m,
                  distance: _distance(l10n, m.distanceFrom(query)),
                  saved: saved[m.placeId],
                  onTap: () => _open(m, saved[m.placeId]),
                ),
            ],
          ),
      ],
      const SizedBox(height: AppSpace.md),
      Text(
        result.source == MosqueSource.google
            ? l10n.nearbyAttributionGoogle
            : l10n.nearbyAttributionOsm,
        style: theme.textTheme.bodySmall?.copyWith(color: ink.muted),
      ),
      const SizedBox(height: AppSpace.lg),
      addByHand,
    ];
  }

  String _distance(AppLocalizations l10n, double metres) {
    if (metres < 50) return l10n.distanceUnder50;
    if (metres < 1000) {
      // Tens of metres: a satellite fix is not more exact than that.
      return l10n.distanceMetres((metres / 10).round() * 10);
    }
    final locale = Localizations.localeOf(context).toLanguageTag();
    return l10n.distanceKilometres(
      NumberFormat('0.0', locale).format(metres / 1000),
    );
  }

  String _locationMessage(AppLocalizations l10n, PlaceFailure failure) =>
      switch (failure) {
        PlaceFailure.denied => l10n.nearbyLocDenied,
        PlaceFailure.permanentlyDenied => l10n.nearbyLocPermanent,
        PlaceFailure.serviceDisabled => l10n.nearbyLocService,
        PlaceFailure.timeout => l10n.nearbyLocTimeout,
        PlaceFailure.unavailable => l10n.nearbyLocUnavailable,
      };

  String _failureMessage(
    AppLocalizations l10n,
    DiscoveryResult? result,
    MosqueSource source,
  ) {
    final provider = providerName(l10n, source);
    return switch (result) {
      DiscoveryNoKey() => l10n.nearbyFailNoKey,
      DiscoveryLimitReached() => l10n.nearbyFailLimit,
      DiscoveryFailed(reason: DiscoveryFailure.keyRejected) =>
        l10n.nearbyFailKeyRejected,
      DiscoveryFailed(reason: DiscoveryFailure.network) =>
        l10n.nearbyFailNetwork,
      DiscoveryFailed(reason: DiscoveryFailure.rateLimited) =>
        l10n.nearbyFailRateLimited(provider),
      DiscoveryFailed(reason: DiscoveryFailure.server) ||
      DiscoveryFound() ||
      null => l10n.nearbyFailServer(provider),
    };
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({
    required this.mosque,
    required this.distance,
    required this.saved,
    required this.onTap,
  });

  final DiscoveredMosque mosque;
  final String distance;
  final Mosque? saved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final ink = AppInk.of(context);
    final small = TextStyle(fontSize: 13, color: ink.muted);

    return AppRow(
      leading: null,
      onTap: onTap,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                mosque.name ?? l10n.nearbyUnnamed,
                style: TextStyle(
                  fontSize: AppType.rowSize,
                  fontWeight: FontWeight.w600,
                  fontStyle: mosque.name == null ? FontStyle.italic : null,
                ),
              ),
              if (saved != null) AppTag(l10n.tagSaved),
            ],
          ),
          Text(
            mosque.address.isEmpty ? l10n.nearbyNoAddress : mosque.address,
            style: small,
          ),
        ],
      ),
      trailing: Padding(
        padding: const EdgeInsetsDirectional.only(start: AppSpace.sm),
        child: Text(distance, style: small),
      ),
    );
  }
}
