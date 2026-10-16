import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/l10n/generated/app_localizations.dart';
import '../../app/providers.dart';
import '../../app/theme/horizon_tokens.dart';
import '../../domain/discovery.dart';
import '../../domain/mosque.dart';
import '../../domain/place.dart';
import '../components/line_icon.dart';
import '../location/city_list_page.dart';
import '../settings/settings_kit.dart';
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

    return SettingsScaffold(
      title: l10n.nearbyTitle,
      lead: l10n.nearbyExplainTitle,
      children: switch (_stage) {
        _Stage.explain => _explain(l10n),
        _Stage.locating => _working(l10n.nearbyLocating),
        _Stage.searching => _working(l10n.nearbySearching),
        _Stage.done => _answer(l10n),
      },
    );
  }

  List<Widget> _explain(AppLocalizations l10n) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final failure = _locationFailure;
    return [
      Text(
        l10n.nearbyExplainBody,
        style: type.body.copyWith(fontSize: 16, color: s.onSurface),
      ),
      SettingsNote(l10n.nearbyExplainSent(providerName(l10n, _source))),
      if (failure != null) ...[
        const SizedBox(height: 14),
        Semantics(
          liveRegion: true,
          child: Text(
            _locationMessage(l10n, failure),
            style: type.body.copyWith(color: s.onSurface),
          ),
        ),
        if (failure == PlaceFailure.permanentlyDenied)
          SettingsTextButton(
            label: l10n.locationOpenSettings,
            onPressed: () =>
                ref.read(nearbyLocationSourceProvider).openSystemSettings(),
          ),
      ],
      const SizedBox(height: 18),
      SettingsButton(
        label: failure == PlaceFailure.timeout
            ? l10n.locationTryAgain
            : l10n.nearbyUseLocation,
        icon: LineIcons.pin,
        filled: true,
        wide: true,
        onPressed: _useMyLocation,
      ),
      const SizedBox(height: 10),
      SettingsButton(
        label: l10n.nearbySearchCity,
        wide: true,
        onPressed: _searchAroundCity,
      ),
    ];
  }

  List<Widget> _working(String label) => [
    const SizedBox(height: 24),
    const Center(child: CircularProgressIndicator()),
    const SizedBox(height: 16),
    Semantics(
      liveRegion: true,
      child: Center(
        child: Text(
          label,
          style: HorizonTheme.typeOf(context).body.copyWith(
            color: HorizonTheme.of(context).surfaces.onSurfaceMuted,
          ),
        ),
      ),
    ),
  ];

  List<Widget> _answer(AppLocalizations l10n) {
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final query = _query!;
    final km = query.radiusMeters ~/ 1000;
    final source = _source;

    final header = SettingsHeading(
      _cityName == null
          ? l10n.nearbyHeaderHere(km)
          : l10n.nearbyHeaderCity(km, _cityName!),
      top: 4,
    );

    final addByHand = SettingsButton(
      label: l10n.nearbyAddManually,
      onPressed: _addByHand,
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
        Semantics(
          liveRegion: true,
          child: Text(
            _failureMessage(l10n, result, source),
            style: type.body.copyWith(color: s.onSurface),
          ),
        ),
        const SizedBox(height: 16),
        if (canTryOsm) ...[
          SettingsButton(
            label: l10n.nearbyTryOsm,
            filled: true,
            onPressed: _switchToOsm,
          ),
          const SizedBox(height: 10),
        ],
        if (canRetry) ...[
          SettingsButton(
            label: l10n.locationTryAgain,
            onPressed: () => _search(query),
          ),
          const SizedBox(height: 10),
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
      if (!_precise) SettingsNote(l10n.nearbyApproximateNote, top: 0),
      const SizedBox(height: 10),
      if (result.mosques.isEmpty)
        SettingsNote(l10n.nearbyEmpty(km), top: 0)
      else ...[
        TextField(
          controller: _filter,
          decoration: InputDecoration(hintText: l10n.nearbyFilterHint),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        if (shown.isEmpty)
          SettingsNote(l10n.nearbyNoMatches, top: 8)
        else
          for (final (i, m) in shown.indexed)
            _ResultRow(
              mosque: m,
              distance: _distance(l10n, m.distanceFrom(query)),
              saved: saved[m.placeId],
              divider: i < shown.length - 1,
              onTap: () => _open(m, saved[m.placeId]),
            ),
      ],
      SettingsNote(
        result.source == MosqueSource.google
            ? l10n.nearbyAttributionGoogle
            : l10n.nearbyAttributionOsm,
        top: 14,
      ),
      const SizedBox(height: 16),
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
    required this.divider,
    required this.onTap,
  });

  final DiscoveredMosque mosque;
  final String distance;
  final Mosque? saved;
  final bool divider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final type = HorizonTheme.typeOf(context);
    final s = HorizonTheme.of(context).surfaces;
    final small = type.meta.copyWith(color: s.onSurfaceMuted);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: divider ? Border(bottom: BorderSide(color: s.divider)) : null,
      ),
      child: MergeSemantics(
        child: Semantics(
          button: true,
          child: InkWell(
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 64),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                mosque.name ?? l10n.nearbyUnnamed,
                                style: type.row.copyWith(
                                  color: s.onSurface,
                                  fontStyle: mosque.name == null
                                      ? FontStyle.italic
                                      : null,
                                ),
                              ),
                              if (saved != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.well,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    l10n.tagSaved,
                                    style: small.copyWith(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: s.onSurface,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            mosque.address.isEmpty
                                ? l10n.nearbyNoAddress
                                : mosque.address,
                            style: small,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(distance, style: small),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
