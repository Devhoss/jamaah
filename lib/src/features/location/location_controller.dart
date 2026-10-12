import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/settings_repository.dart' show PlaceStorage;
import '../../domain/place.dart';

/// Where the location flow stands.
class LocationRequestState {
  const LocationRequestState({this.isRequesting = false, this.failure});

  const LocationRequestState.requesting() : isRequesting = true, failure = null;

  /// Set when the device said no; decides which calm message the sheet shows and
  /// whether it offers the system-settings shortcut. It stays until the next try,
  /// because a failure the user cannot see is a silent failure.
  final PlaceFailure? failure;

  final bool isRequesting;
}

/// Runs the "where are you?" flow and persists the answer.
///
/// The device is only ever asked from [useDeviceLocation], which the sheet calls
/// after the user taps — AGENTS.md requires the explanation to be on screen before
/// any permission dialog.
class LocationRequestController extends Notifier<LocationRequestState> {
  @override
  LocationRequestState build() => const LocationRequestState();

  /// Ask the device. Returns the place when it worked, null when it did not.
  ///
  /// A null result is not a dead end: the state carries which failure it was, and
  /// the sheet keeps the manual list in view.
  Future<Place?> useDeviceLocation() async {
    if (state.isRequesting) return null;
    state = const LocationRequestState.requesting();

    final reading = await ref.read(placeSourceProvider).requestPlace();

    switch (reading) {
      case PlaceFound(:final place):
        await _store(place);
        return place;
      case PlaceRejected(:final failure):
        state = LocationRequestState(failure: failure);
        return null;
    }
  }

  /// A city from the bundled list. Always available, works with no network and no
  /// permission, and is where every failure routes to.
  Future<void> choose(Place place) => _store(place);

  /// The permanently-denied escape hatch.
  Future<void> openSystemSettings() =>
      ref.read(placeSourceProvider).openSystemSettings();

  Future<void> _store(Place place) async {
    await ref.read(settingsRepositoryProvider).setLocation(place.toStored());
    // The place itself reaches the UI through the settings stream, so a save
    // needs no state of its own beyond "not requesting, no failure to show".
    state = const LocationRequestState();
  }
}

final locationRequestProvider =
    NotifierProvider<LocationRequestController, LocationRequestState>(
      LocationRequestController.new,
    );
