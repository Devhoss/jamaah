import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';
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

    test('mosques added on the same instant keep the newest first', () async {
      final sameInstant = MosqueRepository(
        db,
        clock: FixedClock(DateTime.utc(2026, 10, 13, 9)),
      );
      final first = await sameInstant.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );
      final second = await sameInstant.add(
        name: 'Second',
        address: '',
        source: MosqueSource.manual,
      );

      expect((await sameInstant.saved()).map((m) => m.id), [
        second.id,
        first.id,
      ]);
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

    /// Today reads the active mosque from this stream, so an Iqama edit that did
    /// not re-emit would leave the card showing the old time until a restart.
    Future<List<List<Mosque>>> emissionsDuring(
      Future<void> Function() change,
    ) async {
      final seen = <List<Mosque>>[];
      final sub = mosques.watchSaved().listen(seen.add);
      await pumpEventQueue();
      final before = seen.length;
      await change();
      await pumpEventQueue();
      await sub.cancel();
      return seen.sublist(before);
    }

    test('watchSaved re-emits on every change, not just the first', () async {
      final first = await mosques.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );

      final afterSecond = await emissionsDuring(
        () => mosques.add(name: 'Second', address: '', source: MosqueSource.manual),
      );
      expect(afterSecond.last, hasLength(2));

      final afterEdit = await emissionsDuring(
        () => mosques.setIqama(first.id, Prayer.isha, LocalTime.of(20, 0)),
      );
      expect(
        afterEdit.last
            .singleWhere((m) => m.id == first.id)
            .schedules
            .single
            .iqamaFor(Prayer.isha)
            .iqama,
        LocalTime.of(20, 0),
      );
    });

    test('one subscription sees a second change too', () async {
      final seen = <List<Mosque>>[];
      final sub = mosques.watchSaved().listen(seen.add);
      await pumpEventQueue();

      await mosques.add(name: 'First', address: '', source: MosqueSource.manual);
      await pumpEventQueue();
      await mosques.add(name: 'Second', address: '', source: MosqueSource.manual);
      await pumpEventQueue();
      await sub.cancel();

      expect(seen.last, hasLength(2));
    });

    test('watchSaved re-emits when an Iqama time changes', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      );

      final after = await emissionsDuring(
        () => mosques.setIqama(mosque.id, Prayer.fajr, LocalTime.of(5, 40)),
      );

      expect(after, isNotEmpty);
      expect(
        after.last.single.schedules.single.iqamaFor(Prayer.fajr).iqama,
        LocalTime.of(5, 40),
      );
    });

    test('watchSaved re-emits when a reminder is toggled', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(mosque.id, Prayer.asr, LocalTime.of(16, 0));

      final after = await emissionsDuring(
        () => mosques.setReminderEnabled(mosque.id, Prayer.asr, enabled: true),
      );

      expect(
        after.last.single.schedules.single.iqamaFor(Prayer.asr).hasReminder,
        isTrue,
      );
    });

    test('watchSaved re-emits when the name changes', () async {
      final mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      );

      final after = await emissionsDuring(
        () => mosques.updateDetails(mosque.id, name: 'Al-Nasr', address: ''),
      );

      expect(after.last.single.name, 'Al-Nasr');
    });

    test('watchSaved lists newest first, like saved', () async {
      final older = await mosques.add(
        name: 'Older',
        address: '',
        source: MosqueSource.manual,
      );
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final newer = await mosques.add(
        name: 'Newer',
        address: '',
        source: MosqueSource.manual,
      );

      final first = await mosques.watchSaved().first;
      expect(first.map((m) => m.id), [newer.id, older.id]);
    });
  });

  group('finding a saved mosque by its provider id', () {
    test('a saved search result is found by its place id', () async {
      final added = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.google,
        placeId: 'ChIJ-example',
      );
      expect((await mosques.byPlaceId('ChIJ-example'))?.id, added.id);
    });

    test('an unknown place id finds nothing', () async {
      await mosques.add(
        name: 'By hand',
        address: '',
        source: MosqueSource.manual,
      );
      expect(await mosques.byPlaceId('ChIJ-other'), isNull);
    });
  });

  group('adding by hand', () {
    test('the name and address are trimmed', () async {
      final added = await mosques.add(
        name: '  Masjid al-Nasr ',
        address: ' 1 Example Road  ',
        source: MosqueSource.manual,
      );

      final stored = await mosques.byId(added.id);
      expect(stored!.name, 'Masjid al-Nasr');
      expect(stored.address, '1 Example Road');
    });

    test('a blank name is refused and nothing is stored', () async {
      await expectLater(
        mosques.add(name: '   ', address: 'x', source: MosqueSource.manual),
        throwsArgumentError,
      );
      expect(await mosques.saved(), isEmpty);
    });

    test('the created and schedule stamps come from the injected clock',
        () async {
      final instant = DateTime.utc(2026, 10, 13, 8, 15);
      final repo = MosqueRepository(db, clock: FixedClock(instant));

      final added = await repo.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      );

      final stored = await repo.byId(added.id);
      expect(
        stored!.createdAt.millisecondsSinceEpoch,
        instant.millisecondsSinceEpoch,
      );
      expect(
        stored.schedules.single.updatedAt.millisecondsSinceEpoch,
        instant.millisecondsSinceEpoch,
      );
    });

    test('the first mosque saved becomes the active one', () async {
      final added = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      );

      expect(
        (await settings.read()).activeMosqueId,
        added.id,
        reason: 'the prototype makes the first saved mosque active, so Today '
            'has a mosque to read without an extra step',
      );
    });

    test('a later mosque does not take over the active one', () async {
      final first = await mosques.add(
        name: 'First',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.add(
        name: 'Second',
        address: '',
        source: MosqueSource.manual,
      );

      expect((await settings.read()).activeMosqueId, first.id);
    });
  });

  group('editing name and address', () {
    late Mosque mosque;

    setUp(() async {
      mosque = await mosques.add(
        name: 'Masjid al-Nasr',
        address: '1 Example Road',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(
        mosque.id,
        Prayer.fajr,
        LocalTime.of(5, 40),
        reminderEnabled: true,
        reminderMinutesBefore: 15,
      );
    });

    test('changes the details and keeps every Iqama entry', () async {
      await mosques.updateDetails(
        mosque.id,
        name: ' Al-Nasr Mosque ',
        address: ' 2 Other Street ',
      );

      final stored = await mosques.byId(mosque.id);
      expect(stored!.name, 'Al-Nasr Mosque');
      expect(stored.address, '2 Other Street');
      final fajr = stored.schedules.single.iqamaFor(Prayer.fajr);
      expect(fajr.iqama, LocalTime.of(5, 40));
      expect(fajr.hasReminder, isTrue);
      expect(fajr.reminderMinutesBefore, 15);
    });

    test('keeps a dated schedule the UI does not show', () async {
      final stored = (await mosques.byId(mosque.id))!;
      final winter = Schedule.empty(
        mosqueId: mosque.id,
        effectiveFrom: const LocalDay(2027, 1, 1),
      );
      await mosques.save(
        stored.copyWith(schedules: [...stored.schedules, winter]),
      );

      await mosques.updateDetails(mosque.id, name: 'Renamed', address: '');

      expect((await mosques.byId(mosque.id))!.schedules, hasLength(2));
    });

    test('a blank name is refused and the old one stays', () async {
      await expectLater(
        mosques.updateDetails(mosque.id, name: '  ', address: ''),
        throwsArgumentError,
      );
      expect((await mosques.byId(mosque.id))!.name, 'Masjid al-Nasr');
    });

    test('an unknown mosque is an error, not a silent no-op', () async {
      await expectLater(
        mosques.updateDetails('nope', name: 'x', address: ''),
        throwsArgumentError,
      );
    });
  });

  group('the quick reminder toggle', () {
    late String mosqueId;

    setUp(() async {
      mosqueId = (await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      )).id;
    });

    test('turns a reminder on and keeps the time and interval', () async {
      await mosques.setIqama(
        mosqueId,
        Prayer.maghrib,
        LocalTime.of(18, 30),
        reminderMinutesBefore: 5,
      );

      await mosques.setReminderEnabled(mosqueId, Prayer.maghrib, enabled: true);

      final entry = (await mosques.byId(mosqueId))!
          .schedules
          .single
          .iqamaFor(Prayer.maghrib);
      expect(entry.iqama, LocalTime.of(18, 30));
      expect(entry.reminderEnabled, isTrue);
      expect(entry.reminderMinutesBefore, 5);
    });

    test('turns a reminder off and keeps the time', () async {
      await mosques.setIqama(
        mosqueId,
        Prayer.maghrib,
        LocalTime.of(18, 30),
        reminderEnabled: true,
      );

      await mosques.setReminderEnabled(
        mosqueId,
        Prayer.maghrib,
        enabled: false,
      );

      final entry = (await mosques.byId(mosqueId))!
          .schedules
          .single
          .iqamaFor(Prayer.maghrib);
      expect(entry.iqama, LocalTime.of(18, 30));
      expect(entry.reminderEnabled, isFalse);
    });

    test('refuses to turn on a reminder for an unconfigured prayer', () async {
      await expectLater(
        mosques.setReminderEnabled(mosqueId, Prayer.isha, enabled: true),
        throwsA(isA<ReminderWithoutIqamaException>()),
      );
      expect(
        (await mosques.byId(mosqueId))!
            .schedules
            .single
            .iqamaFor(Prayer.isha)
            .reminderEnabled,
        isFalse,
        reason: 'AGENTS.md: a reminder never exists without an Iqama time',
      );
    });

    test('sunrise is refused', () async {
      await expectLater(
        mosques.setReminderEnabled(mosqueId, Prayer.sunrise, enabled: true),
        throwsA(isA<IqamaNotAllowedException>()),
      );
    });

    test('stamps the schedule with the injected clock', () async {
      await mosques.setIqama(mosqueId, Prayer.asr, LocalTime.of(16, 0));
      final instant = DateTime.utc(2026, 10, 13, 12, 0);

      await MosqueRepository(
        db,
        clock: FixedClock(instant),
      ).setReminderEnabled(mosqueId, Prayer.asr, enabled: true);

      expect(
        (await mosques.byId(mosqueId))!
            .schedules
            .single
            .updatedAt
            .millisecondsSinceEpoch,
        instant.millisecondsSinceEpoch,
      );
    });
  });

  group('reminder interval bounds', () {
    late String mosqueId;

    setUp(() async {
      mosqueId = (await mosques.add(
        name: 'Masjid al-Nasr',
        address: '',
        source: MosqueSource.manual,
      )).id;
    });

    test('1 and 120 minutes are accepted', () async {
      await mosques.setIqama(
        mosqueId,
        Prayer.fajr,
        LocalTime.of(5, 0),
        reminderEnabled: true,
        reminderMinutesBefore: 1,
      );
      await mosques.setIqama(
        mosqueId,
        Prayer.isha,
        LocalTime.of(20, 0),
        reminderEnabled: true,
        reminderMinutesBefore: 120,
      );
    });

    test('0 and 121 minutes are refused before they are stored', () async {
      for (final minutes in [0, 121, -10]) {
        await expectLater(
          mosques.setIqama(
            mosqueId,
            Prayer.fajr,
            LocalTime.of(5, 0),
            reminderEnabled: true,
            reminderMinutesBefore: minutes,
          ),
          throwsArgumentError,
        );
      }
      expect(
        (await mosques.byId(mosqueId))!
            .schedules
            .single
            .iqamaFor(Prayer.fajr)
            .isConfigured,
        isFalse,
      );
    });
  });

  group('pausing a mosque\'s reminders', () {
    test('a new mosque is not paused; the pause round-trips', () async {
      final m = await mosques.add(
        name: 'Masjid',
        address: '',
        source: MosqueSource.manual,
      );
      expect(m.remindersPaused, isFalse);

      await mosques.setRemindersPaused(m.id, paused: true);
      expect((await mosques.saved()).single.remindersPaused, isTrue);

      await mosques.setRemindersPaused(m.id, paused: false);
      expect((await mosques.saved()).single.remindersPaused, isFalse);
    });

    test('pausing keeps the Iqama times and reminder settings', () async {
      final m = await mosques.add(
        name: 'Masjid',
        address: '',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(
        m.id,
        Prayer.fajr,
        LocalTime.of(5, 30),
        reminderEnabled: true,
      );
      final before = (await mosques.saved()).single.schedules;
      await mosques.setRemindersPaused(m.id, paused: true);
      expect((await mosques.saved()).single.schedules, before);
    });

    test('an unknown mosque is a programming error', () {
      expect(
        mosques.setRemindersPaused('nope', paused: true),
        throwsArgumentError,
      );
    });
  });
}
