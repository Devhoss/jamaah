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
    expect(channels[AdhanSoundMode.full]!.sound, ChannelSound.azanShort);
    expect(channels[AdhanSoundMode.short]!.sound, ChannelSound.azanShort);
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
    expect(c.id, contains('_v${kAdhanPresentationVersion}_'));
  });

  test('Adhan presentation version changes the immutable channel identity', () {
    final c = channelFor(adhan(mode: AdhanSoundMode.silent, vibrate: false));
    expect(c.id, 'jamaah_adhan_v${kAdhanPresentationVersion}_silent_still');
    expect(c.sound, ChannelSound.none);
    expect(c.vibrate, isFalse);
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

  test('every supplied short Adhan clip has its own channel sound', () {
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
    final channels = [
      for (final clip in ShortAdhan.values)
        channelFor(short(clip, AdhanSoundMode.short)),
    ];
    expect(
      channels.map((c) => c.sound).toSet(),
      hasLength(ShortAdhan.values.length),
    );
    expect(
      channels.map((c) => c.id).toSet(),
      hasLength(ShortAdhan.values.length),
    );
    expect(channels.first.id, channelFor(adhan()).id);
    for (final channel in channels) {
      expect(channel.id, contains('_t$kAdhanToneVersion'));
    }
    expect(
      channelFor(short(ShortAdhan.adhanVerseOne, AdhanSoundMode.full)).sound,
      ChannelSound.adhanVerseOne,
      reason: 'a full Adhan notification sounds the selected short clip',
    );
    expect(
      channelFor(short(ShortAdhan.adhanVerseOne, AdhanSoundMode.standard))
          .sound,
      ChannelSound.platformDefault,
    );
  });

  test('every sound file a channel names is a different raw resource', () {
    expect(
      ShortAdhan.values
          .map(
            (clip) => rawSoundFor(switch (clip) {
              ShortAdhan.azanShort => ChannelSound.azanShort,
              ShortAdhan.azanAllahAkbar => ChannelSound.azanAllahAkbar,
              ShortAdhan.azanShortOne => ChannelSound.azanShortOne,
              ShortAdhan.adhanVerseOne => ChannelSound.adhanVerseOne,
              ShortAdhan.adhanVerseTwo => ChannelSound.adhanVerseTwo,
            }),
          )
          .toSet(),
      ShortAdhan.values.map((clip) => clip.raw).toSet(),
    );
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
    expect(iqama(ReminderSound.silent).sound, ChannelSound.none);
    expect(iqama(ReminderSound.silent, vibrate: false).vibrate, isFalse);
    expect(
      {
        for (final s in ReminderSound.values) ...[
          iqama(s).id,
          iqama(s, vibrate: false).id,
        ],
      },
      hasLength(16),
      reason: 'custom sounds use the chime channel as fallback',
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

  test('extra-time alerts get their own channel, with the reminder sound', () {
    final c = channelFor(
      PlannedNotification(
        id: 1,
        kind: NotificationKind.extra,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: '',
        reminderSound: ReminderSound.chime,
      ),
    );
    expect(c.id, 'jamaah_extra_chime_vib_c$kReminderChimeVersion');
    expect(c.group, ChannelGroup.extra);
    expect(c.sound, ChannelSound.chime);
  });

  group('ringing on silent goes through the app’s own player (2026-10-14)', () {
    // A channel sound is muted with the phone on silent, even on the alarm
    // stream (seen on a Samsung A53): only a sound the app plays rings.
    PlannedNotification reminder({
      NotificationKind kind = NotificationKind.iqama,
      ReminderSound sound = ReminderSound.chime,
      bool ring = true,
    }) => PlannedNotification(
      id: 1,
      kind: kind,
      prayer: Prayer.fajr,
      at: DateTime.utc(2026),
      soundMode: null,
      mosqueId: '',
      reminderSound: sound,
      ringInSilent: ring,
    );

    test('a reminder that rings on silent is played by the app', () {
      expect(playsInApp(reminder()), isTrue);
      expect(playsInApp(reminder(kind: NotificationKind.extra)), isTrue);
      expect(playsInApp(reminder(ring: false)), isFalse);
      expect(
        playsInApp(reminder(sound: ReminderSound.silent)),
        isFalse,
        reason: 'nothing to play',
      );
    });

    test('so is a short Adhan or a reminder before the Adhan', () {
      final short = PlannedNotification(
        id: 1,
        kind: NotificationKind.adhan,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: AdhanSoundMode.short,
        mosqueId: '',
        ringInSilent: true,
      );
      expect(playsInApp(short), isTrue);
      final before = PlannedNotification(
        id: 2,
        kind: NotificationKind.preAdhan,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: null,
        mosqueId: '',
        ringInSilent: true,
      );
      expect(playsInApp(before), isTrue);
    });

    test('the app is told which sound to play', () {
      expect(inAppSound(reminder()), (sound: 'raw', raw: 'reminder_chime'));
      expect(inAppSound(reminder(sound: ReminderSound.standard)), (
        sound: 'standard',
        raw: '',
      ));
      final full = PlannedNotification(
        id: 1,
        kind: NotificationKind.adhan,
        prayer: Prayer.fajr,
        at: DateTime.utc(2026),
        soundMode: AdhanSoundMode.full,
        mosqueId: '',
      );
      expect(inAppSound(full), (sound: 'full', raw: ''));
    });
  });
}
