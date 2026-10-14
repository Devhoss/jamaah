import 'package:flutter_test/flutter_test.dart';

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
}
