import 'adhan_recordings.dart';

/// Ids of the user's own sounds start with this; bundled recordings never do.
const kCustomSoundPrefix = 'custom:';

bool isCustomSoundId(String id) => id.startsWith(kCustomSoundPrefix);

/// A sound the user added from their phone (2026-10-15). The file was copied
/// into the app's own storage, so [path] stays valid whatever happens to the
/// original. Played only by the app's own player: Android cannot use an
/// arbitrary file as a notification channel's sound.
class CustomSound {
  const CustomSound({required this.id, required this.name, required this.path});

  factory CustomSound.fromJson(Map<String, Object?> json) => CustomSound(
    id: json['id']! as String,
    name: json['name']! as String,
    path: json['path']! as String,
  );

  /// `custom:<uuid>`.
  final String id;

  /// The original file's name, or the user's own.
  final String name;

  /// Absolute path of the app's copy.
  final String path;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'path': path};

  CustomSound copyWith({String? name}) =>
      CustomSound(id: id, name: name ?? this.name, path: path);

  @override
  bool operator ==(Object other) =>
      other is CustomSound &&
      other.id == id &&
      other.name == name &&
      other.path == path;

  @override
  int get hashCode => Object.hash(id, name, path);
}

/// What a recording id plays: a bundled recording's asset, or the user's own
/// file. A custom id whose sound was deleted falls back to the bundled default
/// ([fallback] true), so an Adhan never goes silent for a missing file.
({String name, String source, bool fallback}) resolveRecording(
  String id,
  List<CustomSound> custom,
) {
  if (isCustomSoundId(id)) {
    for (final s in custom) {
      if (s.id == id) return (name: s.name, source: s.path, fallback: false);
    }
    final d = adhanRecordingById(kDefaultAdhanRecording);
    return (name: d.name, source: d.asset, fallback: true);
  }
  final r = adhanRecordingById(id);
  return (name: r.name, source: r.asset, fallback: false);
}
