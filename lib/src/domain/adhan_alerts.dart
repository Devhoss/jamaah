import 'prayer.dart';

/// How a reminder sounds. `standard` means "no custom sound": the platform
/// default notification sound.
enum AdhanSoundMode { full, short, standard }

extension AdhanSoundModeX on AdhanSoundMode {
  String get storageKey => name;

  static AdhanSoundMode fromStorageKey(String? key) =>
      AdhanSoundMode.values.firstWhere(
        (m) => m.name == key,
        orElse: () => AdhanSoundMode.standard,
      );
}

/// Global, per-prayer Adhan alerts. Completely independent of Iqama reminders,
/// which live on individual mosques (AGENTS.md).
class AdhanAlertSettings {
  const AdhanAlertSettings({
    this.defaultSoundMode = AdhanSoundMode.standard,
    this.alerts = const {},
  });

  /// Starting point used for a fresh install: nothing enabled.
  factory AdhanAlertSettings.defaults() => const AdhanAlertSettings();

  final AdhanSoundMode defaultSoundMode;

  /// Per-prayer alerts. Absent entries mean "disabled, use the default mode".
  final Map<Prayer, AdhanAlert> alerts;

  AdhanAlertSettings copyWith({
    AdhanSoundMode? defaultSoundMode,
    Map<Prayer, AdhanAlert>? alerts,
  }) => AdhanAlertSettings(
    defaultSoundMode: defaultSoundMode ?? this.defaultSoundMode,
    alerts: alerts ?? this.alerts,
  );

  /// The alert for [prayer]. Sunrise stays disabled unless explicitly turned on.
  AdhanAlert alertFor(Prayer prayer) =>
      alerts[prayer] ?? const AdhanAlert(enabled: false);

  AdhanAlertSettings withAlert(Prayer prayer, AdhanAlert alert) =>
      copyWith(alerts: {...alerts, prayer: alert});

  AdhanAlertSettings withSoundMode(AdhanSoundMode mode) =>
      copyWith(defaultSoundMode: mode);

  /// Sound that actually plays for [prayer]: the per-prayer override if set,
  /// otherwise the global default.
  AdhanSoundMode soundModeFor(Prayer prayer) =>
      alertFor(prayer).soundModeOverride ?? defaultSoundMode;

  List<Prayer> get enabledPrayers =>
      Prayer.adhanPrayers.where((p) => alertFor(p).enabled).toList();

  bool get hasAnyEnabled => enabledPrayers.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is AdhanAlertSettings &&
      other.defaultSoundMode == defaultSoundMode &&
      _sameAlerts(other.alerts, alerts);

  @override
  int get hashCode => Object.hash(defaultSoundMode, alerts.length);
}

bool _sameAlerts(Map<Prayer, AdhanAlert> a, Map<Prayer, AdhanAlert> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// One prayer's alert config: on/off plus an optional sound override.
class AdhanAlert {
  const AdhanAlert({required this.enabled, this.soundModeOverride});

  final bool enabled;

  /// Null means "use the global default mode".
  final AdhanSoundMode? soundModeOverride;

  AdhanAlert copyWith({
    bool? enabled,
    AdhanSoundMode? soundModeOverride,
    bool clearOverride = false,
  }) => AdhanAlert(
    enabled: enabled ?? this.enabled,
    soundModeOverride: clearOverride
        ? null
        : (soundModeOverride ?? this.soundModeOverride),
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanAlert &&
      other.enabled == enabled &&
      other.soundModeOverride == soundModeOverride;

  @override
  int get hashCode => Object.hash(enabled, soundModeOverride);
}
