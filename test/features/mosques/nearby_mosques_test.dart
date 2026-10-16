import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/app.dart';
import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/discovery.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/place.dart';
import 'package:jamaah/src/domain/placeholder_places.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';
import 'package:jamaah/src/features/mosques/mosque_detail_page.dart';
import 'package:jamaah/src/features/mosques/nearby_mosques_page.dart';

import '../../helpers/fake_clock.dart';
import '../../helpers/fake_place_source.dart';
import '../../helpers/test_app.dart';

/// "Find nearby mosques", driven through the real shell and database. The
/// position and both providers are fakes, so no test asks the platform for
/// location or reaches the network.
void main() {
  final t = AppLocalizationsEn();

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late FakeNearbySource position;
  late _FakeDiscovery google;
  late _FakeDiscovery osm;

  setUpAll(loadTimeZoneDatabase);

  // Central Cairo, and three results around it.
  const here = NearbyFound(
    latitude: 30.0444,
    longitude: 31.2357,
    precise: true,
  );
  const near = DiscoveredMosque(
    placeId: 'ChIJ-near',
    source: MosqueSource.google,
    name: 'Near Mosque',
    address: '1 Near Street, Cairo',
    latitude: 30.0450,
    longitude: 31.2360,
  );
  const far = DiscoveredMosque(
    placeId: 'ChIJ-far',
    source: MosqueSource.google,
    name: 'Far Mosque',
    address: '',
    latitude: 30.0600,
    longitude: 31.2400,
  );
  const unnamed = DiscoveredMosque(
    placeId: 'osm:node/303',
    source: MosqueSource.osm,
    name: null,
    address: '',
    latitude: 30.0460,
    longitude: 31.2370,
  );

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    mosques = MosqueRepository(db);
    position = FakeNearbySource(here);
    google = _FakeDiscovery(
      MosqueSource.google,
      const DiscoveryFound(source: MosqueSource.google, mosques: [near, far]),
    );
    osm = _FakeDiscovery(
      MosqueSource.osm,
      const DiscoveryFound(source: MosqueSource.osm, mosques: [unnamed]),
    );
    addTearDown(db.close);
  });

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await settings.setLocation(cairo.toStored());
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          appClockProvider.overrideWithValue(
            FixedClock(DateTime.utc(2026, 10, 12, 7, 0)),
          ),
          placeSourceProvider.overrideWithValue(
            FakePlaceSource(const PlaceRejected(PlaceFailure.unavailable)),
          ),
          nearbyLocationSourceProvider.overrideWithValue(position),
          mosqueDiscoveryProvider.overrideWithValue(google),
          osmDiscoveryProvider.overrideWithValue(osm),
        ],
        child: const JamaahApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await tester.pumpAndSettle();
  }

  Future<void> openNearby(WidgetTester tester) async {
    await tapText(tester, t.tabMosques);
    // "Find mosques nearby" while the list is empty, "Find nearby" after.
    await tapText(
      tester,
      find.text(t.mosquesEmptyFind).evaluate().isNotEmpty
          ? t.mosquesEmptyFind
          : t.mosquesFindNearby,
    );
  }

  Future<void> searchHere(WidgetTester tester) async {
    await openNearby(tester);
    await tapText(tester, t.nearbyUseLocation);
  }

  Finder buttonWith(String label) => find.ancestor(
    of: find.text(label),
    matching: find.bySubtype<ButtonStyleButton>(),
  );

  bool isEnabled(WidgetTester tester, String label) =>
      tester.widget<ButtonStyleButton>(buttonWith(label).last).onPressed !=
      null;

  group('asking first', () {
    testApp('the explanation comes before any location request', (
      tester,
    ) async {
      await open(tester);
      await openNearby(tester);

      expect(find.byType(NearbyMosquesPage), findsOneWidget);
      expect(find.text(t.nearbyExplainTitle), findsOneWidget);
      expect(
        find.text(t.nearbyExplainSent(t.providerGoogle)),
        findsOneWidget,
        reason: 'the one network call that carries the position is named',
      );
      expect(position.requestCount, 0);
      expect(google.queries, isEmpty);
    });
  });

  group('results', () {
    testApp('nearest first, with distances, labelled as not verified', (
      tester,
    ) async {
      await open(tester);
      await searchHere(tester);

      expect(position.requestCount, 1);
      expect(google.queries.single.latitude, here.latitude);
      expect(google.queries.single.radiusMeters, 5000);
      expect(find.text(t.nearbyHeaderHere(5)), findsOneWidget);

      final nearY = tester.getTopLeft(find.text('Near Mosque')).dy;
      final farY = tester.getTopLeft(find.text('Far Mosque')).dy;
      expect(nearY, lessThan(farY));
      expect(find.text(t.distanceMetres(70)), findsOneWidget);
      expect(find.text(t.distanceKilometres('1.8')), findsOneWidget);
      expect(find.text(t.nearbyNoAddress), findsOneWidget);
      expect(find.text(t.nearbyAttributionGoogle), findsOneWidget);
      expect(find.text(t.nearbyApproximateNote), findsNothing);
    });

    testApp('a result at the searched point is "Under 50 m", not "0 m"', (
      tester,
    ) async {
      google.answer = const DiscoveryFound(
        source: MosqueSource.google,
        mosques: [
          DiscoveredMosque(
            placeId: 'ChIJ-here',
            source: MosqueSource.google,
            name: 'Right Here Mosque',
            address: '',
            latitude: 30.0444,
            longitude: 31.2357,
          ),
        ],
      );
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.distanceUnder50), findsOneWidget);
      expect(find.text(t.distanceMetres(0)), findsNothing);
    });

    testApp('approximate location still searches, and says so', (tester) async {
      position.reading = const NearbyFound(
        latitude: 30.0444,
        longitude: 31.2357,
        precise: false,
      );
      await open(tester);
      await searchHere(tester);

      expect(find.text('Near Mosque'), findsOneWidget);
      expect(find.text(t.nearbyApproximateNote), findsOneWidget);
    });

    testApp('the list filters by name without another search', (tester) async {
      await open(tester);
      await searchHere(tester);
      await tester.enterText(
        find.widgetWithText(TextField, t.nearbyFilterHint),
        'far',
      );
      await tester.pump();

      expect(find.text('Far Mosque'), findsOneWidget);
      expect(find.text('Near Mosque'), findsNothing);
      expect(google.queries, hasLength(1));

      await tester.enterText(
        find.widgetWithText(TextField, t.nearbyFilterHint),
        'zzz',
      );
      await tester.pump();
      expect(find.text(t.nearbyNoMatches), findsOneWidget);
    });

    testApp('nothing nearby is an answer, with a way to add by hand', (
      tester,
    ) async {
      google.answer = const DiscoveryFound(
        source: MosqueSource.google,
        mosques: [],
      );
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyEmpty(5)), findsOneWidget);
      expect(find.text(t.nearbyAddManually), findsOneWidget);
    });

    testApp('a city search looks around that city, without asking location', (
      tester,
    ) async {
      await open(tester);
      await openNearby(tester);
      await tapText(tester, t.nearbySearchCity);
      final riyadh = placeholderPlaces.firstWhere(
        (p) =>
            p.ianaZone == 'Asia/Riyadh' && p.displayName.startsWith('Riyadh'),
      );
      await tapText(tester, riyadh.displayName);

      expect(position.requestCount, 0);
      expect(google.queries.single.latitude, riyadh.latitude);
      expect(google.queries.single.longitude, riyadh.longitude);
      expect(
        find.text(t.nearbyHeaderCity(5, riyadh.displayName)),
        findsOneWidget,
      );
    });
  });

  group('saving a result', () {
    testApp(
      'the user confirms the name, and a Google mosque keeps no position',
      (tester) async {
        await open(tester);
        await searchHere(tester);
        await tapText(tester, 'Near Mosque');

        expect(find.text(t.saveMosqueTitle), findsOneWidget);
        expect(find.text(t.saveMosqueBody(t.providerGoogle)), findsOneWidget);
        final name = tester.widget<TextField>(
          find.widgetWithText(TextField, t.mosqueNameLabel),
        );
        expect(name.controller!.text, 'Near Mosque');

        await tester.enterText(
          find.widgetWithText(TextField, t.mosqueNameLabel),
          'Our Mosque',
        );
        await tester.pump();
        await tester.tap(buttonWith(t.save));
        await tester.pumpAndSettle();

        final saved = (await mosques.saved()).single;
        expect(saved.name, 'Our Mosque', reason: 'what the user confirmed');
        expect(saved.address, '1 Near Street, Cairo');
        expect(saved.source, MosqueSource.google);
        expect(saved.placeId, 'ChIJ-near');
        expect(
          saved.latitude,
          isNull,
          reason: "Google's terms limit keeping coordinates to 30 days",
        );
        expect(saved.schedules.single.configuredCount, 0);

        expect(find.byType(MosqueDetailPage), findsOneWidget);
        expect(find.textContaining(t.mosqueSourceGoogle), findsOneWidget);
        // The five prayers and Jumu'ah.
        expect(find.text(t.notConfigured), findsNWidgets(6));
      },
    );

    testApp('a saved result is tagged, and opens the saved mosque', (
      tester,
    ) async {
      final existing = await mosques.add(
        name: 'Our Mosque',
        address: '',
        source: MosqueSource.google,
        placeId: 'ChIJ-near',
      );
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.tagSaved), findsOneWidget);
      await tapText(tester, 'Near Mosque');

      expect(find.text(t.saveMosqueTitle), findsNothing);
      final page = tester.widget<MosqueDetailPage>(
        find.byType(MosqueDetailPage),
      );
      expect(page.mosqueId, existing.id);
      expect(await mosques.saved(), hasLength(1));
    });

    testApp(
      'an unnamed OpenStreetMap mosque must be named, and keeps its position',
      (tester) async {
        await open(tester);
        google.answer = const DiscoveryNoKey();
        await searchHere(tester);
        await tapText(tester, t.nearbyTryOsm);

        expect(find.text(t.nearbyUnnamed), findsOneWidget);
        expect(find.text(t.nearbyAttributionOsm), findsOneWidget);
        await tapText(tester, t.nearbyUnnamed);

        expect(
          isEnabled(tester, t.save),
          isFalse,
          reason: 'no name is invented',
        );
        await tester.enterText(
          find.widgetWithText(TextField, t.mosqueNameLabel),
          'Corner Mosque',
        );
        await tester.pump();
        await tester.tap(buttonWith(t.save));
        await tester.pumpAndSettle();

        final saved = (await mosques.saved()).single;
        expect(saved.name, 'Corner Mosque');
        expect(saved.source, MosqueSource.osm);
        expect(saved.placeId, 'osm:node/303');
        expect(saved.latitude, 30.0460);
        expect(saved.longitude, 31.2370);
      },
    );
  });

  group('when the search cannot answer', () {
    testApp('no key: say so, and offer OpenStreetMap', (tester) async {
      google.answer = const DiscoveryNoKey();
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyFailNoKey), findsOneWidget);
      await tapText(tester, t.nearbyTryOsm);

      expect(osm.queries.single.latitude, here.latitude);
      expect(
        position.requestCount,
        1,
        reason: 'the position is not asked again',
      );
    });

    testApp('a refused key offers OpenStreetMap, not a pointless retry', (
      tester,
    ) async {
      google.answer = const DiscoveryFailed(DiscoveryFailure.keyRejected);
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyFailKeyRejected), findsOneWidget);
      expect(find.text(t.nearbyTryOsm), findsOneWidget);
      expect(find.text(t.locationTryAgain), findsNothing);
    });

    testApp('offline: say saved data still works, and allow a retry', (
      tester,
    ) async {
      google.answer = const DiscoveryFailed(DiscoveryFailure.network);
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyFailNetwork), findsOneWidget);
      expect(find.text(t.nearbyTryOsm), findsNothing);

      google.answer = const DiscoveryFound(
        source: MosqueSource.google,
        mosques: [near],
      );
      await tapText(tester, t.locationTryAgain);
      expect(find.text('Near Mosque'), findsOneWidget);
      expect(google.queries, hasLength(2));
    });

    testApp('the session limit is explained, with a way to add by hand', (
      tester,
    ) async {
      google.answer = const DiscoveryLimitReached();
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyFailLimit), findsOneWidget);
      expect(find.text(t.nearbyAddManually), findsOneWidget);
    });

    for (final (failure, message) in [
      (PlaceFailure.denied, 'nearbyLocDenied'),
      (PlaceFailure.serviceDisabled, 'nearbyLocService'),
      (PlaceFailure.timeout, 'nearbyLocTimeout'),
      (PlaceFailure.unavailable, 'nearbyLocUnavailable'),
    ]) {
      testApp(
        'location ${failure.name}: a message, and the city search stays',
        (tester) async {
          position.reading = NearbyRejected(failure);
          await open(tester);
          await searchHere(tester);

          final text = switch (message) {
            'nearbyLocDenied' => t.nearbyLocDenied,
            'nearbyLocService' => t.nearbyLocService,
            'nearbyLocTimeout' => t.nearbyLocTimeout,
            _ => t.nearbyLocUnavailable,
          };
          expect(find.text(text), findsOneWidget);
          expect(find.text(t.nearbySearchCity), findsOneWidget);
          expect(google.queries, isEmpty, reason: 'nothing to search around');
        },
      );
    }

    testApp('location blocked in settings offers the way there', (
      tester,
    ) async {
      position.reading = const NearbyRejected(PlaceFailure.permanentlyDenied);
      await open(tester);
      await searchHere(tester);

      expect(find.text(t.nearbyLocPermanent), findsOneWidget);
      await tapText(tester, t.locationOpenSettings);
      expect(position.settingsOpenCount, 1);
    });
  });
}

class _FakeDiscovery implements MosqueDiscoveryProvider {
  _FakeDiscovery(this.source, this.answer);

  @override
  final MosqueSource source;

  DiscoveryResult answer;
  final queries = <DiscoveryQuery>[];

  @override
  Future<DiscoveryResult> nearby(DiscoveryQuery query) async {
    queries.add(query);
    return answer;
  }
}
