import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/device_place_source.dart';
import '../data/mosque_repository.dart';
import '../data/settings_repository.dart';
import '../domain/mosque.dart';
import '../domain/place.dart';
import '../domain/prayer_times_calculator.dart';
import '../domain/today.dart';
import '../domain/zone_offsets.dart';
import 'clock.dart';

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
final placeSourceProvider = Provider<PlaceSource>(
  (ref) => const DevicePlaceSource(),
);

/// The place prayer times are calculated from, or null until the user sets one.
final currentPlaceProvider = Provider<Place?>((ref) {
  final settings = ref.watch(appSettingsProvider);
  // While the first read is still landing this is null, which is the same state as
  // "no place yet" — the location prompt is the right thing to show either way.
  return settings.value?.location?.toPlace();
});

final mosqueRepositoryProvider = Provider<MosqueRepository>(
  (ref) => MosqueRepository(ref.watch(appDatabaseProvider)),
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
    method: settings.calculationMethod,
    madhab: settings.madhab,
    highLatitudeRule: settings.highLatitudeRule,
    minuteOffsets: settings.minuteOffsets,
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
final activeMosqueProvider = Provider<Mosque?>((ref) {
  final id = ref.watch(appSettingsProvider).value?.activeMosqueId;
  if (id == null) return null;
  for (final mosque in ref.watch(savedMosquesProvider).value ??
      const <Mosque>[]) {
    if (mosque.id == id) return mosque;
  }
  return null;
});

/// The Iqama schedule in force on the day the rows show, belonging to the active
/// mosque — never a global one (AGENTS.md).
final activeMosqueScheduleProvider = Provider<Schedule?>((ref) {
  final mosque = ref.watch(activeMosqueProvider);
  final day = ref.watch(todayProvider)?.day.day;
  if (mosque == null || day == null) return null;
  return mosque.scheduleFor(day);
});

/// The active mosque's Iqama for the prayer being counted down to, or null when the
/// user has not entered one — the card then shows the Adhan alone.
final nextIqamaProvider = Provider<NextIqama?>((ref) {
  final today = ref.watch(todayProvider);
  if (today == null) return null;
  return readNextIqama(mosque: ref.watch(activeMosqueProvider), today: today);
});
