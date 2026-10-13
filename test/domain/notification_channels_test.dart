import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/domain/adhan_recordings.dart';
import 'package:jamaah/src/domain/adhan_alerts.dart';
import 'package:jamaah/src/domain/notification_channels.dart';
import 'package:jamaah/src/domain/notification_plan.dart';
import 'package:jamaah/src/domain/prayer.dart';

/// Android binds a sound to a channel when the channel is created, so every
/// difference in how a notification sounds must be a different channel
/// (AGENTS.md). These pin that mapping.
void main() {
  PlannedNotification adhan({
    AdhanSoundMode mode = AdhanSoundMode.short,
    bool vibrate = true,
    bool ringInSilent = false,
  }) => PlannedNotification(
    id: 1,
    kind: NotificationKind.adhan,
    prayer: Prayer.fajr,
    at: DateTime.utc(2026),
    soundMode: mode,
    mosqueId: '',
    vibrate: vibrate,
    ringInSilent: ringInSilent,
  );

  test('each sound mode has its own channel and sound', () {
    final channels = {
      for (final mode in AdhanSoundMode.values)
        mode: channelFor(adhan(mode: mode)),
    };
    expect(channels.values.map((c) => c.id).toSet(), hasLength(4));
    expect(channels[AdhanSoundMode.full]!.sound, ChannelSound.adhanShort);
    expect(channels[AdhanSoundMode.short]!.sound, ChannelSound.adhanShort);
    expect(
      channels[AdhanSoundMode.standard]!.sound,
      ChannelSound.platformDefault,
    );
    expect(
      channels[AdhanSoundMode.silent]!.sound,
      ChannelSound.none,
      reason: 'silent is shown without sound, not disabled',
    );
  });

  test('vibration on and off are different channels', () {
    expect(
      channelFor(adhan(vibrate: true)).id,
      isNot(channelFor(adhan(vibrate: false)).id),
    );
    expect(channelFor(adhan(vibrate: false)).vibrate, isFalse);
  });

  test('silent with vibration off is completely quiet', () {
    final c = channelFor(adhan(mode: AdhanSoundMode.silent, vibrate: false));
    expect(c.sound, ChannelSound.none);
    expect(c.vibrate, isFalse);
    expect(c.alarmStream, isFalse);
  });

  test('ring in silent gets an alarm-volume channel of its own', () {
    final normal = channelFor(adhan());
    final alarm = channelFor(adhan(ringInSilent: true));
    expect(alarm.alarmStream, isTrue);
    expect(normal.alarmStream, isFalse);
    expect(alarm.id, isNot(normal.id));
  });

  test('a channel that plays the bundled tone names its tone version', () {
    expect(channelFor(adhan()).id, endsWith('_t$kAdhanToneVersion'));
    expect(
      channelFor(adhan(mode: AdhanSoundMode.standard)).id,
      isNot(contains('_t')),
      reason: 'the platform sound does not change with our files',
    );
  });

  test('reminders and Iqama use their own groups; Iqama chimes by default', () {
    final pre = channelFor(
      PlannedNotification(
        id: 2,
        kind: NotificationKind.preAdhan,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: '',
        minutesBefore: 15,
      ),
    );
    final iqama = channelFor(
      PlannedNotification(
        id: 3,
        kind: NotificationKind.iqama,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: 'm1',
        minutesBefore: 10,
      ),
    );
    expect(pre.group, ChannelGroup.preAdhan);
    expect(iqama.group, ChannelGroup.iqama);
    expect(pre.sound, ChannelSound.platformDefault);
    expect(iqama.sound, ChannelSound.chime);
    expect(iqama.id, endsWith('_c$kReminderChimeVersion'));
    expect({pre.id, iqama.id, channelFor(adhan()).id}, hasLength(3));
  });

  test('the short Adhan clip is part of the Adhan channel', () {
    PlannedNotification short(ShortAdhan clip, AdhanSoundMode mode) =>
        PlannedNotification(
          id: 1,
          kind: NotificationKind.adhan,
          prayer: Prayer.fajr,
          at: DateTime.utc(2026),
          soundMode: mode,
          mosqueId: '',
          shortAdhan: clip,
        );
    final naghshbandi = channelFor(
      short(ShortAdhan.naghshbandi, AdhanSoundMode.short),
    );
    final hayya = channelFor(short(ShortAdhan.hayya, AdhanSoundMode.short));
    expect(naghshbandi.sound, ChannelSound.adhanShort);
    expect(
      naghshbandi.id,
      channelFor(adhan()).id,
      reason: 'the Naghshbandi channels keep the ids they had before',
    );
    expect(hayya.sound, ChannelSound.hayya);
    expect(hayya.id, endsWith('_hayya_h$kHayyaVersion'));
    expect(
      channelFor(short(ShortAdhan.hayya, AdhanSoundMode.full)).sound,
      ChannelSound.hayya,
      reason: 'a full Adhan notification sounds the chosen short clip',
    );
    expect(
      channelFor(short(ShortAdhan.hayya, AdhanSoundMode.standard)).sound,
      ChannelSound.platformDefault,
    );
  });

  test('every sound file a channel names is a different raw resource', () {
    expect(rawSoundFor(ChannelSound.adhanShort), 'adhan_short');
    expect(rawSoundFor(ChannelSound.hayya), 'adhan_short_hayya');
    expect(rawSoundFor(ChannelSound.chime), 'reminder_chime');
    expect(rawSoundFor(ChannelSound.none), isNull);
    expect(rawSoundFor(ChannelSound.platformDefault), isNull);
  });

  test('each Jama’ah reminder sound and vibration is a channel of its own', () {
    ChannelSpec iqama(ReminderSound sound, {bool vibrate = true}) => channelFor(
      PlannedNotification(
        id: 3,
        kind: NotificationKind.iqama,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: 'm1',
        minutesBefore: 10,
        vibrate: vibrate,
        reminderSound: sound,
      ),
    );
    expect(iqama(ReminderSound.standard).sound, ChannelSound.platformDefault);
    expect(iqama(ReminderSound.hayya).sound, ChannelSound.hayya);
    expect(iqama(ReminderSound.silent).sound, ChannelSound.none);
    expect(iqama(ReminderSound.silent, vibrate: false).vibrate, isFalse);
    expect(
      {
        for (final s in ReminderSound.values) ...[
          iqama(s).id,
          iqama(s, vibrate: false).id,
        ],
      },
      hasLength(8),
    );
    expect(
      iqama(ReminderSound.chime).id,
      isNot(contains('standard')),
      reason: 'a channel never carries a sound it does not play',
    );
  });

  test(
    'every channel id carries the app prefix, so stale ones can be found',
    () {
      for (final mode in AdhanSoundMode.values) {
        for (final vibrate in [true, false]) {
          for (final ring in [true, false]) {
            expect(
              channelFor(
                adhan(mode: mode, vibrate: vibrate, ringInSilent: ring),
              ).id,
              startsWith(kChannelPrefix),
            );
          }
        }
      }
    },
  );

  test('the app plays the full Adhan and every full-screen Adhan itself', () {
    PlannedNotification of(AdhanSoundMode mode, {bool fullScreen = false}) =>
        PlannedNotification(
          id: 1,
          kind: NotificationKind.adhan,
          prayer: Prayer.fajr,
          at: DateTime.utc(2026),
          soundMode: mode,
          mosqueId: '',
          fullScreen: fullScreen,
        );
    expect(playsInApp(of(AdhanSoundMode.full)), isTrue);
    expect(playsInApp(of(AdhanSoundMode.short)), isFalse);
    expect(playsInApp(of(AdhanSoundMode.standard)), isFalse);
    expect(playsInApp(of(AdhanSoundMode.silent, fullScreen: true)), isTrue);
    expect(
      playsInApp(
        PlannedNotification(
          id: 2,
          kind: NotificationKind.iqama,
          prayer: Prayer.fajr,
          at: DateTime.utc(2026),
          soundMode: null,
          mosqueId: 'm1',
          fullScreen: true,
        ),
      ),
      isFalse,
      reason: 'reminders are always ordinary notifications',
    );
  });
}
