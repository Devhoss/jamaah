import 'dart:async';

import 'package:intl/date_symbol_data_local.dart';

import '../domain/mosque.dart';
import '../domain/notification_plan.dart';
import '../domain/prayer.dart';
import '../domain/prayer_times_calculator.dart';
import '../domain/sky/ink_rule.dart';
import '../domain/sky/sky_color.dart';
import '../domain/sky/sky_model.dart';
import '../domain/sky/sun_path_geometry.dart';
import '../domain/time_model.dart';
import '../domain/zone_offsets.dart';
import 'date_labels.dart';
import 'l10n/generated/app_localizations.dart';
import 'l10n/prayer_labels.dart';

/// What the full-screen Adhan shows (Horizon spec §4.2), worked out in Dart
/// when the alarm is scheduled and carried to the native page with it, so
/// that page still appears at once over the lock screen without starting
/// Flutter (owner, 2026-10-16).
///
/// The sky is a still picture of the prayer's own minute, for both themes;
/// the page picks one by [theme] and the phone's night mode. Colours are ARGB
/// ints; the sun path is in its 390 × 168 design box (spec §3.4).
Map<String, Object?> adhanScreenPayload({
  required PlannedNotification planned,
  required PrayerTimesCalculator calculator,
  required ZoneOffsets zone,
  required AppLocalizations l10n,
  required Mosque? mosque,
  required String theme,
  required int hijriAdjustDays,
  required String Function(LocalTime time) clockTime,
}) {
  final offset = zone.offsetMinutesAt(planned.at);
  final local = planned.at.toUtc().add(Duration(minutes: offset));
  final day = LocalDay(local.year, local.month, local.day);
  final prayerDay = calculator.forDay(day);
  final prayer = planned.prayer;
  final minute = prayerDay.timeOf(prayer) ?? (local.hour * 60 + local.minute);
  final model = SkyModel.forDay(prayerDay);
  final sunrise = prayerDay.timeOf(Prayer.sunrise);
  final sunset = prayerDay.timeOf(Prayer.maghrib);
  final geometry = sunrise != null && sunset != null && sunset > sunrise
      ? SunPathGeometry(sunrise: sunrise, sunset: sunset)
      : SunPathGeometry.reference;
  final sun = geometry.positionAt(minute.toDouble());
  final sunColours = SunPathGeometry.sunColours(sun.altitude);

  Map<String, Object?> variant(bool dark) {
    final frame = model.frameAt(minute.toDouble(), dark: dark);
    final ink = SkyInk.forRegion(frame, _screen);
    final path = SkyInk.forRegion(frame, _path);
    return {
      'stops': [for (final s in frame.stops) s.argb],
      'positions': SkyModel.stopPositions,
      'glow': _argb(frame.glow),
      'ink': ink.ink.argb,
      'deep': ink.deep.argb,
      'mute': _alpha(ink.ink, ink.muteAlpha),
      'line': _alpha(ink.ink, SkyInk.lineAlpha),
      'fill': ink.fill.argb,
      'shade': _argb(ink.shade),
      'pathInk': path.ink.argb,
      'lightInk': ink.isLight,
    };
  }

  final time = clockTime(LocalTime(minute));
  final date = day.midnightUtc();
  final locale = l10n.localeName;
  final arabic = locale.startsWith('ar');
  final name = prayerNameOn(l10n, prayer, day);

  String? iqamaLine;
  final schedule = prayer == Prayer.sunrise ? null : mosque?.scheduleFor(day);
  if (mosque != null && prayer != Prayer.sunrise) {
    final entry = schedule?.iqamaOn(day, prayer).entry;
    final at = switch (entry) {
      PrayerIqama(afterAdhanMinutes: final after?) => minute + after,
      PrayerIqama(iqama: final fixed?) => fixed.minutes,
      _ => null,
    };
    if (at == null) {
      iqamaLine = l10n.adhanScreenNoIqama(mosque.name);
    } else {
      final wait = at - minute;
      iqamaLine = wait > 0
          ? l10n.adhanScreenIqamaIn(
              mosque.name,
              clockTime(LocalTime(at % 1440)),
              wait >= 60
                  ? l10n.countdownHours(wait ~/ 60, wait % 60)
                  : l10n.countdownMinutes(wait),
            )
          : l10n.adhanScreenIqamaAt(
              mosque.name,
              clockTime(LocalTime(at % 1440)),
            );
    }
  }

  return {
    'theme': theme,
    'light': variant(false),
    'dark': variant(true),
    'sun': {
      'x': sun.point.x,
      'y': sun.point.y,
      'core': sunColours.core.argb,
      'disc': sunColours.disc.argb,
      'opacity': SunPathGeometry.sunOpacity(sun.altitude),
    },
    'markers': [
      for (final p in Prayer.adhanPrayers)
        if (prayerDay.timeOf(p) case final t?)
          () {
            final at = geometry.positionAt(t.toDouble()).point;
            return [at.x, at.y];
          }(),
    ],
    'date': _dateLine(l10n, date, locale, hijriAdjustDays),
    'kicker': arabic
        ? l10n.adhanScreenKicker
        : l10n.adhanScreenKicker.toUpperCase(),
    'prayer': name,
    'adhanLine': l10n.adhanScreenAdhanAt(time),
    'iqamaLine': iqamaLine,
    'hint': l10n.adhanScreenHint,
    'stopped': l10n.adhanScreenStopped,
    'dismiss': l10n.adhanScreenDismiss,
    'stopAccessibility': l10n.adhanScreenStopLabel(name),
    'arabic': arabic,
  };
}

/// "Mon 12 Oct · 29 Rabi' II 1448". The daily refresh syncs with no screen,
/// so the locale's date names may not be loaded yet: load them here (the
/// data is filled in at once), and leave the line out rather than fail the
/// whole sync.
String _dateLine(
  AppLocalizations l10n,
  DateTime date,
  String locale,
  int hijriAdjustDays,
) {
  unawaited(initializeDateFormatting());
  try {
    return l10n.placeSubline(
      DateLabels.weekdayDate(date, locale),
      DateLabels.hijri(date, locale, adjustDays: hijriAdjustDays),
    );
  } on Object {
    return '';
  }
}

/// The page's text sits over the whole screen; the sun path near the top.
const _screen = SkyRegion(0, 1, minContrast: 4.5);
const _path = SkyRegion(0.08, 0.3, minContrast: 3);

int _argb(SkyRgba c) => _alpha(c.rgb, c.alpha);

int _alpha(SkyRgb c, double alpha) =>
    ((alpha.clamp(0.0, 1.0) * 255).round() << 24) | (c.argb & 0x00FFFFFF);
