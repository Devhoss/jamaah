import 'package:jamaah/src/data/updates/github_release_lookup.dart';

/// An update lookup that never touches the network, for ProviderScope
/// overrides in tests and goldens about something else. Its answer carries
/// no APK, so the About row stays at "open the releases page" and no tap
/// can start a download.
class QuietUpdatesLookup implements GitHubReleaseLookup {
  @override
  Future<LatestRelease> latest() async =>
      const LatestRelease(tag: '', apk: null, releasesUrl: '');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
