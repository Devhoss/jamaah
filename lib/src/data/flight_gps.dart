import 'package:geolocator/geolocator.dart';

import '../domain/in_flight.dart';
import 'location_permission.dart';

/// Why in-flight mode cannot read GPS.
enum FlightGpsFailure {
  /// Location services are off on the phone.
  serviceDisabled,

  /// Precise location was refused, or only approximate allowed; the dialog
  /// can still be shown again.
  needsPrecise,

  /// Refused for good: only the app's page in Settings can change it.
  permanentlyDenied,
}

/// GPS aboard (in-flight mode, 2026-10-14).
///
/// Uses the platform's own location manager rather than the fused provider:
/// in airplane mode there is no network for the fused provider to lean on,
/// but the GPS receiver still works.
abstract interface class FlightGps {
  /// Makes sure precise location is allowed, showing the system dialog if it
  /// may. Null when GPS can start.
  Future<FlightGpsFailure?> prepare();

  /// Fixes while listened to; cancelling the subscription stops the GPS.
  Stream<InFlightFix> fixes();

  Future<void> openSettings();
}

class DeviceFlightGps implements FlightGps {
  const DeviceFlightGps({this.permissions = const LocationPermissions()});

  final LocationPermissions permissions;

  @override
  Future<FlightGpsFailure?> prepare() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return FlightGpsFailure.serviceDisabled;
    }
    var grant = await permissions.status();
    if (!grant.fine && grant.canAsk) {
      grant = await permissions.request(precise: true);
    }
    if (grant.fine) return null;
    return grant.canAsk
        ? FlightGpsFailure.needsPrecise
        : FlightGpsFailure.permanentlyDenied;
  }

  @override
  Stream<InFlightFix> fixes() =>
      Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          intervalDuration: const Duration(seconds: 20),
          forceLocationManager: true,
        ),
      ).map(
        (p) => InFlightFix(
          latitude: p.latitude,
          longitude: p.longitude,
          at: p.timestamp.toUtc(),
          altitudeMeters: p.altitude,
          speedMetersPerSecond: p.speed >= 0 ? p.speed : null,
          courseDegrees: p.heading >= 0 ? p.heading : null,
          accuracyMeters: p.accuracy,
        ),
      );

  @override
  Future<void> openSettings() async {
    try {
      await Geolocator.openAppSettings();
    } on Object {
      return;
    }
  }
}
