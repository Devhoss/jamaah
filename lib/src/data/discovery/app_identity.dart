import 'package:flutter/services.dart';

import '../../app/branding.g.dart';

/// Who is calling: the package name and the SHA-1 of the certificate the
/// installed app is signed with. Google matches both against an API key's
/// Android-app restriction.
class AppIdentity {
  const AppIdentity({required this.packageName, this.signingCertSha1});

  final String packageName;

  /// Upper-case hex without colons, as Google expects it. Null when it cannot be
  /// read; the request is then sent without it and an app-restricted key refuses
  /// it, which the UI reports as a key problem.
  final String? signingCertSha1;
}

abstract interface class AppIdentitySource {
  Future<AppIdentity> read();
}

/// Reads the signing certificate from the installed package, so the value is
/// right for whichever key signed this build (debug, release, Play) without
/// anything hard-coded or kept in a file.
class PlatformAppIdentitySource implements AppIdentitySource {
  PlatformAppIdentitySource();

  static const _channel = MethodChannel('dev.jamaah.app/identity');

  AppIdentity? _cached;

  @override
  Future<AppIdentity> read() async {
    if (_cached case final known?) return known;
    String? sha1;
    try {
      sha1 = await _channel.invokeMethod<String>('signingCertSha1');
    } on PlatformException {
      sha1 = null;
    } on MissingPluginException {
      sha1 = null;
    }
    return _cached = AppIdentity(
      packageName: kApplicationId,
      signingCertSha1: sha1 == null || sha1.isEmpty ? null : sha1,
    );
  }
}

/// A fixed identity, for tests and for platforms without the channel.
class FixedAppIdentitySource implements AppIdentitySource {
  const FixedAppIdentitySource(this.identity);

  final AppIdentity identity;

  @override
  Future<AppIdentity> read() async => identity;
}
