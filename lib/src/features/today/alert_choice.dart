import '../../domain/adhan_alerts.dart';
import '../../domain/prayer.dart';

/// The five answers to "how should this prayer's Adhan reach me?", as the
/// Today rows and the alert sheet show them (spec §2.5). Off is not Silent:
/// Silent still shows a notification; Off shows none (AGENTS.md).
enum AlertChoice {
  full,
  short,
  standard,
  silent,
  off;

  static AlertChoice of(AdhanSoundMode mode) => switch (mode) {
    AdhanSoundMode.full => full,
    AdhanSoundMode.short => short,
    AdhanSoundMode.standard => standard,
    AdhanSoundMode.silent => silent,
  };

  AdhanSoundMode? get soundMode => switch (this) {
    full => AdhanSoundMode.full,
    short => AdhanSoundMode.short,
    standard => AdhanSoundMode.standard,
    silent => AdhanSoundMode.silent,
    off => null,
  };
}

/// What a prayer's alert is now: Off when disabled, else its sound.
AlertChoice alertChoiceFor(AdhanAlertSettings settings, Prayer prayer) {
  final alert = settings.alertFor(prayer);
  if (!alert.enabled) return AlertChoice.off;
  return AlertChoice.of(settings.soundModeFor(prayer));
}

/// Applies a choice from the sheet (owner, 2026-10-15).
///
/// Off only switches the alert off and keeps any sound the prayer had, for
/// when it comes back on. A sound switches it on; picking the global default
/// clears the prayer's own override, so it keeps following later changes to
/// the default; any other sound becomes the prayer's override.
AdhanAlertSettings applyAlertChoice(
  AdhanAlertSettings settings,
  Prayer prayer,
  AlertChoice choice,
) {
  final alert = settings.alertFor(prayer);
  final mode = choice.soundMode;
  if (mode == null) {
    return settings.withAlert(prayer, alert.copyWith(enabled: false));
  }
  final updated = mode == settings.defaultSoundMode
      ? alert.copyWith(enabled: true, clearOverride: true)
      : alert.copyWith(enabled: true, soundModeOverride: mode);
  return settings.withAlert(prayer, updated);
}

/// Whether applying [choice] turns notifications on where they were off, so
/// the caller asks for the notification permission (Android 13+).
bool turnsAlertOn(
  AdhanAlertSettings settings,
  Prayer prayer,
  AlertChoice choice,
) => choice != AlertChoice.off && !settings.alertFor(prayer).enabled;
