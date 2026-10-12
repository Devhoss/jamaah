/// Where the app gets "now".
///
/// An interface rather than `DateTime.now()` at the call sites because the whole
/// time-handling risk of the app (midnight rollover, DST days, tomorrow's Fajr
/// after Isha, which day a stored schedule belongs to) is only testable if the
/// clock can be handed in rather than read from the wall.
abstract interface class AppClock {
  /// The current instant, in UTC. Every reading in the app converts from this, so
  /// a device set to the wrong zone changes the day only at the place's own
  /// midnight rather than scrambling the times.
  DateTime nowUtc();
}

/// The device's own clock — the only implementation production ever uses.
class DeviceClock implements AppClock {
  const DeviceClock();

  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}
