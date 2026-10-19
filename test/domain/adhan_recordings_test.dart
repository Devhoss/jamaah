import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/domain/prayer.dart';

/// The bundled Adhan recordings: stored by id, so ids must stay unique and an
/// id that is gone falls back to the default rather than to nothing.
void main() {
  test('ids and files are unique, and every file is bundled', () {
    expect(adhanRecordings.map((r) => r.id).toSet(), hasLength(6));
    expect(adhanRecordings.map((r) => r.asset).toSet(), hasLength(6));
    for (final r in adhanRecordings) {
      expect(File(r.asset).existsSync(), isTrue, reason: r.asset);
      expect(r.seconds, greaterThan(60), reason: r.name);
    }
  });

  test('Fajr recordings are available only when setting Fajr', () {
    expect(recordingsForPrayer(null), hasLength(4));
    expect(recordingsForPrayer(Prayer.isha), hasLength(4));
    expect(recordingsForPrayer(Prayer.fajr), hasLength(6));
    expect(
      recordingsForPrayer(Prayer.fajr).where((r) => r.prayerOnly != null),
      hasLength(2),
    );
  });

  test('the default full Adhan and all supplied short clips are bundled', () {
    expect(adhanRecordingById(kDefaultAdhanRecording).name, 'Muezzin');
    expect(ShortAdhan.values, hasLength(5));
    for (final clip in ShortAdhan.values) {
      expect(File(clip.asset).existsSync(), isTrue, reason: clip.asset);
    }
  });

  test('an unknown or missing id reads as the default', () {
    expect(adhanRecordingById('gone').id, kDefaultAdhanRecording);
    expect(adhanRecordingById(null).id, kDefaultAdhanRecording);
    expect(adhanRecordingById('ahmed_el_haddad').name, 'Ahmed El Haddad');
  });
}
