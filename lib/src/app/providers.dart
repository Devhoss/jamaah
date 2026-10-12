import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/device_place_source.dart';
import '../data/settings_repository.dart';
import '../domain/place.dart';

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
