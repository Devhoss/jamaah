import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../domain/place.dart';

/// Reads the device's **coarse** position and its IANA time zone.
///
/// Requests `LocationAccuracy.low`: the manifest asks only for
/// `ACCESS_COARSE_LOCATION`, so a fine fix is not even available to the app
/// (AGENTS.md — fine location belongs to nearby-mosque search, not Today).
///
/// Every platform failure becomes a [PlaceRejected] value instead of an
/// exception, because the caller has to show a message and route to the manual
/// list for each one. Nothing here is unit-tested against the real plugins: the
/// UI is tested against a fake [PlaceSource], and this class only maps plugin
/// results onto the domain outcomes.
class DevicePlaceSource implements PlaceSource {
  const DevicePlaceSource({this.timeout = const Duration(seconds: 12)});

  /// How long to wait for a fix before giving up and offering the city list.
  final Duration timeout;

  @override
  Future<PlaceReading> requestPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const PlaceRejected(PlaceFailure.serviceDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Only now does the system dialog appear — which is why the explanation
      // sheet has to be on screen before this is ever called.
      permission = await Geolocator.requestPermission();
    }

    final failure = switch (permission) {
      LocationPermission.denied => PlaceFailure.denied,
      LocationPermission.deniedForever => PlaceFailure.permanentlyDenied,
      LocationPermission.unableToDetermine => PlaceFailure.unavailable,
      LocationPermission.whileInUse || LocationPermission.always => null,
    };
    if (failure case final why?) return PlaceRejected(why);

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      ).timeout(timeout);
      final ianaZone = await _ianaZoneName();

      // A device place has no human-readable name we are allowed to invent:
      // reverse geocoding needs the network. The zone is stored as the label and
      // the UI shows its own "this device" wording for it.
      return PlaceFound(
        Place(
          displayName: ianaZone,
          latitude: position.latitude,
          longitude: position.longitude,
          ianaZone: ianaZone,
          fromDevice: true,
        ),
      );
    } on LocationServiceDisabledException {
      return const PlaceRejected(PlaceFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const PlaceRejected(PlaceFailure.denied);
    } on TimeoutException {
      return const PlaceRejected(PlaceFailure.timeout);
    } on Object {
      return const PlaceRejected(PlaceFailure.unavailable);
    }
  }

  @override
  Future<void> openSystemSettings() async {
    // Best effort: the sheet already offers the city list as the way through.
    try {
      await Geolocator.openAppSettings();
    } on Object {
      return;
    }
  }

  /// The device's IANA zone name.
  ///
  /// Falls back to the device clock's own offset when the plugin cannot answer,
  /// so a missing zone never blocks the user: `zoneOffsetsFor` then resolves it to
  /// a device-clock zone and Today's times stay right for the device.
  Future<String> _ianaZoneName() async {
    try {
      final info = await FlutterTimezone.getLocalTimezone();
      if (info.identifier.isNotEmpty) return info.identifier;
    } on Object {
      // handled by the fallback below
    }
    final now = DateTime.now();
    return 'device/${now.timeZoneName}';
  }
}
