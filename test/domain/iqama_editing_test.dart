import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/iqama_editing.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';

/// The rules behind the Mosques tab and the Iqama editor. The screens only
/// render these answers; nothing here knows about widgets.
void main() {
  group('reminder interval', () {
    test('the presets are the prototype chips: 5, 10 and 15 minutes', () {
      expect(ReminderInterval.presets, [5, 10, 15]);
    });

    test('custom accepts whole minutes from 1 to 120', () {
      expect(ReminderInterval.parseCustom('1'), const ReminderMinutesValid(1));
      expect(
        ReminderInterval.parseCustom('45'),
        const ReminderMinutesValid(45),
      );
      expect(
        ReminderInterval.parseCustom(' 120 '),
        const ReminderMinutesValid(120),
        reason: 'surrounding spaces from the keyboard are not an error',
      );
    });

    test('custom refuses an empty field', () {
      expect(ReminderInterval.parseCustom(''), isA<ReminderMinutesEmpty>());
      expect(ReminderInterval.parseCustom('   '), isA<ReminderMinutesEmpty>());
    });

    test('custom refuses anything that is not a whole number', () {
      for (final input in ['7.5', '1e2', 'ten', '5 min', '-', '+5', '0x10']) {
        expect(
          ReminderInterval.parseCustom(input),
          isA<ReminderMinutesNotWhole>(),
          reason: '"$input" is not a whole number of minutes',
        );
      }
    });

    test('custom refuses values outside 1..120', () {
      expect(
        ReminderInterval.parseCustom('0'),
        isA<ReminderMinutesOutOfRange>(),
      );
      expect(
        ReminderInterval.parseCustom('121'),
        isA<ReminderMinutesOutOfRange>(),
      );
      expect(
        ReminderInterval.parseCustom('-5'),
        isA<ReminderMinutesNotWhole>(),
        reason: 'a sign is not something the number keyboard offers',
      );
    });

    test('isValid matches the parser bounds', () {
      expect(ReminderInterval.isValid(0), isFalse);
      expect(ReminderInterval.isValid(1), isTrue);
      expect(ReminderInterval.isValid(120), isTrue);
      expect(ReminderInterval.isValid(121), isFalse);
    });
  });

  group('editor summary', () {
    test('a time with a reminder names both, reminder before the Iqama', () {
      final s = IqamaSummary.of(
        prayer: Prayer.maghrib,
        iqama: LocalTime.of(18, 30),
        reminderEnabled: true,
        reminderMinutesBefore: 10,
      );
      expect(s.prayer, Prayer.maghrib);
      expect(s.iqama, LocalTime.of(18, 30));
      expect(s.reminderAt, LocalTime.of(18, 20));
      expect(s.reminderIsPreviousDay, isFalse);
    });

    test('a time without a reminder has no reminder time', () {
      final s = IqamaSummary.of(
        prayer: Prayer.dhuhr,
        iqama: LocalTime.of(13, 15),
        reminderEnabled: false,
        reminderMinutesBefore: 10,
      );
      expect(s.reminderAt, isNull);
      expect(s.reminderIsPreviousDay, isFalse);
    });

    test('no time means no Iqama and no reminder, even if switched on', () {
      final s = IqamaSummary.of(
        prayer: Prayer.isha,
        iqama: null,
        reminderEnabled: true,
        reminderMinutesBefore: 10,
      );
      expect(s.iqama, isNull);
      expect(
        s.reminderAt,
        isNull,
        reason: 'AGENTS.md: a reminder never exists without an Iqama time',
      );
    });

    test('a reminder that falls before midnight says it is the day before', () {
      // Iqama at 12:05 AM with a 10-minute reminder: the reminder is 11:55 PM on
      // the previous calendar day, and the summary must not pretend otherwise.
      final s = IqamaSummary.of(
        prayer: Prayer.isha,
        iqama: LocalTime.of(0, 5),
        reminderEnabled: true,
        reminderMinutesBefore: 10,
      );
      expect(s.reminderAt, LocalTime.of(23, 55));
      expect(s.reminderIsPreviousDay, isTrue);
    });

    test('a reminder exactly at midnight is the same day', () {
      final s = IqamaSummary.of(
        prayer: Prayer.isha,
        iqama: LocalTime.of(0, 10),
        reminderEnabled: true,
        reminderMinutesBefore: 10,
      );
      expect(s.reminderAt, LocalTime.zero);
      expect(s.reminderIsPreviousDay, isFalse);
    });

    test('the longest custom reminder can cross midnight too', () {
      final s = IqamaSummary.of(
        prayer: Prayer.fajr,
        iqama: LocalTime.of(1, 0),
        reminderEnabled: true,
        reminderMinutesBefore: 120,
      );
      expect(s.reminderAt, LocalTime.of(23, 0));
      expect(s.reminderIsPreviousDay, isTrue);
    });

    test('sunrise has no summary at all', () {
      expect(
        () => IqamaSummary.of(
          prayer: Prayer.sunrise,
          iqama: LocalTime.of(6, 50),
          reminderEnabled: false,
          reminderMinutesBefore: 10,
        ),
        throwsArgumentError,
      );
    });
  });

  group('mosque Iqama status', () {
    const day = LocalDay(2026, 10, 13);

    Mosque mosqueWith(Map<Prayer, LocalTime> times, {LocalDay? from}) {
      var schedule = Schedule.empty(mosqueId: 'm', effectiveFrom: from);
      for (final entry in times.entries) {
        schedule = schedule.withPrayer(
          PrayerIqama(prayer: entry.key, iqama: entry.value),
        );
      }
      return Mosque(
        id: 'm',
        name: 'Masjid',
        address: '',
        source: MosqueSource.manual,
        schedules: [schedule],
      );
    }

    test('a new mosque is not configured', () {
      expect(mosqueIqamaStatus(mosqueWith({}), day), const IqamaStatusNone());
    });

    test('some times set counts them out of five', () {
      final status = mosqueIqamaStatus(
        mosqueWith({
          Prayer.fajr: LocalTime.of(5, 30),
          Prayer.isha: LocalTime.of(20, 0),
        }),
        day,
      );
      expect(status, const IqamaStatusPartial(configured: 2, of: 5));
    });

    test('all five set', () {
      final status = mosqueIqamaStatus(
        mosqueWith({
          for (final p in Prayer.iqamaPrayers) p: LocalTime.of(12, 0),
        }),
        day,
      );
      expect(status, const IqamaStatusAll());
    });

    test('reads the schedule in force on the day, not a future one', () {
      final status = mosqueIqamaStatus(
        mosqueWith({
          Prayer.fajr: LocalTime.of(5, 30),
        }, from: const LocalDay(2027, 1, 1)),
        day,
      );
      expect(
        status,
        const IqamaStatusNone(),
        reason: 'a schedule that has not started yet sets nothing today',
      );
    });
  });

  group('mosque name', () {
    test('is trimmed', () {
      expect(MosqueDetailsInput.name('  Masjid al-Nasr  '), 'Masjid al-Nasr');
    });

    test('a blank name is refused', () {
      expect(MosqueDetailsInput.name(''), isNull);
      expect(MosqueDetailsInput.name('   '), isNull);
    });

    test('an address is optional and trimmed', () {
      expect(MosqueDetailsInput.address('  1 Example Road '), '1 Example Road');
      expect(MosqueDetailsInput.address('   '), '');
    });
  });
}
