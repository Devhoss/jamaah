import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/clock.dart';
import 'package:jamaah/src/app/providers.dart';
import 'package:jamaah/src/data/app_database.dart';
import 'package:jamaah/src/data/mosque_repository.dart';
import 'package:jamaah/src/data/settings_repository.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_parameters.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/today.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// The wiring between the domain's injected clock and the stored settings: which
/// day the app reads, and which mosque's Iqama belongs on the card.
void main() {
  // Without the database every zone name falls back to the device's own clock,
  // which would make the "the day is the place's" test answer with the wrong day.
  setUpAll(loadTimeZoneDatabase);

  late AppDatabase db;
  late SettingsRepository settings;
  late MosqueRepository mosques;
  late _FakeClock clock;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    settings = SettingsRepository(db);
    clock = _FakeClock(DateTime.utc(2026, 10, 12, 9, 0));
    // The same clock the screen reads, which is how the provider wires it.
    mosques = MosqueRepository(db, clock: clock);
    addTearDown(db.close);
  });

  /// A container built after the writes it is meant to read. Settings and saved
  /// mosques reach the UI through streams, and a fresh subscription's first event
  /// is the stored state as it stands, so no test has to guess how long a write
  /// takes to arrive.
  ProviderContainer containerAt(DateTime instant) {
    clock.instant = instant;
    final container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
        appClockProvider.overrideWithValue(clock),
      ],
    );
    // Riverpod 3 pauses a stream subscription while nothing is listening to the
    // provider, so a test that only calls `read` would wait forever for drift's
    // first event. These stand in for the widgets that watch in the app.
    container.listen(appSettingsProvider, (_, _) {});
    container.listen(savedMosquesProvider, (_, _) {});
    container.listen(minuteClockProvider, (_, _) {});
    addTearDown(container.dispose);
    return container;
  }

  Future<void> settled(ProviderContainer container) => Future.wait([
    container.read(appSettingsProvider.future),
    container.read(savedMosquesProvider.future),
  ]);

  Future<void> saveCairo() => settings.setLocation(
    const StoredLocation(
      latitude: 30.0444,
      longitude: 31.2357,
      ianaZone: 'Africa/Cairo',
      placeLabel: 'Cairo',
      usesGps: false,
    ),
  );

  test('nothing is read before the user has set a place', () async {
    final container = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(container);

    expect(container.read(currentPlaceProvider), isNull);
    expect(container.read(todayProvider), isNull);
    expect(container.read(nextIqamaProvider), isNull);
    expect(container.read(activeMosqueScheduleProvider), isNull);
  });

  test('the day is the saved place\'s, not the device\'s', () async {
    // Tokyo is a day ahead here: 15:05 UTC on 12 October is 00:05 on the 13th.
    await settings.setLocation(
      const StoredLocation(
        latitude: 35.68,
        longitude: 139.69,
        ianaZone: 'Asia/Tokyo',
        placeLabel: 'Tokyo',
        usesGps: false,
      ),
    );
    final container = containerAt(DateTime.utc(2026, 10, 12, 15, 5));
    await settled(container);

    expect(
      container.read(todayProvider)?.day.day,
      const LocalDay(2026, 10, 13),
    );
  });

  test('the reading follows the clock across the place\'s midnight', () async {
    await saveCairo();

    final before = containerAt(DateTime.utc(2026, 10, 12, 20, 59));
    await settled(before);
    expect(before.read(todayProvider)?.day.day, const LocalDay(2026, 10, 12));

    // 21:00 UTC is midnight in Cairo on these dates. The minute ticker hands over
    // that new instant, so the day rolls over without waiting for a restart.
    final after = containerAt(DateTime.utc(2026, 10, 12, 21, 1));
    await settled(after);
    expect(after.read(todayProvider)?.day.day, const LocalDay(2026, 10, 13));
  });

  test('refreshing the clock is what moves the reading', () async {
    await saveCairo();
    final container = containerAt(DateTime.utc(2026, 10, 12, 20, 59));
    await settled(container);
    final first = container.read(todayProvider)!.day.day;

    clock.instant = DateTime.utc(2026, 10, 12, 21, 1);
    container.read(minuteClockProvider.notifier).refresh();

    expect(container.read(minuteClockProvider), clock.instant);
    expect(container.read(todayProvider)!.day.day, isNot(first));
  });

  test(
    'the card shows the active mosque\'s earliest remaining Iqama',
    () async {
      await saveCairo();
      final probe = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
      await settled(probe);
      final next = probe.read(todayProvider)!.next!;

      final mosque = await mosques.add(
        name: 'Masjid al-Nour',
        address: '12 Garden Road',
        source: MosqueSource.manual,
      );
      await mosques.setIqama(
        mosque.id,
        next.prayer,
        LocalTime(next.at.minutes + 10),
      );
      await settings.setActiveMosqueId(mosque.id);

      final container = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
      await settled(container);

      final iqama = container.read(nextIqamaProvider);
      expect(iqama, isA<IqamaUpcoming>());
      expect((iqama as IqamaUpcoming).prayer, next.prayer);
      expect(iqama.at, LocalTime(next.at.minutes + 10));
      expect(iqama.mosqueName, 'Masjid al-Nour');
    },
  );

  test('switching the active mosque switches the Iqama', () async {
    await saveCairo();
    final probe = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(probe);
    final next = probe.read(todayProvider)!.next!;

    // Iqamas have to be in front of the clock, or the card has nothing left to
    // count down to — a time already reached is not shown as if it were coming.
    final firstIqama = LocalTime(next.at.minutes + 5);
    final secondIqama = LocalTime(next.at.minutes + 15);

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
    await mosques.setIqama(first.id, next.prayer, firstIqama);
    await mosques.setIqama(second.id, next.prayer, secondIqama);

    await settings.setActiveMosqueId(first.id);
    final withFirst = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(withFirst);
    expect((withFirst.read(nextIqamaProvider) as IqamaUpcoming).at, firstIqama);

    await settings.setActiveMosqueId(second.id);
    final withSecond = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(withSecond);
    final switched = withSecond.read(nextIqamaProvider) as IqamaUpcoming;
    expect(switched.mosqueName, 'Second');
    expect(switched.at, secondIqama);
  });

  test('a mosque with no Iqama times leaves the card alone', () async {
    await saveCairo();
    final mosque = await mosques.add(
      name: 'New one',
      address: 'somewhere',
      source: MosqueSource.manual,
    );
    await settings.setActiveMosqueId(mosque.id);

    final container = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(container);

    expect(container.read(nextIqamaProvider), isA<IqamaNotConfigured>());
    // The rows show the same thing: nothing was invented for them.
    expect(container.read(activeMosqueScheduleProvider)?.configuredCount, 0);
    expect(container.read(activeMosqueProvider)?.name, 'New one');
  });

  test('the schedule the rows read is the one in force today', () async {
    await saveCairo();
    final mosque = await mosques.add(
      name: 'Seasonal',
      address: 'somewhere',
      source: MosqueSource.manual,
    );
    final empty = mosque.schedules.single;
    // A schedule that only starts next week must not be today's. It needs its own
    // id: storage keys schedules by id, so reusing one would overwrite the first.
    final seasonal = Schedule.empty(
      mosqueId: mosque.id,
      effectiveFrom: const LocalDay(2026, 10, 20),
    );
    await mosques.save(
      mosque.copyWith(
        schedules: [
          empty.copyWith(
            prayers: {
              Prayer.dhuhr: PrayerIqama(
                prayer: Prayer.dhuhr,
                iqama: const LocalTime(13 * 60),
              ),
            },
          ),
          seasonal.copyWith(
            prayers: {
              Prayer.dhuhr: PrayerIqama(
                prayer: Prayer.dhuhr,
                iqama: const LocalTime(12 * 60),
              ),
            },
          ),
        ],
      ),
    );
    await settings.setActiveMosqueId(mosque.id);

    final container = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(container);
    expect(
      container
          .read(activeMosqueScheduleProvider)!
          .iqamaFor(Prayer.dhuhr)
          .iqama,
      const LocalTime(13 * 60),
    );
  });

  test('untouched settings keep the documented defaults', () async {
    await saveCairo();
    final container = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(container);

    final reading = container.read(todayProvider)!;
    expect(reading.areTimesAvailable, isTrue);
    expect(reading.day.timeOf(Prayer.fajr), inInclusiveRange(3 * 60, 8 * 60));
    expect(
      reading.prayersMovedByRule,
      isEmpty,
      reason: 'Cairo does not need the rule, so the note stays hidden',
    );
  });

  test('a stored per-prayer offset reaches the rows', () async {
    await saveCairo();
    final plain = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(plain);
    final plainDhuhr = plain.read(todayProvider)!.day.timeOf(Prayer.dhuhr)!;

    await settings.setPrayerTimesPreferences(
      minuteOffsets: const {Prayer.dhuhr: 7},
    );
    final offset = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(offset);

    expect(
      offset.read(todayProvider)!.day.timeOf(Prayer.dhuhr),
      plainDhuhr + 7,
    );
  });

  test('a method the user chose changes the times', () async {
    await saveCairo();
    await settings.setPrayerTimesPreferences(
      calculationMethod: CalculationMethod.muslimWorldLeague,
    );
    final mwl = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(mwl);
    final mwlFajr = mwl.read(todayProvider)!.day.timeOf(Prayer.fajr)!;

    await settings.setPrayerTimesPreferences(
      calculationMethod: CalculationMethod.egyptian,
    );
    final egypt = containerAt(DateTime.utc(2026, 10, 12, 9, 0));
    await settled(egypt);

    expect(egypt.read(todayProvider)!.day.timeOf(Prayer.fajr), isNot(mwlFajr));
  });
}

/// A clock the test moves by hand. Production only ever reads [DeviceClock].
class _FakeClock implements AppClock {
  _FakeClock(this.instant);

  DateTime instant;

  @override
  DateTime nowUtc() => instant;
}
