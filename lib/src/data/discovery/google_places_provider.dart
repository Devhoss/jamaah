import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/discovery.dart';
import '../../domain/mosque.dart';
import 'app_identity.dart';

/// Google Places API (New) Nearby Search, `includedTypes: ["mosque"]`.
///
/// Requests ONLY the fields the list renders. Billing follows the highest-priced
/// field in the mask, so adding ratings, photos or hours here is a cost decision,
/// not a detail (AGENTS.md). There are no per-result Place Details calls.
class GooglePlacesProvider implements MosqueDiscoveryProvider {
  GooglePlacesProvider({
    required this.apiKey,
    required this.identity,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  static final endpoint = Uri.parse(
    'https://places.googleapis.com/v1/places:searchNearby',
  );

  /// Exactly what the list shows: id, name, address, position.
  static const fieldMask =
      'places.id,places.displayName,places.formattedAddress,places.location';

  /// Nearby Search returns at most 20 places per request.
  static const maxResults = 20;

  final String apiKey;
  final AppIdentitySource identity;
  final http.Client _client;
  final Duration timeout;

  @override
  MosqueSource get source => MosqueSource.google;

  @override
  Future<DiscoveryResult> nearby(DiscoveryQuery query) async {
    if (apiKey.isEmpty) return const DiscoveryNoKey();

    final http.Response response;
    try {
      response = await _client
          .post(
            endpoint,
            headers: await _headers(),
            body: jsonEncode(requestBody(query)),
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
      400 || 401 || 403 => DiscoveryFailure.keyRejected,
      429 => DiscoveryFailure.rateLimited,
      _ => DiscoveryFailure.server,
    };
    if (failure != null) return DiscoveryFailed(failure);

    try {
      final json = jsonDecode(response.body) as Map<String, Object?>;
      return DiscoveryFound(
        source: MosqueSource.google,
        mosques: nearestFirst(mosquesFromGoogle(json), query),
      );
    } on FormatException {
      return const DiscoveryFailed(DiscoveryFailure.server);
    } on TypeError {
      return const DiscoveryFailed(DiscoveryFailure.server);
    }
  }

  Future<Map<String, String>> _headers() async {
    final app = await identity.read();
    return {
      'Content-Type': 'application/json',
      'X-Goog-Api-Key': apiKey,
      'X-Goog-FieldMask': fieldMask,
      // A key restricted to the Android app only matches when the request says
      // which app it comes from; a plain HTTP call from Dart does not say so by
      // itself.
      'X-Android-Package': app.packageName,
      'X-Android-Cert': ?app.signingCertSha1,
    };
  }

  /// The request body, public so its shape is pinned by a test.
  static Map<String, Object?> requestBody(DiscoveryQuery query) => {
    'includedTypes': ['mosque'],
    'maxResultCount': maxResults,
    'rankPreference': 'DISTANCE',
    'locationRestriction': {
      'circle': {
        'center': {'latitude': query.latitude, 'longitude': query.longitude},
        'radius': query.radiusMeters.toDouble(),
      },
    },
  };
}

/// Maps a Nearby Search response onto [DiscoveredMosque]s. A place without an id
/// or a position is dropped: it could be neither saved nor placed in the list.
List<DiscoveredMosque> mosquesFromGoogle(Map<String, Object?> json) {
  final places = json['places'];
  if (places is! List) return const [];
  return [
    for (final place in places.whereType<Map<String, Object?>>())
      ?_googlePlace(place),
  ];
}

DiscoveredMosque? _googlePlace(Map<String, Object?> place) {
  final id = place['id'];
  final location = place['location'];
  if (id is! String || id.isEmpty || location is! Map) return null;
  final lat = location['latitude'];
  final lng = location['longitude'];
  if (lat is! num || lng is! num) return null;

  final displayName = place['displayName'];
  final name = displayName is Map ? displayName['text'] : null;
  final address = place['formattedAddress'];

  return DiscoveredMosque(
    placeId: id,
    source: MosqueSource.google,
    name: name is String && name.trim().isNotEmpty ? name.trim() : null,
    address: address is String ? address.trim() : '',
    latitude: lat.toDouble(),
    longitude: lng.toDouble(),
  );
}
