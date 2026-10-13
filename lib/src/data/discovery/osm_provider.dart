import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/discovery.dart';
import '../../domain/mosque.dart';

/// OpenStreetMap via the Overpass API: places of worship tagged
/// `religion=muslim`. No key, no per-call cost; coverage varies by region, which
/// is what having it alongside Google is for (AGENTS.md).
class OpenStreetMapProvider implements MosqueDiscoveryProvider {
  OpenStreetMapProvider({
    http.Client? client,
    Uri? endpoint,
    this.timeout = const Duration(seconds: 20),
  }) : _client = client ?? http.Client(),
       endpoint = endpoint ?? defaultEndpoint;

  static final defaultEndpoint = Uri.parse(
    'https://overpass-api.de/api/interpreter',
  );

  /// Overpass asks clients to identify themselves.
  static const userAgent = 'Jamaah/1.0 (dev.jamaah.app; mosque search)';

  /// A ceiling on what one search can return, so a dense city cannot produce a
  /// list nobody can read.
  static const maxResults = 50;

  final Uri endpoint;
  final http.Client _client;
  final Duration timeout;

  @override
  MosqueSource get source => MosqueSource.osm;

  @override
  Future<DiscoveryResult> nearby(DiscoveryQuery query) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: const {
              'User-Agent': userAgent,
              'Content-Type': 'application/x-www-form-urlencoded',
            },
            body: {'data': overpassQuery(query)},
          )
          .timeout(timeout);
    } on TimeoutException {
      return const DiscoveryFailed(DiscoveryFailure.network);
    } on SocketException {
      return const DiscoveryFailed(DiscoveryFailure.network);
    } on http.ClientException {
      return const DiscoveryFailed(DiscoveryFailure.network);
    }

    final failure = switch (response.statusCode) {
      200 => null,
      429 => DiscoveryFailure.rateLimited,
      _ => DiscoveryFailure.server,
    };
    if (failure != null) return DiscoveryFailed(failure);

    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      return DiscoveryFound(
        source: MosqueSource.osm,
        mosques: nearestFirst(mosquesFromOverpass(json), query),
      );
    } on FormatException {
      return const DiscoveryFailed(DiscoveryFailure.server);
    } on TypeError {
      return const DiscoveryFailed(DiscoveryFailure.server);
    }
  }

  /// The Overpass QL sent, public so its shape is pinned by a test. `out center`
  /// gives ways and relations (a mosque drawn as a building) a single point.
  static String overpassQuery(DiscoveryQuery query) {
    final around = '${query.radiusMeters},${query.latitude},${query.longitude}';
    return '[out:json][timeout:15];'
        'nwr["amenity"="place_of_worship"]["religion"="muslim"](around:$around);'
        'out center tags $maxResults;';
  }
}

/// Maps an Overpass response onto [DiscoveredMosque]s. An element with no
/// position is dropped; one with no name is kept, with a null name, because an
/// unnamed mosque on the map is still a mosque the user may pray at.
List<DiscoveredMosque> mosquesFromOverpass(Map<String, Object?> json) {
  final elements = json['elements'];
  if (elements is! List) return const [];
  return [
    for (final element in elements.whereType<Map<String, Object?>>())
      ?_overpassElement(element),
  ];
}

DiscoveredMosque? _overpassElement(Map<String, Object?> element) {
  final type = element['type'];
  final id = element['id'];
  if (type is! String || id is! num) return null;

  final center = element['center'];
  final lat = element['lat'] ?? (center is Map ? center['lat'] : null);
  final lon = element['lon'] ?? (center is Map ? center['lon'] : null);
  if (lat is! num || lon is! num) return null;

  final rawTags = element['tags'];
  final tags = rawTags is Map ? rawTags : const {};
  String? tag(String key) {
    final value = tags[key];
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  return DiscoveredMosque(
    placeId: 'osm:$type/${id.toInt()}',
    source: MosqueSource.osm,
    name: tag('name') ?? tag('name:en'),
    address: _address(tag),
    latitude: lat.toDouble(),
    longitude: lon.toDouble(),
  );
}

/// "12 Garden Road, Cairo" from whichever `addr:*` tags exist.
String _address(String? Function(String) tag) {
  final street = [
    tag('addr:housenumber'),
    tag('addr:street'),
  ].whereType<String>().join(' ');
  return [if (street.isNotEmpty) street, ?tag('addr:city')].join(', ');
}
