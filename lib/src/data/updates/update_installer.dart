import 'package:flutter/services.dart';

import '../../domain/app_updates.dart';

/// The Android side of the installer (android UpdateChannel.kt): it
/// re-verifies the cached APK's SHA-256 natively, streamed, and only then
/// hands the file to the system package installer. This wrapper is the
/// Dart-facing half; the file's name is the one the native side agrees to
/// ([updaterApkFileName]), so an argument here can only name that download.
class UpdateInstaller {
  UpdateInstaller({this.channel});
  final MethodChannel? channel;

  /// Hands [updaterApkFileName] in the app cache to the system installer
  /// after the native checksum check. A [PlatformException] names where it
  /// stopped: `name`/`hash` (rejected by the native validation), `missing`
  /// (nothing in the cache), `mismatch` (checksum failed, file deleted) or
  /// `intent` (the installer could not be opened).
  Future<void> install({required String sha256}) =>
      _withChannel().invokeMethod('installApk', {
        'fileName': updaterApkFileName,
        'sha256': sha256,
      });

  MethodChannel _withChannel() => channel ?? UpdateInstaller.defaultChannel;

  static const defaultChannel = MethodChannel('dev.jamaah.app/update');
}
