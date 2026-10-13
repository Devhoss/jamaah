import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';

/// The bundled Adhan recordings: stored by id, so ids must stay unique and an
/// id that is gone falls back to the default rather than to nothing.
void main() {
  test('ids and files are unique, and every file is bundled', () {
    expect(adhanRecordings.map((r) => r.id).toSet(), hasLength(17));
    expect(adhanRecordings.map((r) => r.asset).toSet(), hasLength(17));
    for (final r in adhanRecordings) {
      expect(File(r.asset).existsSync(), isTrue, reason: r.asset);
      expect(r.seconds, greaterThan(60), reason: r.name);
    }
  });

  test('the default is Naghshbandi, whose opening is the short Adhan', () {
    expect(adhanRecordingById(kDefaultAdhanRecording).name, 'Naghshbandi');
    expect(File(kShortAdhanAsset).existsSync(), isTrue);
  });

  test('an unknown or missing id reads as the default', () {
    expect(adhanRecordingById('gone').id, kDefaultAdhanRecording);
    expect(adhanRecordingById(null).id, kDefaultAdhanRecording);
    expect(adhanRecordingById('makkah').name, 'Makkah');
  });
}
