import 'package:drift/drift.dart';

import '../domain/adhan_alerts.dart';
import '../domain/adhan_recordings.dart';
import '../domain/extra_times.dart';
import '../domain/hijri.dart';
import '../domain/notification_plan.dart';
import '../domain/place.dart';
import '../domain/prayer.dart';
import '../domain/prayer_times_parameters.dart';
import '../domain/zone_offsets.dart';
import 'app_database.dart';
import 'table_watch.dart';

/// Where the user's prayer times are calculated from.
class StoredLocation {
  const StoredLocation({
    required this.latitude,
    required this.longitude,
    required this.ianaZone,
    required this.placeLabel,
    required this.usesGps,
    this.userName,
  });

  final double latitude;
  final double longitude;

  /// IANA zone name, e.g. 'Europe/London'. Prayer times are local wall-clock
  /// times, so the zone is what makes them correct (AGENTS.md).
  final String ianaZone;

  /// What the UI shows in the location chip.
  final String placeLabel;

  /// The user's own name for the place, if they gave one. It wins over
  /// [placeLabel] in the UI and is the only part of a place they can edit.
  final String? userName;

  /// True when the device supplied this place, false when the user picked it from
  /// the bundled list — which is a labelled placeholder, so the UI says which.
  final bool usesGps;

  ZoneOffsets get offsets => zoneOffsetsFor(ianaZone);

  /// The same place as a domain object, for the UI and the prayer-time calculator.
  Place toPlace() => Place(
    displayName: placeLabel,
    userName: userName,
    latitude: latitude,
    longitude: longitude,
    ianaZone: ianaZone,
    fromDevice: usesGps,
  );

  @override
  bool operator ==(Object other) =>
      other is StoredLocation &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.ianaZone == ianaZone &&
      other.placeLabel == placeLabel &&
      other.userName == userName &&
      other.usesGps == usesGps;

  @override
  int get hashCode =>
      Object.hash(latitude, longitude, ianaZone, placeLabel, userName, usesGps);
}

/// Theme preference, stored as text and mapped to Flutter's ThemeMode by the UI.
enum AppThemeMode { light, dark, system }

/// The app's language (2026-10-14): the phone's, or one chosen in Settings.
enum AppLanguage { system, en, ar }

/// Everything the app remembers between launches, in one readable snapshot.
class AppSettingsSnapshot {
  const AppSettingsSnapshot({
    required this.calculationMethod,
    required this.madhab,
    required this.highLatitudeRule,
    required this.minuteOffsets,
    this.customAngles = const CustomAngles(),
    required this.themeMode,
    this.language = AppLanguage.system,
    this.hijriAdjustDays = 0,
    this.inFlight,
    this.onboardingDone = false,
    required this.adhanAlerts,
    this.travel = const TravelSettings(),
    this.jamaahReminders = const JamaahReminderSettings(),
    this.extraTimes = const ExtraTimesSettings(),
    this.activeMosqueId,
    this.location,
    this.placeCheckedAt,
    this.placeCheckFailed = false,
  });

  final CalculationMethod calculationMethod;
  final Madhab madhab;
  final HighLatitudeRule highLatitudeRule;

  /// Per-prayer minute offsets. Prayers without an entry have no offset.
  final Map<Prayer, int> minuteOffsets;

  /// Used when the method is "Custom angles".
  final CustomAngles customAngles;

  final AppThemeMode themeMode;
  final AppLanguage language;

  /// Days the Hijri date is moved from the calculated one (−2…+2).
  final int hijriAdjustDays;

  /// In-flight mode's hold on notifications, while one has been set.
  final InFlightHold? inFlight;

  /// The first-run introduction has been finished.
  final bool onboardingDone;
  final AdhanAlertSettings adhanAlerts;

  /// Travel mode and its manual Iqama pause.
  final TravelSettings travel;

  /// How Jama’ah (Iqama) reminders sound.
  final JamaahReminderSettings jamaahReminders;

  /// Imsak, Duha and the last third of the night: how, and which are shown.
  final ExtraTimesSettings extraTimes;

  /// Mosque whose Iqama schedule drives reminders. Null until the user picks one.
  final String? activeMosqueId;

  /// Null on a fresh install, before the user grants location or picks a place.
  final StoredLocation? location;

  /// "Follow my location": when the device last confirmed where the phone is.
  final DateTime? placeCheckedAt;

  /// True when the latest try to follow the device failed, so the saved place
  /// may be out of date. Shown on Today, never silent.
  final bool placeCheckFailed;
}

/// Reads and writes the stored settings.
///
/// Every value has a documented default, so a missing or unreadable row degrades
/// to that default instead of throwing: a corrupt setting must never stop the app
/// from showing prayer times. Defaults match AGENTS.md — MWL, Standard asr,
/// middleOfTheNight, the device's own theme, no Adhan alert enabled, no location.
class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  static const defaults = AppSettingsSnapshot(
    calculationMethod: CalculationMethod.muslimWorldLeague,
    madhab: Madhab.standard,
    highLatitudeRule: HighLatitudeRule.middleOfTheNight,
    minuteOffsets: {},
    themeMode: AppThemeMode.system,
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
        AppThemeMode.system,
      ),
      language: _enumOrDefault(
        AppLanguage.values,
        values[SettingKeys.appLanguage],
        AppLanguage.system,
      ),
      hijriAdjustDays: clampHijriAdjust(
        int.tryParse(values[SettingKeys.hijriAdjustDays] ?? '') ?? 0,
      ),
      inFlight: _inFlight(values),
      onboardingDone: values[SettingKeys.onboardingDone] == 'true',
      customAngles: _customAngles(values),
      adhanAlerts: _adhanAlerts(values, alerts),
      travel: TravelSettings(
        // Before travel mode, following was a switch of its own: a user who
        // had it on starts in travel mode, so nothing changes for them.
        travelMode: switch (values[SettingKeys.travelModeOn]) {
          final v? => v == 'true',
          null => values[SettingKeys.followLocation] == 'true',
        },
        followLocation: values[SettingKeys.followLocation] != 'false',
        // Before the per-mosque pause there was a travel-mode pause; a user
        // who had it on keeps every reminder paused rather than suddenly
        // getting them again.
        pauseAllIqamaReminders: switch (values[SettingKeys.pauseAllIqamaReminders]) {
          final v? => v == 'true',
          null =>
            values[SettingKeys.travelMode] == 'true' &&
                values[SettingKeys.pauseIqamaReminders] == 'true',
        },
      ),
      jamaahReminders: JamaahReminderSettings(
        sound: _enumOrDefault(
          ReminderSound.values,
          values[SettingKeys.jamaahReminderSound],
          ReminderSound.chime,
        ),
        vibrate: values[SettingKeys.jamaahReminderVibrate] != 'false',
        ringInSilent: values[SettingKeys.jamaahReminderRingInSilent] == 'true',
      ),
      extraTimes: ExtraTimesSettings(
        imsakMinutes: clampImsakMinutes(
          int.tryParse(values[SettingKeys.extraImsakMinutes] ?? '') ?? 10,
        ),
        duhaMinutes: clampDuhaMinutes(
          int.tryParse(values[SettingKeys.extraDuhaMinutes] ?? '') ?? 15,
        ),
        shown: _extraSet(values[SettingKeys.extraShown], const {
          ExtraTime.imsak,
        }),
        alerts: _extraSet(values[SettingKeys.extraAlerts], const {}),
      ),
      activeMosqueId: values[SettingKeys.activeMosqueId],
      location: _location(values),
      placeCheckedAt: switch (int.tryParse(
        values[SettingKeys.placeCheckedAt] ?? '',
      )) {
        final ms? => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
        null => null,
      },
      placeCheckFailed: values[SettingKeys.placeCheckFailed] == 'true',
    );
  }

  /// Re-emits whenever any stored setting changes, including the per-prayer Adhan
  /// alerts and offsets that live in their own tables.
  Stream<AppSettingsSnapshot> watch() => watchTables(
    _db,
    [_db.appSettings, _db.adhanAlertRows, _db.prayerOffsets],
    read,
  );

  Future<void> setPrayerTimesPreferences({
    CalculationMethod? calculationMethod,
    Madhab? madhab,
    HighLatitudeRule? highLatitudeRule,
    Map<Prayer, int>? minuteOffsets,
    CustomAngles? customAngles,
  }) => _db.transaction(() async {
    if (customAngles != null) {
      await _put(SettingKeys.customFajrAngle, '${customAngles.fajrAngle}');
      await _put(SettingKeys.customIshaAngle, '${customAngles.ishaAngle}');
      final minutes = customAngles.ishaMinutesAfterMaghrib;
      if (minutes == null) {
        await (_db.delete(_db.appSettings)
              ..where((t) => t.key.equals(SettingKeys.customIshaMinutes)))
            .go();
      } else {
        await _put(SettingKeys.customIshaMinutes, '$minutes');
      }
    }
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

  Future<void> setOnboardingDone(bool done) =>
      _put(SettingKeys.onboardingDone, '$done');

  Future<void> setLanguage(AppLanguage language) =>
      _put(SettingKeys.appLanguage, language.name);

  /// Sets in-flight mode's hold (see [InFlightHold]); null ends it.
  Future<void> saveInFlight(InFlightHold? hold) => _db.transaction(() async {
    if (hold == null) {
      for (final key in const [
        SettingKeys.inFlightPausedUntil,
        SettingKeys.inFlightPrayer,
        SettingKeys.inFlightAt,
      ]) {
        await (_db.delete(
          _db.appSettings,
        )..where((r) => r.key.equals(key))).go();
      }
      return;
    }
    await _put(
      SettingKeys.inFlightPausedUntil,
      '${hold.pausedUntil.toUtc().millisecondsSinceEpoch}',
    );
    await _put(SettingKeys.inFlightPrayer, hold.prayer?.name ?? '');
    await _put(
      SettingKeys.inFlightAt,
      hold.at == null ? '' : '${hold.at!.toUtc().millisecondsSinceEpoch}',
    );
  });

  InFlightHold? _inFlight(Map<String, String?> values) {
    DateTime? instant(String key) => switch (int.tryParse(values[key] ?? '')) {
      final ms? => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true),
      null => null,
    };
    final until = instant(SettingKeys.inFlightPausedUntil);
    if (until == null) return null;
    return InFlightHold(
      pausedUntil: until,
      prayer: _prayerByName(values[SettingKeys.inFlightPrayer] ?? ''),
      at: instant(SettingKeys.inFlightAt),
    );
  }

  Future<void> setHijriAdjustDays(int days) =>
      _put(SettingKeys.hijriAdjustDays, '${clampHijriAdjust(days)}');

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
        await _put(SettingKeys.adhanFullScreen, '${alerts.fullScreen}');
        await _put(SettingKeys.adhanFullRecording, alerts.fullRecording);
        await _put(SettingKeys.adhanShortClip, alerts.shortAdhan.name);
        for (final prayer in Prayer.adhanPrayers) {
          final alert = alerts.alertFor(prayer);
          final row = AdhanAlertRowsCompanion.insert(
            prayer: prayer.name,
            enabled: Value(alert.enabled),
            soundOverride: Value(alert.soundModeOverride?.storageKey),
            vibrate: Value(alert.vibrate),
            preAdhanMinutes: Value(alert.preAdhanMinutes),
            ringInSilent: Value(alert.ringInSilent),
            preAdhanRingInSilent: Value(alert.preAdhanRingInSilent),
          );
          await _db
              .into(_db.adhanAlertRows)
              .insert(row, onConflict: DoUpdate((_) => row));
        }
      });

  /// Records a "Follow my location" check: [at] when the device answered, and
  /// whether this try [failed] (then [at] is left as it was).
  Future<void> markPlaceChecked({DateTime? at, required bool failed}) =>
      _db.transaction(() async {
        if (at != null) {
          await _put(
            SettingKeys.placeCheckedAt,
            '${at.toUtc().millisecondsSinceEpoch}',
          );
        }
        await _put(SettingKeys.placeCheckFailed, '$failed');
      });

  /// How every Jama’ah reminder sounds.
  Future<void> saveJamaahReminders(JamaahReminderSettings reminders) =>
      _db.transaction(() async {
        await _put(SettingKeys.jamaahReminderSound, reminders.sound.name);
        await _put(
          SettingKeys.jamaahReminderVibrate,
          '${reminders.vibrate}',
        );
        await _put(
          SettingKeys.jamaahReminderRingInSilent,
          '${reminders.ringInSilent}',
        );
      });

  /// The extra times' minutes, and which are shown and alerted.
  Future<void> saveExtraTimes(ExtraTimesSettings extra) =>
      _db.transaction(() async {
        await _put(
          SettingKeys.extraImsakMinutes,
          '${clampImsakMinutes(extra.imsakMinutes)}',
        );
        await _put(
          SettingKeys.extraDuhaMinutes,
          '${clampDuhaMinutes(extra.duhaMinutes)}',
        );
        await _put(
          SettingKeys.extraShown,
          extra.shown.map((t) => t.name).join(','),
        );
        await _put(
          SettingKeys.extraAlerts,
          extra.alerts.map((t) => t.name).join(','),
        );
      });

  /// Travel mode and its options, and the pause on every Iqama reminder.
  Future<void> saveTravel(TravelSettings travel) => _db.transaction(() async {
    await _put(SettingKeys.travelModeOn, '${travel.travelMode}');
    await _put(
      SettingKeys.pauseAllIqamaReminders,
      '${travel.pauseAllIqamaReminders}',
    );
    await _put(SettingKeys.followLocation, '${travel.followLocation}');
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
          SettingKeys.placeUserName,
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
        final userName = location.userName;
        if (userName != null) {
          await _put(SettingKeys.placeUserName, userName);
        }
        await _put(SettingKeys.usesGps, location.usesGps ? 'true' : 'false');
      });

  /// Give the saved place the user's own name, or clear it with null so the app's
  /// label comes back. Nothing else about the place changes: the coordinates,
  /// zone and source stay exactly as they were.
  ///
  /// A no-op when no place is stored — a name with no place behind it would be a
  /// setting the UI has no way to show or undo.
  Future<void> renamePlace(String? name) async {
    final trimmed = name?.trim();
    final existing = (await read()).location;
    if (existing == null) return;
    await setLocation(
      StoredLocation(
        latitude: existing.latitude,
        longitude: existing.longitude,
        ianaZone: existing.ianaZone,
        placeLabel: existing.placeLabel,
        userName: (trimmed == null || trimmed.isEmpty) ? null : trimmed,
        usesGps: existing.usesGps,
      ),
    );
  }

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
      fullScreen: values[SettingKeys.adhanFullScreen] == 'true',
      fullRecording: adhanRecordingById(
        values[SettingKeys.adhanFullRecording],
      ).id,
      shortAdhan: _enumOrDefault(
        ShortAdhan.values,
        values[SettingKeys.adhanShortClip],
        ShortAdhan.naghshbandi,
      ),
      alerts: {
        for (final prayer in Prayer.adhanPrayers)
          if (byPrayer[prayer.name] case final row?)
            prayer: AdhanAlert(
              enabled: row.enabled,
              soundModeOverride: row.soundOverride == null
                  ? null
                  : AdhanSoundModeX.fromStorageKey(row.soundOverride),
              vibrate: row.vibrate,
              // A stored value outside the allowed range (only possible by
              // hand) is read as "no reminder" rather than crashing the app.
              preAdhanMinutes: switch (row.preAdhanMinutes) {
                final m? when m >= 1 && m <= 120 => m,
                _ => null,
              },
              ringInSilent: row.ringInSilent,
              preAdhanRingInSilent: row.preAdhanRingInSilent,
            ),
      },
    );
  }

  /// Unreadable or out-of-range values fall back to the defaults: a bad row
  /// must never stop prayer times from showing.
  CustomAngles _customAngles(Map<String, String?> values) {
    const defaults = CustomAngles();
    double angle(String key, double fallback) {
      final v = double.tryParse(values[key] ?? '');
      return v != null && CustomAngles.validAngle(v) ? v : fallback;
    }

    final minutes = int.tryParse(values[SettingKeys.customIshaMinutes] ?? '');
    return CustomAngles(
      fajrAngle: angle(SettingKeys.customFajrAngle, defaults.fajrAngle),
      ishaAngle: angle(SettingKeys.customIshaAngle, defaults.ishaAngle),
      ishaMinutesAfterMaghrib: minutes != null && minutes > 0 && minutes <= 180
          ? minutes
          : null,
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
      userName: values[SettingKeys.placeUserName],
      usesGps: values[SettingKeys.usesGps] == 'true',
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Storing the place the user ended up with.
extension PlaceStorage on Place {
  StoredLocation toStored() => StoredLocation(
    latitude: latitude,
    longitude: longitude,
    ianaZone: ianaZone,
    placeLabel: displayName,
    userName: userName,
    usesGps: fromDevice,
  );
}

/// A stored comma list of extra times; absent means [fallback], empty none.
Set<ExtraTime> _extraSet(String? stored, Set<ExtraTime> fallback) {
  if (stored == null) return fallback;
  return {
    for (final name in stored.split(',')) ?ExtraTime.values.asNameMap()[name],
  };
}
