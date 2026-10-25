#!/usr/bin/env bash
# Builds the APK for testers, stamped with the version, commit and date that
# Settings shows at the bottom (lib/src/app/build_info.dart).
#
#   tool/build_apk.sh            # debug
#   tool/build_apk.sh --release  # release
set -euo pipefail
cd "$(dirname "$0")/.."

version=$(grep -m1 '^version:' pubspec.yaml | awk '{print $2}')
commit=$(git rev-parse --short HEAD)
# A build from uncommitted changes says so.
if ! git diff --quiet -- . ':!android/app/build.gradle.kts'; then
  commit="$commit+"
fi
date=$(date +%Y-%m-%d)
mode=${1:---debug}

flutter build apk "$mode" \
  --dart-define-from-file=.env \
  --dart-define=APP_VERSION="$version" \
  --dart-define=GIT_COMMIT="$commit" \
  --dart-define=BUILD_DATE="$date"

if [[ "$mode" == "--release" ]]; then
  apk="build/app/outputs/flutter-apk/app-release.apk"
  release_version=${version%%+*}
  named_apk="build/app/outputs/flutter-apk/Jamaah-$release_version.apk"
  mv -f "$apk" "$named_apk"
  printf 'Release APK: %s\n' "$named_apk"
fi
