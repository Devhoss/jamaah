import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/iqama_editing.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/time_model.dart';

/// An Iqama as "N minutes after the Adhan" (2026-10-14): the mosque's rule,
/// typed by the user; the app only adds.
void main() {
  const fajr = Prayer.fajr;

  test('a fixed time is itself, whatever the Adhan', () {
    const e = PrayerIqama(prayer: fajr, iqama: LocalTime(5 * 60 + 36));
    expect(e.isConfigured, isTrue);
    expect(e.minutesOfDay(5 * 60), 5 * 60 + 36);
    expect(e.minutesOfDay(null), 5 * 60 + 36);
  });

  test('minutes after the Adhan are added to it', () {
    const e = PrayerIqama(prayer: fajr, afterAdhanMinutes: 22);
    expect(e.isConfigured, isTrue);
    expect(e.minutesOfDay(4 * 60 + 29), 4 * 60 + 51);
  });

  test('past midnight the minutes run on into the next date', () {
    const e = PrayerIqama(prayer: Prayer.isha, afterAdhanMinutes: 20);
    expect(e.minutesOfDay(23 * 60 + 50), 24 * 60 + 10);
  });

  test('no Adhan that day, no Iqama: never guessed', () {
    const e = PrayerIqama(prayer: fajr, afterAdhanMinutes: 22);
    expect(e.minutesOfDay(null), isNull);
  });

  test('neither set is Not configured, and has no reminder', () {
    const e = PrayerIqama(prayer: fajr, reminderEnabled: true);
    expect(e.isConfigured, isFalse);
    expect(e.hasReminder, isFalse);
    expect(e.minutesOfDay(300), isNull);
  });

  test('choosing one kind clears the other', () {
    const fixed = PrayerIqama(prayer: fajr, iqama: LocalTime(336));
    final after = fixed.withAfterAdhan(22);
    expect(after.iqama, isNull);
    expect(after.afterAdhanMinutes, 22);
    final back = after.withFixed(const LocalTime(340));
    expect(back.afterAdhanMinutes, isNull);
    expect(back.iqama, const LocalTime(340));
  });

  test('the minutes are part of equality', () {
    expect(
      const PrayerIqama(prayer: fajr, afterAdhanMinutes: 20) ==
          const PrayerIqama(prayer: fajr, afterAdhanMinutes: 22),
      isFalse,
    );
  });

  test('the allowed range', () {
    expect(kMinAfterAdhanMinutes, 1);
    expect(kMaxAfterAdhanMinutes, 90);
  });

  group('the next one, for the editor’s preview', () {
    test('still ahead today: today’s Adhan', () {
      final n = nextIqamaAfterAdhan(
        minutes: 22,
        nowMinutes: 4 * 60,
        adhanToday: 5 * 60 + 30,
        adhanTomorrow: 5 * 60 + 31,
      )!;
      expect(n.adhan, const LocalTime(5 * 60 + 30));
      expect(n.iqama, const LocalTime(5 * 60 + 52));
      expect(n.tomorrow, isFalse);
    });

    test('already gone today: tomorrow’s Adhan, said as tomorrow', () {
      final n = nextIqamaAfterAdhan(
        minutes: 22,
        nowMinutes: 22 * 60 + 15,
        adhanToday: 5 * 60 + 30,
        adhanTomorrow: 5 * 60 + 31,
      )!;
      expect(n.adhan, const LocalTime(5 * 60 + 31));
      expect(n.iqama, const LocalTime(5 * 60 + 53));
      expect(n.tomorrow, isTrue);
    });

    test('ahead but past midnight is tomorrow’s date', () {
      final n = nextIqamaAfterAdhan(
        minutes: 20,
        nowMinutes: 22 * 60,
        adhanToday: 23 * 60 + 50,
        adhanTomorrow: 23 * 60 + 51,
      )!;
      expect(n.adhan, const LocalTime(23 * 60 + 50));
      expect(n.iqama, const LocalTime(10));
      expect(n.tomorrow, isTrue);
    });

    test('no Adhan to count from: nothing', () {
      expect(
        nextIqamaAfterAdhan(
          minutes: 22,
          nowMinutes: 600,
          adhanToday: null,
          adhanTomorrow: null,
        ),
        isNull,
      );
    });
  });
}
