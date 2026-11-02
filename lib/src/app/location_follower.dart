import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/settings_repository.dart';
import '../domain/place.dart';
import '../domain/place_follow.dart';
import 'clock.dart';
import 'providers.dart';

/// "Follow my location" (2026-11-02): automatic, no longer a travel option.
///
/// Each time the app opens or comes back, it reads the device's permitted
/// location — without ever showing a permission dialog at that moment — and
/// moves the saved place when the phone has travelled to another city or time
/// zone, so prayer times, "today" and every scheduled notification follow the
/// user. A place the user picked by hand is pinned: it is offered on Today
/// instead, never moved silently.
///
/// A failed check keeps the last place and says so on Today; it is never
/// silent. A user who has never allowed location says nothing either: the
/// saved place stands, and the offer to follow runs from Onboarding.
class LocationFollower {
  LocationFollower(this._ref);

  final Ref _ref;
  bool _running = false;

  SettingsRepository get _settings => _ref.read(settingsRepositoryProvider);

  /// Checks once. Safe to call as often as the app likes.
  Future<void> refresh() async {
    if (_running) return;
    _running = true;
    try {
      final snapshot = await _settings.read();
      // Nothing is placed for a fresh install still in its first-run
      // introduction: the user has not been walked through choosing yet, and
      // the app must not take the choice away. An install older than the
      // introduction already has a place, and keeps following.
      if (!snapshot.onboardingDone && snapshot.location == null) return;
      final reading = await _ref
          .read(placeSourceProvider)
          .currentPlaceIfAllowed();
      await _apply(reading, saved: snapshot.location?.toPlace());
    } finally {
      _running = false;
    }
  }

  /// Travel mode on or off, from the user's tap (top bar or Settings).
  ///
  /// The place is untouched: travel mode says "away from my mosque" — it
  /// pauses Iqama reminders and opens in-flight mode — and following runs
  /// whatever travel mode says.
  Future<void> setTravelMode(bool on) async {
    final travel = (await _settings.read()).travel;
    await _settings.saveTravel(travel.copyWith(travelMode: on));
    if (!on) await _settings.markPlaceChecked(failed: false);
  }

  Future<void> _apply(PlaceReading reading, {required Place? saved}) async {
    switch (reading) {
      case PlaceFound(:final place):
        switch (decideFollow(saved: saved, fix: place)) {
          case FollowDecision.keep:
            // Still here: a standing offer says something that is no longer
            // true, so it goes.
            await _settings.saveFollowOffer(null);
          case FollowDecision.replace:
            await _settings.setLocation(place.toStored());
            await _settings.saveFollowOffer(null);
          case FollowDecision.offer:
            // The saved place was picked by hand: stand the fix as an offer
            // and leave the place exactly as it is.
            await _settings.saveFollowOffer(
              FollowOffer(
                place: place,
                at: _ref.read(appClockProvider).nowUtc(),
              ),
            );
        }
        await _settings.markPlaceChecked(
          at: _ref.read(appClockProvider).nowUtc(),
          failed: false,
        );
      case PlaceRejected(:final failure):
        switch (failure) {
          // No permission: following simply cannot run, and there is nothing
          // to stamp. Someone who picked a place with location off must not
          // see "couldn't update" over and over.
          case PlaceFailure.denied:
          case PlaceFailure.permanentlyDenied:
            return;
          case PlaceFailure.serviceDisabled:
          case PlaceFailure.timeout:
          case PlaceFailure.unavailable:
            // Location is on (a grant exists), so the last place may be out
            // of date: say so on Today.
            await _settings.markPlaceChecked(failed: true);
        }
    }
  }

  /// Applies the [FollowOffer] standing on Today: the fix becomes the saved
  /// place (un-pinning it) and the offer goes. A no-op when none stands.
  Future<void> applyOffer() async {
    final offer = (await _settings.read()).followOffer;
    if (offer == null) return;
    await _settings.setLocation(offer.place.toStored());
    await _settings.saveFollowOffer(null);
  }

  /// Dismisses the [FollowOffer] standing on Today, leaving the place as it
  /// is. The next check that sees the same distance stands it again.
  Future<void> dismissOffer() async {
    await _settings.saveFollowOffer(null);
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
