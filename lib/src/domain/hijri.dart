import 'package:hijri/hijri_calendar.dart';

/// The Hijri date adjustment (2026-10-14).
///
/// The app's Hijri dates come from the Umm al-Qura calendar. Countries that
/// start each month by moon sighting, Kuwait among them, can be a day or two
/// off it, so the user can move the Hijri date by up to [kMaxHijriAdjustDays]
/// either way. It moves only the Hijri date (Today's sub-line, and which days
/// are Ramadan for Umm al-Qura's longer Isha); prayer times are untouched.
const kMaxHijriAdjustDays = 2;

/// The Hijri date for the Gregorian [date], moved by [adjustDays].
HijriCalendar hijriFor(DateTime date, {int adjustDays = 0}) =>
    HijriCalendar.fromDate(
      DateTime(date.year, date.month, date.day).add(Duration(days: adjustDays)),
    );

/// A stored adjustment, kept within the allowed range.
int clampHijriAdjust(int days) =>
    days.clamp(-kMaxHijriAdjustDays, kMaxHijriAdjustDays);
