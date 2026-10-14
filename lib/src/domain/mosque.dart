import 'package:uuid/uuid.dart';

import 'prayer.dart';
import 'time_model.dart';

const _uuid = Uuid();

/// Where a saved mosque came from. Labelled in the UI: there is no verification
/// concept, so we never imply a mosque is verified (AGENTS.md).
enum MosqueSource { google, osm, manual }

/// A saved mosque. Coordinates are optional: a mosque added by hand without a
/// location still works, it simply cannot be sorted by distance.
class Mosque {
  Mosque({
    required this.id,
    required this.name,
    required this.address,
    required this.source,
    this.latitude,
    this.longitude,
    this.placeId,
    this.schedules = const [],
    DateTime? createdAt,
    this.remindersPaused = false,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a new mosque with a fresh id and one empty schedule.
  ///
  /// A caller with a clock of its own passes [now], which stamps both the mosque
  /// and its schedule.
  factory Mosque.draft({
    required String name,
    required String address,
    required MosqueSource source,
    double? latitude,
    double? longitude,
    String? placeId,
    DateTime? now,
  }) {
    final id = _uuid.v4();
    return Mosque(
      id: id,
      name: name,
      address: address,
      source: source,
      latitude: latitude,
      longitude: longitude,
      placeId: placeId,
      schedules: [Schedule.empty(mosqueId: id, updatedAt: now)],
      createdAt: now,
    );
  }

  final String id;
  final String name;
  final String address;
  final MosqueSource source;
  final double? latitude;
  final double? longitude;
  final String? placeId;

  /// One editable schedule today; storage allows several with effective-from dates.
  final List<Schedule> schedules;

  final DateTime createdAt;

  /// The user paused this mosque's Iqama reminders (2026-10-13). Its Iqama
  /// times and reminder settings stay as they are; only the notifications stop.
  final bool remindersPaused;

  bool get hasLocation => latitude != null && longitude != null;

  /// The schedule in force on [day]: the one with the latest effectiveFrom on or
  /// before [day]; otherwise the schedule with no effectiveFrom (AGENTS.md).
  ///
  /// A schedule dated later than [day] is never returned, not even when it is the
  /// only one: a mosque whose next schedule has not started yet has no schedule for
  /// that day, and showing the future one would put times on screen that the user
  /// did not enter for it.
  Schedule? scheduleFor(LocalDay day) {
    Schedule? bestDated;
    Schedule? fallback;
    for (final s in schedules) {
      final from = s.effectiveFrom;
      if (from == null) {
        fallback ??= s;
      } else if (!from.isAfterDay(day)) {
        if (bestDated == null ||
            from.isAfterDay(bestDated.effectiveFrom!)) {
          bestDated = s;
        }
      }
    }
    return bestDated ?? fallback;
  }

  Mosque copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    List<Schedule>? schedules,
    bool? remindersPaused,
  }) => Mosque(
    id: id,
    name: name ?? this.name,
    address: address ?? this.address,
    source: source,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    placeId: placeId ?? this.placeId,
    schedules: schedules ?? this.schedules,
    createdAt: createdAt,
    remindersPaused: remindersPaused ?? this.remindersPaused,
  );

  @override
  bool operator ==(Object other) =>
      other is Mosque &&
      other.id == id &&
      other.name == name &&
      other.address == address &&
      other.source == source &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.placeId == placeId &&
      other.remindersPaused == remindersPaused &&
      _sameSchedules(other.schedules, schedules);

  @override
  int get hashCode => Object.hash(id, name, address, source, placeId);
}

bool _sameSchedules(List<Schedule> a, List<Schedule> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// One editable Iqama schedule for a mosque.
///
/// Every Iqama time starts as "Not configured" — never a default, never derived
/// from Adhan times (AGENTS.md).
class Schedule {
  Schedule({
    required this.id,
    required this.mosqueId,
    this.effectiveFrom,
    required this.prayers,
    required this.updatedAt,
    this.jumuah = const PrayerIqama(prayer: Prayer.dhuhr),
  });

  /// A fresh schedule where all five prayers are unconfigured.
  ///
  /// A caller that has a clock of its own passes [updatedAt], so the stamp on a
  /// stored schedule comes from the same injected time everything else reads.
  factory Schedule.empty({
    String? mosqueId,
    LocalDay? effectiveFrom,
    DateTime? updatedAt,
  }) => Schedule(
    id: _uuid.v4(),
    mosqueId: mosqueId ?? '',
    effectiveFrom: effectiveFrom,
    prayers: {
      for (final p in Prayer.iqamaPrayers) p: PrayerIqama(prayer: p),
    },
    updatedAt: updatedAt ?? DateTime.now(),
  );

  final String id;
  final String mosqueId;

  /// Optional first day this schedule applies. Null means "always".
  final LocalDay? effectiveFrom;

  final Map<Prayer, PrayerIqama> prayers;

  final DateTime updatedAt;

  /// Jumu'ah's Iqama (2026-10-14), kept apart from Dhuhr's: it replaces it on
  /// Fridays. Stored with prayer dhuhr; the UI names it Jumu'ah. Starts "Not
  /// configured" like every Iqama.
  final PrayerIqama jumuah;

  PrayerIqama iqamaFor(Prayer prayer) =>
      prayers[prayer] ?? PrayerIqama(prayer: prayer);

  /// How many of the five prayers have an Iqama time.
  int get configuredCount =>
      Prayer.iqamaPrayers.where((p) => iqamaFor(p).isConfigured).length;

  bool get isFullyConfigured => configuredCount == Prayer.iqamaPrayers.length;

  Schedule copyWith({
    LocalDay? effectiveFrom,
    bool clearEffectiveFrom = false,
    Map<Prayer, PrayerIqama>? prayers,
    DateTime? updatedAt,
    PrayerIqama? jumuah,
  }) => Schedule(
    id: id,
    mosqueId: mosqueId,
    effectiveFrom: clearEffectiveFrom
        ? null
        : (effectiveFrom ?? this.effectiveFrom),
    prayers: prayers ?? this.prayers,
    updatedAt: updatedAt ?? DateTime.now(),
    jumuah: jumuah ?? this.jumuah,
  );

  /// The Iqama for [prayer] on [day]: on a Friday, Dhuhr's is Jumu'ah's, or
  /// Dhuhr's own (flagged) while Jumu'ah has no time.
  DayIqama iqamaOn(LocalDay day, Prayer prayer) {
    if (prayer != Prayer.dhuhr || !day.isFriday) {
      return DayIqama(entry: iqamaFor(prayer));
    }
    if (jumuah.isConfigured) return DayIqama(entry: jumuah, isJumuah: true);
    return DayIqama(
      entry: iqamaFor(Prayer.dhuhr),
      isJumuah: true,
      jumuahNotSet: true,
    );
  }

  /// Replaces one prayer's entry, stamping [updatedAt].
  Schedule withPrayer(PrayerIqama updated, {DateTime? updatedAt}) => copyWith(
    prayers: {...prayers, updated.prayer: updated},
    updatedAt: updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is Schedule &&
      other.id == id &&
      other.mosqueId == mosqueId &&
      other.effectiveFrom == effectiveFrom &&
      other.updatedAt == updatedAt &&
      other.jumuah == jumuah &&
      _sameIqamas(other.prayers, prayers);

  @override
  int get hashCode => Object.hash(id, mosqueId, effectiveFrom, updatedAt);
}

bool _sameIqamas(Map<Prayer, PrayerIqama> a, Map<Prayer, PrayerIqama> b) {
  if (a.length != b.length) return false;
  for (final entry in a.entries) {
    if (b[entry.key] != entry.value) return false;
  }
  return true;
}

/// One prayer's Iqama as it applies on a given day.
class DayIqama {
  const DayIqama({
    required this.entry,
    this.isJumuah = false,
    this.jumuahNotSet = false,
  });

  final PrayerIqama entry;

  /// Friday's Dhuhr: named Jumu'ah wherever it is shown.
  final bool isJumuah;

  /// Friday, but the mosque has no Jumu'ah time: [entry] is Dhuhr's own, and
  /// the UI says so rather than present it as the Jumu'ah time.
  final bool jumuahNotSet;
}

/// The range of "minutes after the Adhan" an Iqama can be (2026-10-14).
const kMinAfterAdhanMinutes = 1;
const kMaxAfterAdhanMinutes = 90;

/// The user-entered Iqama for one prayer of one schedule: a fixed time, or
/// "N minutes after the Adhan" as the mosque publishes it (2026-10-14). Both
/// are the user's own entry; the app only adds the minutes to the day's
/// Adhan. Neither set means "Not configured".
class PrayerIqama {
  const PrayerIqama({
    required this.prayer,
    this.iqama,
    this.afterAdhanMinutes,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 10,
  }) : assert(iqama == null || afterAdhanMinutes == null);

  final Prayer prayer;

  /// A fixed Iqama time. Null when not configured or set as minutes.
  final LocalTime? iqama;

  /// Minutes after the day's Adhan. Null when not configured or fixed.
  final int? afterAdhanMinutes;

  final bool reminderEnabled;

  final int reminderMinutesBefore;

  bool get isConfigured => iqama != null || afterAdhanMinutes != null;

  bool get isAfterAdhan => afterAdhanMinutes != null;

  /// The Iqama as minutes from the day's midnight, given that day's Adhan
  /// ([adhanMinutes]): may be 1440 or more, meaning the next date. Null when
  /// not configured, or when it counts from an Adhan the day does not have.
  int? minutesOfDay(int? adhanMinutes) {
    if (iqama case final fixed?) return fixed.minutes;
    final after = afterAdhanMinutes;
    if (after == null || adhanMinutes == null) return null;
    return adhanMinutes + after;
  }

  /// [minutesOfDay] as a wall-clock time, wrapped to 0..1439.
  LocalTime? timeOfDay(int? adhanMinutes) => switch (minutesOfDay(
    adhanMinutes,
  )) {
    final m? => LocalTime(m % 1440),
    null => null,
  };

  /// The same entry as a fixed time; the minutes are cleared.
  PrayerIqama withFixed(LocalTime time) => PrayerIqama(
    prayer: prayer,
    iqama: time,
    reminderEnabled: reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore,
  );

  /// The same entry as minutes after the Adhan; a fixed time is cleared.
  PrayerIqama withAfterAdhan(int minutes) => PrayerIqama(
    prayer: prayer,
    afterAdhanMinutes: minutes,
    reminderEnabled: reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore,
  );

  /// A reminder only exists for a prayer with a configured Iqama time.
  bool get hasReminder => isConfigured && reminderEnabled;

  /// When the reminder fires, as minutes from the Iqama time (negative).
  int get reminderOffsetMinutes => -reminderMinutesBefore;

  PrayerIqama copyWith({
    LocalTime? iqama,
    bool clearIqama = false,
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) => PrayerIqama(
    prayer: prayer,
    iqama: clearIqama ? null : (iqama ?? this.iqama),
    afterAdhanMinutes: clearIqama || iqama != null ? null : afterAdhanMinutes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerIqama &&
      other.prayer == prayer &&
      other.iqama == iqama &&
      other.afterAdhanMinutes == afterAdhanMinutes &&
      other.reminderEnabled == reminderEnabled &&
      other.reminderMinutesBefore == reminderMinutesBefore;

  @override
  int get hashCode => Object.hash(
    prayer,
    iqama,
    afterAdhanMinutes,
    reminderEnabled,
    reminderMinutesBefore,
  );
}
