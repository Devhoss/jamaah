import 'package:hijri/hijri_calendar.dart';
import 'package:intl/intl.dart';

import '../domain/hijri.dart';
import 'l10n/digits.dart';

/// Formats the Gregorian and Hijri dates shown under the Today title.
///
/// The prototype shows "Monday, 12 October" with the Hijri date as the sub-line.
///
/// The Hijri date is informational only: this package uses the tabular arithmetic
/// calendar, which can differ by a day from local moon-sighting announcements. It
/// is shown as a sub-line, never as the authority for anything the app does.
abstract final class DateLabels {
  static String gregorian(DateTime date, String locale) => DateFormat(
    // Arabic takes its own comma (،).
    locale.startsWith('ar') ? 'EEEE، d MMMM' : 'EEEE, d MMMM',
    locale,
  ).format(date);

  static String hijri(DateTime date, String locale, {int adjustDays = 0}) {
    final calendar = hijriFor(date, adjustDays: adjustDays);
    // The package knows 'ar' and 'en' only, not a full tag like ar-EG.
    final language = locale.split(RegExp('[-_]')).first;
    HijriCalendar.setLocal(language == 'ar' ? 'ar' : 'en');
    return localDigits(calendar.toFormat('d MMMM yyyy'), language);
  }

  /// `12 Oct 2026`, used for "Set by you · last updated ..." on a schedule.
  static String shortDate(DateTime date, String locale) =>
      DateFormat('d MMM yyyy', locale).format(date);
}
