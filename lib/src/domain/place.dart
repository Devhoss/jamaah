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
    this.countryCode,
  });

  /// What the UI shows, e.g. "Cairo, Egypt" or the label for the device itself.
  final String displayName;

  /// The name the user chose for this place, if they chose one. It replaces
  /// [displayName] everywhere, because "Home" is what they called it.
  final String? userName;

  /// ISO 3166-1 alpha-2 country from reverse geocoding, when available.
  final String? countryCode;

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
      other.countryCode == countryCode &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.ianaZone == ianaZone &&
      other.fromDevice == fromDevice;

  @override
  int get hashCode => Object.hash(
    displayName,
    userName,
    countryCode,
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
  /// Ask for the device's location and its time zone.
  ///
  /// Implementations must return a [PlaceRejected] for every failure rather than
  /// throwing, and must not call the platform until this is invoked — the
  /// explanation sheet has to be on screen first.
  Future<PlaceReading> requestPlace();

  /// The device's allowed location only if permission was already given: never
  /// shows a dialog. "Follow my location" uses it when the app opens or comes
  /// back, which is not a moment the user asked for anything.
  Future<PlaceReading> currentPlaceIfAllowed();

  /// Open this app's page in the system settings, for the permanently-denied case.
  ///
  /// Best effort: if the platform cannot, it returns normally and the UI has
  /// already offered the manual list as the way through.
  Future<void> openSystemSettings();
}

/// The outcome of asking for a position to search for mosques around.
sealed class NearbyReading {
  const NearbyReading();
}

final class NearbyFound extends NearbyReading {
  const NearbyFound({
    required this.latitude,
    required this.longitude,
    required this.precise,
  });

  final double latitude;
  final double longitude;

  /// False when the user kept location approximate: the search still runs, and
  /// the screen says results may be a little off.
  final bool precise;
}

final class NearbyRejected extends NearbyReading {
  const NearbyRejected(this.failure);

  final PlaceFailure failure;
}

/// Where "Find nearby mosques" gets its starting point. Separate from
/// [PlaceSource] because it asks for a different level of location: precise,
/// and only when the user taps the search (decided 2026-10-13).
abstract interface class NearbyLocationSource {
  /// Must not call the platform until invoked: the explanation is shown first.
  Future<NearbyReading> requestPosition();

  Future<void> openSystemSettings();
}
