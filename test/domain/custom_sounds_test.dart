import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/domain/custom_sounds.dart';
import 'package:jamaah/src/domain/notification_channels.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/prayer.dart';

/// The user's own sounds (2026-10-15): files from the phone, played by the
/// app's own player, with a bundled sound behind them if they go missing.
void main() {
  const fajrAdhan = CustomSound(
    id: 'custom:a1',
    name: 'Fajr Adhan',
    path: '/data/user/0/dev.jamaah.app/files/sounds/a1.mp3',
  );
  const bell = CustomSound(
    id: 'custom:b2',
    name: 'Bell',
    path: '/data/user/0/dev.jamaah.app/files/sounds/b2.ogg',
  );

  group('which recording plays', () {
    test('a bundled one by its asset', () {
      final r = resolveRecording('ahmed_el_haddad', const []);
      expect(r.source, adhanRecordingById('ahmed_el_haddad').asset);
      expect(r.name, 'Ahmed El Haddad');
      expect(r.fallback, isFalse);
    });

    test('your own by its file', () {
      final r = resolveRecording(fajrAdhan.id, const [fajrAdhan]);
      expect(r.source, fajrAdhan.path);
      expect(r.name, 'Fajr Adhan');
      expect(r.fallback, isFalse);
    });

    test('a deleted one falls back to the bundled default, and says so', () {
      final r = resolveRecording('custom:gone', const [fajrAdhan]);
      expect(r.source, adhanRecordingById(kDefaultAdhanRecording).asset);
      expect(r.fallback, isTrue);
    });

    test('a prayer can have its own, else the one in Settings', () {
      final alerts =
          const AdhanAlertSettings(
            fullRecording: 'ahmed_el_haddad',
            customRecordings: [fajrAdhan],
          ).withAlert(
            Prayer.fajr,
            AdhanAlert(enabled: true, recording: fajrAdhan.id),
          );
      expect(alerts.recordingFor(Prayer.fajr), fajrAdhan.id);
      expect(alerts.recordingFor(Prayer.dhuhr), 'ahmed_el_haddad');
      expect(alerts.recordingSourceFor(Prayer.fajr).source, fajrAdhan.path);
    });

    test("a full Adhan alert carries that prayer's recording", () {
      final alerts =
          const AdhanAlertSettings(
            defaultSoundMode: AdhanSoundMode.full,
            customRecordings: [fajrAdhan],
          ).withAlert(
            Prayer.fajr,
            AdhanAlert(enabled: true, recording: fajrAdhan.id),
          );
      final n = adhanAlert(alerts, Prayer.fajr, at: DateTime.utc(2026), id: 1);
      expect(n.recordingAsset, fajrAdhan.path);
      expect(playsInApp(n), isTrue);
    });
  });

  group('your own Jama’ah reminder sound', () {
    PlannedNotification reminder(JamaahReminderSettings r) =>
        PlannedNotification(
          id: 1,
          kind: NotificationKind.iqama,
          prayer: Prayer.asr,
          at: DateTime.utc(2026),
          soundMode: null,
          mosqueId: 'm1',
          reminderSound: r.sound,
          customSoundPath: r.customSoundPath,
          ringInSilent: r.ringInSilent,
        );

    test('is played by the app, from its file, with the chime behind it', () {
      const r = JamaahReminderSettings(
        sound: ReminderSound.custom,
        customSound: bell,
      );
      expect(r.customSoundPath, bell.path);
      final n = reminder(r);
      expect(playsInApp(n), isTrue, reason: 'even without ring on silent');
      expect(inAppSound(n), (sound: 'file', raw: 'reminder_chime'));
    });

    test('without its file it is the chime', () {
      const r = JamaahReminderSettings(sound: ReminderSound.custom);
      expect(r.customSoundPath, isNull);
      final n = reminder(r);
      expect(playsInApp(n), isFalse);
      expect(channelFor(n).sound, ChannelSound.chime);
    });

    test('a reminder plays at most 30 seconds; an Adhan to the end', () {
      expect(kReminderMaxSeconds, 30);
      expect(maxSecondsFor(reminder(const JamaahReminderSettings())), 30);
      final adhan = PlannedNotification(
        id: 2,
        kind: NotificationKind.adhan,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: AdhanSoundMode.full,
        mosqueId: '',
      );
      expect(maxSecondsFor(adhan), 0);
    });
  });

  test('a sound round-trips through JSON', () {
    expect(CustomSound.fromJson(bell.toJson()), bell);
    expect(isCustomSoundId(bell.id), isTrue);
    expect(isCustomSoundId('makkah'), isFalse);
  });
}
