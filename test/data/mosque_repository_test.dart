import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:awqaity/src/data/app_database.dart';
import 'package:awqaity/src/data/mosque_repository.dart';
import 'package:awqaity/src/data/settings_repository.dart';
import 'package:awqaity/src/domain/mosque.dart';
import 'package:awqaity/src/domain/prayer.dart';
import 'package:awqaity/src/domain/time_model.dart';
import '../helpers/fake_clock.dart';

void main() {
  late AppDatabase db;
  late MosqueRepository mosques;
  late SettingsRepository settings;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mosques = MosqueRepository(db);
    settings = SettingsRepository(db);
  });

  tearDown(() => db.close());

  group('adding a mosque', () {
    test('starts with every Iqama time not configured', () async {
      final added = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );

      final stored = await mosques.byId(added.id);
      expect(stored, isNotNull);
      expect(stored!.schedules, hasLength(1));
      expect(stored.schedules.single.configuredCount, 0);
      for (final prayer in Prayer.iqamaPrayers) {
        expect(
          stored.scheduleFor(LocalDay.fromDateTime(DateTime.now()))!
              .iqamaFor(prayer)
              .isConfigured,
          isFalse,
          reason: 'AGENTS.md: a new mosque never gets invented Iqama times',
        );
      }
    });

    test('has no Iqama row for sunrise at all', () async {
      final added = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );

      final stored = await mosques.byId(added.id);
      expect(
        stored!.schedules.single.prayers.keys,
        isNot(contains(Prayer.sunrise)),
      );
    });

    test('keeps coordinates and the provider place id when present', () async {
      final added = await mosques.add(
        name: 'Central Mosque',
        address: '9 King Street',
        source: MosqueSource.google,
        latitude: 51.5,
        longitude: -0.12,
        placeId: 'place-123',
      );

      final stored = await mosques.byId(added.id);
      expect(stored!.source, MosqueSource.google);
      expect(stored.latitude, 51.5);
      expect(stored.placeId, 'place-123');
      expect(stored.hasLocation, isTrue);
    });

    test('a mosque added without coordinates still saves', () async {
      final added = await mosques.add(
        name: 'Small Musalla',
        address: 'No fixed address',
        source: MosqueSource.manual,
      );

      expect((await mosques.byId(added.id))!.hasLocation, isFalse);
    });
  });

  group('editing Iqama times', () {
    late String mosqueId;

    setUp(() async {
      mosqueId = (await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      )).id;
    });

    test('a configured time reads back as the same local time of day', () async {
      await mosques.setIqama(mosqueId, Prayer.fajr, LocalTime.of(5, 40));

      final stored = await mosques.byId(mosqueId);
      final entry = stored!.scheduleFor(LocalDay.fromDateTime(DateTime.now()))!
          .iqamaFor(Prayer.fajr);
      expect(entry.iqama, LocalTime.of(5, 40));
      expect(entry.isConfigured, isTrue);
      expect(stored.schedules.single.configuredCount, 1);
    });

    test('saving stamps the schedule so the UI can say when it was set',
        () async {
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      await mosques.setIqama(mosqueId, Prayer.dhuhr, LocalTime.of(13, 15));

      final stored = await mosques.byId(mosqueId);
      expect(
        stored!.schedules.single.updatedAt.isAfter(before),
        isTrue,
        reason: 'AGENTS.md: "Set by you · last updated <date>"',
      );
    });

    test('a reminder only exists alongside a configured time', () async {
      await mosques.setIqama(
        mosqueId,
        Prayer.asr,
        LocalTime.of(16, 0),
        reminderEnabled: true,
        reminderMinutesBefore: 15,
      );

      final entry = (await mosques.byId(mosqueId))!
          .schedules
          .single
          .iqamaFor(Prayer.asr);
      expect(entry.hasReminder, isTrue);
      expect(entry.reminderMinutesBefore, 15);
    });

    test('clearing a time also clears its reminder', () async {
      await mosques.setIqama(
        mosqueId,
        Prayer.maghrib,
        LocalTime.of(18, 30),
        reminderEnabled: true,
      );
      await mosques.setIqama(mosqueId, Prayer.maghrib, null);

      final entry = (await mosques.byId(mosqueId))!
          .schedules
          .single
          .iqamaFor(Prayer.maghrib);
      expect(entry.isConfigured, isFalse);
      expect(entry.reminderEnabled, isFalse);
      expect(
        entry.hasReminder,
        isFalse,
        reason: 'AGENTS.md: a reminder can never exist without an Iqama time',
      );
    });

    test('sunrise is refused before it reaches storage', () async {
      expect(
        () => mosques.setIqama(mosqueId, Prayer.sunrise, LocalTime.of(6, 55)),
        throwsA(isA<IqamaNotAllowedException>()),
      );

      // Nothing half-written should be stored.
      final rows = await db.select(db.schedulePrayers).get();
      expect(rows.where((r) => r.prayer == 'sunrise'), isEmpty);
    });
  });

  group('schedules over dates', () {
    test('the dated schedule in force wins over the undated one', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      final current = mosque.schedules.single;
      final winter = Schedule.empty(
        mosqueId: mosque.id,
        effectiveFrom: LocalDay(2026, 12, 1),
      ).withPrayer(
        const PrayerIqama(
          prayer: Prayer.fajr,
          iqama: LocalTime(360),
        ),
      );
      await mosques.save(mosque.copyWith(schedules: [current, winter]));

      expect(
        (await mosques.byId(mosque.id))!
            .scheduleFor(LocalDay(2026, 10, 12))!
            .iqamaFor(Prayer.fajr)
            .isConfigured,
        isFalse,
      );
      expect(
        (await mosques.byId(mosque.id))!
            .scheduleFor(LocalDay(2026, 12, 2))!
            .iqamaFor(Prayer.fajr)
            .iqama,
        const LocalTime(360),
      );
    });
  });

  group('the clock a write is stamped with', () {
    /// The repository on a clock the test owns, so neither the day it resolves nor
    /// the stamp it writes depends on when the suite happened to run.
    MosqueRepository onClock(DateTime instant) =>
        MosqueRepository(db, clock: FixedClock(instant));

    test('the schedule stamp is the injected clock', () async {
      final instant = DateTime.utc(2026, 10, 12, 9, 30);
      final added = await onClock(instant).add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      final updated = await onClock(
        instant,
      ).setIqama(added.id, Prayer.fajr, LocalTime.of(5, 40));

      expect(
        updated.updatedAt,
        instant,
        reason: 'AGENTS.md: "Set by you · last updated <date>" must be readable '
            'and reproducible, which a wall-clock read of the test machine is not',
      );

      final stored = await onClock(instant).byId(added.id);
      expect(
        stored!.schedules.single.updatedAt.millisecondsSinceEpoch,
        instant.millisecondsSinceEpoch,
        reason: 'the stamp survives the round trip through storage',
      );
    });

    test('the write lands on the schedule in force on the clock\'s day', () async {
      final seeded = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      final ramadan = Schedule.empty(
        mosqueId: seeded.id,
        effectiveFrom: const LocalDay(2027, 1, 1),
      );
      await mosques.save(
        seeded.copyWith(schedules: [seeded.schedules.single, ramadan]),
      );

      // Editing on a June 2027 day: the dated schedule is the one in force then, so
      // that is the one the entry belongs to — not whatever the device's own date
      // happened to be when the suite ran.
      final future = onClock(DateTime.utc(2027, 6, 1, 12, 0));
      await future.setIqama(seeded.id, Prayer.fajr, LocalTime.of(5, 5));

      final stored = await future.byId(seeded.id);
      expect(
        stored!
            .scheduleFor(const LocalDay(2027, 6, 1))!
            .iqamaFor(Prayer.fajr)
            .iqama,
        const LocalTime(5 * 60 + 5),
      );
      expect(
        stored
            .scheduleFor(const LocalDay(2026, 10, 12))!
            .iqamaFor(Prayer.fajr)
            .isConfigured,
        isFalse,
        reason: 'the schedule before Ramadan was left alone',
      );
    });
  });

  group('deleting', () {
    test('clears the active mosque setting', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      await settings.setActiveMosqueId(mosque.id);
      expect((await settings.read()).activeMosqueId, mosque.id);

      await mosques.delete(mosque.id);

      expect((await settings.read()).activeMosqueId, isNull);
      expect(await mosques.saved(), isEmpty);
    });

    test('leaves another mosque active', () async {
      final first = await mosques.add(
        name: 'First',
        address: 'a',
        source: MosqueSource.manual,
      );
      final second = await mosques.add(
        name: 'Second',
        address: 'b',
        source: MosqueSource.manual,
      );
      await settings.setActiveMosqueId(second.id);

      await mosques.delete(first.id);

      expect((await settings.read()).activeMosqueId, second.id);
    });

    test('a mosque whose id is unknown deletes quietly', () async {
      await mosques.delete('nope');
      expect(await mosques.saved(), isEmpty);
    });
  });

  group('listing', () {
    test('saved returns newest first with their Iqama counts', () async {
      final older = await mosques.add(
        name: 'Older',
        address: 'a',
        source: MosqueSource.manual,
      );
      final newer = await mosques.add(
        name: 'Newer',
        address: 'b',
        source: MosqueSource.osm,
      );
      await mosques.setIqama(newer.id, Prayer.fajr, LocalTime.of(5, 30));
      await mosques.setIqama(newer.id, Prayer.isha, LocalTime.of(20, 15));

      final list = await mosques.saved();
      expect(list.map((m) => m.id), [newer.id, older.id]);
      expect(list.first.schedules.single.configuredCount, 2);
      expect(list.last.schedules.single.configuredCount, 0);
    });

    test('watchSaved re-emits when a mosque is added', () async {
      final seen = <List<Mosque>>[];
      final sub = mosques.watchSaved().listen(seen.add);
      await Future<void>.delayed(Duration.zero);

      await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      await Future<void>.delayed(Duration.zero);
      await sub.cancel();

      expect(seen.first, isEmpty);
      expect(seen.last, hasLength(1));
    });
  });
}
