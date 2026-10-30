import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/http.dart';

import '../../domain/app_updates.dart';

/// The published release the app compares itself against, as the updater
/// needs it: the version on the tag, and the release's APK with its checksum
/// sidecar. Null-y bits mean "nothing newer to offer directly" — the row then
/// opens the releases page instead of downloading anything.
class LatestRelease {
  const LatestRelease({
    required this.tag,
    required this.apk,
    required this.releasesUrl,
  });

  /// The version on the tag without its "v" ("v1.0.5" → "1.0.5"), or "" when
  /// the tag carries no version.
  final String tag;

  /// The release's APK and checksum sidecar, or null when either is missing.
  final ApkAsset? apk;

  /// The human page for this release, for "open the releases page".
  final String releasesUrl;
}

/// Looks up the newest published release of the app on GitHub.
///
/// The API is public: no key travels with the check, and its address is the
/// app's own repository. `releases/latest` answers the newest release that is
/// neither a draft nor a pre-release, so a beta never offers itself as an
/// update.
class GitHubReleaseLookup {
  GitHubReleaseLookup({Client? client, this.endpoint, this.releasesPage})
    : _client = client ?? http.Client();

  final Client _client;

  /// `releases/latest` answers 404 while no release exists yet; that means
  /// exactly "no update", not an error.
  static const defaultEndpoint =
      'https://api.github.com/repos/Devhoss/jamaah/releases/latest';

  final String? endpoint;
  final String? releasesPage;

  String get releasesUrl =>
      releasesPage ?? 'https://github.com/Devhoss/jamaah/releases';

  Future<LatestRelease> latest() async {
    final response = await _client.get(
      Uri.parse(endpoint ?? defaultEndpoint),
      headers: const {'Accept': 'application/vnd.github+json'},
    );
    // 404: the repository has no published release yet.
    if (response.statusCode == 404) {
      return LatestRelease(tag: '', apk: null, releasesUrl: releasesUrl);
    }
    if (response.statusCode != 200) {
      throw UpdateException('the release lookup answered ${response.statusCode}');
    }
    final release =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, Object?>;
    final tag = release['tag_name'];
    final assets = (release['assets'] as List<Object?>? ?? [])
        .whereType<Map<String, Object?>>()
        .toList(growable: false);
    return LatestRelease(
      tag: tag is String ? tag.replaceFirst(RegExp('^v'), '') : '',
      releasesUrl: releasesUrl,
      apk: pickApkAsset(assets),
    );
  }

  /// Streams [apkUrl] into [file] — the cache file the native installer
  /// verifies later — calling [onProgress] with bytes received and the total,
  /// when the server said one. An exact-alarm app has no service running this;
  /// it runs while the user watches the row.
  ///
  /// [cancelled] is checked per chunk: true cancels, the part-written file is
  /// deleted, and [UpdateCancelled] is thrown — a partial APK must never sit
  /// where the installer goes looking.
  Future<void> downloadApk(
    String apkUrl,
    File file, {
    void Function(int received, int? total)? onProgress,
    bool Function()? cancelled,
  }) async {
    final streamed = await _client.send(
      http.Request('GET', Uri.parse(apkUrl))
        ..headers['Accept'] = 'application/vnd.android.package-archive',
    );
    if (streamed.statusCode != 200) {
      throw UpdateException('the download answered ${streamed.statusCode}');
    }
    final total = streamed.contentLength;
    var received = 0;
    IOSink? sink;
    try {
      sink = file.openWrite();
      await for (final chunk in streamed.stream) {
        if (cancelled?.call() ?? false) throw const UpdateCancelled();
        sink.add(chunk);
        received += chunk.length;
        if (onProgress != null) onProgress(received, total);
      }
      await sink.flush();
      await sink.close();
      sink = null;
      if (total != null && received != total) {
        throw UpdateException('the download stopped at $received of $total bytes');
      }
    } catch (error) {
      try {
        await sink?.flush();
        await sink?.close();
      } catch (_) {
        // Closing again already-closed is fine; the file is deleted below.
      }
      try {
        if (await file.exists()) await file.delete();
      } on FileSystemException {
        // The next attempt writes over it.
      }
      rethrow;
    }
  }

  /// The checksum sidecar's 64 hex characters, with any of GitHub's trailing
  /// whitespace stripped. Missing or malformed: null — the caller refuses to
  /// install against no checksum rather than installing unchecked.
  Future<String?> fetchSha256(String sha256Url) async {
    final response = await _client.get(Uri.parse(sha256Url));
    if (response.statusCode != 200) return null;
    final text = utf8.decode(response.bodyBytes).trim();
    final hex = text.split(RegExp(r'\s+')).first;
    return RegExp(r'^[0-9a-f]{64}$', caseSensitive: false).hasMatch(hex)
        ? hex.toLowerCase()
        : null;
  }
}

/// Something the updater cannot recover from on its own.
class UpdateException implements Exception {
  const UpdateException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// A download the user stopped: not a failure, and never an APK on disk.
class UpdateCancelled implements Exception {
  const UpdateCancelled();
}
