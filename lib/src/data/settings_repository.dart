import 'package:drift/drift.dart';

import '../domain/adhan_alerts.dart';
import '../domain/prayer.dart';
import '../domain/prayer_times_parameters.dart';
import '../domain/zone_offsets.dart';
import 'app_database.dart';

/// Where the user's prayer times are calculated from.
class StoredLocation {
  const StoredLocation({
    required this.latitude,
    required this.longitude,
    required this.ianaZone,
    required this.placeLabel,
    required this.usesGps,
  });

  final double latitude;
  final double longitude;

  /// IANA zone name, e.g. 'Europe/London'. Prayer times are local wall-clock
  /// times, so the zone is what makes them correct (AGENTS.md).
  final String ianaZone;

  /// What the UI shows in the location chip.
  final String placeLabel;

  /// True when the device GPS supplied this place, false for a manual pick.
  final bool usesGps;

  ZoneOffsets get offsets => zoneOffsetsFor(ianaZone);

  @override
  bool operator ==(Object other) =>
      other is StoredLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.ianaZone == ianaZone &&
      other.placeLabel == placeLabel &&
      other.usesGps == usesGps;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, ianaZone, placeLabel, usesGps);
}

/// Theme preference, stored as text and mapped to Flutter's ThemeMode by the UI.
enum AppThemeMode { light, dark, system }

/// Everything the app remembers between launches, in one readable snapshot.
class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    required this.calculationMethod,
    required this.madhab,
    required this.highLatitudeRule,
    required this.minuteOffsets,
    required this.themeMode,
    required this.adhanAlerts,
    this.activeMosqueId,
    this.location,
  });

  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Per-prayer minute offsets. Prayers without an entry have no offset.
  final Map<Prayer, int> minuteOffsets;

  final AppThemeMode themeMode;
  final AdhanAlertSettings adhanAlerts;

  /// Mosque whose Iqama schedule drives reminders. Null until the user picks one.
  final String? activeMosqueId;

  /// Null on a fresh install, before the user grants location or picks a place.
  final StoredLocation? location;
}

/// Reads and writes the stored settings.
///
/// Every value has a documented default, so a missing or unreadable row degrades
/// to that default instead of throwing: a corrupt setting must never stop the app
/// from showing prayer times. Defaults match AGENTS.md — MWL, Standard asr,
/// middleOfTheNight, light theme, no Adhan alert enabled, no location.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const defaults = AppSettingsSnapshot(
    calculationMethod: CalculationMethod.muslimWorldLeague,
    madhab: Madhab.standard,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
    minuteOffsets: {},
    themeMode: AppThemeMode.light,
    adhanAlerts: AdhanAlertSettings(),
  );

  Future<AppSettingsSnapshot> read() async {
    final settings = await _db.select(_db.appSettings).get();
    final values = {for (final row in settings) row.key: row.value};
    final offsets = await _db.select(_db.prayerOffsets).get();
    final alerts = await _db.select(_db.adhanAlertRows).get();

    return AppSettingsSnapshot(
      calculationMethod: CalculationMethod.fromStorageKey(
        values[SettingKeys.calculationMethod],
      ),
      madhab: _enumOrDefault(
        Madhab.values,
        values[SettingKeys.madhab],
        Madhab.standard,
      ),
      highLatitudeRule: HighLatitudeRule.fromStorageKey(
        values[SettingKeys.highLatitudeRule],
      ),
      minuteOffsets: {
        for (final row in offsets)
          if (_prayerByName(row.prayer) case final prayer?
              when row.minutes != 0)
            prayer: row.minutes,
      },
      themeMode: _enumOrDefault(
        AppThemeMode.values,
        values[SettingKeys.themeMode],
        AppThemeMode.light,
      ),
      adhanAlerts: _adhanAlerts(values, alerts),
      activeMosqueId: values[SettingKeys.activeMosqueId],
      location: _location(values),
    );
  }

  /// Re-emits whenever any stored setting changes, including the per-prayer Adhan
  /// alerts and offsets that live in their own tables.
  Stream<AppSettingsSnapshot> watch() => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.appSettings, _db.adhanAlertRows, _db.prayerOffsets},
      )
      .watch()
      .asyncMap((_) => read());

  Future<void> setPrayerTimesPreferences({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? minuteOffsets,
  }) => _db.transaction(() async {
    if (calculationMethod != null) {
      await _put(SettingKeys.calculationMethod, calculationMethod.storageKey);
    }
    if (madhab != null) await _put(SettingKeys.madhab, madhab.name);
    if (highLatitudeRule != null) {
      await _put(
        SettingKeys.highLatitudeRule,
        highLatitudeRule.storageKey,
      );
    }
    if (minuteOffsets != null) {
      await _db.delete(_db.prayerOffsets).go();
      for (final entry in minuteOffsets.entries) {
        if (entry.value == 0) continue;
        await _db
            .into(_db.prayerOffsets)
            .insert(
              PrayerOffsetsCompanion.insert(
                prayer: entry.key.name,
                minutes: Value(entry.value),
              ),
            );
      }
    }
  });

  Future<void> setThemeMode(AppThemeMode mode) =>
      _put(SettingKeys.themeMode, mode.name);

  /// Passing null clears the active mosque, which is what stops every Iqama
  /// reminder (AGENTS.md: switching the active mosque switches the schedule that
  /// drives reminders).
  Future<void> setActiveMosqueId(String? mosqueId) => mosqueId == null
      ? (_db.delete(_db.appSettings)
            ..where((t) => t.key.equals(SettingKeys.activeMosqueId)))
          .go()
      : _put(SettingKeys.activeMosqueId, mosqueId);

  Future<void> saveAdhanAlerts(AdhanAlertSettings alerts) =>
      _db.transaction(() async {
        await _put(
          SettingKeys.adhanDefaultSoundMode,
          alerts.defaultSoundMode.storageKey,
        );
        for (final prayer in Prayer.adhanPrayers) {
          final alert = alerts.alertFor(prayer);
          final row = AdhanAlertRowsCompanion.insert(
            prayer: prayer.name,
            enabled: Value(alert.enabled),
            soundOverride: Value(alert.soundModeOverride?.storageKey),
          );
          await _db
              .into(_db.adhanAlertRows)
              .insert(row, onConflict: DoUpdate((_) => row));
        }
      });

  /// Passing null forgets the location; the Today screen then shows the
  /// "set your location" state again.
  Future<void> setLocation(StoredLocation? location) =>
      _db.transaction(() async {
        for (final key in const [
          SettingKeys.latitude,
          SettingKeys.longitude,
          SettingKeys.ianaZone,
          SettingKeys.placeLabel,
          SettingKeys.usesGps,
        ]) {
          await (_db.delete(_db.appSettings)
                ..where((t) => t.key.equals(key)))
              .go();
        }
        if (location == null) return;
        await _put(SettingKeys.latitude, location.latitude.toString());
        await _put(SettingKeys.longitude, location.longitude.toString());
        await _put(SettingKeys.ianaZone, location.ianaZone);
        await _put(SettingKeys.placeLabel, location.placeLabel);
        await _put(SettingKeys.usesGps, location.usesGps ? 'true' : 'false');
      });

  Future<void> _put(String key, String value) => _db
      .into(_db.appSettings)
      .insert(
        AppSettingsCompanion.insert(key: key, value: Value(value)),
        onConflict: DoUpdate((_) => AppSettingRow(key: key, value: value)),
      );

  T _enumOrDefault<T extends Enum>(List<T> values, String? name, T fallback) =>
      values.firstWhere((v) => v.name == name, orElse: () => fallback);

  Prayer? _prayerByName(String name) =>
      Prayer.values.where((p) => p.name == name).firstOrNull;

  AdhanAlertSettings _adhanAlerts(
    Map<String, String?> values,
    List<AdhanAlertRow> rows,
  ) {
    final byPrayer = {for (final row in rows) row.prayer: row};
    return AdhanAlertSettings(
      defaultSoundMode: AdhanSoundModeX.fromStorageKey(
        values[SettingKeys.adhanDefaultSoundMode],
      ),
      alerts: {
        for (final prayer in Prayer.adhanPrayers)
          if (byPrayer[prayer.name] case final row?)
            prayer: AdhanAlert(
              enabled: row.enabled,
              soundModeOverride: row.soundOverride == null
                  ? null
                  : AdhanSoundModeX.fromStorageKey(row.soundOverride),
            ),
      },
    );
  }

  StoredLocation? _location(Map<String, String?> values) {
    final lat = double.tryParse(values[SettingKeys.latitude] ?? '');
    final lng = double.tryParse(values[SettingKeys.longitude] ?? '');
    final zone = values[SettingKeys.ianaZone];
    if (lat == null || lng == null || zone == null || zone.isEmpty) return null;
    return StoredLocation(
      latitude: lat,
      longitude: lng,
      ianaZone: zone,
      placeLabel: values[SettingKeys.placeLabel] ?? zone,
      usesGps: values[SettingKeys.usesGps] == 'true',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
