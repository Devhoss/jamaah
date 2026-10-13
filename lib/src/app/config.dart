import 'package:flutter/foundation.dart';

/// Values come from `--dart-define-from-file=.env` (see .env.example). Nothing
/// secret is ever committed; .env is git-ignored.
class AppConfig {
  const AppConfig({
    required this.discoveryProvider,
    required this.googlePlacesApiKey,
  });

  /// Which mosque discovery backend to use: `google` (default) or `osm`.
  final String discoveryProvider;

  /// Places API key. Empty means the Google provider must report "no key" and the
  /// UI should offer manual entry; OSM needs no key at all.
  final String googlePlacesApiKey;

  static const _kProvider = String.fromEnvironment('DISCOVERY_PROVIDER');
  static const _kGoogleKey = String.fromEnvironment('GOOGLE_PLACES_API_KEY');

  bool get googleConfigured => googlePlacesApiKey.isNotEmpty;

  /// True when the selected provider cannot serve results with the current config.
  bool get discoveryBlocked =>
      discoveryProvider == 'google' && !googleConfigured;

  static AppConfig fromEnvironment() => AppConfig(
    discoveryProvider: _kProvider.isEmpty ? 'google' : _kProvider,
    googlePlacesApiKey: _kGoogleKey,
  );

  @override
  bool operator ==(Object other) =>
      other is AppConfig &&
      other.discoveryProvider == discoveryProvider &&
      other.googlePlacesApiKey == googlePlacesApiKey;

  @override
  int get hashCode => Object.hash(discoveryProvider, googlePlacesApiKey);

  @override
  String toString() =>
      'AppConfig(provider: $discoveryProvider, key: '
      '${googleConfigured ? "set" : "missing"})';

  /// Logged at start-up so we always know which provider served a session.
  void logProvider() => debugPrint('Jamaah discovery provider: $this');
}
