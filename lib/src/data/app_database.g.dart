// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSettingRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSettingRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSettingRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSettingRow(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSettingRow extends DataClass implements Insertable<AppSettingRow> {
  final String key;
  final String? value;
  const AppSettingRow({required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory AppSettingRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSettingRow(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  AppSettingRow copyWith({
    String? key,
    Value<String?> value = const Value.absent(),
  }) => AppSettingRow(
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  AppSettingRow copyWithCompanion(AppSettingsCompanion data) {
    return AppSettingRow(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingRow(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSettingRow &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSettingRow> {
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
  static Insertable<AppSettingRow> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AdhanAlertRowsTable extends AdhanAlertRows
    with TableInfo<$AdhanAlertRowsTable, AdhanAlertRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AdhanAlertRowsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (prayer IN (\'fajr\',\'sunrise\',\'dhuhr\',\'asr\',\'maghrib\',\'isha\'))',
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _soundOverrideMeta = const VerificationMeta(
    'soundOverride',
  );
  @override
  late final GeneratedColumn<String> soundOverride = GeneratedColumn<String>(
    'sound_override',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NULL CHECK (sound_override IN (\'full\',\'short\',\'standard\',\'silent\'))',
  );
  static const VerificationMeta _vibrateMeta = const VerificationMeta(
    'vibrate',
  );
  @override
  late final GeneratedColumn<bool> vibrate = GeneratedColumn<bool>(
    'vibrate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("vibrate" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _preAdhanMinutesMeta = const VerificationMeta(
    'preAdhanMinutes',
  );
  @override
  late final GeneratedColumn<int> preAdhanMinutes = GeneratedColumn<int>(
    'pre_adhan_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NULL CHECK (pre_adhan_minutes BETWEEN 1 AND 120)',
  );
  static const VerificationMeta _ringInSilentMeta = const VerificationMeta(
    'ringInSilent',
  );
  @override
  late final GeneratedColumn<bool> ringInSilent = GeneratedColumn<bool>(
    'ring_in_silent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("ring_in_silent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _preAdhanRingInSilentMeta =
      const VerificationMeta('preAdhanRingInSilent');
  @override
  late final GeneratedColumn<bool> preAdhanRingInSilent = GeneratedColumn<bool>(
    'pre_adhan_ring_in_silent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("pre_adhan_ring_in_silent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    prayer,
    enabled,
    soundOverride,
    vibrate,
    preAdhanMinutes,
    ringInSilent,
    preAdhanRingInSilent,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'adhan_alert_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<AdhanAlertRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('sound_override')) {
      context.handle(
        _soundOverrideMeta,
        soundOverride.isAcceptableOrUnknown(
          data['sound_override']!,
          _soundOverrideMeta,
        ),
      );
    }
    if (data.containsKey('vibrate')) {
      context.handle(
        _vibrateMeta,
        vibrate.isAcceptableOrUnknown(data['vibrate']!, _vibrateMeta),
      );
    }
    if (data.containsKey('pre_adhan_minutes')) {
      context.handle(
        _preAdhanMinutesMeta,
        preAdhanMinutes.isAcceptableOrUnknown(
          data['pre_adhan_minutes']!,
          _preAdhanMinutesMeta,
        ),
      );
    }
    if (data.containsKey('ring_in_silent')) {
      context.handle(
        _ringInSilentMeta,
        ringInSilent.isAcceptableOrUnknown(
          data['ring_in_silent']!,
          _ringInSilentMeta,
        ),
      );
    }
    if (data.containsKey('pre_adhan_ring_in_silent')) {
      context.handle(
        _preAdhanRingInSilentMeta,
        preAdhanRingInSilent.isAcceptableOrUnknown(
          data['pre_adhan_ring_in_silent']!,
          _preAdhanRingInSilentMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prayer};
  @override
  AdhanAlertRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AdhanAlertRow(
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      soundOverride: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sound_override'],
      ),
      vibrate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}vibrate'],
      )!,
      preAdhanMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pre_adhan_minutes'],
      ),
      ringInSilent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}ring_in_silent'],
      )!,
      preAdhanRingInSilent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}pre_adhan_ring_in_silent'],
      )!,
    );
  }

  @override
  $AdhanAlertRowsTable createAlias(String alias) {
    return $AdhanAlertRowsTable(attachedDatabase, alias);
  }
}

class AdhanAlertRow extends DataClass implements Insertable<AdhanAlertRow> {
  final String prayer;
  final bool enabled;

  /// Null means "use the global default sound mode".
  final String? soundOverride;

  /// Schema v2. Whether the alert vibrates; on for every existing row.
  final bool vibrate;

  /// Schema v2. Minutes before the Adhan for a heads-up; null means none.
  final int? preAdhanMinutes;

  /// Schema v2. Play the Adhan through the alarm volume even on silent.
  final bool ringInSilent;

  /// Schema v5 (2026-10-14). The reminder before the Adhan rings on silent too.
  final bool preAdhanRingInSilent;
  const AdhanAlertRow({
    required this.prayer,
    required this.enabled,
    this.soundOverride,
    required this.vibrate,
    this.preAdhanMinutes,
    required this.ringInSilent,
    required this.preAdhanRingInSilent,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prayer'] = Variable<String>(prayer);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || soundOverride != null) {
      map['sound_override'] = Variable<String>(soundOverride);
    }
    map['vibrate'] = Variable<bool>(vibrate);
    if (!nullToAbsent || preAdhanMinutes != null) {
      map['pre_adhan_minutes'] = Variable<int>(preAdhanMinutes);
    }
    map['ring_in_silent'] = Variable<bool>(ringInSilent);
    map['pre_adhan_ring_in_silent'] = Variable<bool>(preAdhanRingInSilent);
    return map;
  }

  AdhanAlertRowsCompanion toCompanion(bool nullToAbsent) {
    return AdhanAlertRowsCompanion(
      prayer: Value(prayer),
      enabled: Value(enabled),
      soundOverride: soundOverride == null && nullToAbsent
          ? const Value.absent()
          : Value(soundOverride),
      vibrate: Value(vibrate),
      preAdhanMinutes: preAdhanMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(preAdhanMinutes),
      ringInSilent: Value(ringInSilent),
      preAdhanRingInSilent: Value(preAdhanRingInSilent),
    );
  }

  factory AdhanAlertRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AdhanAlertRow(
      prayer: serializer.fromJson<String>(json['prayer']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      soundOverride: serializer.fromJson<String?>(json['soundOverride']),
      vibrate: serializer.fromJson<bool>(json['vibrate']),
      preAdhanMinutes: serializer.fromJson<int?>(json['preAdhanMinutes']),
      ringInSilent: serializer.fromJson<bool>(json['ringInSilent']),
      preAdhanRingInSilent: serializer.fromJson<bool>(
        json['preAdhanRingInSilent'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayer': serializer.toJson<String>(prayer),
      'enabled': serializer.toJson<bool>(enabled),
      'soundOverride': serializer.toJson<String?>(soundOverride),
      'vibrate': serializer.toJson<bool>(vibrate),
      'preAdhanMinutes': serializer.toJson<int?>(preAdhanMinutes),
      'ringInSilent': serializer.toJson<bool>(ringInSilent),
      'preAdhanRingInSilent': serializer.toJson<bool>(preAdhanRingInSilent),
    };
  }

  AdhanAlertRow copyWith({
    String? prayer,
    bool? enabled,
    Value<String?> soundOverride = const Value.absent(),
    bool? vibrate,
    Value<int?> preAdhanMinutes = const Value.absent(),
    bool? ringInSilent,
    bool? preAdhanRingInSilent,
  }) => AdhanAlertRow(
    prayer: prayer ?? this.prayer,
    enabled: enabled ?? this.enabled,
    soundOverride: soundOverride.present
        ? soundOverride.value
        : this.soundOverride,
    vibrate: vibrate ?? this.vibrate,
    preAdhanMinutes: preAdhanMinutes.present
        ? preAdhanMinutes.value
        : this.preAdhanMinutes,
    ringInSilent: ringInSilent ?? this.ringInSilent,
    preAdhanRingInSilent: preAdhanRingInSilent ?? this.preAdhanRingInSilent,
  );
  AdhanAlertRow copyWithCompanion(AdhanAlertRowsCompanion data) {
    return AdhanAlertRow(
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      soundOverride: data.soundOverride.present
          ? data.soundOverride.value
          : this.soundOverride,
      vibrate: data.vibrate.present ? data.vibrate.value : this.vibrate,
      preAdhanMinutes: data.preAdhanMinutes.present
          ? data.preAdhanMinutes.value
          : this.preAdhanMinutes,
      ringInSilent: data.ringInSilent.present
          ? data.ringInSilent.value
          : this.ringInSilent,
      preAdhanRingInSilent: data.preAdhanRingInSilent.present
          ? data.preAdhanRingInSilent.value
          : this.preAdhanRingInSilent,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AdhanAlertRow(')
          ..write('prayer: $prayer, ')
          ..write('enabled: $enabled, ')
          ..write('soundOverride: $soundOverride, ')
          ..write('vibrate: $vibrate, ')
          ..write('preAdhanMinutes: $preAdhanMinutes, ')
          ..write('ringInSilent: $ringInSilent, ')
          ..write('preAdhanRingInSilent: $preAdhanRingInSilent')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    prayer,
    enabled,
    soundOverride,
    vibrate,
    preAdhanMinutes,
    ringInSilent,
    preAdhanRingInSilent,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AdhanAlertRow &&
          other.prayer == this.prayer &&
          other.enabled == this.enabled &&
          other.soundOverride == this.soundOverride &&
          other.vibrate == this.vibrate &&
          other.preAdhanMinutes == this.preAdhanMinutes &&
          other.ringInSilent == this.ringInSilent &&
          other.preAdhanRingInSilent == this.preAdhanRingInSilent);
}

class AdhanAlertRowsCompanion extends UpdateCompanion<AdhanAlertRow> {
  final Value<String> prayer;
  final Value<bool> enabled;
  final Value<String?> soundOverride;
  final Value<bool> vibrate;
  final Value<int?> preAdhanMinutes;
  final Value<bool> ringInSilent;
  final Value<bool> preAdhanRingInSilent;
  final Value<int> rowid;
  const AdhanAlertRowsCompanion({
    this.prayer = const Value.absent(),
    this.enabled = const Value.absent(),
    this.soundOverride = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.preAdhanMinutes = const Value.absent(),
    this.ringInSilent = const Value.absent(),
    this.preAdhanRingInSilent = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AdhanAlertRowsCompanion.insert({
    required String prayer,
    this.enabled = const Value.absent(),
    this.soundOverride = const Value.absent(),
    this.vibrate = const Value.absent(),
    this.preAdhanMinutes = const Value.absent(),
    this.ringInSilent = const Value.absent(),
    this.preAdhanRingInSilent = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : prayer = Value(prayer);
  static Insertable<AdhanAlertRow> custom({
    Expression<String>? prayer,
    Expression<bool>? enabled,
    Expression<String>? soundOverride,
    Expression<bool>? vibrate,
    Expression<int>? preAdhanMinutes,
    Expression<bool>? ringInSilent,
    Expression<bool>? preAdhanRingInSilent,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayer != null) 'prayer': prayer,
      if (enabled != null) 'enabled': enabled,
      if (soundOverride != null) 'sound_override': soundOverride,
      if (vibrate != null) 'vibrate': vibrate,
      if (preAdhanMinutes != null) 'pre_adhan_minutes': preAdhanMinutes,
      if (ringInSilent != null) 'ring_in_silent': ringInSilent,
      if (preAdhanRingInSilent != null)
        'pre_adhan_ring_in_silent': preAdhanRingInSilent,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AdhanAlertRowsCompanion copyWith({
    Value<String>? prayer,
    Value<bool>? enabled,
    Value<String?>? soundOverride,
    Value<bool>? vibrate,
    Value<int?>? preAdhanMinutes,
    Value<bool>? ringInSilent,
    Value<bool>? preAdhanRingInSilent,
    Value<int>? rowid,
  }) {
    return AdhanAlertRowsCompanion(
      prayer: prayer ?? this.prayer,
      enabled: enabled ?? this.enabled,
      soundOverride: soundOverride ?? this.soundOverride,
      vibrate: vibrate ?? this.vibrate,
      preAdhanMinutes: preAdhanMinutes ?? this.preAdhanMinutes,
      ringInSilent: ringInSilent ?? this.ringInSilent,
      preAdhanRingInSilent: preAdhanRingInSilent ?? this.preAdhanRingInSilent,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (soundOverride.present) {
      map['sound_override'] = Variable<String>(soundOverride.value);
    }
    if (vibrate.present) {
      map['vibrate'] = Variable<bool>(vibrate.value);
    }
    if (preAdhanMinutes.present) {
      map['pre_adhan_minutes'] = Variable<int>(preAdhanMinutes.value);
    }
    if (ringInSilent.present) {
      map['ring_in_silent'] = Variable<bool>(ringInSilent.value);
    }
    if (preAdhanRingInSilent.present) {
      map['pre_adhan_ring_in_silent'] = Variable<bool>(
        preAdhanRingInSilent.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AdhanAlertRowsCompanion(')
          ..write('prayer: $prayer, ')
          ..write('enabled: $enabled, ')
          ..write('soundOverride: $soundOverride, ')
          ..write('vibrate: $vibrate, ')
          ..write('preAdhanMinutes: $preAdhanMinutes, ')
          ..write('ringInSilent: $ringInSilent, ')
          ..write('preAdhanRingInSilent: $preAdhanRingInSilent, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PrayerOffsetsTable extends PrayerOffsets
    with TableInfo<$PrayerOffsetsTable, PrayerOffsetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PrayerOffsetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (prayer IN (\'fajr\',\'sunrise\',\'dhuhr\',\'asr\',\'maghrib\',\'isha\'))',
  );
  static const VerificationMeta _minutesMeta = const VerificationMeta(
    'minutes',
  );
  @override
  late final GeneratedColumn<int> minutes = GeneratedColumn<int>(
    'minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [prayer, minutes];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'prayer_offsets';
  @override
  VerificationContext validateIntegrity(
    Insertable<PrayerOffsetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('minutes')) {
      context.handle(
        _minutesMeta,
        minutes.isAcceptableOrUnknown(data['minutes']!, _minutesMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {prayer};
  @override
  PrayerOffsetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PrayerOffsetRow(
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      minutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}minutes'],
      )!,
    );
  }

  @override
  $PrayerOffsetsTable createAlias(String alias) {
    return $PrayerOffsetsTable(attachedDatabase, alias);
  }
}

class PrayerOffsetRow extends DataClass implements Insertable<PrayerOffsetRow> {
  final String prayer;
  final int minutes;
  const PrayerOffsetRow({required this.prayer, required this.minutes});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['prayer'] = Variable<String>(prayer);
    map['minutes'] = Variable<int>(minutes);
    return map;
  }

  PrayerOffsetsCompanion toCompanion(bool nullToAbsent) {
    return PrayerOffsetsCompanion(
      prayer: Value(prayer),
      minutes: Value(minutes),
    );
  }

  factory PrayerOffsetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PrayerOffsetRow(
      prayer: serializer.fromJson<String>(json['prayer']),
      minutes: serializer.fromJson<int>(json['minutes']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'prayer': serializer.toJson<String>(prayer),
      'minutes': serializer.toJson<int>(minutes),
    };
  }

  PrayerOffsetRow copyWith({String? prayer, int? minutes}) => PrayerOffsetRow(
    prayer: prayer ?? this.prayer,
    minutes: minutes ?? this.minutes,
  );
  PrayerOffsetRow copyWithCompanion(PrayerOffsetsCompanion data) {
    return PrayerOffsetRow(
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      minutes: data.minutes.present ? data.minutes.value : this.minutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PrayerOffsetRow(')
          ..write('prayer: $prayer, ')
          ..write('minutes: $minutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(prayer, minutes);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PrayerOffsetRow &&
          other.prayer == this.prayer &&
          other.minutes == this.minutes);
}

class PrayerOffsetsCompanion extends UpdateCompanion<PrayerOffsetRow> {
  final Value<String> prayer;
  final Value<int> minutes;
  final Value<int> rowid;
  const PrayerOffsetsCompanion({
    this.prayer = const Value.absent(),
    this.minutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PrayerOffsetsCompanion.insert({
    required String prayer,
    this.minutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : prayer = Value(prayer);
  static Insertable<PrayerOffsetRow> custom({
    Expression<String>? prayer,
    Expression<int>? minutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (prayer != null) 'prayer': prayer,
      if (minutes != null) 'minutes': minutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PrayerOffsetsCompanion copyWith({
    Value<String>? prayer,
    Value<int>? minutes,
    Value<int>? rowid,
  }) {
    return PrayerOffsetsCompanion(
      prayer: prayer ?? this.prayer,
      minutes: minutes ?? this.minutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (minutes.present) {
      map['minutes'] = Variable<int>(minutes.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PrayerOffsetsCompanion(')
          ..write('prayer: $prayer, ')
          ..write('minutes: $minutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MosquesTable extends Mosques with TableInfo<$MosquesTable, MosqueRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MosquesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addressMeta = const VerificationMeta(
    'address',
  );
  @override
  late final GeneratedColumn<String> address = GeneratedColumn<String>(
    'address',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (source IN (\'google\',\'osm\',\'manual\'))',
  );
  static const VerificationMeta _latitudeMeta = const VerificationMeta(
    'latitude',
  );
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
    'latitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _longitudeMeta = const VerificationMeta(
    'longitude',
  );
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
    'longitude',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _placeIdMeta = const VerificationMeta(
    'placeId',
  );
  @override
  late final GeneratedColumn<String> placeId = GeneratedColumn<String>(
    'place_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remindersPausedMeta = const VerificationMeta(
    'remindersPaused',
  );
  @override
  late final GeneratedColumn<bool> remindersPaused = GeneratedColumn<bool>(
    'reminders_paused',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminders_paused" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    address,
    source,
    latitude,
    longitude,
    placeId,
    createdAt,
    remindersPaused,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'mosques';
  @override
  VerificationContext validateIntegrity(
    Insertable<MosqueRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('address')) {
      context.handle(
        _addressMeta,
        address.isAcceptableOrUnknown(data['address']!, _addressMeta),
      );
    } else if (isInserting) {
      context.missing(_addressMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(
        _latitudeMeta,
        latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta),
      );
    }
    if (data.containsKey('longitude')) {
      context.handle(
        _longitudeMeta,
        longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta),
      );
    }
    if (data.containsKey('place_id')) {
      context.handle(
        _placeIdMeta,
        placeId.isAcceptableOrUnknown(data['place_id']!, _placeIdMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('reminders_paused')) {
      context.handle(
        _remindersPausedMeta,
        remindersPaused.isAcceptableOrUnknown(
          data['reminders_paused']!,
          _remindersPausedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MosqueRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MosqueRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      address: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}address'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      latitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}latitude'],
      ),
      longitude: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}longitude'],
      ),
      placeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}place_id'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      remindersPaused: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminders_paused'],
      )!,
    );
  }

  @override
  $MosquesTable createAlias(String alias) {
    return $MosquesTable(attachedDatabase, alias);
  }
}

class MosqueRow extends DataClass implements Insertable<MosqueRow> {
  final String id;
  final String name;
  final String address;

  /// Which provider found this mosque, shown in the UI. There is no verification
  /// concept, so this is a source label and never a check mark (AGENTS.md).
  final String source;
  final double? latitude;
  final double? longitude;

  /// Provider place ID, kept so a re-search recognises the same mosque.
  final String? placeId;

  /// Unix milliseconds, written by [MosqueRepository] from the domain model.
  final int createdAt;

  /// Schema v3. The user paused this mosque's Iqama reminders (decided
  /// 2026-10-13); its Iqama times and reminder settings are kept.
  final bool remindersPaused;
  const MosqueRow({
    required this.id,
    required this.name,
    required this.address,
    required this.source,
    this.latitude,
    this.longitude,
    this.placeId,
    required this.createdAt,
    required this.remindersPaused,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['address'] = Variable<String>(address);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || latitude != null) {
      map['latitude'] = Variable<double>(latitude);
    }
    if (!nullToAbsent || longitude != null) {
      map['longitude'] = Variable<double>(longitude);
    }
    if (!nullToAbsent || placeId != null) {
      map['place_id'] = Variable<String>(placeId);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['reminders_paused'] = Variable<bool>(remindersPaused);
    return map;
  }

  MosquesCompanion toCompanion(bool nullToAbsent) {
    return MosquesCompanion(
      id: Value(id),
      name: Value(name),
      address: Value(address),
      source: Value(source),
      latitude: latitude == null && nullToAbsent
          ? const Value.absent()
          : Value(latitude),
      longitude: longitude == null && nullToAbsent
          ? const Value.absent()
          : Value(longitude),
      placeId: placeId == null && nullToAbsent
          ? const Value.absent()
          : Value(placeId),
      createdAt: Value(createdAt),
      remindersPaused: Value(remindersPaused),
    );
  }

  factory MosqueRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MosqueRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      address: serializer.fromJson<String>(json['address']),
      source: serializer.fromJson<String>(json['source']),
      latitude: serializer.fromJson<double?>(json['latitude']),
      longitude: serializer.fromJson<double?>(json['longitude']),
      placeId: serializer.fromJson<String?>(json['placeId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      remindersPaused: serializer.fromJson<bool>(json['remindersPaused']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'address': serializer.toJson<String>(address),
      'source': serializer.toJson<String>(source),
      'latitude': serializer.toJson<double?>(latitude),
      'longitude': serializer.toJson<double?>(longitude),
      'placeId': serializer.toJson<String?>(placeId),
      'createdAt': serializer.toJson<int>(createdAt),
      'remindersPaused': serializer.toJson<bool>(remindersPaused),
    };
  }

  MosqueRow copyWith({
    String? id,
    String? name,
    String? address,
    String? source,
    Value<double?> latitude = const Value.absent(),
    Value<double?> longitude = const Value.absent(),
    Value<String?> placeId = const Value.absent(),
    int? createdAt,
    bool? remindersPaused,
  }) => MosqueRow(
    id: id ?? this.id,
    name: name ?? this.name,
    address: address ?? this.address,
    source: source ?? this.source,
    latitude: latitude.present ? latitude.value : this.latitude,
    longitude: longitude.present ? longitude.value : this.longitude,
    placeId: placeId.present ? placeId.value : this.placeId,
    createdAt: createdAt ?? this.createdAt,
    remindersPaused: remindersPaused ?? this.remindersPaused,
  );
  MosqueRow copyWithCompanion(MosquesCompanion data) {
    return MosqueRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      address: data.address.present ? data.address.value : this.address,
      source: data.source.present ? data.source.value : this.source,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      placeId: data.placeId.present ? data.placeId.value : this.placeId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      remindersPaused: data.remindersPaused.present
          ? data.remindersPaused.value
          : this.remindersPaused,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MosqueRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('source: $source, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeId: $placeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersPaused: $remindersPaused')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    address,
    source,
    latitude,
    longitude,
    placeId,
    createdAt,
    remindersPaused,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MosqueRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.address == this.address &&
          other.source == this.source &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.placeId == this.placeId &&
          other.createdAt == this.createdAt &&
          other.remindersPaused == this.remindersPaused);
}

class MosquesCompanion extends UpdateCompanion<MosqueRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> address;
  final Value<String> source;
  final Value<double?> latitude;
  final Value<double?> longitude;
  final Value<String?> placeId;
  final Value<int> createdAt;
  final Value<bool> remindersPaused;
  final Value<int> rowid;
  const MosquesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.address = const Value.absent(),
    this.source = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.remindersPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MosquesCompanion.insert({
    required String id,
    required String name,
    required String address,
    required String source,
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.placeId = const Value.absent(),
    required int createdAt,
    this.remindersPaused = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       address = Value(address),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<MosqueRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? address,
    Expression<String>? source,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? placeId,
    Expression<int>? createdAt,
    Expression<bool>? remindersPaused,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (address != null) 'address': address,
      if (source != null) 'source': source,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (placeId != null) 'place_id': placeId,
      if (createdAt != null) 'created_at': createdAt,
      if (remindersPaused != null) 'reminders_paused': remindersPaused,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MosquesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? address,
    Value<String>? source,
    Value<double?>? latitude,
    Value<double?>? longitude,
    Value<String?>? placeId,
    Value<int>? createdAt,
    Value<bool>? remindersPaused,
    Value<int>? rowid,
  }) {
    return MosquesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      source: source ?? this.source,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      placeId: placeId ?? this.placeId,
      createdAt: createdAt ?? this.createdAt,
      remindersPaused: remindersPaused ?? this.remindersPaused,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (address.present) {
      map['address'] = Variable<String>(address.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (placeId.present) {
      map['place_id'] = Variable<String>(placeId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (remindersPaused.present) {
      map['reminders_paused'] = Variable<bool>(remindersPaused.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MosquesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('address: $address, ')
          ..write('source: $source, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('placeId: $placeId, ')
          ..write('createdAt: $createdAt, ')
          ..write('remindersPaused: $remindersPaused, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulesTable extends Schedules
    with TableInfo<$SchedulesTable, ScheduleRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mosqueIdMeta = const VerificationMeta(
    'mosqueId',
  );
  @override
  late final GeneratedColumn<String> mosqueId = GeneratedColumn<String>(
    'mosque_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES mosques (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _effectiveFromMeta = const VerificationMeta(
    'effectiveFrom',
  );
  @override
  late final GeneratedColumn<int> effectiveFrom = GeneratedColumn<int>(
    'effective_from',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _jumuahMinutesMeta = const VerificationMeta(
    'jumuahMinutes',
  );
  @override
  late final GeneratedColumn<int> jumuahMinutes = GeneratedColumn<int>(
    'jumuah_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _jumuahReminderEnabledMeta =
      const VerificationMeta('jumuahReminderEnabled');
  @override
  late final GeneratedColumn<bool> jumuahReminderEnabled =
      GeneratedColumn<bool>(
        'jumuah_reminder_enabled',
        aliasedName,
        false,
        type: DriftSqlType.bool,
        requiredDuringInsert: false,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'CHECK ("jumuah_reminder_enabled" IN (0, 1))',
        ),
        defaultValue: const Constant(false),
      );
  static const VerificationMeta _jumuahReminderMinutesBeforeMeta =
      const VerificationMeta('jumuahReminderMinutesBefore');
  @override
  late final GeneratedColumn<int> jumuahReminderMinutesBefore =
      GeneratedColumn<int>(
        'jumuah_reminder_minutes_before',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        defaultValue: const Constant(10),
      );
  static const VerificationMeta _jumuahAfterAdhanMinutesMeta =
      const VerificationMeta('jumuahAfterAdhanMinutes');
  @override
  late final GeneratedColumn<int> jumuahAfterAdhanMinutes =
      GeneratedColumn<int>(
        'jumuah_after_adhan_minutes',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    mosqueId,
    effectiveFrom,
    updatedAt,
    jumuahMinutes,
    jumuahReminderEnabled,
    jumuahReminderMinutesBefore,
    jumuahAfterAdhanMinutes,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedules';
  @override
  VerificationContext validateIntegrity(
    Insertable<ScheduleRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('mosque_id')) {
      context.handle(
        _mosqueIdMeta,
        mosqueId.isAcceptableOrUnknown(data['mosque_id']!, _mosqueIdMeta),
      );
    } else if (isInserting) {
      context.missing(_mosqueIdMeta);
    }
    if (data.containsKey('effective_from')) {
      context.handle(
        _effectiveFromMeta,
        effectiveFrom.isAcceptableOrUnknown(
          data['effective_from']!,
          _effectiveFromMeta,
        ),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('jumuah_minutes')) {
      context.handle(
        _jumuahMinutesMeta,
        jumuahMinutes.isAcceptableOrUnknown(
          data['jumuah_minutes']!,
          _jumuahMinutesMeta,
        ),
      );
    }
    if (data.containsKey('jumuah_reminder_enabled')) {
      context.handle(
        _jumuahReminderEnabledMeta,
        jumuahReminderEnabled.isAcceptableOrUnknown(
          data['jumuah_reminder_enabled']!,
          _jumuahReminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('jumuah_reminder_minutes_before')) {
      context.handle(
        _jumuahReminderMinutesBeforeMeta,
        jumuahReminderMinutesBefore.isAcceptableOrUnknown(
          data['jumuah_reminder_minutes_before']!,
          _jumuahReminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('jumuah_after_adhan_minutes')) {
      context.handle(
        _jumuahAfterAdhanMinutesMeta,
        jumuahAfterAdhanMinutes.isAcceptableOrUnknown(
          data['jumuah_after_adhan_minutes']!,
          _jumuahAfterAdhanMinutesMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ScheduleRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ScheduleRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      mosqueId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mosque_id'],
      )!,
      effectiveFrom: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}effective_from'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      jumuahMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumuah_minutes'],
      ),
      jumuahReminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}jumuah_reminder_enabled'],
      )!,
      jumuahReminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumuah_reminder_minutes_before'],
      )!,
      jumuahAfterAdhanMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}jumuah_after_adhan_minutes'],
      ),
    );
  }

  @override
  $SchedulesTable createAlias(String alias) {
    return $SchedulesTable(attachedDatabase, alias);
  }
}

class ScheduleRow extends DataClass implements Insertable<ScheduleRow> {
  final String id;
  final String mosqueId;

  /// First day this schedule applies, as a `yyyyMMdd` number so it compares
  /// correctly. Null means "always", the fallback when no dated schedule applies.
  final int? effectiveFrom;
  final int updatedAt;

  /// Jumu'ah's Iqama (schema v4, 2026-10-14). Null is "Not configured".
  final int? jumuahMinutes;
  final bool jumuahReminderEnabled;
  final int jumuahReminderMinutesBefore;

  /// Schema v6: Jumu'ah as minutes after Dhuhr's Adhan.
  final int? jumuahAfterAdhanMinutes;
  const ScheduleRow({
    required this.id,
    required this.mosqueId,
    this.effectiveFrom,
    required this.updatedAt,
    this.jumuahMinutes,
    required this.jumuahReminderEnabled,
    required this.jumuahReminderMinutesBefore,
    this.jumuahAfterAdhanMinutes,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['mosque_id'] = Variable<String>(mosqueId);
    if (!nullToAbsent || effectiveFrom != null) {
      map['effective_from'] = Variable<int>(effectiveFrom);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    if (!nullToAbsent || jumuahMinutes != null) {
      map['jumuah_minutes'] = Variable<int>(jumuahMinutes);
    }
    map['jumuah_reminder_enabled'] = Variable<bool>(jumuahReminderEnabled);
    map['jumuah_reminder_minutes_before'] = Variable<int>(
      jumuahReminderMinutesBefore,
    );
    if (!nullToAbsent || jumuahAfterAdhanMinutes != null) {
      map['jumuah_after_adhan_minutes'] = Variable<int>(
        jumuahAfterAdhanMinutes,
      );
    }
    return map;
  }

  SchedulesCompanion toCompanion(bool nullToAbsent) {
    return SchedulesCompanion(
      id: Value(id),
      mosqueId: Value(mosqueId),
      effectiveFrom: effectiveFrom == null && nullToAbsent
          ? const Value.absent()
          : Value(effectiveFrom),
      updatedAt: Value(updatedAt),
      jumuahMinutes: jumuahMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(jumuahMinutes),
      jumuahReminderEnabled: Value(jumuahReminderEnabled),
      jumuahReminderMinutesBefore: Value(jumuahReminderMinutesBefore),
      jumuahAfterAdhanMinutes: jumuahAfterAdhanMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(jumuahAfterAdhanMinutes),
    );
  }

  factory ScheduleRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ScheduleRow(
      id: serializer.fromJson<String>(json['id']),
      mosqueId: serializer.fromJson<String>(json['mosqueId']),
      effectiveFrom: serializer.fromJson<int?>(json['effectiveFrom']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      jumuahMinutes: serializer.fromJson<int?>(json['jumuahMinutes']),
      jumuahReminderEnabled: serializer.fromJson<bool>(
        json['jumuahReminderEnabled'],
      ),
      jumuahReminderMinutesBefore: serializer.fromJson<int>(
        json['jumuahReminderMinutesBefore'],
      ),
      jumuahAfterAdhanMinutes: serializer.fromJson<int?>(
        json['jumuahAfterAdhanMinutes'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'mosqueId': serializer.toJson<String>(mosqueId),
      'effectiveFrom': serializer.toJson<int?>(effectiveFrom),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'jumuahMinutes': serializer.toJson<int?>(jumuahMinutes),
      'jumuahReminderEnabled': serializer.toJson<bool>(jumuahReminderEnabled),
      'jumuahReminderMinutesBefore': serializer.toJson<int>(
        jumuahReminderMinutesBefore,
      ),
      'jumuahAfterAdhanMinutes': serializer.toJson<int?>(
        jumuahAfterAdhanMinutes,
      ),
    };
  }

  ScheduleRow copyWith({
    String? id,
    String? mosqueId,
    Value<int?> effectiveFrom = const Value.absent(),
    int? updatedAt,
    Value<int?> jumuahMinutes = const Value.absent(),
    bool? jumuahReminderEnabled,
    int? jumuahReminderMinutesBefore,
    Value<int?> jumuahAfterAdhanMinutes = const Value.absent(),
  }) => ScheduleRow(
    id: id ?? this.id,
    mosqueId: mosqueId ?? this.mosqueId,
    effectiveFrom: effectiveFrom.present
        ? effectiveFrom.value
        : this.effectiveFrom,
    updatedAt: updatedAt ?? this.updatedAt,
    jumuahMinutes: jumuahMinutes.present
        ? jumuahMinutes.value
        : this.jumuahMinutes,
    jumuahReminderEnabled: jumuahReminderEnabled ?? this.jumuahReminderEnabled,
    jumuahReminderMinutesBefore:
        jumuahReminderMinutesBefore ?? this.jumuahReminderMinutesBefore,
    jumuahAfterAdhanMinutes: jumuahAfterAdhanMinutes.present
        ? jumuahAfterAdhanMinutes.value
        : this.jumuahAfterAdhanMinutes,
  );
  ScheduleRow copyWithCompanion(SchedulesCompanion data) {
    return ScheduleRow(
      id: data.id.present ? data.id.value : this.id,
      mosqueId: data.mosqueId.present ? data.mosqueId.value : this.mosqueId,
      effectiveFrom: data.effectiveFrom.present
          ? data.effectiveFrom.value
          : this.effectiveFrom,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      jumuahMinutes: data.jumuahMinutes.present
          ? data.jumuahMinutes.value
          : this.jumuahMinutes,
      jumuahReminderEnabled: data.jumuahReminderEnabled.present
          ? data.jumuahReminderEnabled.value
          : this.jumuahReminderEnabled,
      jumuahReminderMinutesBefore: data.jumuahReminderMinutesBefore.present
          ? data.jumuahReminderMinutesBefore.value
          : this.jumuahReminderMinutesBefore,
      jumuahAfterAdhanMinutes: data.jumuahAfterAdhanMinutes.present
          ? data.jumuahAfterAdhanMinutes.value
          : this.jumuahAfterAdhanMinutes,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ScheduleRow(')
          ..write('id: $id, ')
          ..write('mosqueId: $mosqueId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('jumuahMinutes: $jumuahMinutes, ')
          ..write('jumuahReminderEnabled: $jumuahReminderEnabled, ')
          ..write('jumuahReminderMinutesBefore: $jumuahReminderMinutesBefore, ')
          ..write('jumuahAfterAdhanMinutes: $jumuahAfterAdhanMinutes')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    mosqueId,
    effectiveFrom,
    updatedAt,
    jumuahMinutes,
    jumuahReminderEnabled,
    jumuahReminderMinutesBefore,
    jumuahAfterAdhanMinutes,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ScheduleRow &&
          other.id == this.id &&
          other.mosqueId == this.mosqueId &&
          other.effectiveFrom == this.effectiveFrom &&
          other.updatedAt == this.updatedAt &&
          other.jumuahMinutes == this.jumuahMinutes &&
          other.jumuahReminderEnabled == this.jumuahReminderEnabled &&
          other.jumuahReminderMinutesBefore ==
              this.jumuahReminderMinutesBefore &&
          other.jumuahAfterAdhanMinutes == this.jumuahAfterAdhanMinutes);
}

class SchedulesCompanion extends UpdateCompanion<ScheduleRow> {
  final Value<String> id;
  final Value<String> mosqueId;
  final Value<int?> effectiveFrom;
  final Value<int> updatedAt;
  final Value<int?> jumuahMinutes;
  final Value<bool> jumuahReminderEnabled;
  final Value<int> jumuahReminderMinutesBefore;
  final Value<int?> jumuahAfterAdhanMinutes;
  final Value<int> rowid;
  const SchedulesCompanion({
    this.id = const Value.absent(),
    this.mosqueId = const Value.absent(),
    this.effectiveFrom = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.jumuahMinutes = const Value.absent(),
    this.jumuahReminderEnabled = const Value.absent(),
    this.jumuahReminderMinutesBefore = const Value.absent(),
    this.jumuahAfterAdhanMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulesCompanion.insert({
    required String id,
    required String mosqueId,
    this.effectiveFrom = const Value.absent(),
    required int updatedAt,
    this.jumuahMinutes = const Value.absent(),
    this.jumuahReminderEnabled = const Value.absent(),
    this.jumuahReminderMinutesBefore = const Value.absent(),
    this.jumuahAfterAdhanMinutes = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       mosqueId = Value(mosqueId),
       updatedAt = Value(updatedAt);
  static Insertable<ScheduleRow> custom({
    Expression<String>? id,
    Expression<String>? mosqueId,
    Expression<int>? effectiveFrom,
    Expression<int>? updatedAt,
    Expression<int>? jumuahMinutes,
    Expression<bool>? jumuahReminderEnabled,
    Expression<int>? jumuahReminderMinutesBefore,
    Expression<int>? jumuahAfterAdhanMinutes,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (mosqueId != null) 'mosque_id': mosqueId,
      if (effectiveFrom != null) 'effective_from': effectiveFrom,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (jumuahMinutes != null) 'jumuah_minutes': jumuahMinutes,
      if (jumuahReminderEnabled != null)
        'jumuah_reminder_enabled': jumuahReminderEnabled,
      if (jumuahReminderMinutesBefore != null)
        'jumuah_reminder_minutes_before': jumuahReminderMinutesBefore,
      if (jumuahAfterAdhanMinutes != null)
        'jumuah_after_adhan_minutes': jumuahAfterAdhanMinutes,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulesCompanion copyWith({
    Value<String>? id,
    Value<String>? mosqueId,
    Value<int?>? effectiveFrom,
    Value<int>? updatedAt,
    Value<int?>? jumuahMinutes,
    Value<bool>? jumuahReminderEnabled,
    Value<int>? jumuahReminderMinutesBefore,
    Value<int?>? jumuahAfterAdhanMinutes,
    Value<int>? rowid,
  }) {
    return SchedulesCompanion(
      id: id ?? this.id,
      mosqueId: mosqueId ?? this.mosqueId,
      effectiveFrom: effectiveFrom ?? this.effectiveFrom,
      updatedAt: updatedAt ?? this.updatedAt,
      jumuahMinutes: jumuahMinutes ?? this.jumuahMinutes,
      jumuahReminderEnabled:
          jumuahReminderEnabled ?? this.jumuahReminderEnabled,
      jumuahReminderMinutesBefore:
          jumuahReminderMinutesBefore ?? this.jumuahReminderMinutesBefore,
      jumuahAfterAdhanMinutes:
          jumuahAfterAdhanMinutes ?? this.jumuahAfterAdhanMinutes,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (mosqueId.present) {
      map['mosque_id'] = Variable<String>(mosqueId.value);
    }
    if (effectiveFrom.present) {
      map['effective_from'] = Variable<int>(effectiveFrom.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (jumuahMinutes.present) {
      map['jumuah_minutes'] = Variable<int>(jumuahMinutes.value);
    }
    if (jumuahReminderEnabled.present) {
      map['jumuah_reminder_enabled'] = Variable<bool>(
        jumuahReminderEnabled.value,
      );
    }
    if (jumuahReminderMinutesBefore.present) {
      map['jumuah_reminder_minutes_before'] = Variable<int>(
        jumuahReminderMinutesBefore.value,
      );
    }
    if (jumuahAfterAdhanMinutes.present) {
      map['jumuah_after_adhan_minutes'] = Variable<int>(
        jumuahAfterAdhanMinutes.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulesCompanion(')
          ..write('id: $id, ')
          ..write('mosqueId: $mosqueId, ')
          ..write('effectiveFrom: $effectiveFrom, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('jumuahMinutes: $jumuahMinutes, ')
          ..write('jumuahReminderEnabled: $jumuahReminderEnabled, ')
          ..write('jumuahReminderMinutesBefore: $jumuahReminderMinutesBefore, ')
          ..write('jumuahAfterAdhanMinutes: $jumuahAfterAdhanMinutes, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SchedulePrayersTable extends SchedulePrayers
    with TableInfo<$SchedulePrayersTable, SchedulePrayerRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SchedulePrayersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _scheduleIdMeta = const VerificationMeta(
    'scheduleId',
  );
  @override
  late final GeneratedColumn<String> scheduleId = GeneratedColumn<String>(
    'schedule_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES schedules (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _prayerMeta = const VerificationMeta('prayer');
  @override
  late final GeneratedColumn<String> prayer = GeneratedColumn<String>(
    'prayer',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (prayer IN (\'fajr\',\'dhuhr\',\'asr\',\'maghrib\',\'isha\'))',
  );
  static const VerificationMeta _iqamaMinutesMeta = const VerificationMeta(
    'iqamaMinutes',
  );
  @override
  late final GeneratedColumn<int> iqamaMinutes = GeneratedColumn<int>(
    'iqama_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _iqamaAfterAdhanMinutesMeta =
      const VerificationMeta('iqamaAfterAdhanMinutes');
  @override
  late final GeneratedColumn<int> iqamaAfterAdhanMinutes = GeneratedColumn<int>(
    'iqama_after_adhan_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderEnabledMeta = const VerificationMeta(
    'reminderEnabled',
  );
  @override
  late final GeneratedColumn<bool> reminderEnabled = GeneratedColumn<bool>(
    'reminder_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("reminder_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(10),
  );
  @override
  List<GeneratedColumn> get $columns => [
    scheduleId,
    prayer,
    iqamaMinutes,
    iqamaAfterAdhanMinutes,
    reminderEnabled,
    reminderMinutesBefore,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'schedule_prayers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SchedulePrayerRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('schedule_id')) {
      context.handle(
        _scheduleIdMeta,
        scheduleId.isAcceptableOrUnknown(data['schedule_id']!, _scheduleIdMeta),
      );
    } else if (isInserting) {
      context.missing(_scheduleIdMeta);
    }
    if (data.containsKey('prayer')) {
      context.handle(
        _prayerMeta,
        prayer.isAcceptableOrUnknown(data['prayer']!, _prayerMeta),
      );
    } else if (isInserting) {
      context.missing(_prayerMeta);
    }
    if (data.containsKey('iqama_minutes')) {
      context.handle(
        _iqamaMinutesMeta,
        iqamaMinutes.isAcceptableOrUnknown(
          data['iqama_minutes']!,
          _iqamaMinutesMeta,
        ),
      );
    }
    if (data.containsKey('iqama_after_adhan_minutes')) {
      context.handle(
        _iqamaAfterAdhanMinutesMeta,
        iqamaAfterAdhanMinutes.isAcceptableOrUnknown(
          data['iqama_after_adhan_minutes']!,
          _iqamaAfterAdhanMinutesMeta,
        ),
      );
    }
    if (data.containsKey('reminder_enabled')) {
      context.handle(
        _reminderEnabledMeta,
        reminderEnabled.isAcceptableOrUnknown(
          data['reminder_enabled']!,
          _reminderEnabledMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {scheduleId, prayer};
  @override
  SchedulePrayerRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SchedulePrayerRow(
      scheduleId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_id'],
      )!,
      prayer: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prayer'],
      )!,
      iqamaMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iqama_minutes'],
      ),
      iqamaAfterAdhanMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}iqama_after_adhan_minutes'],
      ),
      reminderEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}reminder_enabled'],
      )!,
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      )!,
    );
  }

  @override
  $SchedulePrayersTable createAlias(String alias) {
    return $SchedulePrayersTable(attachedDatabase, alias);
  }
}

class SchedulePrayerRow extends DataClass
    implements Insertable<SchedulePrayerRow> {
  final String scheduleId;
  final String prayer;

  /// Minutes from local midnight. Null is "Not configured".
  final int? iqamaMinutes;

  /// Schema v6 (2026-10-14): the Iqama as minutes after the day's Adhan,
  /// instead of [iqamaMinutes]. At most one of the two is set.
  final int? iqamaAfterAdhanMinutes;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  const SchedulePrayerRow({
    required this.scheduleId,
    required this.prayer,
    this.iqamaMinutes,
    this.iqamaAfterAdhanMinutes,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['schedule_id'] = Variable<String>(scheduleId);
    map['prayer'] = Variable<String>(prayer);
    if (!nullToAbsent || iqamaMinutes != null) {
      map['iqama_minutes'] = Variable<int>(iqamaMinutes);
    }
    if (!nullToAbsent || iqamaAfterAdhanMinutes != null) {
      map['iqama_after_adhan_minutes'] = Variable<int>(iqamaAfterAdhanMinutes);
    }
    map['reminder_enabled'] = Variable<bool>(reminderEnabled);
    map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    return map;
  }

  SchedulePrayersCompanion toCompanion(bool nullToAbsent) {
    return SchedulePrayersCompanion(
      scheduleId: Value(scheduleId),
      prayer: Value(prayer),
      iqamaMinutes: iqamaMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(iqamaMinutes),
      iqamaAfterAdhanMinutes: iqamaAfterAdhanMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(iqamaAfterAdhanMinutes),
      reminderEnabled: Value(reminderEnabled),
      reminderMinutesBefore: Value(reminderMinutesBefore),
    );
  }

  factory SchedulePrayerRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SchedulePrayerRow(
      scheduleId: serializer.fromJson<String>(json['scheduleId']),
      prayer: serializer.fromJson<String>(json['prayer']),
      iqamaMinutes: serializer.fromJson<int?>(json['iqamaMinutes']),
      iqamaAfterAdhanMinutes: serializer.fromJson<int?>(
        json['iqamaAfterAdhanMinutes'],
      ),
      reminderEnabled: serializer.fromJson<bool>(json['reminderEnabled']),
      reminderMinutesBefore: serializer.fromJson<int>(
        json['reminderMinutesBefore'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'scheduleId': serializer.toJson<String>(scheduleId),
      'prayer': serializer.toJson<String>(prayer),
      'iqamaMinutes': serializer.toJson<int?>(iqamaMinutes),
      'iqamaAfterAdhanMinutes': serializer.toJson<int?>(iqamaAfterAdhanMinutes),
      'reminderEnabled': serializer.toJson<bool>(reminderEnabled),
      'reminderMinutesBefore': serializer.toJson<int>(reminderMinutesBefore),
    };
  }

  SchedulePrayerRow copyWith({
    String? scheduleId,
    String? prayer,
    Value<int?> iqamaMinutes = const Value.absent(),
    Value<int?> iqamaAfterAdhanMinutes = const Value.absent(),
    bool? reminderEnabled,
    int? reminderMinutesBefore,
  }) => SchedulePrayerRow(
    scheduleId: scheduleId ?? this.scheduleId,
    prayer: prayer ?? this.prayer,
    iqamaMinutes: iqamaMinutes.present ? iqamaMinutes.value : this.iqamaMinutes,
    iqamaAfterAdhanMinutes: iqamaAfterAdhanMinutes.present
        ? iqamaAfterAdhanMinutes.value
        : this.iqamaAfterAdhanMinutes,
    reminderEnabled: reminderEnabled ?? this.reminderEnabled,
    reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
  );
  SchedulePrayerRow copyWithCompanion(SchedulePrayersCompanion data) {
    return SchedulePrayerRow(
      scheduleId: data.scheduleId.present
          ? data.scheduleId.value
          : this.scheduleId,
      prayer: data.prayer.present ? data.prayer.value : this.prayer,
      iqamaMinutes: data.iqamaMinutes.present
          ? data.iqamaMinutes.value
          : this.iqamaMinutes,
      iqamaAfterAdhanMinutes: data.iqamaAfterAdhanMinutes.present
          ? data.iqamaAfterAdhanMinutes.value
          : this.iqamaAfterAdhanMinutes,
      reminderEnabled: data.reminderEnabled.present
          ? data.reminderEnabled.value
          : this.reminderEnabled,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SchedulePrayerRow(')
          ..write('scheduleId: $scheduleId, ')
          ..write('prayer: $prayer, ')
          ..write('iqamaMinutes: $iqamaMinutes, ')
          ..write('iqamaAfterAdhanMinutes: $iqamaAfterAdhanMinutes, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    scheduleId,
    prayer,
    iqamaMinutes,
    iqamaAfterAdhanMinutes,
    reminderEnabled,
    reminderMinutesBefore,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SchedulePrayerRow &&
          other.scheduleId == this.scheduleId &&
          other.prayer == this.prayer &&
          other.iqamaMinutes == this.iqamaMinutes &&
          other.iqamaAfterAdhanMinutes == this.iqamaAfterAdhanMinutes &&
          other.reminderEnabled == this.reminderEnabled &&
          other.reminderMinutesBefore == this.reminderMinutesBefore);
}

class SchedulePrayersCompanion extends UpdateCompanion<SchedulePrayerRow> {
  final Value<String> scheduleId;
  final Value<String> prayer;
  final Value<int?> iqamaMinutes;
  final Value<int?> iqamaAfterAdhanMinutes;
  final Value<bool> reminderEnabled;
  final Value<int> reminderMinutesBefore;
  final Value<int> rowid;
  const SchedulePrayersCompanion({
    this.scheduleId = const Value.absent(),
    this.prayer = const Value.absent(),
    this.iqamaMinutes = const Value.absent(),
    this.iqamaAfterAdhanMinutes = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SchedulePrayersCompanion.insert({
    required String scheduleId,
    required String prayer,
    this.iqamaMinutes = const Value.absent(),
    this.iqamaAfterAdhanMinutes = const Value.absent(),
    this.reminderEnabled = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : scheduleId = Value(scheduleId),
       prayer = Value(prayer);
  static Insertable<SchedulePrayerRow> custom({
    Expression<String>? scheduleId,
    Expression<String>? prayer,
    Expression<int>? iqamaMinutes,
    Expression<int>? iqamaAfterAdhanMinutes,
    Expression<bool>? reminderEnabled,
    Expression<int>? reminderMinutesBefore,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (scheduleId != null) 'schedule_id': scheduleId,
      if (prayer != null) 'prayer': prayer,
      if (iqamaMinutes != null) 'iqama_minutes': iqamaMinutes,
      if (iqamaAfterAdhanMinutes != null)
        'iqama_after_adhan_minutes': iqamaAfterAdhanMinutes,
      if (reminderEnabled != null) 'reminder_enabled': reminderEnabled,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SchedulePrayersCompanion copyWith({
    Value<String>? scheduleId,
    Value<String>? prayer,
    Value<int?>? iqamaMinutes,
    Value<int?>? iqamaAfterAdhanMinutes,
    Value<bool>? reminderEnabled,
    Value<int>? reminderMinutesBefore,
    Value<int>? rowid,
  }) {
    return SchedulePrayersCompanion(
      scheduleId: scheduleId ?? this.scheduleId,
      prayer: prayer ?? this.prayer,
      iqamaMinutes: iqamaMinutes ?? this.iqamaMinutes,
      iqamaAfterAdhanMinutes:
          iqamaAfterAdhanMinutes ?? this.iqamaAfterAdhanMinutes,
      reminderEnabled: reminderEnabled ?? this.reminderEnabled,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (scheduleId.present) {
      map['schedule_id'] = Variable<String>(scheduleId.value);
    }
    if (prayer.present) {
      map['prayer'] = Variable<String>(prayer.value);
    }
    if (iqamaMinutes.present) {
      map['iqama_minutes'] = Variable<int>(iqamaMinutes.value);
    }
    if (iqamaAfterAdhanMinutes.present) {
      map['iqama_after_adhan_minutes'] = Variable<int>(
        iqamaAfterAdhanMinutes.value,
      );
    }
    if (reminderEnabled.present) {
      map['reminder_enabled'] = Variable<bool>(reminderEnabled.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SchedulePrayersCompanion(')
          ..write('scheduleId: $scheduleId, ')
          ..write('prayer: $prayer, ')
          ..write('iqamaMinutes: $iqamaMinutes, ')
          ..write('iqamaAfterAdhanMinutes: $iqamaAfterAdhanMinutes, ')
          ..write('reminderEnabled: $reminderEnabled, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $AdhanAlertRowsTable adhanAlertRows = $AdhanAlertRowsTable(this);
  late final $PrayerOffsetsTable prayerOffsets = $PrayerOffsetsTable(this);
  late final $MosquesTable mosques = $MosquesTable(this);
  late final $SchedulesTable schedules = $SchedulesTable(this);
  late final $SchedulePrayersTable schedulePrayers = $SchedulePrayersTable(
    this,
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    adhanAlertRows,
    prayerOffsets,
    mosques,
    schedules,
    schedulePrayers,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'mosques',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedules', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'schedules',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('schedule_prayers', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSettingRow,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSettingRow,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
          ),
          AppSettingRow,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String?> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AppSettingsTable, AppSettingRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AppSettingsTable,
                    AppSettingRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSettingRow,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSettingRow,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSettingRow>,
      ),
      AppSettingRow,
      PrefetchHooks Function()
    >;
typedef $$AdhanAlertRowsTableCreateCompanionBuilder =
    AdhanAlertRowsCompanion Function({
      required String prayer,
      Value<bool> enabled,
      Value<String?> soundOverride,
      Value<bool> vibrate,
      Value<int?> preAdhanMinutes,
      Value<bool> ringInSilent,
      Value<bool> preAdhanRingInSilent,
      Value<int> rowid,
    });
typedef $$AdhanAlertRowsTableUpdateCompanionBuilder =
    AdhanAlertRowsCompanion Function({
      Value<String> prayer,
      Value<bool> enabled,
      Value<String?> soundOverride,
      Value<bool> vibrate,
      Value<int?> preAdhanMinutes,
      Value<bool> ringInSilent,
      Value<bool> preAdhanRingInSilent,
      Value<int> rowid,
    });

class $$AdhanAlertRowsTableFilterComposer
    extends Composer<_$AppDatabase, $AdhanAlertRowsTable> {
  $$AdhanAlertRowsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get soundOverride => $composableBuilder(
    column: $table.soundOverride,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get vibrate => $composableBuilder(
    column: $table.vibrate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get preAdhanMinutes => $composableBuilder(
    column: $table.preAdhanMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get ringInSilent => $composableBuilder(
    column: $table.ringInSilent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get preAdhanRingInSilent => $composableBuilder(
    column: $table.preAdhanRingInSilent,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AdhanAlertRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $AdhanAlertRowsTable> {
  $$AdhanAlertRowsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get soundOverride => $composableBuilder(
    column: $table.soundOverride,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get vibrate => $composableBuilder(
    column: $table.vibrate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get preAdhanMinutes => $composableBuilder(
    column: $table.preAdhanMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get ringInSilent => $composableBuilder(
    column: $table.ringInSilent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get preAdhanRingInSilent => $composableBuilder(
    column: $table.preAdhanRingInSilent,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AdhanAlertRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AdhanAlertRowsTable> {
  $$AdhanAlertRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get soundOverride => $composableBuilder(
    column: $table.soundOverride,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get vibrate =>
      $composableBuilder(column: $table.vibrate, builder: (column) => column);

  GeneratedColumn<int> get preAdhanMinutes => $composableBuilder(
    column: $table.preAdhanMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get ringInSilent => $composableBuilder(
    column: $table.ringInSilent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get preAdhanRingInSilent => $composableBuilder(
    column: $table.preAdhanRingInSilent,
    builder: (column) => column,
  );
}

class $$AdhanAlertRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AdhanAlertRowsTable,
          AdhanAlertRow,
          $$AdhanAlertRowsTableFilterComposer,
          $$AdhanAlertRowsTableOrderingComposer,
          $$AdhanAlertRowsTableAnnotationComposer,
          $$AdhanAlertRowsTableCreateCompanionBuilder,
          $$AdhanAlertRowsTableUpdateCompanionBuilder,
          (
            AdhanAlertRow,
            BaseReferences<_$AppDatabase, $AdhanAlertRowsTable, AdhanAlertRow>,
          ),
          AdhanAlertRow,
          PrefetchHooks Function()
        > {
  $$AdhanAlertRowsTableTableManager(
    _$AppDatabase db,
    $AdhanAlertRowsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AdhanAlertRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AdhanAlertRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AdhanAlertRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> prayer = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> soundOverride = const Value.absent(),
                Value<bool> vibrate = const Value.absent(),
                Value<int?> preAdhanMinutes = const Value.absent(),
                Value<bool> ringInSilent = const Value.absent(),
                Value<bool> preAdhanRingInSilent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhanAlertRowsCompanion(
                prayer: prayer,
                enabled: enabled,
                soundOverride: soundOverride,
                vibrate: vibrate,
                preAdhanMinutes: preAdhanMinutes,
                ringInSilent: ringInSilent,
                preAdhanRingInSilent: preAdhanRingInSilent,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String prayer,
                Value<bool> enabled = const Value.absent(),
                Value<String?> soundOverride = const Value.absent(),
                Value<bool> vibrate = const Value.absent(),
                Value<int?> preAdhanMinutes = const Value.absent(),
                Value<bool> ringInSilent = const Value.absent(),
                Value<bool> preAdhanRingInSilent = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AdhanAlertRowsCompanion.insert(
                prayer: prayer,
                enabled: enabled,
                soundOverride: soundOverride,
                vibrate: vibrate,
                preAdhanMinutes: preAdhanMinutes,
                ringInSilent: ringInSilent,
                preAdhanRingInSilent: preAdhanRingInSilent,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AdhanAlertRowsTable, AdhanAlertRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AdhanAlertRowsTable,
                    AdhanAlertRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AdhanAlertRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AdhanAlertRowsTable,
      AdhanAlertRow,
      $$AdhanAlertRowsTableFilterComposer,
      $$AdhanAlertRowsTableOrderingComposer,
      $$AdhanAlertRowsTableAnnotationComposer,
      $$AdhanAlertRowsTableCreateCompanionBuilder,
      $$AdhanAlertRowsTableUpdateCompanionBuilder,
      (
        AdhanAlertRow,
        BaseReferences<_$AppDatabase, $AdhanAlertRowsTable, AdhanAlertRow>,
      ),
      AdhanAlertRow,
      PrefetchHooks Function()
    >;
typedef $$PrayerOffsetsTableCreateCompanionBuilder =
    PrayerOffsetsCompanion Function({
      required String prayer,
      Value<int> minutes,
      Value<int> rowid,
    });
typedef $$PrayerOffsetsTableUpdateCompanionBuilder =
    PrayerOffsetsCompanion Function({
      Value<String> prayer,
      Value<int> minutes,
      Value<int> rowid,
    });

class $$PrayerOffsetsTableFilterComposer
    extends Composer<_$AppDatabase, $PrayerOffsetsTable> {
  $$PrayerOffsetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnFilters(column),
  );
}

class $$PrayerOffsetsTableOrderingComposer
    extends Composer<_$AppDatabase, $PrayerOffsetsTable> {
  $$PrayerOffsetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get minutes => $composableBuilder(
    column: $table.minutes,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$PrayerOffsetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PrayerOffsetsTable> {
  $$PrayerOffsetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<int> get minutes =>
      $composableBuilder(column: $table.minutes, builder: (column) => column);
}

class $$PrayerOffsetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PrayerOffsetsTable,
          PrayerOffsetRow,
          $$PrayerOffsetsTableFilterComposer,
          $$PrayerOffsetsTableOrderingComposer,
          $$PrayerOffsetsTableAnnotationComposer,
          $$PrayerOffsetsTableCreateCompanionBuilder,
          $$PrayerOffsetsTableUpdateCompanionBuilder,
          (
            PrayerOffsetRow,
            BaseReferences<_$AppDatabase, $PrayerOffsetsTable, PrayerOffsetRow>,
          ),
          PrayerOffsetRow,
          PrefetchHooks Function()
        > {
  $$PrayerOffsetsTableTableManager(_$AppDatabase db, $PrayerOffsetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PrayerOffsetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PrayerOffsetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PrayerOffsetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> prayer = const Value.absent(),
                Value<int> minutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerOffsetsCompanion(
                prayer: prayer,
                minutes: minutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String prayer,
                Value<int> minutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PrayerOffsetsCompanion.insert(
                prayer: prayer,
                minutes: minutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PrayerOffsetsTable, PrayerOffsetRow>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $PrayerOffsetsTable,
                    PrayerOffsetRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$PrayerOffsetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PrayerOffsetsTable,
      PrayerOffsetRow,
      $$PrayerOffsetsTableFilterComposer,
      $$PrayerOffsetsTableOrderingComposer,
      $$PrayerOffsetsTableAnnotationComposer,
      $$PrayerOffsetsTableCreateCompanionBuilder,
      $$PrayerOffsetsTableUpdateCompanionBuilder,
      (
        PrayerOffsetRow,
        BaseReferences<_$AppDatabase, $PrayerOffsetsTable, PrayerOffsetRow>,
      ),
      PrayerOffsetRow,
      PrefetchHooks Function()
    >;
typedef $$MosquesTableCreateCompanionBuilder = MosquesCompanion Function({
  required String id,
  required String name,
  required String address,
  required String source,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeId,
  required int createdAt,
  Value<bool> remindersPaused,
  Value<int> rowid,
});
typedef $$MosquesTableUpdateCompanionBuilder = MosquesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String> address,
  Value<String> source,
  Value<double?> latitude,
  Value<double?> longitude,
  Value<String?> placeId,
  Value<int> createdAt,
  Value<bool> remindersPaused,
  Value<int> rowid,
});

final class $$MosquesTableReferences
    extends BaseReferences<_$AppDatabase, $MosquesTable, MosqueRow> {
  $$MosquesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SchedulesTable, List<ScheduleRow>>
  _schedulesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.schedules,
    aliasName: 'mosques__id__schedules__mosque_id',
  );

  $$SchedulesTableProcessedTableManager get schedulesRefs {
    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.mosqueId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_schedulesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MosquesTableFilterComposer
    extends Composer<_$AppDatabase, $MosquesTable> {
  $$MosquesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindersPaused => $composableBuilder(
    column: $table.remindersPaused,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> schedulesRefs(
    Expression<bool> Function($$SchedulesTableFilterComposer f) f,
  ) {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.mosqueId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MosquesTableOrderingComposer
    extends Composer<_$AppDatabase, $MosquesTable> {
  $$MosquesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get address => $composableBuilder(
    column: $table.address,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get latitude => $composableBuilder(
    column: $table.latitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get longitude => $composableBuilder(
    column: $table.longitude,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get placeId => $composableBuilder(
    column: $table.placeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindersPaused => $composableBuilder(
    column: $table.remindersPaused,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MosquesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MosquesTable> {
  $$MosquesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get address =>
      $composableBuilder(column: $table.address, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get placeId =>
      $composableBuilder(column: $table.placeId, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<bool> get remindersPaused => $composableBuilder(
    column: $table.remindersPaused,
    builder: (column) => column,
  );

  Expression<T> schedulesRefs<T extends Object>(
    Expression<T> Function($$SchedulesTableAnnotationComposer a) f,
  ) {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.mosqueId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MosquesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MosquesTable,
          MosqueRow,
          $$MosquesTableFilterComposer,
          $$MosquesTableOrderingComposer,
          $$MosquesTableAnnotationComposer,
          $$MosquesTableCreateCompanionBuilder,
          $$MosquesTableUpdateCompanionBuilder,
          (MosqueRow, $$MosquesTableReferences),
          MosqueRow,
          PrefetchHooks Function({bool schedulesRefs})
        > {
  $$MosquesTableTableManager(_$AppDatabase db, $MosquesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MosquesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MosquesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MosquesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> address = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> placeId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<bool> remindersPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MosquesCompanion(
                id: id,
                name: name,
                address: address,
                source: source,
                latitude: latitude,
                longitude: longitude,
                placeId: placeId,
                createdAt: createdAt,
                remindersPaused: remindersPaused,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                required String address,
                required String source,
                Value<double?> latitude = const Value.absent(),
                Value<double?> longitude = const Value.absent(),
                Value<String?> placeId = const Value.absent(),
                required int createdAt,
                Value<bool> remindersPaused = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MosquesCompanion.insert(
                id: id,
                name: name,
                address: address,
                source: source,
                latitude: latitude,
                longitude: longitude,
                placeId: placeId,
                createdAt: createdAt,
                remindersPaused: remindersPaused,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MosquesTable, MosqueRow>(table),
                  $$MosquesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({schedulesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (schedulesRefs) db.schedules],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (schedulesRefs)
                    await $_getPrefetchedData<
                      MosqueRow,
                      $MosquesTable,
                      ScheduleRow
                    >(
                      currentTable: table,
                      referencedTable: $$MosquesTableReferences
                          ._schedulesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MosquesTableReferences(db, table, p0).schedulesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.mosqueId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MosquesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MosquesTable,
      MosqueRow,
      $$MosquesTableFilterComposer,
      $$MosquesTableOrderingComposer,
      $$MosquesTableAnnotationComposer,
      $$MosquesTableCreateCompanionBuilder,
      $$MosquesTableUpdateCompanionBuilder,
      (MosqueRow, $$MosquesTableReferences),
      MosqueRow,
      PrefetchHooks Function({bool schedulesRefs})
    >;
typedef $$SchedulesTableCreateCompanionBuilder = SchedulesCompanion Function({
  required String id,
  required String mosqueId,
  Value<int?> effectiveFrom,
  required int updatedAt,
  Value<int?> jumuahMinutes,
  Value<bool> jumuahReminderEnabled,
  Value<int> jumuahReminderMinutesBefore,
  Value<int?> jumuahAfterAdhanMinutes,
  Value<int> rowid,
});
typedef $$SchedulesTableUpdateCompanionBuilder = SchedulesCompanion Function({
  Value<String> id,
  Value<String> mosqueId,
  Value<int?> effectiveFrom,
  Value<int> updatedAt,
  Value<int?> jumuahMinutes,
  Value<bool> jumuahReminderEnabled,
  Value<int> jumuahReminderMinutesBefore,
  Value<int?> jumuahAfterAdhanMinutes,
  Value<int> rowid,
});

final class $$SchedulesTableReferences
    extends BaseReferences<_$AppDatabase, $SchedulesTable, ScheduleRow> {
  $$SchedulesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MosquesTable _mosqueIdTable(_$AppDatabase db) =>
      db.mosques.createAlias('schedules__mosque_id__mosques__id');

  $$MosquesTableProcessedTableManager get mosqueId {
    final $_column = $_itemColumn<String>('mosque_id')!;

    final manager = $$MosquesTableTableManager(
      $_db,
      $_db.mosques,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_mosqueIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SchedulePrayersTable, List<SchedulePrayerRow>>
  _schedulePrayersRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.schedulePrayers,
    aliasName: 'schedules__id__schedule_prayers__schedule_id',
  );

  $$SchedulePrayersTableProcessedTableManager get schedulePrayersRefs {
    final manager = $$SchedulePrayersTableTableManager(
      $_db,
      $_db.schedulePrayers,
    ).filter((f) => f.scheduleId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _schedulePrayersRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SchedulesTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumuahMinutes => $composableBuilder(
    column: $table.jumuahMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get jumuahReminderEnabled => $composableBuilder(
    column: $table.jumuahReminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumuahReminderMinutesBefore => $composableBuilder(
    column: $table.jumuahReminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get jumuahAfterAdhanMinutes => $composableBuilder(
    column: $table.jumuahAfterAdhanMinutes,
    builder: (column) => ColumnFilters(column),
  );

  $$MosquesTableFilterComposer get mosqueId {
    final $$MosquesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mosqueId,
      referencedTable: $db.mosques,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MosquesTableFilterComposer(
            $db: $db,
            $table: $db.mosques,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> schedulePrayersRefs(
    Expression<bool> Function($$SchedulePrayersTableFilterComposer f) f,
  ) {
    final $$SchedulePrayersTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedulePrayers,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulePrayersTableFilterComposer(
            $db: $db,
            $table: $db.schedulePrayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchedulesTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumuahMinutes => $composableBuilder(
    column: $table.jumuahMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get jumuahReminderEnabled => $composableBuilder(
    column: $table.jumuahReminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumuahReminderMinutesBefore => $composableBuilder(
    column: $table.jumuahReminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get jumuahAfterAdhanMinutes => $composableBuilder(
    column: $table.jumuahAfterAdhanMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  $$MosquesTableOrderingComposer get mosqueId {
    final $$MosquesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mosqueId,
      referencedTable: $db.mosques,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MosquesTableOrderingComposer(
            $db: $db,
            $table: $db.mosques,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulesTable> {
  $$SchedulesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get effectiveFrom => $composableBuilder(
    column: $table.effectiveFrom,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get jumuahMinutes => $composableBuilder(
    column: $table.jumuahMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get jumuahReminderEnabled => $composableBuilder(
    column: $table.jumuahReminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jumuahReminderMinutesBefore => $composableBuilder(
    column: $table.jumuahReminderMinutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get jumuahAfterAdhanMinutes => $composableBuilder(
    column: $table.jumuahAfterAdhanMinutes,
    builder: (column) => column,
  );

  $$MosquesTableAnnotationComposer get mosqueId {
    final $$MosquesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.mosqueId,
      referencedTable: $db.mosques,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MosquesTableAnnotationComposer(
            $db: $db,
            $table: $db.mosques,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> schedulePrayersRefs<T extends Object>(
    Expression<T> Function($$SchedulePrayersTableAnnotationComposer a) f,
  ) {
    final $$SchedulePrayersTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.schedulePrayers,
      getReferencedColumn: (t) => t.scheduleId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulePrayersTableAnnotationComposer(
            $db: $db,
            $table: $db.schedulePrayers,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SchedulesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulesTable,
          ScheduleRow,
          $$SchedulesTableFilterComposer,
          $$SchedulesTableOrderingComposer,
          $$SchedulesTableAnnotationComposer,
          $$SchedulesTableCreateCompanionBuilder,
          $$SchedulesTableUpdateCompanionBuilder,
          (ScheduleRow, $$SchedulesTableReferences),
          ScheduleRow,
          PrefetchHooks Function({bool mosqueId, bool schedulePrayersRefs})
        > {
  $$SchedulesTableTableManager(_$AppDatabase db, $SchedulesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> mosqueId = const Value.absent(),
                Value<int?> effectiveFrom = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int?> jumuahMinutes = const Value.absent(),
                Value<bool> jumuahReminderEnabled = const Value.absent(),
                Value<int> jumuahReminderMinutesBefore = const Value.absent(),
                Value<int?> jumuahAfterAdhanMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion(
                id: id,
                mosqueId: mosqueId,
                effectiveFrom: effectiveFrom,
                updatedAt: updatedAt,
                jumuahMinutes: jumuahMinutes,
                jumuahReminderEnabled: jumuahReminderEnabled,
                jumuahReminderMinutesBefore: jumuahReminderMinutesBefore,
                jumuahAfterAdhanMinutes: jumuahAfterAdhanMinutes,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String mosqueId,
                Value<int?> effectiveFrom = const Value.absent(),
                required int updatedAt,
                Value<int?> jumuahMinutes = const Value.absent(),
                Value<bool> jumuahReminderEnabled = const Value.absent(),
                Value<int> jumuahReminderMinutesBefore = const Value.absent(),
                Value<int?> jumuahAfterAdhanMinutes = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulesCompanion.insert(
                id: id,
                mosqueId: mosqueId,
                effectiveFrom: effectiveFrom,
                updatedAt: updatedAt,
                jumuahMinutes: jumuahMinutes,
                jumuahReminderEnabled: jumuahReminderEnabled,
                jumuahReminderMinutesBefore: jumuahReminderMinutesBefore,
                jumuahAfterAdhanMinutes: jumuahAfterAdhanMinutes,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchedulesTable, ScheduleRow>(table),
                  $$SchedulesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({mosqueId = false, schedulePrayersRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (schedulePrayersRefs) db.schedulePrayers,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (mosqueId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.mosqueId,
                            referencedTable: $$SchedulesTableReferences
                                ._mosqueIdTable(db),
                            referencedColumn: $$SchedulesTableReferences
                                ._mosqueIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (schedulePrayersRefs)
                        await $_getPrefetchedData<
                          ScheduleRow,
                          $SchedulesTable,
                          SchedulePrayerRow
                        >(
                          currentTable: table,
                          referencedTable: $$SchedulesTableReferences
                              ._schedulePrayersRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SchedulesTableReferences(
                                db,
                                table,
                                p0,
                              ).schedulePrayersRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$SchedulesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulesTable,
      ScheduleRow,
      $$SchedulesTableFilterComposer,
      $$SchedulesTableOrderingComposer,
      $$SchedulesTableAnnotationComposer,
      $$SchedulesTableCreateCompanionBuilder,
      $$SchedulesTableUpdateCompanionBuilder,
      (ScheduleRow, $$SchedulesTableReferences),
      ScheduleRow,
      PrefetchHooks Function({bool mosqueId, bool schedulePrayersRefs})
    >;
typedef $$SchedulePrayersTableCreateCompanionBuilder =
    SchedulePrayersCompanion Function({
      required String scheduleId,
      required String prayer,
      Value<int?> iqamaMinutes,
      Value<int?> iqamaAfterAdhanMinutes,
      Value<bool> reminderEnabled,
      Value<int> reminderMinutesBefore,
      Value<int> rowid,
    });
typedef $$SchedulePrayersTableUpdateCompanionBuilder =
    SchedulePrayersCompanion Function({
      Value<String> scheduleId,
      Value<String> prayer,
      Value<int?> iqamaMinutes,
      Value<int?> iqamaAfterAdhanMinutes,
      Value<bool> reminderEnabled,
      Value<int> reminderMinutesBefore,
      Value<int> rowid,
    });

final class $$SchedulePrayersTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $SchedulePrayersTable,
          SchedulePrayerRow
        > {
  $$SchedulePrayersTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $SchedulesTable _scheduleIdTable(_$AppDatabase db) =>
      db.schedules.createAlias('schedule_prayers__schedule_id__schedules__id');

  $$SchedulesTableProcessedTableManager get scheduleId {
    final $_column = $_itemColumn<String>('schedule_id')!;

    final manager = $$SchedulesTableTableManager(
      $_db,
      $_db.schedules,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SchedulePrayersTableFilterComposer
    extends Composer<_$AppDatabase, $SchedulePrayersTable> {
  $$SchedulePrayersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iqamaMinutes => $composableBuilder(
    column: $table.iqamaMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get iqamaAfterAdhanMinutes => $composableBuilder(
    column: $table.iqamaAfterAdhanMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  $$SchedulesTableFilterComposer get scheduleId {
    final $$SchedulesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableFilterComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulePrayersTableOrderingComposer
    extends Composer<_$AppDatabase, $SchedulePrayersTable> {
  $$SchedulePrayersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get prayer => $composableBuilder(
    column: $table.prayer,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iqamaMinutes => $composableBuilder(
    column: $table.iqamaMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get iqamaAfterAdhanMinutes => $composableBuilder(
    column: $table.iqamaAfterAdhanMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  $$SchedulesTableOrderingComposer get scheduleId {
    final $$SchedulesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableOrderingComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulePrayersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SchedulePrayersTable> {
  $$SchedulePrayersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get prayer =>
      $composableBuilder(column: $table.prayer, builder: (column) => column);

  GeneratedColumn<int> get iqamaMinutes => $composableBuilder(
    column: $table.iqamaMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get iqamaAfterAdhanMinutes => $composableBuilder(
    column: $table.iqamaAfterAdhanMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get reminderEnabled => $composableBuilder(
    column: $table.reminderEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  $$SchedulesTableAnnotationComposer get scheduleId {
    final $$SchedulesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.scheduleId,
      referencedTable: $db.schedules,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SchedulesTableAnnotationComposer(
            $db: $db,
            $table: $db.schedules,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SchedulePrayersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SchedulePrayersTable,
          SchedulePrayerRow,
          $$SchedulePrayersTableFilterComposer,
          $$SchedulePrayersTableOrderingComposer,
          $$SchedulePrayersTableAnnotationComposer,
          $$SchedulePrayersTableCreateCompanionBuilder,
          $$SchedulePrayersTableUpdateCompanionBuilder,
          (SchedulePrayerRow, $$SchedulePrayersTableReferences),
          SchedulePrayerRow,
          PrefetchHooks Function({bool scheduleId})
        > {
  $$SchedulePrayersTableTableManager(
    _$AppDatabase db,
    $SchedulePrayersTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SchedulePrayersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SchedulePrayersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SchedulePrayersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> scheduleId = const Value.absent(),
                Value<String> prayer = const Value.absent(),
                Value<int?> iqamaMinutes = const Value.absent(),
                Value<int?> iqamaAfterAdhanMinutes = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderMinutesBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulePrayersCompanion(
                scheduleId: scheduleId,
                prayer: prayer,
                iqamaMinutes: iqamaMinutes,
                iqamaAfterAdhanMinutes: iqamaAfterAdhanMinutes,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String scheduleId,
                required String prayer,
                Value<int?> iqamaMinutes = const Value.absent(),
                Value<int?> iqamaAfterAdhanMinutes = const Value.absent(),
                Value<bool> reminderEnabled = const Value.absent(),
                Value<int> reminderMinutesBefore = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SchedulePrayersCompanion.insert(
                scheduleId: scheduleId,
                prayer: prayer,
                iqamaMinutes: iqamaMinutes,
                iqamaAfterAdhanMinutes: iqamaAfterAdhanMinutes,
                reminderEnabled: reminderEnabled,
                reminderMinutesBefore: reminderMinutesBefore,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SchedulePrayersTable, SchedulePrayerRow>(table),
                  $$SchedulePrayersTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.scheduleId,
                        referencedTable: $$SchedulePrayersTableReferences
                            ._scheduleIdTable(db),
                        referencedColumn: $$SchedulePrayersTableReferences
                            ._scheduleIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SchedulePrayersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SchedulePrayersTable,
      SchedulePrayerRow,
      $$SchedulePrayersTableFilterComposer,
      $$SchedulePrayersTableOrderingComposer,
      $$SchedulePrayersTableAnnotationComposer,
      $$SchedulePrayersTableCreateCompanionBuilder,
      $$SchedulePrayersTableUpdateCompanionBuilder,
      (SchedulePrayerRow, $$SchedulePrayersTableReferences),
      SchedulePrayerRow,
      PrefetchHooks Function({bool scheduleId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$AdhanAlertRowsTableTableManager get adhanAlertRows =>
      $$AdhanAlertRowsTableTableManager(_db, _db.adhanAlertRows);
  $$PrayerOffsetsTableTableManager get prayerOffsets =>
      $$PrayerOffsetsTableTableManager(_db, _db.prayerOffsets);
  $$MosquesTableTableManager get mosques =>
      $$MosquesTableTableManager(_db, _db.mosques);
  $$SchedulesTableTableManager get schedules =>
      $$SchedulesTableTableManager(_db, _db.schedules);
  $$SchedulePrayersTableTableManager get schedulePrayers =>
      $$SchedulePrayersTableTableManager(_db, _db.schedulePrayers);
}
