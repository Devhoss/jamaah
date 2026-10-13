import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:jamaah/src/app/config.dart';
import 'package:jamaah/src/data/discovery/app_identity.dart';
import 'package:jamaah/src/data/discovery/discovery_session.dart';
import 'package:jamaah/src/data/discovery/google_places_provider.dart';
import 'package:jamaah/src/data/discovery/osm_provider.dart';
import 'package:jamaah/src/domain/discovery.dart';
import 'package:jamaah/src/domain/mosque.dart';

/// Both discovery providers mapped onto one model, the request each one sends,
/// and the session guards that protect the free tier. No test reaches the
/// network: every response is a recorded shape played back by a [MockClient].
void main() {
  // Central Cairo.
  const here = DiscoveryQuery(latitude: 30.0444, longitude: 31.2357);

  const identity = FixedAppIdentitySource(
    AppIdentity(
      packageName: 'dev.jamaah.app',
      signingCertSha1: '886CC7E84199B530F77CF407FEEC0A3E125E02A1',
    ),
  );

  group('Google Places mapping', () {
    final response = {
      'places': [
        {
          'id': 'ChIJ-far',
          'displayName': {'text': 'Far Mosque', 'languageCode': 'en'},
          'formattedAddress': '9 Far Street, Cairo',
          'location': {'latitude': 30.0600, 'longitude': 31.2400},
        },
        {
          'id': 'ChIJ-near',
          'displayName': {'text': '  Near Mosque '},
          'formattedAddress': '1 Near Street, Cairo',
          'location': {'latitude': 30.0450, 'longitude': 31.2360},
        },
        {
          'id': 'ChIJ-noname',
          'location': {'latitude': 30.0460, 'longitude': 31.2370},
        },
        // Dropped: no position, so it can be neither placed nor saved.
        {
          'id': 'ChIJ-nowhere',
          'displayName': {'text': 'Nowhere'},
        },
        // Dropped: no id.
        {
          'displayName': {'text': 'Anonymous'},
          'location': {'latitude': 30.0, 'longitude': 31.0},
        },
      ],
    };

    test('maps id, name, address and position, labelled as Google', () {
      final mosques = mosquesFromGoogle(response);
      final near = mosques.singleWhere((m) => m.placeId == 'ChIJ-near');
      expect(near.source, MosqueSource.google);
      expect(near.name, 'Near Mosque');
      expect(near.address, '1 Near Street, Cairo');
      expect(near.latitude, 30.0450);
      expect(near.longitude, 31.2360);
    });

    test(
      'a place with no name or address keeps empty values, not inventions',
      () {
        final noName = mosquesFromGoogle(response)
            .singleWhere((m) => m.placeId == 'ChIJ-noname');
        expect(noName.name, isNull);
        expect(noName.address, '');
      },
    );

    test('places without an id or a position are dropped', () {
      expect(
        mosquesFromGoogle(response).map((m) => m.placeId),
        unorderedEquals(['ChIJ-far', 'ChIJ-near', 'ChIJ-noname']),
      );
    });

    test('an empty answer is an empty list', () {
      expect(mosquesFromGoogle(const {}), isEmpty);
    });
  });

  group('Google Places request', () {
    late http.Request sent;
    late GooglePlacesProvider provider;

    setUp(() {
      provider = GooglePlacesProvider(
        apiKey: 'test-key',
        identity: identity,
        client: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'places': [
                {
                  'id': 'ChIJ-far',
                  'displayName': {'text': 'Far'},
                  'location': {'latitude': 30.0600, 'longitude': 31.2400},
                },
                {
                  'id': 'ChIJ-near',
                  'displayName': {'text': 'Near'},
                  'location': {'latitude': 30.0450, 'longitude': 31.2360},
                },
              ],
            }),
            200,
          );
        }),
      );
    });

    test('asks for exactly the rendered fields and nothing pricier', () async {
      await provider.nearby(here);

      expect(
        sent.headers['X-Goog-FieldMask'],
        'places.id,places.displayName,places.formattedAddress,places.location',
        reason:
            'billing follows the highest-priced field requested (AGENTS.md); '
            'ratings, photos or hours are a cost decision, not a detail',
      );
      expect(sent.method, 'POST');
      expect(sent.url, GooglePlacesProvider.endpoint);
      expect(sent.headers['X-Goog-Api-Key'], 'test-key');
    });

    test('names the Android app so a restricted key matches', () async {
      await provider.nearby(here);

      expect(sent.headers['X-Android-Package'], 'dev.jamaah.app');
      expect(
        sent.headers['X-Android-Cert'],
        '886CC7E84199B530F77CF407FEEC0A3E125E02A1',
      );
    });

    test('searches mosques only, nearest first, within the radius', () async {
      await provider.nearby(here);
      final body = jsonDecode(sent.body) as Map<String, Object?>;

      expect(body['includedTypes'], ['mosque']);
      expect(body['rankPreference'], 'DISTANCE');
      expect(body['maxResultCount'], 20);
      expect(body['locationRestriction'], {
        'circle': {
          'center': {'latitude': 30.0444, 'longitude': 31.2357},
          'radius': 5000.0,
        },
      });
      expect(
        body.keys,
        isNot(contains('fieldMask')),
        reason: 'the field mask travels as a header',
      );
    });

    test('results come back nearest first, labelled Google', () async {
      final result = await provider.nearby(here) as DiscoveryFound;
      expect(result.source, MosqueSource.google);
      expect(result.mosques.map((m) => m.placeId), ['ChIJ-near', 'ChIJ-far']);
    });

    test('with no key, nothing is sent and the answer says so', () async {
      var calls = 0;
      final noKey = GooglePlacesProvider(
        apiKey: '',
        identity: identity,
        client: MockClient((_) async {
          calls++;
          return http.Response('{}', 200);
        }),
      );

      expect(await noKey.nearby(here), isA<DiscoveryNoKey>());
      expect(calls, 0);
    });

    test('without a certificate the package is still named', () async {
      final unsigned = GooglePlacesProvider(
        apiKey: 'test-key',
        identity: const FixedAppIdentitySource(
          AppIdentity(packageName: 'dev.jamaah.app'),
        ),
        client: MockClient((request) async {
          sent = request;
          return http.Response('{}', 200);
        }),
      );
      await unsigned.nearby(here);
      expect(sent.headers['X-Android-Package'], 'dev.jamaah.app');
      expect(sent.headers.containsKey('X-Android-Cert'), isFalse);
    });
  });

  group('failures become named answers', () {
    Future<DiscoveryResult> googleAnswering(
      Future<http.Response> Function() respond,
    ) => GooglePlacesProvider(
      apiKey: 'test-key',
      identity: identity,
      client: MockClient((_) => respond()),
    ).nearby(here);

    for (final (status, reason) in [
      (403, DiscoveryFailure.keyRejected),
      (400, DiscoveryFailure.keyRejected),
      (429, DiscoveryFailure.rateLimited),
      (500, DiscoveryFailure.server),
    ]) {
      test('Google $status is ${reason.name}', () async {
        final result = await googleAnswering(
          () async => http.Response('{"error":{}}', status),
        );
        expect((result as DiscoveryFailed).reason, reason);
      });
    }

    test('no connection is a network failure', () async {
      final result = await googleAnswering(
        () => Future.error(const SocketException('offline')),
      );
      expect((result as DiscoveryFailed).reason, DiscoveryFailure.network);
    });

    test('a garbled body is a server failure, not a crash', () async {
      final result = await googleAnswering(
        () async => http.Response('<html>', 200),
      );
      expect((result as DiscoveryFailed).reason, DiscoveryFailure.server);
    });

    test('OpenStreetMap 429 is rate limited, offline is network', () async {
      final busy = await OpenStreetMapProvider(
        client: MockClient((_) async => http.Response('busy', 429)),
      ).nearby(here);
      expect((busy as DiscoveryFailed).reason, DiscoveryFailure.rateLimited);

      final offline = await OpenStreetMapProvider(
        client: MockClient((_) => Future.error(const SocketException('x'))),
      ).nearby(here);
      expect((offline as DiscoveryFailed).reason, DiscoveryFailure.network);
    });
  });

  group('OpenStreetMap mapping', () {
    final response = {
      'elements': [
        {
          'type': 'node',
          'id': 101,
          'lat': 30.0450,
          'lon': 31.2360,
          'tags': {
            'amenity': 'place_of_worship',
            'religion': 'muslim',
            'name': 'Node Mosque',
            'addr:housenumber': '12',
            'addr:street': 'Garden Road',
            'addr:city': 'Cairo',
          },
        },
        {
          'type': 'way',
          'id': 202,
          'center': {'lat': 30.0500, 'lon': 31.2400},
          'tags': {'name:en': 'Way Mosque', 'addr:city': 'Cairo'},
        },
        {
          'type': 'node',
          'id': 303,
          'lat': 30.0460,
          'lon': 31.2370,
          'tags': {'amenity': 'place_of_worship', 'religion': 'muslim'},
        },
        // Dropped: a relation with no centre has no point to list.
        {
          'type': 'relation',
          'id': 404,
          'tags': {'name': 'Nowhere'},
        },
      ],
    };

    test('nodes use their own point, buildings their centre', () {
      final mosques = mosquesFromOverpass(response);
      final node = mosques.singleWhere((m) => m.placeId == 'osm:node/101');
      final way = mosques.singleWhere((m) => m.placeId == 'osm:way/202');
      expect(node.latitude, 30.0450);
      expect(way.latitude, 30.0500);
      expect(way.longitude, 31.2400);
      expect(node.source, MosqueSource.osm);
    });

    test('the address is built from the addr tags that exist', () {
      final mosques = mosquesFromOverpass(response);
      expect(
        mosques.singleWhere((m) => m.placeId == 'osm:node/101').address,
        '12 Garden Road, Cairo',
      );
      expect(
        mosques.singleWhere((m) => m.placeId == 'osm:way/202').address,
        'Cairo',
      );
    });

    test(
      'the name falls back to name:en, and an unnamed mosque stays listed',
      () {
        final mosques = mosquesFromOverpass(response);
        expect(
          mosques.singleWhere((m) => m.placeId == 'osm:way/202').name,
          'Way Mosque',
        );
        final unnamed = mosques.singleWhere((m) => m.placeId == 'osm:node/303');
        expect(unnamed.name, isNull, reason: 'never invent a name');
        expect(unnamed.address, '');
      },
    );

    test('elements without a position are dropped', () {
      expect(
        mosquesFromOverpass(response).map((m) => m.placeId),
        isNot(contains('osm:relation/404')),
      );
    });

    test('the query asks for Muslim places of worship around the point', () {
      final query = OpenStreetMapProvider.overpassQuery(here);
      expect(query, contains('["amenity"="place_of_worship"]'));
      expect(query, contains('["religion"="muslim"]'));
      expect(query, contains('(around:5000,30.0444,31.2357)'));
      expect(query, contains('out center tags 50'));
    });

    test(
      'the request identifies the app and sends the query as a form',
      () async {
        late http.Request sent;
        await OpenStreetMapProvider(
          client: MockClient((request) async {
            sent = request;
            return http.Response(jsonEncode(response), 200);
          }),
        ).nearby(here);
        expect(sent.headers['User-Agent'], OpenStreetMapProvider.userAgent);
        expect(
          Uri.splitQueryString(sent.body)['data'],
          OpenStreetMapProvider.overpassQuery(here),
        );
      },
    );
  });

  group('both providers land on one model', () {
    test('the same mosque from each source differs only by id and source', () {
      final google = mosquesFromGoogle({
        'places': [
          {
            'id': 'ChIJ-x',
            'displayName': {'text': 'Masjid X'},
            'formattedAddress': '12 Garden Road, Cairo',
            'location': {'latitude': 30.0450, 'longitude': 31.2360},
          },
        ],
      }).single;
      final osm = mosquesFromOverpass({
        'elements': [
          {
            'type': 'node',
            'id': 7,
            'lat': 30.0450,
            'lon': 31.2360,
            'tags': {
              'name': 'Masjid X',
              'addr:housenumber': '12',
              'addr:street': 'Garden Road',
              'addr:city': 'Cairo',
            },
          },
        ],
      }).single;

      expect(google.name, osm.name);
      expect(google.address, osm.address);
      expect(google.latitude, osm.latitude);
      expect(google.longitude, osm.longitude);
      expect(
        {google.source, osm.source},
        {MosqueSource.google, MosqueSource.osm},
      );
    });
  });

  group('session guards', () {
    late int calls;
    late List<String> logs;

    DiscoverySession session({
      int maxRequests = 3,
      DiscoveryResult? answer,
      Completer<DiscoveryResult>? gate,
    }) {
      calls = 0;
      logs = [];
      return DiscoverySession(
        _FakeProvider((query) {
          calls++;
          if (gate != null) return gate.future;
          return Future.value(
            answer ??
                const DiscoveryFound(source: MosqueSource.osm, mosques: []),
          );
        }),
        maxRequests: maxRequests,
        log: logs.add,
      );
    }

    test('a search 1 km away is a new search', () async {
      final s = session();
      await s.nearby(here);
      await s.nearby(
        const DiscoveryQuery(latitude: 30.0534, longitude: 31.2357),
      );
      expect(calls, 2);
    });

    test('the same area is answered from the cache', () async {
      final s = session();
      await s.nearby(here);
      // About 30 m away: the same search.
      await s.nearby(
        const DiscoveryQuery(latitude: 30.0446, longitude: 31.2359),
      );
      expect(calls, 1);
      expect(s.requestsMade, 1);
    });

    test('a search already in flight is shared, not sent twice', () async {
      final gate = Completer<DiscoveryResult>();
      final s = session(gate: gate);
      final first = s.nearby(here);
      final second = s.nearby(here);
      gate.complete(
        const DiscoveryFound(source: MosqueSource.osm, mosques: []),
      );
      await Future.wait([first, second]);
      expect(calls, 1);
    });

    test('the session stops sending at its limit', () async {
      final s = session(maxRequests: 2);
      await s.nearby(const DiscoveryQuery(latitude: 1, longitude: 1));
      await s.nearby(const DiscoveryQuery(latitude: 2, longitude: 2));
      final third = await s.nearby(
        const DiscoveryQuery(latitude: 3, longitude: 3),
      );
      expect(third, isA<DiscoveryLimitReached>());
      expect(calls, 2);
    });

    test('failures are not cached but do count', () async {
      final s = session(
        maxRequests: 2,
        answer: const DiscoveryFailed(DiscoveryFailure.network),
      );
      await s.nearby(here);
      await s.nearby(here);
      expect(calls, 2, reason: 'try again really tries again');
      expect(await s.nearby(here), isA<DiscoveryLimitReached>());
    });

    test('a missing key costs nothing against the limit', () async {
      final s = session(maxRequests: 1, answer: const DiscoveryNoKey());
      await s.nearby(here);
      expect(s.requestsMade, 0);
    });

    test('every answer is logged with the provider that served it', () async {
      final s = session();
      await s.nearby(here);
      expect(logs.single, startsWith('Discovery [osm] served 0'));
    });
  });

  group('distance and order', () {
    test('a degree of latitude is about 111 km', () {
      final metres = distanceMeters(
        fromLatitude: 0,
        fromLongitude: 0,
        toLatitude: 1,
        toLongitude: 0,
      );
      expect(metres, closeTo(111195, 50));
    });

    test('duplicates by place id are listed once', () {
      const m = DiscoveredMosque(
        placeId: 'a',
        source: MosqueSource.osm,
        name: 'A',
        address: '',
        latitude: 30.045,
        longitude: 31.236,
      );
      expect(nearestFirst([m, m], here), hasLength(1));
    });
  });

  group('configuration', () {
    test('Google is the default, OSM when configured', () {
      expect(
        const AppConfig(
          discoveryProvider: 'google',
          googlePlacesApiKey: '',
        ).discoveryBlocked,
        isTrue,
      );
      expect(
        const AppConfig(
          discoveryProvider: 'osm',
          googlePlacesApiKey: '',
        ).discoveryBlocked,
        isFalse,
      );
    });

    test('the config never prints the key', () {
      const config = AppConfig(
        discoveryProvider: 'google',
        googlePlacesApiKey: 'secret-value',
      );
      expect(config.toString(), isNot(contains('secret-value')));
      expect(config.toString(), contains('set'));
    });
  });
}

class _FakeProvider implements MosqueDiscoveryProvider {
  _FakeProvider(this._answer);

  final Future<DiscoveryResult> Function(DiscoveryQuery) _answer;

  @override
  MosqueSource get source => MosqueSource.osm;

  @override
  Future<DiscoveryResult> nearby(DiscoveryQuery query) => _answer(query);
}
