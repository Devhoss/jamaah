import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/data/updates/github_release_lookup.dart';
import 'package:jamaah/src/data/updates/update_flow.dart';
import 'package:jamaah/src/data/updates/update_installer.dart';
import 'package:jamaah/src/domain/app_updates.dart';

/// A lookup whose answers are whatever the test needs, shaped like GitHub's.
class _Lookup implements GitHubReleaseLookup {
  _Lookup({
    this.tag = 'v1.0.6',
    this.withApk = true,
    this.fails = false,
    String? sha,
  }) : sha = sha ?? 'a' * 64;

  String tag;
  bool withApk;
  bool fails;
  String? sha;

  int lookups = 0;

  @override
  Future<LatestRelease> latest() async {
    lookups++;
    if (fails) throw Exception('unreachable');
    final List<Map<String, Object?>> assets = [];
    if (withApk) {
      assets.addAll([
        {
          'name': 'Jamaah-1.0.6.apk',
          'browser_download_url': 'https://x/Jamaah-1.0.6.apk',
        },
        {
          'name': 'Jamaah-1.0.6.apk.sha256',
          'browser_download_url': 'https://x/Jamaah-1.0.6.apk.sha256',
        },
      ]);
    }
    return LatestRelease(
      tag: tag,
      apk: pickApkAsset(assets),
      releasesUrl: 'https://github.com/Devhoss/jamaah/releases',
    );
  }

  /// A small "APK" in chunks; the cancel flag is asked exactly as in release.
  @override
  Future<void> downloadApk(
    String apkUrl,
    File file, {
    void Function(int received, int? total)? onProgress,
    bool Function()? cancelled,
  }) async {
    try {
      for (final chunk in ['1000', '1000', '1000']) {
        if (cancelled?.call() ?? false) throw const UpdateCancelled();
        await file.writeAsString(chunk, mode: FileMode.append);
        onProgress?.call(file.lengthSync(), 1200);
      }
    } catch (_) {
      try {
        if (await file.exists()) await file.delete();
      } catch (_) {
        // As in release: the next attempt writes over it.
      }
      rethrow;
    }
  }

  @override
  Future<String?> fetchSha256(String sha256Url) async => sha;

  @override
  String get releasesUrl => 'https://github.com/Devhoss/jamaah/releases';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// The release published no checksum next to its APK: nothing is verified,
/// so nothing is installed.
class _NoSha extends _Lookup {
  _NoSha() : super(sha: 'a' * 64);

  @override
  Future<String?> fetchSha256(String sha256Url) async => null;
}

class _Installer implements UpdateInstaller {
  _Installer({this.failsWith});

  /// An exception the native side would answer with, or null on success.
  Object? failsWith;
  int calls = 0;
  String? lastSha;

  @override
  Future<void> install({required String sha256}) async {
    calls++;
    lastSha = sha256;
    final failsWith = this.failsWith;
    if (failsWith != null) throw failsWith;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<Directory> _tempSub(String name) => Directory.systemTemp.createTemp(name);

/// The whole cache area of a test: the file, then its directory — whichever
/// the flow left behind.
Future<void> _removeCacheDir(File file) async {
  if (await file.exists()) await file.delete();
  if (file.parent.existsSync()) await file.parent.delete();
}

void main() {
  tearDown(() async {
    // The throttle's real timers run under the test zone; the flow cancels
    // them when a step ends, so all that is expected here is a clean end.
  });

  test('the check runs once per session, retries only on demand', () async {
    final lookup = _Lookup(tag: '1.0.6', withApk: false);
    final flow = UpdateFlow(lookup: lookup, installer: _Installer());
    await flow.check();
    await flow.check();
    expect(lookup.lookups, 1);
    expect(flow.latestVersion, '1.0.6');
    expect(flow.stage, UpdateStage.available);
    expect(flow.needsReleasesPage, isTrue);
  });

  test('a failed lookup is not cached: the row tap retries for real', () async {
    final lookup = _Lookup(fails: true);
    final flow = UpdateFlow(lookup: lookup, installer: _Installer());
    await flow.check();
    expect(flow.stage, UpdateStage.lookupFailed);
    lookup.fails = false;
    await flow.check(again: true);
    expect(flow.stage, UpdateStage.available);
  });

  Future<File> cacheFile() async {
    final dir = await _tempSub('jamaah-update-flow');
    return File('${dir.path}${Platform.pathSeparator}Jamaah-update.apk');
  }

  test('running current deletes a leftover download', () async {
    final file = await cacheFile();
    try {
      await file.writeAsBytes([0]);
      expect(await file.exists(), isTrue);
      final flow = UpdateFlow(
        lookup: _Lookup(tag: '1.0.5', withApk: false),
        installer: _Installer(),
        cacheFile: () async => file,
        runningVersion: '1.0.5',
      );
      await flow.check();
      expect(flow.stage, UpdateStage.upToDate);
      expect(await file.exists(), isFalse);
    } finally {
      if (file.existsSync()) file.deleteSync();
      await file.parent.delete();
    }
  });

  test('download then install hand-off carries the checksum', () async {
    final file = await cacheFile();
    final lookup = _Lookup(tag: '1.0.6');
    final installer = _Installer();
    final flow = UpdateFlow(
      lookup: lookup,
      installer: installer,
      cacheFile: () async => file,
    );
    await flow.check();
    expect(flow.stage, UpdateStage.available);
    expect(flow.needsReleasesPage, isFalse);
    await flow.begin();
    expect(flow.stage, UpdateStage.ready);
    await flow.begin();
    expect(installer.calls, 1);
    expect(installer.lastSha, 'a' * 64);
    await _removeCacheDir(file);
  });

  test('no checksum refuses the download before anything moves', () async {
    final file = await cacheFile();
    final lookup = _NoSha();
    final flow = UpdateFlow(
      lookup: lookup,
      installer: _Installer(),
      cacheFile: () async => file,
    );
    await flow.check();
    await flow.begin();
    expect(flow.stage, UpdateStage.downloadFailed);
    expect(flow.failure, UpdateFailure.noChecksum);
    expect(await file.exists(), isFalse);
    await _removeCacheDir(file);
  });

  test('a cancel returns the row to available, with the file gone', () async {
    final file = await cacheFile();
    final lookup = _Lookup(tag: '1.0.6');
    final flow = UpdateFlow(
      lookup: lookup,
      installer: _Installer(),
      cacheFile: () async => file,
    );
    await flow.check();
    final running = flow.begin();
    flow.cancelDownload();
    await running;
    expect(flow.stage, UpdateStage.available);
    expect(flow.failure, isNull);
    expect(await file.exists(), isFalse);
    await _removeCacheDir(file);
  });

  test('a native mismatch cleans up and re-offers the download', () async {
    final file = await cacheFile();
    final lookup = _Lookup(tag: '1.0.6');
    final installer = _Installer(failsWith: PlatformException(code: 'mismatch'));
    final flow = UpdateFlow(
      lookup: lookup,
      installer: installer,
      cacheFile: () async => file,
    );
    await flow.check();
    await flow.begin(); // download
    await flow.begin(); // hand off — refused
    expect(flow.stage, UpdateStage.available);
    await _removeCacheDir(file);
  });

  test('an installer that cannot open keeps the APK ready', () async {
    final file = await cacheFile();
    final lookup = _Lookup(tag: '1.0.6');
    final installer = _Installer(failsWith: PlatformException(code: 'intent'));
    final flow = UpdateFlow(
      lookup: lookup,
      installer: installer,
      cacheFile: () async => file,
    );
    await flow.check();
    await flow.begin();
    await expectLater(flow.begin(), throwsA(isA<PlatformException>()));
    expect(flow.stage, UpdateStage.ready);
    await _removeCacheDir(file);
  });

  test('progress asks for a few notifications, not one per chunk', () async {
    final file = await cacheFile();
    final lookup = _Lookup(tag: '1.0.6');
    final flow = UpdateFlow(
      lookup: lookup,
      installer: _Installer(),
      cacheFile: () async => file,
    );
    var notifications = 0;
    flow.addListener(() => notifications++);
    await flow.check();
    await flow.begin();
    // Three chunks at one instant: the stage changes plus one throttled
    // update — never one per chunk.
    expect(notifications, lessThan(15));
    await _removeCacheDir(file);
  });
}
