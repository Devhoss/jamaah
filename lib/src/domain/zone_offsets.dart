import 'package:timezone/data/latest_all.dart' as tz_database;
import 'package:timezone/timezone.dart' as tz;

/// Loads the full IANA time zone database (598 zones).
///
/// The package's default database is a *reduced* set of 341 zones that merges
/// territories whose clocks have agreed since 1970 — it omits real device zone
/// names such as Asia/Kuwait, Asia/Doha, Europe/Oslo and Europe/Stockholm. The
/// full variant is used so `flutter_timezone` can never hand us a name we cannot
/// resolve.
///
/// Call once at start-up and in `setUpAll` for tests.
void loadTimeZoneDatabase() => tz_database.initializeTimeZones();

/// UTC offsets for one place, aware of DST.
///
/// Injected rather than read from a global so prayer times stay unit-testable and
/// the device is never touched from domain code.
abstract class ZoneOffsets {
  const ZoneOffsets();

  /// The IANA zone name this resolver answers for, e.g. 'Africa/Cairo'.
  String get zoneName;

  /// Offset from UTC in minutes at [utcInstant], e.g. 180 for UTC+3.
  int offsetMinutesAt(DateTime utcInstant);

  /// Local wall-clock minutes for a UTC wall-clock value, using a two-pass offset
  /// lookup so DST transitions resolve correctly.
  int localMinutes(DateTime utcWallClock) => _wrap(
    utcWallClock.hour * 60 +
        utcWallClock.minute +
        _offsetAtSelf(utcWallClock),
  );

  int _offsetAtSelf(DateTime utcWallClock) {
    var offset = offsetMinutesAt(utcWallClock);
    final instant = utcWallClock.add(Duration(minutes: offset));
    offset = offsetMinutesAt(instant);
    return offset;
  }

  static int _wrap(int minutes) => ((minutes % 1440) + 1440) % 1440;
}

/// Offsets resolved from the bundled IANA database.
class TzDatabaseOffsets extends ZoneOffsets {
  const TzDatabaseOffsets(this._location);

  final tz.Location _location;

  factory TzDatabaseOffsets.forZone(String ianaZoneName) =>
      TzDatabaseOffsets(tz.getLocation(ianaZoneName));

  @override
  String get zoneName => _location.name;

  @override
  int offsetMinutesAt(DateTime utcInstant) => _location
      .timeZone(utcInstant.toUtc().millisecondsSinceEpoch)
      .offset
      .inMinutes;
}

/// Offsets read from the running device's own clock.
///
/// Used only when the device reports a zone the bundled database does not carry
/// (the full database covers the IANA zones, but some devices report legacy
/// aliases such as Asia/Doha or POSIX-style names). Exact while the device sits
/// in that zone, which is the case whenever the user picked it from the device;
/// a manually chosen city always comes from the bundled list, which only
/// references zones the database has.
class DeviceClockOffsets extends ZoneOffsets {
  const DeviceClockOffsets(this.zoneName);

  @override
  final String zoneName;

  @override
  int offsetMinutesAt(DateTime utcInstant) =>
      utcInstant.toLocal().timeZoneOffset.inMinutes;
}

/// Resolves [ianaZoneName], falling back to the device clock when the bundled
/// database has no such zone. Never throws: an unresolvable zone silently becomes
/// a device-clock zone rather than killing prayer times.
ZoneOffsets zoneOffsetsFor(String ianaZoneName) {
  try {
    return TzDatabaseOffsets.forZone(ianaZoneName);
  } on Object catch (_) {
    return DeviceClockOffsets(ianaZoneName);
  }
}
