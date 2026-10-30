import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import '../../app/build_info.dart';
import '../../domain/app_updates.dart';
import 'github_release_lookup.dart';
import 'update_installer.dart';

/// How far the self-update has got, as the About row renders it. Each stage
/// has its own row label and tap action.
enum UpdateStage {
  /// Not checked in this session yet.
  unchecked,

  /// Looking up the newest release on GitHub.
  checking,

  /// This build already is the latest published release.
  upToDate,

  /// A newer release is published. `release.apk == null` means the release
  /// carries no directly downloadable APK of ours, and the releases page is
  /// the way to it.
  available,

  /// The APK is on its way: [received] of [total] bytes.
  downloading,

  /// The cached APK matches the release's checksum; a tap hands it to the
  /// system installer.
  ready,

  /// GitHub could not answer this session. Not cached: a retry is real.
  lookupFailed,

  /// The last download could not finish or be verified; the cache is clean.
  downloadFailed,
}

/// Why the last download attempt failed.
enum UpdateFailure { noChecksum, broken }

/// The app's own update path, held by the About row.
///
/// The check runs once per app session (this single instance), not once per
/// About-page look: a user peeking twice does not make GitHub hear about it
/// twice. A failed lookup is never cached, so tapping the row retries for
/// real. Opening the About page auto-checks, quietly.
///
/// Everything runs while the user is looking at the page. openGym's updater,
/// the model here, waits for the app to be foregrounded before opening the
/// package installer, because Android 10+ refuses background-started
/// installer activities without a word. Ours hands off straight from the row:
/// if the phone was left during a download, the row is still "Downloaded —
/// tap to install" when the user comes back, and the next tap retries. The
/// Android installer refuses a partial APK by design — the flow verified a
/// checksum by then, and the installer re-checks the file itself.
class UpdateFlow extends ChangeNotifier {
  UpdateFlow({
    GitHubReleaseLookup? lookup,
    UpdateInstaller? installer,
    Future<File> Function()? cacheFile,
    String? runningVersion,
  }) : lookup = lookup ?? GitHubReleaseLookup(),
       installer = installer ?? UpdateInstaller(),
       _cacheFile = cacheFile ?? _defaultCacheFile,
       _runningVersion = runningVersion ?? kAppVersion;

  final GitHubReleaseLookup lookup;
  final UpdateInstaller installer;

  /// The version the check compares against. Tests inject one; a release
  /// build runs with its own.
  final String _runningVersion;

  /// Where the download goes. Tests hand in a temp file; the release default
  /// is the app cache the native side reads too (getCacheDir() there, the
  /// temporary directory here answers the same place).
  final Future<File> Function() _cacheFile;

  static Future<File> _defaultCacheFile() async {
    final dir = await getTemporaryDirectory();
    return File('${dir.path}${Platform.pathSeparator}$updaterApkFileName');
  }

  UpdateStage _stage = UpdateStage.unchecked;
  LatestRelease? _release;
  String? _sha256;
  UpdateFailure? _failure;
  int _received = 0;
  int? _total;
  bool _stopped = false;
  final _Throttle _throttle = _Throttle();
  Future<void>? _inFlightCheck;

  UpdateStage get stage => _stage;
  LatestRelease? get release => _release;

  /// The version this device runs (injected for tests; a release build
  /// carries its own). "You already have x" speaks of this one.
  String get runningVersion => _runningVersion;

  int get received => _received;
  int? get total => _total;
  UpdateFailure? get failure => _failure;

  /// The version being offered, or the running one when the tag has none.
  String get latestVersion {
    final r = _release;
    return (r != null && runningVersionIsKnown(r.tag)) ? r.tag : _runningVersion;
  }

  /// A release whose APK cannot be offered directly — no APK asset of the
  /// expected name, or no checksum sidecar next to it — updates the old way,
  /// through the releases page.
  bool get needsReleasesPage => _release?.apk == null;

  /// What GitHub says, once per session unless [again]. Concurrent calls
  /// share the one lookup; a finished answer (even one whose download later
  /// failed) is this session's answer — tests and rows ask again explicitly.
  Future<void> check({bool again = false}) async {
    if (_stage == UpdateStage.downloading) return;
    if (!again && _release != null) return Future.value();
    final inFlight = _inFlightCheck;
    if (inFlight != null && !again) return inFlight;
    _stage = UpdateStage.checking;
    notifyListeners();
    final attempt = _performCheck();
    _inFlightCheck = attempt;
    await attempt;
    if (identical(_inFlightCheck, attempt)) _inFlightCheck = null;
  }

  Future<void> _performCheck() async {
    try {
      final latest = await lookup.latest();
      _release = latest;
      if (!runningIsOlderThan(latest.tag, _runningVersion)) {
        _stage = UpdateStage.upToDate;
        // Nothing newer asks for the download, so drop an old one: the new
        // install keeps this app's cache otherwise.
        await _deleteCached();
      } else {
        _stopped = false;
        _stage = UpdateStage.available;
      }
    } on Exception {
      _inFlightCheck = null;
      _stage = UpdateStage.lookupFailed;
    }
    notifyListeners();
  }

  /// The row's action, per stage. The widget decides the labels; this decides
  /// the motions.
  Future<void> begin() {
    switch (_stage) {
      case UpdateStage.unchecked:
      case UpdateStage.lookupFailed:
        return check(again: true);
      case UpdateStage.available:
        return _download();
      case UpdateStage.ready:
        return _handOff();
      case UpdateStage.upToDate:
      case UpdateStage.checking:
      case UpdateStage.downloading:
      case UpdateStage.downloadFailed:
        return Future.value();
    }
  }

  /// Stops the running download. The part-written file is deleted where the
  /// lookup notices, and the row falls back to "update available".
  void cancelDownload() => _stopped = true;

  /// Fetches the checksum sidecar first, then streams the APK into the
  /// cache. Nothing is downloaded when there is nothing to verify the bytes
  /// against; the native installer re-verifies the file itself before any
  /// install. The download runs with the page open; a stop throws through as
  /// a deliberate cancel, breaking apart the part file.
  Future<void> _download() async {
    final apk = _release?.apk;
    if (apk == null) return;
    _failure = null;
    _received = 0;
    _total = null;
    _throttle.reset();
    final expected = await lookup.fetchSha256(apk.sha256Url);
    if (expected == null || _stopped) {
      if (_stopped) {
        // The stop landed while the checksum was on its way: not a failure,
        // simply back where the row was.
        _stage = UpdateStage.available;
      } else {
        // Without a checksum nothing gets installed — a deliberate refusal,
        // not a gap to skip past.
        _stage = UpdateStage.downloadFailed;
        _failure = UpdateFailure.noChecksum;
      }
      notifyListeners();
      return;
    }
    _sha256 = expected;
    _stage = UpdateStage.downloading;
    notifyListeners();
    try {
      await lookup.downloadApk(
        apk.downloadUrl,
        await _cacheFile(),
        cancelled: () => _stopped,
        onProgress: (got, bytes) {
          _received = got;
          _total = bytes;
          _throttle.throttle(notifyListeners);
        },
      );
      _stage = _stopped ? UpdateStage.available : UpdateStage.ready;
    } catch (error) {
      _stage = UpdateStage.downloadFailed;
      // A deliberate stop is not a failure to the row: back to available.
      if (error is UpdateCancelled) _stage = UpdateStage.available;
      _failure = error is UpdateCancelled ? null : UpdateFailure.broken;
    } finally {
      _throttle.reset();
      notifyListeners();
    }
  }

  /// Hands the verified APK to the system installer. A mismatch on the
  /// native side (or nothing in the cache) cleans up and returns the row to
  /// "update available"; any other failure is rethrown for the row to say a
  /// word, and the verified APK stays ready for the next tap.
  Future<void> _handOff() async {
    final sha = _sha256;
    if (sha == null) return;
    try {
      await installer.install(sha256: sha);
    } on PlatformException catch (error) {
      final code = error.code.toLowerCase();
      if (code == 'mismatch' || code == 'missing') {
        _sha256 = null;
        await _deleteCached();
        _stage = UpdateStage.available;
        notifyListeners();
        return;
      }
      rethrow;
    }
    // A successful hand-off changes nothing further here: confirming the
    // install replaces the app (the next session's own check says up to
    // date), and declining the installer leaves the verified APK in place
    // for another tap.
    notifyListeners();
  }

  Future<void> _deleteCached() async {
    try {
      final file = await _cacheFile();
      if (await file.exists()) await file.delete();
    } on FileSystemException {
      // The next download writes over anything left behind.
    }
  }
}

/// Coalesces a stream's per-chunk change notifications to human rate: one
/// now when the previous was long enough ago, otherwise one held for a
/// moment, so a final chunk is never dropped.
class _Throttle {
  static const every = Duration(milliseconds: 300);
  DateTime _last = DateTime.fromMillisecondsSinceEpoch(0);
  Timer? _pending;

  void throttle(void Function() callback) {
    final now = DateTime.now();
    if (now.difference(_last) >= every) {
      _cancelPending();
      _last = now;
      callback();
      return;
    }
    _pending ??= Timer(every, () {
      _pending = null;
      _last = DateTime.now();
      callback();
    });
  }

  void _cancelPending() {
    _pending?.cancel();
    _pending = null;
  }

  /// Cancels any held call, used after a stage change and in tests.
  void reset() {
    _cancelPending();
    _last = DateTime.fromMillisecondsSinceEpoch(0);
  }
}
