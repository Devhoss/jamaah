/// A place the app calculates prayer times for, whatever its source.
///
/// Carries the IANA zone with it because prayer times are local wall-clock times:
/// coordinates without a zone are not enough (AGENTS.md).
class Place {
  const Place({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    required this.ianaZone,
    required this.fromDevice,
    this.userName,
  });

  /// What the UI shows, e.g. "Cairo, Egypt" or the label for the device itself.
  final String displayName;

  /// The name the user chose for this place, if they chose one. It replaces
  /// [displayName] everywhere, because "Home" is what they called it.
  final String? userName;

  final double latitude;
  final double longitude;

  /// IANA zone name, e.g. `Africa/Cairo`.
  final String ianaZone;

  /// True when the device supplied it, false for a city from the bundled list, so
  /// the UI can name the kind of place in use instead of pretending precision.
  final bool fromDevice;

  @override
  bool operator ==(Object other) =>
      other is Place &&
      other.displayName == displayName &&
      other.userName == userName &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.ianaZone == ianaZone &&
      other.fromDevice == fromDevice;

  @override
  int get hashCode =>
      Object.hash(
        displayName,
        userName,
        latitude,
        longitude,
        ianaZone,
        fromDevice,
      );

  @override
  String toString() =>
      'Place($displayName, $ianaZone, ${latitude.toStringAsFixed(3)}, '
      '${longitude.toStringAsFixed(3)}, ${fromDevice ? "device" : "list"})';
}

/// Why the device could not give us a place.
///
/// Every case has a message and a route to the manual list (AGENTS.md: never a
/// silent failure). [unavailable] covers anything the platform reports that is not
/// one of the specific cases — a positioning error, a missing permission channel,
/// a plugin exception.
enum PlaceFailure {
  denied,
  permanentlyDenied,
  serviceDisabled,
  timeout,
  unavailable,
}

/// The outcome of asking the device for its location.
///
/// Returned as a value, never thrown: the caller must handle every case, and a
/// widget test can assert each one without a plugin underneath.
sealed class PlaceReading {
  const PlaceReading();
}

final class PlaceFound extends PlaceReading {
  const PlaceFound(this.place);

  final Place place;
}

final class PlaceRejected extends PlaceReading {
  const PlaceRejected(this.failure);

  final PlaceFailure failure;
}

/// Where a [Place] can come from.
///
/// The app has two: the device itself (coarse, only after the user taps) and the
/// bundled placeholder list. Mosque discovery is a third source later and does not
/// change this interface — it produces a place the user saves, not the one prayer
/// times are calculated from.
abstract interface class PlaceSource {
  /// Ask for the device's coarse location and its time zone.
  ///
  /// Implementations must return a [PlaceRejected] for every failure rather than
  /// throwing, and must not call the platform until this is invoked — the
  /// explanation sheet has to be on screen first.
  Future<PlaceReading> requestPlace();

  /// Open this app's page in the system settings, for the permanently-denied case.
  ///
  /// Best effort: if the platform cannot, it returns normally and the UI has
  /// already offered the manual list as the way through.
  Future<void> openSystemSettings();
}
