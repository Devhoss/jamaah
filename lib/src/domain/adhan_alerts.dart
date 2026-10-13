import 'iqama_editing.dart';
import 'prayer.dart';

/// How a reminder sounds, when it is enabled at all.
///
/// `enabled = false` is a separate thing from any mode: no notification is shown.
/// - [full]: the whole Adhan recording.
/// - [short]: the opening of the Adhan only.
/// - [standard]: the platform's default notification sound, no bundled audio.
/// - [silent]: the notification is still shown, but makes no sound. On Android it
///   needs its own channel with sound disabled, because a channel's sound is fixed
///   at creation.
enum AdhanSoundMode { full, short, standard, silent }

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
    this.fullScreen = false,
  });

  /// Starting point used for a fresh install: nothing enabled.
  factory AdhanAlertSettings.defaults() => const AdhanAlertSettings();

  final AdhanSoundMode defaultSoundMode;

  /// Show the Adhan as a full-screen page with a Stop button when the phone is
  /// idle, instead of only a notification. Off by default: it takes over the
  /// screen, which is the user's call to make.
  final bool fullScreen;

  /// Per-prayer alerts. Absent entries mean "disabled, use the default mode".
  final Map<Prayer, AdhanAlert> alerts;

  AdhanAlertSettings copyWith({
    AdhanSoundMode? defaultSoundMode,
    Map<Prayer, AdhanAlert>? alerts,
    bool? fullScreen,
  }) => AdhanAlertSettings(
    defaultSoundMode: defaultSoundMode ?? this.defaultSoundMode,
    alerts: alerts ?? this.alerts,
    fullScreen: fullScreen ?? this.fullScreen,
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
      other.fullScreen == fullScreen &&
      _sameAlerts(other.alerts, alerts);

  @override
  int get hashCode => Object.hash(defaultSoundMode, fullScreen, alerts.length);
}

bool _sameAlerts(Map<Prayer, AdhanAlert> a, Map<Prayer, AdhanAlert> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// One prayer's alert config.
///
/// [enabled] decides whether the Adhan alert exists at all. The reminder before
/// the Adhan is a separate, optional notification, so it works whether or not
/// the Adhan alert itself is on.
class AdhanAlert {
  const AdhanAlert({
    required this.enabled,
    this.soundModeOverride,
    this.vibrate = true,
    this.preAdhanMinutes,
    this.ringInSilent = false,
  }) : assert(
         preAdhanMinutes == null ||
             (preAdhanMinutes >= ReminderInterval.minMinutes &&
                 preAdhanMinutes <= ReminderInterval.maxMinutes),
       );

  final bool enabled;

  /// Null means "use the global default mode".
  final AdhanSoundMode? soundModeOverride;

  /// Whether the alert also vibrates. A silent alert with vibration off is shown
  /// without any sound or buzz.
  final bool vibrate;

  /// Minutes before the Adhan for a heads-up notification; null means none.
  final int? preAdhanMinutes;

  /// Play the Adhan even when the phone is on silent, through the alarm volume.
  /// Off by default, so the app never surprises anyone in a quiet room.
  final bool ringInSilent;

  bool get hasPreAdhanReminder => preAdhanMinutes != null;

  AdhanAlert copyWith({
    bool? enabled,
    AdhanSoundMode? soundModeOverride,
    bool clearOverride = false,
    bool? vibrate,
    int? preAdhanMinutes,
    bool clearPreAdhan = false,
    bool? ringInSilent,
  }) => AdhanAlert(
    enabled: enabled ?? this.enabled,
    soundModeOverride: clearOverride
        ? null
        : (soundModeOverride ?? this.soundModeOverride),
    vibrate: vibrate ?? this.vibrate,
    preAdhanMinutes: clearPreAdhan
        ? null
        : (preAdhanMinutes ?? this.preAdhanMinutes),
    ringInSilent: ringInSilent ?? this.ringInSilent,
  );

  @override
  bool operator ==(Object other) =>
      other is AdhanAlert &&
      other.enabled == enabled &&
      other.soundModeOverride == soundModeOverride &&
      other.vibrate == vibrate &&
      other.preAdhanMinutes == preAdhanMinutes &&
      other.ringInSilent == ringInSilent;

  @override
  int get hashCode => Object.hash(
    enabled,
    soundModeOverride,
    vibrate,
    preAdhanMinutes,
    ringInSilent,
  );
}

/// Reminder and travel preferences that are not per prayer.
///
/// [pauseAllIqamaReminders] (2026-10-13) stops every Iqama reminder at once;
/// each mosque can also be paused on its own ([Mosque.remindersPaused]). Adhan
/// alerts are never paused by either.
class TravelSettings {
  const TravelSettings({
    this.followLocation = false,
    this.pauseAllIqamaReminders = false,
  });

  /// Refresh the place from the device when the app opens.
  final bool followLocation;

  /// No Iqama reminders at all, whichever mosque is active. Iqama times and
  /// reminder settings are kept.
  final bool pauseAllIqamaReminders;

  TravelSettings copyWith({
    bool? followLocation,
    bool? pauseAllIqamaReminders,
  }) => TravelSettings(
    followLocation: followLocation ?? this.followLocation,
    pauseAllIqamaReminders:
        pauseAllIqamaReminders ?? this.pauseAllIqamaReminders,
  );

  @override
  bool operator ==(Object other) =>
      other is TravelSettings &&
      other.followLocation == followLocation &&
      other.pauseAllIqamaReminders == pauseAllIqamaReminders;

  @override
  int get hashCode => Object.hash(followLocation, pauseAllIqamaReminders);
}
