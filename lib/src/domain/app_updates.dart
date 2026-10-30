/// Pure logic for the app's own update check (2026-10-31): the newest Jama'ah
/// release on GitHub is compared with this build, and the release's APK asset
/// and its checksum sidecar are picked out. No Flutter here, so the comparison
/// and the picking are unit-tested without a device (modelled on openGym's
/// updater, which discovered both tricky parts the hard way).
library;

/// Compares two released version numbers by major, minor and patch.
///
/// Build metadata after a "+" takes no part in precedence, and it is dropped
/// from both operands: "1.0.5" and "1.0.5+6" are the same version, whichever
/// side carries the build. A wrong comparison has already shipped once in an
/// app like ours — metadata split as a third-and-more part read as 0, and a
/// real update went unnoticed. Something that does not parse as numbers at
/// all ("dev") has no version: [runningVersionIsKnown] reports it.
int compareAppVersions(String a, String b) {
  final pa = _versionParts(a);
  final pb = _versionParts(b);
  for (var i = 0; i < 3; i++) {
    final diff = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (diff > 0) return 1;
    if (diff < 0) return -1;
  }
  return 0;
}

/// Whether [version] is a real released version ("1.0.5") rather than a
/// placeholder ("dev"). A build made outside the release script has none.
bool runningVersionIsKnown(String version) =>
    _versionParts(version).any((p) => p != null);

/// Whether [latest] is newer than [running], with the "dev" rule: a build
/// without a version number always sees an update, so a tester's local build
/// is never told it is up to date while a released one sits on GitHub.
bool runningIsOlderThan(String latest, String running) {
  if (!runningVersionIsKnown(running)) return true;
  if (!runningVersionIsKnown(latest)) return false;
  return compareAppVersions(latest, running) > 0;
}

/// Major, minor and patch of [version], each null where it is not a plain
/// number. "v1.2.3" loses its "v"; "1.2.3+6" loses its build metadata; "dev"
/// has none at all.
List<int?> _versionParts(String version) {
  final core = version.trim().replaceFirst(RegExp('^v', caseSensitive: false), '').split('+').first;
  final parts = core.split('.');
  return [for (var i = 0; i < 3; i++) i < parts.length ? int.tryParse(parts[i].trim()) : null];
}

/// One release's usable APK, with the checksum sidecar named exactly after it.
///
/// The name is pinned ([releaseAssetNamePattern]) on purpose: the updater only
/// ever offers the app its own well-formed release file, never the first
/// anything on a release that happens to end in .apk.
class ApkAsset {
  const ApkAsset({required this.version, required this.downloadUrl, required this.sha256Url});

  final String version;
  final String downloadUrl;
  final String sha256Url;
}

final RegExp releaseAssetNamePattern =
    RegExp(r'^Jamaah-([0-9]+\.[0-9]+\.[0-9]+)\.apk$', caseSensitive: false);

/// The file the updater writes its download as, and the one the native
/// installer agrees to touch (android UpdateFile.kt knows this shape too).
const String updaterApkFileName = 'Jamaah-update.apk';

/// Picks the release's APK from its assets, Windows naming straight from the
/// README's build script. The sidecar must exist next to it: without a
/// checksum the download cannot be verified, and an unverified APK is never
/// installed — no sidecar means no direct update and the user is sent to the
/// releases page instead.
ApkAsset? pickApkAsset(List<Map<String, Object?>> assets) {
  for (final asset in assets) {
    final name = asset['name'];
    final url = asset['browser_download_url'];
    if (name is! String || url is! String) continue;
    final match = releaseAssetNamePattern.firstMatch(name);
    if (match == null) continue;
    final sha = assets.any(
      (a) => a['name'] == '$name.sha256' && a['browser_download_url'] is String,
    );
    if (!sha) return null;
    return ApkAsset(
      version: match.group(1)!,
      downloadUrl: url,
      sha256Url: '$url.sha256',
    );
  }
  return null;
}
