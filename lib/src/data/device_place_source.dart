import 'dart:async';

import 'package:geolocator/geolocator.dart';
import 'package:flutter_timezone/flutter_timezone.dart';

import '../domain/place.dart';
import 'location_permission.dart';

/// Reads the device's **coarse** position and its IANA time zone.
///
/// Asks for approximate location only — the system dialog offers nothing more —
/// and reads `LocationAccuracy.low`. Precise location belongs to the mosque
/// search alone (decided 2026-10-13), see [DeviceNearbyLocationSource].
///
/// Every platform failure becomes a [PlaceRejected] value instead of an
/// exception, because the caller has to show a message and route to the manual
/// list for each one. Nothing here is unit-tested against the real plugins: the
/// UI is tested against a fake [PlaceSource], and this class only maps plugin
/// results onto the domain outcomes.
class DevicePlaceSource implements PlaceSource {
  const DevicePlaceSource({
    this.timeout = const Duration(seconds: 12),
    this.permissions = const LocationPermissions(),
  });

  /// How long to wait for a fix before giving up and offering the city list.
  final Duration timeout;
  final LocationPermissions permissions;

  @override
  Future<PlaceReading> requestPlace() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const PlaceRejected(PlaceFailure.serviceDisabled);
    }

    // Only now does the system dialog appear — which is why the explanation
    // sheet has to be on screen before this is ever called.
    final grant = await _grant(permissions, precise: false);
    if (!grant.any) {
      return PlaceRejected(
        grant.canAsk ? PlaceFailure.denied : PlaceFailure.permanentlyDenied,
      );
    }

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
  Future<void> openSystemSettings() => _openAppSettings();

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

/// The current grant, asking first when the system still lets the app ask.
Future<LocationGrant> _grant(
  LocationPermissions permissions, {
  required bool precise,
}) async {
  final now = await permissions.status();
  final enough = precise ? now.fine : now.any;
  if (enough || !now.canAsk && !now.any) return now;
  return permissions.request(precise: precise);
}

/// Best effort: every screen that offers this also offers another way through.
Future<void> _openAppSettings() async {
  try {
    await Geolocator.openAppSettings();
  } on Object {
    return;
  }
}

/// The device's precise position, for "Find nearby mosques" only.
///
/// Asks for precise location with the system dialog, which lets the user keep
/// it approximate; that is reported, not treated as a failure, because a search
/// around an approximate point still finds mosques — just less exactly.
class DeviceNearbyLocationSource implements NearbyLocationSource {
  const DeviceNearbyLocationSource({
    this.timeout = const Duration(seconds: 15),
    this.permissions = const LocationPermissions(),
  });

  final Duration timeout;
  final LocationPermissions permissions;

  @override
  Future<NearbyReading> requestPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const NearbyRejected(PlaceFailure.serviceDisabled);
    }

    final grant = await _grant(permissions, precise: true);
    if (!grant.any) {
      return NearbyRejected(
        grant.canAsk ? PlaceFailure.denied : PlaceFailure.permanentlyDenied,
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: grant.fine ? LocationAccuracy.high : LocationAccuracy.low,
        ),
      ).timeout(timeout);
      return NearbyFound(
        latitude: position.latitude,
        longitude: position.longitude,
        precise: grant.fine,
      );
    } on LocationServiceDisabledException {
      return const NearbyRejected(PlaceFailure.serviceDisabled);
    } on PermissionDeniedException {
      return const NearbyRejected(PlaceFailure.denied);
    } on TimeoutException {
      return const NearbyRejected(PlaceFailure.timeout);
    } on Object {
      return const NearbyRejected(PlaceFailure.unavailable);
    }
  }

  @override
  Future<void> openSystemSettings() => _openAppSettings();
}
