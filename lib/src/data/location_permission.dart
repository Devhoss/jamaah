import 'package:flutter/services.dart';

/// What the system says the app may do with location right now.
class LocationGrant {
  const LocationGrant({
    required this.fine,
    required this.coarse,
    required this.canAsk,
  });

  /// Precise location.
  final bool fine;

  /// Approximate location. Granted whenever [fine] is.
  final bool coarse;

  /// False when the system will no longer show the dialog ("don't ask again"),
  /// so only the app's page in Settings can change it.
  final bool canAsk;

  bool get any => fine || coarse;

  static const none = LocationGrant(fine: false, coarse: false, canAsk: false);
}

/// Requests approximate or precise location according to the user's explicit
/// step, after the app explains why it needs that level.
///
/// The platform side lives in MainActivity. A plugin that requests every
/// location permission in the manifest would offer precise at the first prompt,
/// which is not what the user agreed to.
class LocationPermissions {
  const LocationPermissions();

  static const _channel = MethodChannel('dev.jamaah.app/location');

  Future<LocationGrant> status() => _call('status');

  /// Shows the system dialog when needed. With [precise] the dialog offers
  /// precise or approximate, and the answer says which the user picked.
  Future<LocationGrant> request({required bool precise}) =>
      _call('request', {'precise': precise});

  Future<LocationGrant> _call(String method, [Object? arguments]) async {
    try {
      final map = await _channel.invokeMapMethod<String, bool>(
        method,
        arguments,
      );
      if (map == null) return LocationGrant.none;
      return LocationGrant(
        fine: map['fine'] ?? false,
        coarse: map['coarse'] ?? false,
        canAsk: map['canAsk'] ?? false,
      );
    } on PlatformException {
      return LocationGrant.none;
    } on MissingPluginException {
      return LocationGrant.none;
    }
  }
}
