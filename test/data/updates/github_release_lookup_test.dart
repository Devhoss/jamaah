import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:jamaah/src/data/updates/github_release_lookup.dart';
import 'package:jamaah/src/domain/app_updates.dart';

/// Stub answers. Everything false here is on purpose: the updater is only as
/// good as its habit of never believing a broken answer.
class _StubClient implements http.Client {
  _StubClient({this.json, this.status = 200, this.error = false});

  final String? json;
  final int status;
  final bool error;

  @override
  Future<Response> get(Uri url, {Map<String, String>? headers}) async {
    if (error) throw Exception('unreachable');
    return Response(json ?? '', status, headers: {'content-type': 'application/json'});
  }

  @override
  Future<http.StreamedResponse> send(BaseRequest request) =>
      throw UnimplementedError('not used in this test');

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('a release answer is read into the check', () async {
    final lookup = GitHubReleaseLookup(
      client: _StubClient(
        json: '{"tag_name": "v1.0.6", "assets": ['
            '{"name": "Jamaah-1.0.6.apk", "browser_download_url": "https://x/Jamaah-1.0.6.apk"},'
            '{"name": "Jamaah-1.0.6.apk.sha256", "browser_download_url": "https://x/Jamaah-1.0.6.apk.sha256"}'
            ']}',
      ),
    );
    final release = await lookup.latest();
    expect(release.tag, '1.0.6');
    expect(release.apk, isNotNull);
    expect(release.apk!.version, '1.0.6');
    expect(release.apk!.downloadUrl, 'https://x/Jamaah-1.0.6.apk');
    expect(release.apk!.sha256Url, 'https://x/Jamaah-1.0.6.apk.sha256');
  });

  test('no release yet is not an error', () async {
    final lookup = GitHubReleaseLookup(client: _StubClient(status: 404));
    final release = await lookup.latest();
    expect(release.tag, '');
    expect(release.apk, isNull);
  });

  test('a lookup failure is surfaced, never faked into up-to-date', () async {
    final lookup = GitHubReleaseLookup(client: _StubClient(error: true));
    await expectLater(lookup.latest(), throwsA(isA<Exception>()));
  });

  test('a release without a checksum sidecar offers nothing to install', () {
    final apk = pickApkAsset([
      {'name': 'Jamaah-1.0.6.apk', 'browser_download_url': 'https://x/Jamaah-1.0.6.apk'},
    ]);
    expect(apk, isNull);
  });

  test('a sidecar of another file is not a checksum', () {
    final apk = pickApkAsset([
      {'name': 'Jamaah-1.0.6.apk', 'browser_download_url': 'https://x/Jamaah-1.0.6.apk'},
      {'name': 'SHA256SUMS', 'browser_download_url': 'https://x/SHA256SUMS'},
    ]);
    expect(apk, isNull);
  });

  test('the historical dotted name is not picked up', () {
    final apk = pickApkAsset([
      {'name': 'Jama.ah-1.0.4.apk', 'browser_download_url': 'https://x/Jama.ah-1.0.4.apk'},
      {'name': 'Jama.ah-1.0.4.apk.sha256', 'browser_download_url': 'https://x/x'},
    ]);
    expect(apk, isNull);
  });
}
