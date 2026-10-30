import 'package:flutter_test/flutter_test.dart';
import 'package:jamaah/src/domain/app_updates.dart';

void main() {
  test('versions compare by numbers, not by strings', () {
    expect(compareAppVersions('1.0.10', '1.0.9'), greaterThan(0));
    expect(compareAppVersions('1.10.0', '1.9.0'), greaterThan(0));
    expect(compareAppVersions('1.0.5', '1.0.5'), isZero);
  });

  test('build metadata plays no part in precedence, from either side', () {
    // openGym's old bug, with our shape of the number: an update tagged
    // "1.0.6" must look newer than a running "1.0.5+6".
    expect(compareAppVersions('1.0.6', '1.0.5+6'), greaterThan(0));
    expect(compareAppVersions('1.0.6+7', '1.0.5+6'), greaterThan(0));
    expect(compareAppVersions('1.0.5', '1.0.5+6'), isZero);
  });

  test('a leading v is a tag, not a version difference', () {
    expect(compareAppVersions('v1.0.6', '1.0.5'), greaterThan(0));
    expect(compareAppVersions('1.0.6', 'v1.0.6'), isZero);
  });

  test('dev is no version at all', () {
    expect(runningVersionIsKnown('dev'), isFalse);
    expect(runningVersionIsKnown('1.0.5'), isTrue);
    expect(runningVersionIsKnown(''), isFalse);
    expect(runningVersionIsKnown('dev-dev'), isFalse);
  });

  test('a dev build always sees an update, never false freshness', () {
    // Decided 2026-10-31: a local build without a released version number is
    // never told it is up to date, so a tester with one sees the row.
    expect(runningIsOlderThan('1.0.6', 'dev'), isTrue);
    expect(runningIsOlderThan('v1.0.6', 'dev'), isTrue);
  });

  test('a non-update is not offered as one', () {
    expect(runningIsOlderThan('1.0.6', '1.0.6'), isFalse);
    expect(runningIsOlderThan('1.0.6', '1.0.6+99'), isFalse);
    expect(runningIsOlderThan('1.0.5', '1.0.6'), isFalse);
    expect(runningIsOlderThan('dev', '1.0.6'), isFalse);
  });

  test('the pinned release file is picked, sidecar included', () {
    final apk = pickApkAsset([
      {'name': 'Jamaah-1.0.6.apk', 'browser_download_url': 'https://x/Jamaah-1.0.6.apk'},
      {
        'name': 'Jamaah-1.0.6.apk.sha256',
        'browser_download_url': 'https://x/Jamaah-1.0.6.apk.sha256',
      },
    ]);
    expect(apk, isNotNull);
    expect(apk!.version, '1.0.6');
    expect(apk.sha256Url, 'https://x/Jamaah-1.0.6.apk.sha256');
  });
}
