import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../domain/time_model.dart';

/// A time of day turned into the text the device would show on its own clock.
///
/// Which convention is right is not the app's decision: the system's 12/24-hour
/// setting makes it, and a Settings override comes later. Resolving that once per
/// build and passing the result down is what keeps a screen from showing `12:42` on
/// one line and `12:42 PM` on the next.
class ClockFormat {
  const ClockFormat({required this.use24Hour, required this.locale});

  /// The format for the device and locale this tree is rendered in.
  factory ClockFormat.of(BuildContext context) => ClockFormat(
    use24Hour: MediaQuery.of(context).alwaysUse24HourFormat,
    locale: Localizations.localeOf(context).toLanguageTag(),
  );

  final bool use24Hour;
  final String locale;

  /// `12:42` on a 24-hour device, `12:42 PM` on a 12-hour one.
  String time(LocalTime at) {
    // A time of day has no date, but intl formats a moment rather than an offset,
    // so a fixed placeholder date keeps the reading out of the calendar.
    final moment = DateTime(2000, 1, 1, at.hour, at.minute);
    return (use24Hour ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(moment);
  }

  /// The time split for the hero (Horizon): `1:59` big and `PM` beside it. A
  /// 24-hour device has no period.
  ({String clock, String? period}) parts(LocalTime at) {
    final moment = DateTime(2000, 1, 1, at.hour, at.minute);
    if (use24Hour) return (clock: DateFormat.Hm(locale).format(moment), period: null);
    return (
      clock: DateFormat('h:mm', locale).format(moment),
      period: DateFormat('a', locale).format(moment),
    );
  }
}
