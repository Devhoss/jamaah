import 'package:flutter_test/flutter_test.dart';

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

  test('reminders and Iqama use their own groups and the default sound', () {
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
    expect(iqama.sound, ChannelSound.platformDefault);
    expect({pre.id, iqama.id, channelFor(adhan()).id}, hasLength(3));
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
}
