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
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a new mosque with a fresh id and one empty schedule.
  factory Mosque.draft({
    required String name,
    required String address,
    required MosqueSource source,
    double? latitude,
    double? longitude,
    String? placeId,
  }) => Mosque(
    id: _uuid.v4(),
    name: name,
    address: address,
    source: source,
    latitude: latitude,
    longitude: longitude,
    placeId: placeId,
    schedules: [Schedule.empty()],
  );

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

  bool get hasLocation => latitude != null && longitude != null;

  /// The schedule in force on [day]: the one with the latest effectiveFrom on or
  /// before [day]; otherwise the schedule with no effectiveFrom (AGENDS.md).
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
    return bestDated ?? fallback ?? schedules.firstOrNull;
  }

  Mosque copyWith({
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? placeId,
    List<Schedule>? schedules,
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
/// from Adhan times (AGENDS.md).
class Schedule {
  Schedule({
    required this.id,
    required this.mosqueId,
    this.effectiveFrom,
    required this.prayers,
    required this.updatedAt,
  });

  /// A fresh schedule where all five prayers are unconfigured.
  factory Schedule.empty({String? mosqueId, LocalDay? effectiveFrom}) => Schedule(
    id: _uuid.v4(),
    mosqueId: mosqueId ?? '',
    effectiveFrom: effectiveFrom,
    prayers: {
      for (final p in Prayer.iqamaPrayers) p: PrayerIqama(prayer: p),
    },
    updatedAt: DateTime.now(),
  );

  final String id;
  final String mosqueId;

  /// Optional first day this schedule applies. Null means "always".
  final LocalDay? effectiveFrom;

  final Map<Prayer, PrayerIqama> prayers;

  final DateTime updatedAt;

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
  }) => Schedule(
    id: id,
    mosqueId: mosqueId,
    effectiveFrom: clearEffectiveFrom
        ? null
        : (effectiveFrom ?? this.effectiveFrom),
    prayers: prayers ?? this.prayers,
    updatedAt: updatedAt ?? DateTime.now(),
  );

  /// Replaces one prayer's entry, stamping [updatedAt].
  Schedule withPrayer(PrayerIqama updated) => copyWith(
    prayers: {...prayers, updated.prayer: updated},
    updatedAt: DateTime.now(),
  );

  @override
  bool operator ==(Object other) =>
      other is Schedule &&
      other.id == id &&
      other.mosqueId == mosqueId &&
      other.effectiveFrom == effectiveFrom &&
      other.updatedAt == updatedAt &&
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

/// The user-entered Iqama for one prayer of one schedule.
class PrayerIqama {
  const PrayerIqama({
    required this.prayer,
    this.iqama,
    this.reminderEnabled = false,
    this.reminderMinutesBefore = 10,
  });

  final Prayer prayer;

  /// Null means "Not configured".
  final LocalTime? iqama;

  final bool reminderEnabled;

  final int reminderMinutesBefore;

  bool get isConfigured => iqama != null;

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
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
  );

  @override
  bool operator ==(Object other) =>
      other is PrayerIqama &&
      other.prayer == prayer &&
      other.iqama == iqama &&
      other.reminderEnabled == reminderEnabled &&
      other.reminderMinutesBefore == reminderMinutesBefore;

  @override
  int get hashCode =>
      Object.hash(prayer, iqama, reminderEnabled, reminderMinutesBefore);
}

extension _FirstOrNull<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
