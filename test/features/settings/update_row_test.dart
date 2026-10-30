import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jamaah/src/app/l10n/app_locale.dart';
import 'package:jamaah/src/data/updates/github_release_lookup.dart';
import 'package:jamaah/src/data/updates/update_flow.dart';
import 'package:jamaah/src/data/updates/update_installer.dart';
import 'package:jamaah/src/domain/app_updates.dart';
import 'package:jamaah/src/features/settings/update_row.dart';

import '../../helpers/test_app.dart';

/// The About page's update row (2026-10-31): what it says at each stage, and
/// what a tap means there — including the two confirmations the row asks for
/// before a big download and before stopping one half-way.
void main() {
  late Directory cacheDir;
  late File apkFile;

  setUp(() async {
    cacheDir = await Directory.systemTemp.createTemp('jamaah-update-row');
    apkFile = File('${cacheDir.path}${Platform.pathSeparator}Jamaah-update.apk');
    addTearDown(() async {
      if (await apkFile.exists()) await apkFile.delete();
      await cacheDir.delete();
    });
  });

  Widget harness(UpdateFlow flow) => MaterialApp(
    locale: kEnglishLocale,
    supportedLocales: kSupportedLocales,
    localizationsDelegates: kLocalizationsDelegates,
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          UpdateRow(flow: flow, divider: false),
        ],
      ),
    ),
  );

  UpdateFlow flowFor(
    _Lookup lookup, {
    _Installer? installer,
    String? runningVersion,
  }) => UpdateFlow(
    lookup: lookup,
    installer: installer ?? _Installer(),
    cacheFile: () async => apkFile,
    runningVersion: runningVersion,
  );

  testApp('the row answers GitHub quietly, as an available update', (
    tester,
  ) async {
    final flow = flowFor(_Lookup(tag: 'v1.0.6'));
    await tester.pumpWidget(harness(flow));
    // The row title is there at once; the answer lands a moment later.
    expect(find.text('GitHub releases'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text('Update to 1.0.6'), findsOneWidget);
  });

  testApp('updating confirms first, then downloads, then installs on a tap', (
    tester,
  ) async {
    final lookup = _Lookup(tag: 'v1.0.6');
    final installer = _Installer();
    final flow = flowFor(lookup, installer: installer);
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update to 1.0.6'));
    await tester.pumpAndSettle();
    // The confirmation says what will happen before anything moves.
    expect(find.text('Update to 1.0.6?'), findsOneWidget);
    expect(
      find.text(
        '1.0.6 downloads from GitHub Releases and is checked before '
        'installing. The app restarts during the install.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(find.text('Downloaded · tap to install'), findsOneWidget);

    // The hand-off is the tap on the ready row itself: no second
    // confirmation, because the download already was one.
    await tester.tap(find.text('Downloaded · tap to install'));
    await tester.pumpAndSettle();
    expect(installer.calls, 1);
    expect(installer.lastSha, 'a' * 64);
  });

  testApp('a running download stops only through its own sheet', (tester) async {
    final hold = Completer<void>();
    final flow = flowFor(_Lookup(tag: 'v1.0.6', holdDownload: hold));
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update to 1.0.6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    // Let the sheet close and the download take the stage.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(
      find.textContaining('Downloading'),
      findsOneWidget,
      reason: 'the held download leaves the row at "Downloading…"',
    );

    await tester.tap(find.textContaining('Downloading'));
    await tester.pumpAndSettle();
    expect(find.text('Stop the download?'), findsOneWidget);
    expect(find.text('Keep downloading'), findsOneWidget);
    expect(find.text('Stop'), findsOneWidget);

    await tester.tap(find.text('Stop'));
    hold.complete();
    await tester.pumpAndSettle();
    // Stopped, not failed: the row is back where the update is offered.
    expect(find.text('Update to 1.0.6'), findsOneWidget);
  });

  testApp('a released APK with no checksum is refused, and said so', (
    tester,
  ) async {
    final flow = flowFor(_Lookup(tag: 'v1.0.6', noSha: true));
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Update to 1.0.6'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    expect(
      find.text('No checksum published — open the releases page'),
      findsOneWidget,
    );
  });

  testApp('a build that is the newest says so, with its version', (
    tester,
  ) async {
    // GitHub's newest (1.0.4) is older than this build (1.0.5): the row
    // speaks of the version you have, never of the one GitHub is on.
    final flow = flowFor(
      _Lookup(tag: '1.0.4'),
      runningVersion: '1.0.5',
    );
    // The check (its housekeeping touches the real cache with IO) runs in
    // the tester's real zone; the pumped row only reads its answer.
    await tester.runAsync(() => flow.check());
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();
    expect(find.text('You already have 1.0.5'), findsOneWidget);
  });

  testApp('an unreachable GitHub says what to do, and a tap retries', (
    tester,
  ) async {
    final lookup = _Lookup(fails: true);
    final flow = flowFor(lookup);
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();
    expect(
      find.text("Couldn't reach GitHub. Tap to try again."),
      findsOneWidget,
    );

    lookup.fails = false;
    await tester.tap(find.text("Couldn't reach GitHub. Tap to try again."));
    await tester.pumpAndSettle();
    expect(find.text('Update to 1.0.6'), findsOneWidget);
  });

  testApp('a release without an APK points at the releases page', (
    tester,
  ) async {
    final flow = flowFor(_Lookup(tag: 'v1.0.6', withApk: false));
    await tester.pumpWidget(harness(flow));
    await tester.pumpAndSettle();
    expect(find.text('1.0.6 · open the releases page'), findsOneWidget);
  });

  testApp('a checking row is not tappable, and one lookup answers both taps', (
    tester,
  ) async {
    final hold = Completer<LatestRelease>();
    final lookup = _Lookup(tag: 'v1.0.6')..holdLookup = hold;
    final flow = flowFor(lookup);
    await tester.pumpWidget(harness(flow));
    await tester.pump();
    expect(find.text('Checking…'), findsOneWidget);

    // Disabled while checking: the tap does nothing.
    await tester.tap(find.text('Checking…'), warnIfMissed: false);
    hold.complete(lookup.answer);
    await tester.pumpAndSettle();
    expect(lookup.calls, 1);
    expect(find.text('Update to 1.0.6'), findsOneWidget);
  });
}

/// A lookup whose answers shape the stage the row shows. Its "APK" is a small
/// string in a temp file; a held download lets a test tap mid-flight.
class _Lookup implements GitHubReleaseLookup {
  _Lookup({
    this.tag = 'v1.0.6',
    this.withApk = true,
    this.fails = false,
    bool noSha = false,
    this.holdDownload,
  }) : sha = noSha ? null : ('a' * 64);

  String tag;
  bool withApk;
  bool fails;
  late final String? sha;
  Completer<void>? holdDownload;
  Completer<LatestRelease>? holdLookup;
  int calls = 0;

  LatestRelease get answer {
    final List<Map<String, Object?>> assets = [
      if (withApk) ...[
        {
          'name': 'Jamaah-1.0.6.apk',
          'browser_download_url': 'https://x/Jamaah-1.0.6.apk',
        },
        {
          'name': 'Jamaah-1.0.6.apk.sha256',
          'browser_download_url': 'https://x/Jamaah-1.0.6.apk.sha256',
        },
      ],
    ];
    return LatestRelease(
      // As the real lookup does: the tag's "v" is display noise.
      tag: tag.replaceFirst(RegExp('^v'), ''),
      apk: pickApkAsset(assets),
      releasesUrl: 'https://github.com/Devhoss/jamaah/releases',
    );
  }

  @override
  Future<LatestRelease> latest() async {
    calls++;
    if (holdLookup case final hold?) {
      return hold.future;
    }
    if (fails) throw const UpdateException('unreachable');
    return answer;
  }

  @override
  Future<void> downloadApk(
    String apkUrl,
    File file, {
    void Function(int received, int? total)? onProgress,
    bool Function()? cancelled,
  }) async {
    // No real IO here: this zone is fake-async, where a real file write
    // never lands. The row's behaviour is the labels it shows, and the
    // pure "does the checksum land in the installer" lives in the flow's
    // own test (test/data/updates/update_flow_test.dart), which does the
    // bytes with plain async.
    onProgress?.call(600, 1200);
    if (holdDownload case final hold?) {
      await hold.future;
    }
    if (cancelled?.call() ?? false) throw const UpdateCancelled();
    onProgress?.call(1200, 1200);
  }

  @override
  Future<String?> fetchSha256(String sha256Url) async => sha;

  @override
  String get releasesUrl => 'https://github.com/Devhoss/jamaah/releases';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Installer implements UpdateInstaller {
  int calls = 0;
  String? lastSha;

  @override
  Future<void> install({required String sha256}) async {
    calls++;
    lastSha = sha256;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
