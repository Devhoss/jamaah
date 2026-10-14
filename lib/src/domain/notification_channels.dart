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
  adhanShort,

  /// The app's own Jama’ah reminder chime (tool/generate_reminder_chime.dart).
  chime,

  /// The «حيّ على الصلاة» clip: a short Adhan choice and a reminder choice.
  hayya,
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
const kAdhanToneVersion = 2;

/// The same, for the Jama’ah reminder chime.
const kReminderChimeVersion = 1;

/// The same, for the «حيّ على الصلاة» clip.
const kHayyaVersion = 2;

/// The raw resource a channel sound plays, or null for the platform's sound
/// or none.
String? rawSoundFor(ChannelSound sound) => switch (sound) {
  ChannelSound.adhanShort => ShortAdhan.naghshbandi.raw,
  ChannelSound.hayya => ShortAdhan.hayya.raw,
  ChannelSound.chime => 'reminder_chime',
  ChannelSound.none || ChannelSound.platformDefault => null,
};

/// The file version that goes into the id of a channel with [sound], so a
/// changed file gets a new channel.
String? _versionTag(ChannelSound sound) => switch (sound) {
  ChannelSound.adhanShort => 't$kAdhanToneVersion',
  ChannelSound.hayya => 'h$kHayyaVersion',
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
    id: '${kChannelPrefix}reminder_${n.vibrate ? 'vib' : 'still'}',
    group: ChannelGroup.preAdhan,
    sound: ChannelSound.platformDefault,
    vibrate: n.vibrate,
    alarmStream: false,
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
  final reminder = n.reminderSound ?? ReminderSound.chime;
  final sound = switch (reminder) {
    ReminderSound.chime => ChannelSound.chime,
    ReminderSound.hayya => ChannelSound.hayya,
    ReminderSound.standard => ChannelSound.platformDefault,
    ReminderSound.silent => ChannelSound.none,
  };
  final parts = [
    prefix,
    reminder.name,
    n.vibrate ? 'vib' : 'still',
    ?_versionTag(sound),
  ];
  return ChannelSpec(
    id: '$kChannelPrefix${parts.join('_')}',
    group: group,
    sound: sound,
    vibrate: n.vibrate,
    alarmStream: false,
    reminderSound: reminder,
  );
}

ChannelSpec _adhanChannel(PlannedNotification n) {
  final mode = n.soundMode ?? AdhanSoundMode.standard;
  final clip = n.shortAdhan ?? ShortAdhan.naghshbandi;
  final sound = switch (mode) {
    AdhanSoundMode.full || AdhanSoundMode.short => switch (clip) {
      ShortAdhan.naghshbandi => ChannelSound.adhanShort,
      ShortAdhan.hayya => ChannelSound.hayya,
    },
    AdhanSoundMode.standard => ChannelSound.platformDefault,
    AdhanSoundMode.silent => ChannelSound.none,
  };
  final plays = sound == ChannelSound.adhanShort || sound == ChannelSound.hayya;
  // Ring in silent only applies to a recording that plays (the planner already
  // drops it otherwise); silent with vibration off is fully quiet.
  final alarm = n.ringInSilent && plays;
  final vibrate = n.vibrate;
  final parts = [
    'adhan',
    mode.name,
    vibrate ? 'vib' : 'still',
    if (alarm) 'alarm',
    // The Naghshbandi clip keeps the ids it had before there was a choice.
    if (sound == ChannelSound.hayya) 'hayya',
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

/// True for an Adhan the app plays itself (native AdhanService) rather than as
/// a notification sound: the full recording, which is too long for a channel
/// sound, and any Adhan shown full screen.
bool playsInApp(PlannedNotification n) =>
    n.kind == NotificationKind.adhan &&
    (n.soundMode == AdhanSoundMode.full || n.fullScreen);
