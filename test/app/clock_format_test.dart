import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:jamaah/src/app/clock_format.dart';
import 'package:jamaah/src/domain/time_model.dart';

/// The one place a time of day becomes text.
///
/// Which of the two conventions is right is not the app's decision: the system's
/// 12/24-hour setting decides, and the app follows it (AGENTS.md: no hard-coded
/// conventions). Both are pinned here because a device can be in either, and a
/// screen that mixed `12:42` with `12:42 PM` would read as two different clocks.
void main() {
  // Inside the app the localization delegates load intl's locale data; this test
  // has no widget tree, so it loads them itself.
  setUpAll(() => initializeDateFormatting());

  const midday = LocalTime(12 * 60 + 42);
  const early = LocalTime(5 * 60 + 28);

  group('the 24-hour device', () {
    const clock = ClockFormat(use24Hour: true, locale: 'en');

    test('keeps four digits on a midday reading', () {
      expect(clock.time(midday), '12:42');
    });

    test('keeps the leading zero on an early hour', () {
      expect(clock.time(early), '05:28');
    });

    test('calls midnight 00:00, not 12:00', () {
      expect(clock.time(const LocalTime(0)), '00:00');
    });
  });

  group('the 12-hour device', () {
    const clock = ClockFormat(use24Hour: false, locale: 'en');

    // The marker is separated by a narrow no-break space (U+202F), which is what
    // CLDR says and what intl prints. Pinned as the real reading rather than
    // normalised away, because a plain space would be a different string on screen.
    test('marks an afternoon reading', () {
      expect(clock.time(midday), '12:42\u202FPM');
    });

    test('marks a pre-dawn reading and drops the padding', () {
      expect(clock.time(early), '5:28\u202FAM');
    });

    test('calls midnight 12:00 AM', () {
      expect(clock.time(const LocalTime(0)), '12:00\u202FAM');
    });

    test('calls noon 12:00 PM, which is the hour a naive offset gets wrong', () {
      expect(clock.time(const LocalTime(12 * 60)), '12:00\u202FPM');
      expect(clock.time(const LocalTime(0 * 60 + 1)), '12:01\u202FAM');
    });
  });
}
