/// The Adhan recordings bundled with the app (added 2026-10-13), one of which
/// plays for every alert set to "Full Adhan".
///
/// Source and licence are recorded in docs/audio-licence.md. The names are
/// the reciters' and places' own, so they are data rather than strings to
/// translate.
class AdhanRecording {
  const AdhanRecording({
    required this.id,
    required this.name,
    required this.asset,
    required this.seconds,
  });

  /// Stored in the settings; never changes once shipped.
  final String id;
  final String name;

  /// The Flutter asset path. The native Adhan player opens the same file.
  final String asset;

  /// Length, for the list in Settings.
  final int seconds;
}

const _dir = 'assets/audio';

const List<AdhanRecording> adhanRecordings = [
  AdhanRecording(
    id: 'abdul_basit',
    name: 'Abdul Basit',
    asset: '$_dir/Abdul-Basit.mp3',
    seconds: 206,
  ),
  AdhanRecording(
    id: 'abdul_ghaffar',
    name: 'Abdul Ghaffar',
    asset: '$_dir/Abdul-Ghaffar.mp3',
    seconds: 186,
  ),
  AdhanRecording(
    id: 'abdul_hakam',
    name: 'Abdul Hakam',
    asset: '$_dir/Abdul-Hakam.mp3',
    seconds: 190,
  ),
  AdhanRecording(
    id: 'al_aqsa',
    name: 'Al-Aqsa',
    asset: '$_dir/Adhan-Alaqsa.mp3',
    seconds: 225,
  ),
  AdhanRecording(
    id: 'al_hussaini',
    name: 'Al-Hussaini',
    asset: '$_dir/Al-Hussaini.mp3',
    seconds: 196,
  ),
  AdhanRecording(
    id: 'bakir_bash',
    name: 'Bakir Bash',
    asset: '$_dir/Bakir-Bash.mp3',
    seconds: 347,
  ),
  AdhanRecording(
    id: 'egypt',
    name: 'Egypt',
    asset: '$_dir/Adhan-Egypt.mp3',
    seconds: 183,
  ),
  AdhanRecording(
    id: 'hafez',
    name: 'Hafez',
    asset: '$_dir/Hafez.mp3',
    seconds: 167,
  ),
  AdhanRecording(
    id: 'hafiz_murad',
    name: 'Hafiz Murad',
    asset: '$_dir/Hafiz-Murad.mp3',
    seconds: 102,
  ),
  AdhanRecording(
    id: 'halab',
    name: 'Halab',
    asset: '$_dir/Adhan-Halab.mp3',
    seconds: 223,
  ),
  AdhanRecording(
    id: 'madinah',
    name: 'Madinah',
    asset: '$_dir/Adhan-Madinah.mp3',
    seconds: 96,
  ),
  AdhanRecording(
    id: 'makkah',
    name: 'Makkah',
    asset: '$_dir/Adhan-Makkah.mp3',
    seconds: 201,
  ),
  AdhanRecording(
    id: 'minshawi',
    name: 'Minshawi',
    asset: '$_dir/Minshawi.mp3',
    seconds: 235,
  ),
  AdhanRecording(
    id: 'naghshbandi',
    name: 'Naghshbandi',
    asset: '$_dir/Naghshbandi.mp3',
    seconds: 162,
  ),
  AdhanRecording(
    id: 'saber',
    name: 'Saber',
    asset: '$_dir/Saber.mp3',
    seconds: 149,
  ),
  AdhanRecording(
    id: 'sharif_doman',
    name: 'Sharif Doman',
    asset: '$_dir/Sharif-Doman.mp3',
    seconds: 281,
  ),
  AdhanRecording(
    id: 'yusuf_islam',
    name: 'Yusuf Islam',
    asset: '$_dir/Yusuf-Islam.mp3',
    seconds: 99,
  ),
];

/// The recording a fresh install plays; the short Adhan is its opening.
const kDefaultAdhanRecording = 'naghshbandi';

/// "Short Adhan": the first 8 seconds of Naghshbandi, the opening phrase,
/// faded out in the pause after it. The same file is the notification
/// channel's sound (android/app/src/main/res/raw/adhan_short.ogg).
const kShortAdhanAsset = 'assets/audio/short/adhan_short.ogg';

/// «حيّ على الصلاة»: 1:09–1:19 of audio_sources/حي على الصلاه.mp3 (added
/// 2026-10-13). A choice for the short Adhan and for Jama’ah reminders.
const kHayyaAsset = 'assets/audio/short/hayya.ogg';

/// The short clips the user can choose for "Short Adhan" (2026-10-13). Each
/// is a notification channel sound, so each has a raw resource of its own.
enum ShortAdhan {
  naghshbandi(asset: kShortAdhanAsset, raw: 'adhan_short'),
  hayya(asset: kHayyaAsset, raw: 'adhan_short_hayya');

  const ShortAdhan({required this.asset, required this.raw});

  /// The Flutter asset: preview, and the app's own player.
  final String asset;

  /// The Android raw resource the notification channel plays.
  final String raw;
}

/// The recording stored as [id]; the default one for an id that is unknown
/// (a recording removed in a later version).
AdhanRecording adhanRecordingById(String? id) => adhanRecordings.firstWhere(
  (r) => r.id == id,
  orElse: () =>
      adhanRecordings.firstWhere((r) => r.id == kDefaultAdhanRecording),
);
