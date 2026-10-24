import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/device_place_source.dart';
import '../data/discovery/app_identity.dart';
import '../data/flight_gps.dart';
import '../data/discovery/discovery_session.dart';
import '../data/discovery/google_places_provider.dart';
import '../data/discovery/osm_provider.dart';
import '../data/mosque_repository.dart';
import '../data/settings_repository.dart';
import '../domain/extra_times.dart';
import '../domain/discovery.dart';
import '../domain/mosque.dart';
import '../domain/place.dart';
import '../domain/time_model.dart';
import '../domain/prayer_times_calculator.dart';
import '../domain/today.dart';
import '../domain/zone_offsets.dart';
import 'clock.dart';
import 'config.dart';

/// App-level wiring.
///
/// Everything here is overridable, which is how the widget tests run the real
/// settings flow against an in-memory database and a fake [PlaceSource] without a
/// device or a plugin call.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(appDatabaseProvider)),
);

/// The settings the UI renders from, re-emitted on every change.
final appSettingsProvider = StreamProvider<AppSettingsSnapshot>(
  (ref) => ref.watch(settingsRepositoryProvider).watch(),
);

/// The device itself, when the user asks for it.
///
/// A [PlaceSource] rather than the geolocator types, so nothing above this line
/// touches a plugin and every failure path stays testable.
/// GPS aboard, for in-flight mode; overridden with a fake in tests.
final flightGpsProvider = Provider<FlightGps>((ref) => const DeviceFlightGps());

final placeSourceProvider = Provider<PlaceSource>(
  (ref) => const DevicePlaceSource(),
);

/// The device's precise position, for "Find nearby mosques" only.
final nearbyLocationSourceProvider = Provider<NearbyLocationSource>(
  (ref) => const DeviceNearbyLocationSource(),
);

/// The place prayer times are calculated from, or null until the user sets one.
final currentPlaceProvider = Provider<Place?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  // While the first read is still landing this is null, which is the same state as
  // "no place yet" — the location prompt is the right thing to show either way.
  return settings.value?.location?.toPlace();
});

final mosqueRepositoryProvider = Provider<MosqueRepository>(
  (ref) => MosqueRepository(
    ref.watch(appDatabaseProvider),
    // The same clock the screen reads, so the schedule a write lands on and the
    // schedule the card reads are resolved from one time.
    clock: ref.watch(appClockProvider),
  ),
);

/// Every mosque the user saved, with its Iqama schedules.
final savedMosquesProvider = StreamProvider<List<Mosque>>(
  (ref) => ref.watch(mosqueRepositoryProvider).watchSaved(),
);

/// The zone the saved place lives in. Times are wall-clock, so the zone is part of
/// the place rather than a detail of the device.
final placeZoneProvider = Provider<ZoneOffsets?>((ref) {
  final place = ref.watch(currentPlaceProvider);
  return place == null ? null : zoneOffsetsFor(place.ianaZone);
});

final prayerTimesCalculatorProvider = Provider<PrayerTimesCalculator?>((ref) {
  final place = ref.watch(currentPlaceProvider);
  final zone = ref.watch(placeZoneProvider);
  if (place == null || zone == null) return null;
  // Until the stored settings arrive, the documented defaults are the honest
  // answer: they are what a fresh install uses anyway.
  final settings =
      ref.watch(appSettingsProvider).value ?? SettingsRepository.defaults;
  return PrayerTimesCalculator(
    latitude: place.latitude,
    longitude: place.longitude,
    zone: zone,
    // "Auto detect" uses the reverse-geocoded country, then the time zone.
    method: settings.calculationMethod.resolvedForPlace(
      place.ianaZone,
      place.countryCode,
    ),
    madhab: settings.madhab,
    highLatitudeRule: settings.highLatitudeRule,
    minuteOffsets: settings.minuteOffsets,
    customAngles: settings.customAngles,
    hijriAdjustDays: settings.hijriAdjustDays,
  );
});

/// Today at the saved place, and the prayer in front of it.
///
/// Rebuilt every minute by [minuteClockProvider], so the day rolls over at the
/// place's midnight while the screen is on.
final todayProvider = Provider<TodayReading?>((ref) {
  final calculator = ref.watch(prayerTimesCalculatorProvider);
  final zone = ref.watch(placeZoneProvider);
  if (calculator == null || zone == null) return null;
  return readToday(
    calculator: calculator,
    moment: LocalMoment.inZone(
      zone: zone,
      utcInstant: ref.watch(minuteClockProvider),
    ),
  );
});

/// The mosque whose Iqama times the app shows. Null when none is active.
/// The extra times Today lists (2026-10-14), from the place's reading.
final todayExtraTimesProvider = Provider<List<ExtraTimeAt>>((ref) {
  final calculator = ref.watch(prayerTimesCalculatorProvider);
  final today = ref.watch(todayProvider);
  if (calculator == null || today == null) return const [];
  final settings =
      ref.watch(appSettingsProvider.select((s) => s.value?.extraTimes)) ??
      const ExtraTimesSettings();
  return extraTimesForToday(
    calculator: calculator,
    moment: today.moment,
    settings: settings,
  );
});

final activeMosqueProvider = Provider<Mosque?>((ref) {
  final id = ref.watch(appSettingsProvider).value?.activeMosqueId;
  if (id == null) return null;
  for (final mosque
      in ref.watch(savedMosquesProvider).value ?? const <Mosque>[]) {
    if (mosque.id == id) return mosque;
  }
  return null;
});

/// One saved mosque, followed live: an Iqama edit or a rename re-emits it, and a
/// removed mosque reads as null.
final mosqueByIdProvider = Provider.family<Mosque?, String>((ref, id) {
  for (final mosque
      in ref.watch(savedMosquesProvider).value ?? const <Mosque>[]) {
    if (mosque.id == id) return mosque;
  }
  return null;
});

/// The calendar day a mosque's schedule is read for: the saved place's day when
/// there is one, otherwise the device's own.
final scheduleDayProvider = Provider<LocalDay>((ref) {
  final placeDay = ref.watch(todayProvider)?.day.day;
  if (placeDay != null) return placeDay;
  return LocalDay.fromDateTime(ref.watch(minuteClockProvider).toLocal());
});

/// The Iqama schedule in force on the day the rows show, belonging to the active
/// mosque — never a global one (AGENTS.md).
final activeMosqueScheduleProvider = Provider<Schedule?>((ref) {
  final mosque = ref.watch(activeMosqueProvider);
  final day = ref.watch(todayProvider)?.day.day;
  if (mosque == null || day == null) return null;
  return mosque.scheduleFor(day);
});

/// What the card can say about the active mosque's Iqama times, or null until the
/// app has a place to read a day from.
final nextIqamaProvider = Provider<NextIqama?>((ref) {
  final today = ref.watch(todayProvider);
  if (today == null) return null;
  final calculator = ref.watch(prayerTimesCalculatorProvider);
  return readNextIqama(
    mosque: ref.watch(activeMosqueProvider),
    today: today,
    adhanTimesOn: (day) => calculator?.forDay(day).times ?? const {},
  );
});

/// `--dart-define-from-file=.env` values: which discovery provider, and the key.
final appConfigProvider = Provider<AppConfig>((ref) {
  final config = AppConfig.fromEnvironment();
  config.logProvider();
  return config;
});

/// The installed app's package and signing certificate, for the Places key's
/// Android-app restriction.
final appIdentityProvider = Provider<AppIdentitySource>(
  (ref) => PlatformAppIdentitySource(),
);

/// OpenStreetMap, always available: it is the fallback when the Google key is
/// missing or refused, and the provider itself when DISCOVERY_PROVIDER=osm.
final osmDiscoveryProvider = Provider<MosqueDiscoveryProvider>(
  (ref) => DiscoverySession(OpenStreetMapProvider()),
);

/// The configured provider (AGENTS.md: DISCOVERY_PROVIDER=google|osm, Google by
/// default), wrapped in a session that caches, de-duplicates and caps requests.
final mosqueDiscoveryProvider = Provider<MosqueDiscoveryProvider>((ref) {
  final config = ref.watch(appConfigProvider);
  if (config.discoveryProvider == 'osm') return ref.watch(osmDiscoveryProvider);
  return DiscoverySession(
    GooglePlacesProvider(
      apiKey: config.googlePlacesApiKey,
      identity: ref.watch(appIdentityProvider),
    ),
  );
});
