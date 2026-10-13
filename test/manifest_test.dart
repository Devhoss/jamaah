import 'dart:io';

import 'package:jamaah/src/app/branding.g.dart';
import 'package:flutter_test/flutter_test.dart';

/// Guards the Android manifest against permissions that no code asks for.
///
/// A declared permission is a promise to the user, so the file is checked the way
/// behaviour is: INTERNET and both location levels are allowed now, and the ones
/// that belong to later steps stay out until their commit.
void main() {
  const manifest = 'android/app/src/main/AndroidManifest.xml';

  test('the release manifest asks for internet and the two location levels', () {
    final text = File(manifest).readAsStringSync();

    expect(
      text,
      contains('android.permission.INTERNET'),
      reason: 'discovery and place search need it in release builds',
    );
    expect(
      text,
      contains('android.permission.ACCESS_COARSE_LOCATION'),
      reason: 'Today asks for city-level location on its own',
    );
    expect(
      text,
      contains('android.permission.ACCESS_FINE_LOCATION'),
      reason: 'precise location, asked for only by "Find nearby mosques"',
    );
    for (final deferred in const [
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

  /// The crash this guards against is invisible to every Dart test: the manifest
  /// names the activity with a leading dot, Android resolves that against the
  /// Gradle namespace, and the namespace comes from branding. If the Kotlin file
  /// sits in another package, the launcher asks for a class that does not exist
  /// and the app dies before Flutter starts. This was exactly the state of the
  /// tree on the first real-device run.
  test('the launcher activity exists at the name Android will ask for', () {
    final gradle = File(
      'android/app/build.gradle.kts',
    ).readAsStringSync();
    expect(
      gradle,
      contains('namespace = brandingApplicationId'),
      reason: 'the namespace must follow branding, or the two drift apart',
    );

    final activity = RegExp(
      r'android:name="(\.[A-Za-z0-9_]+)"',
    ).firstMatch(File(manifest).readAsStringSync());
    expect(activity, isNotNull, reason: 'the launcher is named with a leading dot');
    final className = activity!.group(1)!;
    expect(className, '.MainActivity');

    final path =
        'android/app/src/main/kotlin/'
        '${kApplicationId.replaceAll('.', '/')}/MainActivity.kt';
    final source = File(path);
    expect(
      source.existsSync(),
      isTrue,
      reason: '$kApplicationId$className is what the launcher loads, so $path '
          'has to be the file that declares it',
    );
    expect(
      source.readAsStringSync(),
      contains('package $kApplicationId'),
      reason: 'a matching folder with a different package is the same crash',
    );
  });

  /// geolocator's requestPermission asks for every location permission in the
  /// manifest at once, so with precise declared the startup prompt would offer
  /// precise too. Both levels go through the app's own channel instead.
  test('no code asks the plugin for location permission directly', () {
    final offenders = [
      for (final file in Directory('lib').listSync(recursive: true))
        if (file is File &&
            file.path.endsWith('.dart') &&
            file.readAsStringSync().contains('Geolocator.requestPermission'))
          file.path,
    ];
    expect(offenders, isEmpty);
  });
}
