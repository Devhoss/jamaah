import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/app_clock.dart';

export '../domain/app_clock.dart';

final appClockProvider = Provider<AppClock>((ref) => const DeviceClock());

/// The instant the UI reads the day from, re-read every minute.
///
/// A countdown that only updates when the app is opened is stale within a minute,
/// and the day must roll over while the screen is still on. The ticker is a
/// battery cost, so it is paused while the app is not in the foreground; the
/// screen refreshes the moment it returns (see [MinuteClock.resume]).
class MinuteClock extends Notifier<DateTime> {
  Timer? _ticker;

  @override
  DateTime build() {
    _ticker?.cancel();
    ref.onDispose(() => _ticker?.cancel());
    _startTicker();
    return ref.read(appClockProvider).nowUtc();
  }

  /// Picked up when the app comes back to the foreground: the reading is taken
  /// again immediately rather than waiting for the next minute.
  void resume() {
    _startTicker();
    refresh();
  }

  /// Called when the app leaves the foreground. Nothing is scheduled or counted
  /// while the user is away.
  void pause() => _ticker?.cancel();

  /// Reads the clock again, which is how a test moves time without waiting for it.
  void refresh() => state = ref.read(appClockProvider).nowUtc();

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => refresh());
  }
}

final minuteClockProvider = NotifierProvider<MinuteClock, DateTime>(
  MinuteClock.new,
);
