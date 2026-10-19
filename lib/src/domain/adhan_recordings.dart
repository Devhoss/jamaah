import 'prayer.dart';

/// The Adhan recordings bundled with the app. Source files were supplied by
/// the project owner; their known provenance and licence status are recorded
/// in docs/audio-licence.md.
class AdhanRecording {
  const AdhanRecording({
    required this.id,
    required this.name,
    required this.asset,
    required this.seconds,
    this.prayerOnly,
  });

  /// Stored in settings; ids must remain stable after release.
  final String id;
  final String name;
  final String asset;
  final int seconds;

  /// Fajr-specific recordings are offered only for Fajr alerts.
  final Prayer? prayerOnly;
}

const _full = 'audio/full';
const _fajr = 'audio/fajr';
const _short = 'audio/short';

const List<AdhanRecording> adhanRecordings = [
  AdhanRecording(
    id: 'ahmed_el_haddad',
    name: 'Ahmed El Haddad',
    asset: '$_full/Ahmed El Haddad.mp3',
    seconds: 155,
  ),
  AdhanRecording(
    id: 'mansour_al_salimi',
    name: 'Mansour Al Salimi',
    asset: '$_full/Mansour Al Salimi.mp3',
    seconds: 149,
  ),
  AdhanRecording(
    id: 'mohammad_hmoud',
    name: 'Mohammad Hmoud',
    asset: '$_full/Mohammad Hmoud.mp3',
    seconds: 174,
  ),
  AdhanRecording(
    id: 'muezzin',
    name: 'Muezzin',
    // Asset paths are case-sensitive on Android; preserve the supplied name.
    asset: '$_full/muezzin.mp3',
    seconds: 130,
  ),
  AdhanRecording(
    id: 'muezzin_fajr',
    name: 'Muezzin Fajr',
    asset: '$_fajr/muezzin fajr.mp3',
    seconds: 188,
    prayerOnly: Prayer.fajr,
  ),
  AdhanRecording(
    id: 'fajr_adhan_alarm',
    name: 'Fajr Adhan Alarm',
    asset: '$_fajr/fajr_adhan_alarm_v3.mp3',
    seconds: 278,
    prayerOnly: Prayer.fajr,
  ),
];

/// The full Adhan used for a fresh install.
const kDefaultAdhanRecording = 'muezzin';

/// A short Adhan clip. Its same MP3 asset is copied to Android's `res/raw` so
/// notification previews and notification-channel sounds use the same audio.
enum ShortAdhan {
  azanShort(
    label: 'Azan Short',
    asset: '$_short/azan_short.mp3',
    raw: 'azan_short',
  ),
  azanAllahAkbar(
    label: 'Azan Allah Akbar HD',
    asset: '$_short/azan_allah_akbar_hd.mp3',
    raw: 'azan_allah_akbar_hd',
  ),
  azanShortOne(
    label: 'Azan Short 1',
    asset: '$_short/azan_short1.mp3',
    raw: 'azan_short_1',
  ),
  adhanVerseOne(
    label: 'Adhan Verse 1',
    asset: '$_short/adhan_verse1_clean.mp3',
    raw: 'adhan_verse_1',
  ),
  adhanVerseTwo(
    label: 'Adhan Verse 2',
    asset: '$_short/adhan_verse2_clean.mp3',
    raw: 'adhan_verse_2',
  );

  const ShortAdhan({
    required this.label,
    required this.asset,
    required this.raw,
  });

  /// Source filename rendered as a human-readable option label.
  final String label;

  /// Flutter asset used for the preview and app-owned playback.
  final String asset;

  /// Android raw resource used by a notification channel.
  final String raw;
}

/// The recording stored as [id]; if a removed recording is still saved on a
/// device, use the current default instead of leaving an alert without audio.
AdhanRecording adhanRecordingById(String? id) => adhanRecordings.firstWhere(
  (r) => r.id == id,
  orElse: () =>
      adhanRecordings.firstWhere((r) => r.id == kDefaultAdhanRecording),
);

/// The recordings available for the shared setting or one prayer's setting.
List<AdhanRecording> recordingsForPrayer(Prayer? prayer) => [
  for (final recording in adhanRecordings)
    if (recording.prayerOnly == null || recording.prayerOnly == prayer)
      recording,
];
