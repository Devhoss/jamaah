import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the Android manifest against permissions that no code asks for.
///
/// A declared permission is a promise to the user, so the file is checked the way
/// behaviour is: INTERNET and coarse location are allowed now, and the ones that
/// belong to later steps stay out until their commit.
void main() {
  const manifest = 'android/app/src/main/AndroidManifest.xml';

  test('the release manifest asks for internet and coarse location only', () {
    final text = File(manifest).readAsStringSync();

    expect(
      text,
      contains('android.permission.INTERNET'),
      reason: 'discovery and place search need it in release builds',
    );
    expect(
      text,
      contains('android.permission.ACCESS_COARSE_LOCATION'),
      reason: 'Today asks for city-level location, never a precise position',
    );
    for (final deferred in const [
      'android.permission.ACCESS_FINE_LOCATION',
      'android.permission.POST_NOTIFICATIONS',
      'android.permission.SCHEDULE_EXACT_ALARM',
      'android.permission.USE_EXACT_ALARM',
    ]) {
      expect(
        text,
        isNot(contains(deferred)),
        reason: '$deferred belongs to a later step, not this one',
      );
    }
  });
}
