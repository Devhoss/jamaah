import 'package:jamaah/src/domain/place.dart';

/// A stand-in for the device. No widget test in this repository touches geolocator
/// or flutter_timezone: every path is driven through this fake (AGENTS.md quality
/// bar), which also records how often the app dared to ask.
class FakePlaceSource implements PlaceSource {
  FakePlaceSource(this.reading);

  PlaceReading reading;
  int requestCount = 0;
  int settingsOpenCount = 0;

  @override
  Future<PlaceReading> requestPlace() async {
    requestCount++;
    return reading;
  }

  @override
  Future<void> openSystemSettings() async {
    settingsOpenCount++;
  }

  /// What a silent check finds; falls back to [reading].
  PlaceReading? silentReading;
  int silentCount = 0;

  @override
  Future<PlaceReading> currentPlaceIfAllowed() async {
    silentCount++;
    return silentReading ?? reading;
  }
}

/// A city from the bundled list.
const cairo = Place(
  displayName: 'Cairo, Egypt',
  latitude: 30.0444,
  longitude: 31.2357,
  ianaZone: 'Africa/Cairo',
  fromDevice: false,
);

/// The same city, but reported by the device instead of chosen by hand, so
/// `fromDevice` has a real value to assert on.
const devicePlace = Place(
  displayName: 'Africa/Cairo',
  latitude: 30.0444,
  longitude: 31.2357,
  ianaZone: 'Africa/Cairo',
  fromDevice: true,
);

/// A precise-position source the test answers, counting how often it is asked.
class FakeNearbySource implements NearbyLocationSource {
  FakeNearbySource(this.reading);

  NearbyReading reading;
  int requestCount = 0;
  int settingsOpenCount = 0;

  @override
  Future<NearbyReading> requestPosition() async {
    requestCount++;
    return reading;
  }

  @override
  Future<void> openSystemSettings() async {
    settingsOpenCount++;
  }
}
