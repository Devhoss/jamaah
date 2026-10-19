import 'dart:io';

import 'package:jamaah/src/app/branding.g.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';

/// Guards the Android manifest against permissions that no code asks for.
///
/// A declared permission is a promise to the user, so the file is checked the way
/// behaviour is: INTERNET and both location levels are allowed now, and the ones
/// that belong to later steps stay out until their commit.
void main() {
  const manifest = 'android/app/src/main/AndroidManifest.xml';

  test(
    'the release manifest asks for internet and the two location levels',
    () {
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
      for (final notifications in const [
        'android.permission.POST_NOTIFICATIONS',
        'android.permission.SCHEDULE_EXACT_ALARM',
        'android.permission.RECEIVE_BOOT_COMPLETED',
      ]) {
        expect(
          text,
          contains(notifications),
          reason: 'local notifications, on the minute, restored after a reboot',
        );
      }
      for (final deferred in const [
        // Play reserves it for alarm-clock and calendar apps; the app uses
        // SCHEDULE_EXACT_ALARM and says so when it is denied (AGENTS.md).
        'android.permission.USE_EXACT_ALARM',
      ]) {
        expect(
          text,
          isNot(contains(deferred)),
          reason: '$deferred belongs to a later step, not this one',
        );
      }
    },
  );

  /// The crash this guards against is invisible to every Dart test: the manifest
  /// names the activity with a leading dot, Android resolves that against the
  /// Gradle namespace, and the namespace comes from branding. If the Kotlin file
  /// sits in another package, the launcher asks for a class that does not exist
  /// and the app dies before Flutter starts. This was exactly the state of the
  /// tree on the first real-device run.
  test('the launcher activity exists at the name Android will ask for', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(
      gradle,
      contains('namespace = brandingApplicationId'),
      reason: 'the namespace must follow branding, or the two drift apart',
    );

    final activity = RegExp(r'android:name="(\.[A-Za-z0-9_]+)"')
        .firstMatch(File(manifest).readAsStringSync());
    expect(
      activity,
      isNotNull,
      reason: 'the launcher is named with a leading dot',
    );
    final className = activity!.group(1)!;
    expect(className, '.MainActivity');

    final path =
        'android/app/src/main/kotlin/'
        '${kApplicationId.replaceAll('.', '/')}/MainActivity.kt';
    final source = File(path);
    expect(
      source.existsSync(),
      isTrue,
      reason:
          '$kApplicationId$className is what the launcher loads, so $path '
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

  test('scheduled notifications fire and survive a reboot', () {
    final text = File(manifest).readAsStringSync();
    expect(
      text,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver',
      ),
    );
    expect(
      text,
      contains(
        'com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver',
      ),
    );
    expect(text, contains('android.intent.action.BOOT_COMPLETED'));
  });

  test('the sounds and icon the code names exist, and are kept in release', () {
    for (final path in [
      'android/app/src/main/res/raw/reminder_chime.wav',
      'assets/audio/chime/reminder_chime.wav',
      'android/app/src/main/res/drawable/ic_stat_jamaah.xml',
      for (final r in adhanRecordings) r.asset,
      for (final clip in ShortAdhan.values) clip.asset,
      for (final clip in ShortAdhan.values)
        'android/app/src/main/res/raw/${clip.raw}.mp3',
    ]) {
      expect(File(path).existsSync(), isTrue, reason: path);
    }
    expect(
      File('android/app/src/main/res/raw/keep.xml').readAsStringSync(),
      allOf(
        contains('@raw/adhan_*'),
        contains('@raw/azan_*'),
        contains('@raw/reminder_*'),
        contains('@drawable/ic_stat_jamaah'),
      ),
      reason: 'resource shrinking cannot see names used only from Dart',
    );
    expect(
      File('pubspec.yaml').readAsStringSync(),
      allOf(
        contains('- audio/full/'),
        contains('- audio/fajr/'),
        contains('- audio/short/'),
      ),
    );
    for (final clip in ShortAdhan.values) {
      final bytes = File(clip.asset).readAsBytesSync();
      expect(
        File('android/app/src/main/res/raw/${clip.raw}.mp3').readAsBytesSync(),
        bytes,
        reason: 'the preview plays exactly what the notification plays',
      );
    }
    expect(
      Directory('assets/audio')
          .listSync()
          .whereType<File>()
          .where((f) => !f.path.endsWith('.mp3') || f.path.contains('حي')),
      isEmpty,
      reason: 'source files stay out of the bundled assets',
    );
  });

  test(
    'the app can play the Adhan itself, full screen, and after a reboot',
    () {
      final text = File(manifest).readAsStringSync();
      for (final permission in const [
        'android.permission.FOREGROUND_SERVICE',
        'android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK',
        'android.permission.USE_FULL_SCREEN_INTENT',
        'android.permission.WAKE_LOCK',
      ]) {
        expect(text, contains(permission));
      }
      expect(text, contains('android:name=".AdhanService"'));
      expect(text, contains('android:foregroundServiceType="mediaPlayback"'));
      expect(text, contains('android:name=".AdhanActivity"'));
      expect(text, contains('android:showWhenLocked="true"'));
      expect(text, contains('android:name=".AdhanAlarmReceiver"'));
      expect(text, contains('android:name=".AdhanBootReceiver"'));
      // The full recording is read from the Flutter assets in place.
      expect(
        File('android/app/src/main/kotlin/dev/jamaah/app/AdhanService.kt')
            .readAsStringSync(),
        contains('flutter_assets/'),
      );
    },
  );
}
