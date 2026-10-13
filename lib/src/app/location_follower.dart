import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/place.dart';
import '../domain/place_follow.dart';
import 'clock.dart';
import 'providers.dart';

/// "Follow my location" (travel, decided 2026-10-13).
///
/// When it is on, the app reads the device's coarse location each time it opens
/// or comes back, without ever showing a permission dialog at that moment, and
/// replaces the saved place when the phone has moved to another city or time
/// zone. The new place reaches everything through the settings stream, so prayer
/// times, "today" and every scheduled notification follow it.
///
/// A failed check keeps the last place and says so on Today; it is never silent.
class LocationFollower {
  LocationFollower(this._ref);

  final Ref _ref;
  bool _running = false;

  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);

  /// Checks once, if following is on. Safe to call as often as the app likes.
  Future<void> refresh() async {
    if (_running) return;
    _running = true;
    try {
      final snapshot = await _settings.read();
      if (!snapshot.travel.followLocation) return;
      final reading = await _ref
          .read(placeSourceProvider)
          .currentPlaceIfAllowed();
      await _apply(reading, saved: snapshot.location?.toPlace());
    } finally {
      _running = false;
    }
  }

  /// Turns following on, from the user's tap in Settings, so the permission
  /// dialog may show now. Returns null when it worked, or why it did not; then
  /// following stays off and nothing else changes.
  Future<PlaceFailure?> enable() async {
    final reading = await _ref.read(placeSourceProvider).requestPlace();
    if (reading case PlaceRejected(:final failure)) return failure;
    final snapshot = await _settings.read();
    await _settings.saveTravel(snapshot.travel.copyWith(followLocation: true));
    await _apply(reading, saved: snapshot.location?.toPlace());
    return null;
  }

  Future<void> disable() async {
    final snapshot = await _settings.read();
    await _settings.saveTravel(snapshot.travel.copyWith(followLocation: false));
    await _settings.markPlaceChecked(failed: false);
  }

  Future<void> _apply(PlaceReading reading, {required Place? saved}) async {
    switch (reading) {
      case PlaceFound(:final place):
        if (decideFollow(saved: saved, fix: place) == FollowDecision.replace) {
          await _settings.setLocation(place.toStored());
        }
        await _settings.markPlaceChecked(
          at: _ref.read(appClockProvider).nowUtc(),
          failed: false,
        );
      case PlaceRejected():
        // No fix (in the air, location off, permission withdrawn): the last
        // place stays in use, and Today says how old it is.
        await _settings.markPlaceChecked(failed: true);
    }
  }
}

final locationFollowerProvider = Provider<LocationFollower>(
  LocationFollower.new,
);

/// Runs [LocationFollower.refresh] when the app starts and each time it comes
/// back to the foreground.
class FollowLocationKeeper extends ConsumerStatefulWidget {
  const FollowLocationKeeper({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<FollowLocationKeeper> createState() =>
      _FollowLocationKeeperState();
}

class _FollowLocationKeeperState extends ConsumerState<FollowLocationKeeper> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(onResume: _refresh);
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  void _refresh() => ref.read(locationFollowerProvider).refresh();

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
