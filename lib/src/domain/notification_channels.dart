import 'adhan_alerts.dart';
import 'notification_plan.dart';

/// What a channel plays. Android fixes a channel's sound when the channel is
/// created, so the sound is part of the channel's identity (AGENTS.md).
enum ChannelSound {
  /// No sound at all: the notification is still shown (silent is not disabled).
  none,

  /// The platform's default notification sound.
  platformDefault,

  /// The bundled short Adhan. Also used by "full" alerts: a full-length Adhan is
  /// played by the app itself (g4), not by the channel.
  adhanShort,
}

/// One Android notification channel, as data.
class ChannelSpec {
  const ChannelSpec({
    required this.id,
    required this.group,
    required this.sound,
    required this.vibrate,
    required this.alarmStream,
    this.mode,
  });

  final String id;
  final ChannelGroup group;
  final ChannelSound sound;
  final bool vibrate;

  /// Plays through the alarm volume, so it is heard when the phone is on silent.
  final bool alarmStream;

  /// The Adhan sound mode, for Adhan channels.
  final AdhanSoundMode? mode;

  @override
  bool operator ==(Object other) => other is ChannelSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChannelSpec($id)';
}

enum ChannelGroup { adhan, preAdhan, iqama }

/// Bumped whenever a bundled sound file changes. The version is part of every
/// Adhan channel id, so a new recording gets new channels and the old ones are
/// retired, instead of Android quietly keeping the old sound.
const kAdhanToneVersion = 1;

/// Every channel id this app creates starts with this, so stale ones can be found
/// and removed without touching anything else.
const kChannelPrefix = 'jamaah_';

/// The channel a planned notification is posted on.
ChannelSpec channelFor(PlannedNotification n) => switch (n.kind) {
  NotificationKind.adhan => _adhanChannel(n),
  NotificationKind.preAdhan => ChannelSpec(
    id: '${kChannelPrefix}reminder_${n.vibrate ? 'vib' : 'still'}',
    group: ChannelGroup.preAdhan,
    sound: ChannelSound.platformDefault,
    vibrate: n.vibrate,
    alarmStream: false,
  ),
  NotificationKind.iqama => const ChannelSpec(
    id: '${kChannelPrefix}iqama',
    group: ChannelGroup.iqama,
    sound: ChannelSound.platformDefault,
    vibrate: true,
    alarmStream: false,
  ),
};

ChannelSpec _adhanChannel(PlannedNotification n) {
  final mode = n.soundMode ?? AdhanSoundMode.standard;
  final sound = switch (mode) {
    AdhanSoundMode.full || AdhanSoundMode.short => ChannelSound.adhanShort,
    AdhanSoundMode.standard => ChannelSound.platformDefault,
    AdhanSoundMode.silent => ChannelSound.none,
  };
  // Ring in silent only applies to a recording that plays (the planner already
  // drops it otherwise); silent with vibration off is fully quiet.
  final alarm = n.ringInSilent && sound == ChannelSound.adhanShort;
  final vibrate = n.vibrate;
  final parts = [
    'adhan',
    mode.name,
    vibrate ? 'vib' : 'still',
    if (alarm) 'alarm',
    if (sound == ChannelSound.adhanShort) 't$kAdhanToneVersion',
  ];
  return ChannelSpec(
    id: '$kChannelPrefix${parts.join('_')}',
    group: ChannelGroup.adhan,
    sound: sound,
    vibrate: vibrate,
    alarmStream: alarm,
    mode: mode,
  );
}
