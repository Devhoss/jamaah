import 'adhan_alerts.dart';
import 'adhan_recordings.dart';
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
  azanShort,
  azanAllahAkbar,
  azanShortOne,
  adhanVerseOne,
  adhanVerseTwo,

  /// The app's own Jama’ah reminder chime (tool/generate_reminder_chime.dart).
  chime,
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
    this.reminderSound,
  });

  final String id;
  final ChannelGroup group;
  final ChannelSound sound;
  final bool vibrate;

  /// Plays through the alarm volume, so it is heard when the phone is on silent.
  final bool alarmStream;

  /// The Adhan sound mode, for Adhan channels.
  final AdhanSoundMode? mode;

  /// The reminder sound, for Jama’ah reminder channels.
  final ReminderSound? reminderSound;

  @override
  bool operator ==(Object other) => other is ChannelSpec && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ChannelSpec($id)';
}

enum ChannelGroup { adhan, preAdhan, iqama, extra }

/// Bumped whenever a bundled sound file changes. The version is part of every
/// Adhan channel id, so a new recording gets new channels and the old ones are
/// retired, instead of Android quietly keeping the old sound.
const kAdhanToneVersion = 3;

const kReminderChimeVersion = 1;

/// The raw resource a channel sound plays, or null for the platform's sound
/// or none.
String? rawSoundFor(ChannelSound sound) => switch (sound) {
  ChannelSound.azanShort => ShortAdhan.azanShort.raw,
  ChannelSound.azanAllahAkbar => ShortAdhan.azanAllahAkbar.raw,
  ChannelSound.azanShortOne => ShortAdhan.azanShortOne.raw,
  ChannelSound.adhanVerseOne => ShortAdhan.adhanVerseOne.raw,
  ChannelSound.adhanVerseTwo => ShortAdhan.adhanVerseTwo.raw,
  ChannelSound.chime => 'reminder_chime',
  ChannelSound.none || ChannelSound.platformDefault => null,
};

/// The file version that goes into the id of a channel with [sound], so a
/// changed file gets a new channel.
String? _versionTag(ChannelSound sound) => switch (sound) {
  ChannelSound.azanShort ||
  ChannelSound.azanAllahAkbar ||
  ChannelSound.azanShortOne ||
  ChannelSound.adhanVerseOne ||
  ChannelSound.adhanVerseTwo => 't$kAdhanToneVersion',
  ChannelSound.chime => 'c$kReminderChimeVersion',
  ChannelSound.none || ChannelSound.platformDefault => null,
};

/// Every channel id this app creates starts with this, so stale ones can be found
/// and removed without touching anything else.
const kChannelPrefix = 'jamaah_';

/// The channel a planned notification is posted on.
ChannelSpec channelFor(PlannedNotification n) => switch (n.kind) {
  NotificationKind.adhan => _adhanChannel(n),
  NotificationKind.preAdhan => ChannelSpec(
    id:
        '${kChannelPrefix}reminder_${n.vibrate ? 'vib' : 'still'}'
        '${n.ringInSilent ? '_alarm' : ''}',
    group: ChannelGroup.preAdhan,
    sound: ChannelSound.platformDefault,
    vibrate: n.vibrate,
    alarmStream: n.ringInSilent,
  ),
  NotificationKind.iqama => _reminderChannel(n, 'iqama', ChannelGroup.iqama),
  NotificationKind.extra => _reminderChannel(n, 'extra', ChannelGroup.extra),
};

/// A channel that plays the Jama’ah reminder sound: the reminders themselves,
/// and the extra-time alerts, which sound the same but are their own channel.
ChannelSpec _reminderChannel(
  PlannedNotification n,
  String prefix,
  ChannelGroup group,
) {
  // The user's own sound is played by the app; on a channel it is the chime,
  // the same channel as the chime itself.
  final reminder = switch (n.reminderSound ?? ReminderSound.chime) {
    ReminderSound.custom => ReminderSound.chime,
    final other => other,
  };
  final sound = switch (reminder) {
    ReminderSound.chime => ChannelSound.chime,
    ReminderSound.shortAzan => ChannelSound.azanShort,
    ReminderSound.shortAllahAkbar => ChannelSound.azanAllahAkbar,
    ReminderSound.shortAzanOne => ChannelSound.azanShortOne,
    ReminderSound.shortVerseOne => ChannelSound.adhanVerseOne,
    ReminderSound.shortVerseTwo => ChannelSound.adhanVerseTwo,
    ReminderSound.standard => ChannelSound.platformDefault,
    ReminderSound.silent => ChannelSound.none,
    // The user's own file is played by the app; the chime stands behind it.
    ReminderSound.custom => ChannelSound.chime,
  };
  // A silent reminder has nothing to play through the alarm volume.
  final alarm = n.ringInSilent && sound != ChannelSound.none;
  final parts = [
    prefix,
    reminder.name,
    n.vibrate ? 'vib' : 'still',
    if (alarm) 'alarm',
    ?_versionTag(sound),
  ];
  return ChannelSpec(
    id: '$kChannelPrefix${parts.join('_')}',
    group: group,
    sound: sound,
    vibrate: n.vibrate,
    alarmStream: alarm,
    reminderSound: reminder,
  );
}

ChannelSpec _adhanChannel(PlannedNotification n) {
  final mode = n.soundMode ?? AdhanSoundMode.standard;
  final clip = n.shortAdhan ?? ShortAdhan.azanShort;
  final sound = switch (mode) {
    AdhanSoundMode.full || AdhanSoundMode.short => switch (clip) {
      ShortAdhan.azanShort => ChannelSound.azanShort,
      ShortAdhan.azanAllahAkbar => ChannelSound.azanAllahAkbar,
      ShortAdhan.azanShortOne => ChannelSound.azanShortOne,
      ShortAdhan.adhanVerseOne => ChannelSound.adhanVerseOne,
      ShortAdhan.adhanVerseTwo => ChannelSound.adhanVerseTwo,
    },
    AdhanSoundMode.standard => ChannelSound.platformDefault,
    AdhanSoundMode.silent => ChannelSound.none,
  };
  // Ring in silent applies to any Adhan with a sound (the planner already
  // drops it otherwise); silent with vibration off is fully quiet.
  final alarm = n.ringInSilent && sound != ChannelSound.none;
  final vibrate = n.vibrate;
  final parts = [
    'adhan',
    mode.name,
    vibrate ? 'vib' : 'still',
    if (alarm) 'alarm',
    if (sound == ChannelSound.azanShort ||
        sound == ChannelSound.azanAllahAkbar ||
        sound == ChannelSound.azanShortOne ||
        sound == ChannelSound.adhanVerseOne ||
        sound == ChannelSound.adhanVerseTwo)
      sound.name,
    ?_versionTag(sound),
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

/// True for what the app plays itself (native AdhanService) rather than as a
/// notification sound: the full recording, which is too long for a channel
/// sound; any Adhan shown full screen; and anything set to ring on silent
/// that has a sound. A channel's sound is muted with the phone on silent even
/// on the alarm stream (seen on a Samsung A53, 2026-10-14); a sound the app
/// plays on the alarm stream is not.
bool playsInApp(PlannedNotification n) =>
    (n.kind == NotificationKind.adhan &&
        (n.soundMode == AdhanSoundMode.full || n.fullScreen)) ||
    n.customSoundPath != null ||
    (n.ringInSilent && channelFor(n).sound != ChannelSound.none);

/// How long a sound the app plays may last: a reminder at most
/// [kReminderMaxSeconds], so a long file of the user's cannot keep ringing; an
/// Adhan to its end (0).
int maxSecondsFor(PlannedNotification n) =>
    n.kind == NotificationKind.adhan ? 0 : kReminderMaxSeconds;

const kReminderMaxSeconds = 30;

/// What the app's own player plays for [n]: an Adhan by its sound mode (and
/// recording), anything else by its channel's sound: a bundled raw sound by
/// name, the phone's notification sound, or none.
({String sound, String raw}) inAppSound(PlannedNotification n) {
  if (n.kind == NotificationKind.adhan) {
    return (sound: (n.soundMode ?? AdhanSoundMode.standard).name, raw: '');
  }
  // The user's own file, with the chime to fall back on if it cannot play.
  if (n.customSoundPath != null) {
    return (sound: 'file', raw: rawSoundFor(ChannelSound.chime)!);
  }
  final sound = channelFor(n).sound;
  return switch (rawSoundFor(sound)) {
    final raw? => (sound: 'raw', raw: raw),
    null when sound == ChannelSound.platformDefault => (
      sound: 'standard',
      raw: '',
    ),
    null => (sound: 'silent', raw: ''),
  };
}
