import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/adhan_screen.dart';
import 'package:jamaah/src/app/l10n/generated/app_localizations_en.dart';
import 'package:jamaah/src/domain/mosque.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/prayer.dart';
import 'package:jamaah/src/domain/prayer_times_calculator.dart';
import 'package:jamaah/src/domain/sky/sky_color.dart';
import 'package:jamaah/src/domain/time_model.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// The full-screen Adhan's page, worked out in Dart for the native screen
/// (spec §4.2).
void main() {
  setUpAll(loadTimeZoneDatabase);

  final l10n = AppLocalizationsEn();
  final zone = zoneOffsetsFor('Africa/Cairo');
  final cairo = PrayerTimesCalculator(
    latitude: 30.0444,
    longitude: 31.2357,
    zone: zone,
  );
  const day = LocalDay(2026, 10, 12);
  final times = cairo.forDay(day);

  PlannedNotification adhan(Prayer prayer) => PlannedNotification(
    id: 1,
    kind: NotificationKind.adhan,
    prayer: prayer,
    at: zone.utcInstantOf(day: day, time: LocalTime(times.timeOf(prayer)!)),
    soundMode: null,
    mosqueId: '',
    fullScreen: true,
  );

  Mosque mosque({int? maghribAfter}) => Mosque(
    id: 'm1',
    name: 'Masjid al-Nour',
    address: '',
    source: MosqueSource.manual,
    schedules: [
      Schedule.empty(mosqueId: 'm1').copyWith(
        prayers: {
          for (final p in Prayer.iqamaPrayers)
            p: p == Prayer.maghrib && maghribAfter != null
                ? PrayerIqama(prayer: p, afterAdhanMinutes: maghribAfter)
                : PrayerIqama(prayer: p),
        },
      ),
    ],
  );

  Map<String, Object?> payload(Prayer prayer, {Mosque? at}) =>
      adhanScreenPayload(
        planned: adhan(prayer),
        calculator: cairo,
        zone: zone,
        l10n: l10n,
        mosque: at,
        theme: 'system',
        hijriAdjustDays: 0,
        clockTime: (t) =>
            '${t.minutes ~/ 60}:${(t.minutes % 60).toString().padLeft(2, '0')}',
      );

  String hm(int minutes) =>
      '${minutes ~/ 60}:${(minutes % 60).toString().padLeft(2, '0')}';

  test('the prayer, its Adhan time and the Iqama at the active mosque', () {
    final p = payload(Prayer.maghrib, at: mosque(maghribAfter: 10));
    final maghrib = times.timeOf(Prayer.maghrib)!;
    expect(p['prayer'], l10n.prayerMaghrib);
    expect(p['kicker'], l10n.adhanScreenKicker.toUpperCase());
    expect(p['adhanLine'], l10n.adhanScreenAdhanAt(hm(maghrib)));
    expect(
      p['iqamaLine'],
      l10n.adhanScreenIqamaIn(
        'Masjid al-Nour',
        hm(maghrib + 10),
        l10n.countdownMinutes(10),
      ),
    );
  });

  test('a mosque with no Iqama for the prayer says so; none says nothing', () {
    expect(
      payload(Prayer.isha, at: mosque())['iqamaLine'],
      l10n.adhanScreenNoIqama('Masjid al-Nour'),
    );
    expect(payload(Prayer.isha)['iqamaLine'], isNull);
    expect(
      payload(Prayer.sunrise, at: mosque())['iqamaLine'],
      isNull,
      reason: 'sunrise never has an Iqama (AGENTS.md)',
    );
  });

  test('both themes come with the sky, and the ink keeps its contrast', () {
    final p = payload(Prayer.maghrib);
    for (final theme in ['light', 'dark']) {
      final v = p[theme]! as Map<String, Object?>;
      final stops = (v['stops']! as List).cast<int>();
      expect(stops, hasLength(5));
      // The ink against the middle of the sky, where the name sits.
      final ink = v['ink']! as int;
      final sky = stops[3];
      SkyRgb rgb(int c) => SkyRgb(
        ((c >> 16) & 0xFF).toDouble(),
        ((c >> 8) & 0xFF).toDouble(),
        (c & 0xFF).toDouble(),
      );
      expect(rgb(ink).contrastWith(rgb(sky)), greaterThan(3));
    }
  });

  test('the sun sits on the horizon at Maghrib, with every marker', () {
    final p = payload(Prayer.maghrib);
    final sun = p['sun']! as Map<String, Object?>;
    expect((sun['y']! as double), closeTo(118, 2));
    expect((p['markers']! as List), hasLength(6));
  });
}
