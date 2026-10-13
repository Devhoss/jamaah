import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/placeholder_places.dart';
import 'package:jamaah/src/domain/zone_offsets.dart';

/// Guards the bundled placeholder list.
///
/// A wrong or misspelled IANA zone does not crash anything: `zoneOffsetsFor`
/// degrades to the device clock, so every prayer time silently shifts and looks
/// plausible. These tests are the only thing standing between a typo in that list
/// and a user praying at the wrong minute.
void main() {
  setUpAll(loadTimeZoneDatabase);

  group('placeholder place list', () {
    test('every zone resolves in the bundled time zone database', () {
      for (final place in placeholderPlaces) {
        final offsets = zoneOffsetsFor(place.ianaZone);
        expect(
          offsets,
          isA<TzDatabaseOffsets>(),
          reason:
              '${place.displayName} carries ${place.ianaZone}, which the '
              'database does not have — prayer times here would silently fall '
              'back to the device clock.',
        );
        expect(offsets.zoneName, place.ianaZone);
      }
    });

    test('the offsets the list implies are the real ones', () {
      // Checked at a fixed UTC instant: 12 Oct 2026, 12:00Z. Zones with no
      // daylight saving pin the arithmetic; London and New York are in
      // daylight saving that day, so they also prove the lookup is DST-aware.
      final instant = DateTime.utc(2026, 10, 12, 12);
      final expected = <String, int>{
        'Asia/Riyadh': 3 * 60, // Makkah, Madinah, Riyadh, Jeddah
        'Asia/Karachi': 5 * 60, // Karachi, Lahore, Islamabad
        'Asia/Kolkata': 5 * 60 + 30, // Delhi, Mumbai, Hyderabad
        'Asia/Kathmandu': 5 * 60 + 45, // a half-hour-and-quarter-hour zone
        'Africa/Lagos': 60, // Lagos, Kano
        'Africa/Nairobi': 3 * 60, // Nairobi, Mombasa
        'Asia/Jakarta': 7 * 60, // Jakarta, Surabaya
        'America/Bogota': -5 * 60, // Bogota
        'Europe/London': 60, // British Summer Time on this date
        'America/New_York': -4 * 60, // Eastern Daylight Time on this date
      };

      for (final entry in expected.entries) {
        final zone = entry.key;
        expect(
          placeholderPlaces.map((p) => p.ianaZone),
          contains(zone),
          reason: '$zone is in the expected set but not in the list',
        );
        expect(
          zoneOffsetsFor(zone).offsetMinutesAt(instant),
          entry.value,
          reason: '$zone has the wrong offset on 12 Oct 2026',
        );
      }
    });

    test('labels are unique and coordinates are on the globe', () {
      final labels = placeholderPlaces.map((p) => p.displayName).toList();
      expect(labels.toSet(), hasLength(labels.length));

      for (final place in placeholderPlaces) {
        expect(
          place.latitude,
          inInclusiveRange(-90, 90),
          reason: place.displayName,
        );
        expect(
          place.longitude,
          inInclusiveRange(-180, 180),
          reason: place.displayName,
        );
        expect(place.fromDevice, isFalse, reason: place.displayName);
      }
    });

    test('the list covers a spread of regions, not one neighbourhood', () {
      final regions = placeholderPlaces
          .map((p) => p.ianaZone.split('/').first)
          .toSet();

      expect(
        regions,
        containsAll(<String>{
          'Africa',
          'Asia',
          'Europe',
          'America',
          'Australia',
          'Pacific',
        }),
      );
      expect(
        placeholderPlaces.map((p) => p.ianaZone).toSet().length,
        greaterThan(40),
        reason: 'distinct zones, not just distinct cities',
      );
    });
  });
}
