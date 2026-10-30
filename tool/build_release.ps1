# Builds Jama'ah's release APK the way the app is meant to be released:
#
#   - with the local environment (.env) passed to the compiler, so mosque
#     discovery, Sentry and other configured pieces actually work;
#   - with APP_VERSION / GIT_COMMIT / BUILD_DATE baked in, so the About page can
#     say which build this is (a build without these shows "dev - dev");
#   - named Jamaah-<version>.apk (stable ASCII, README convention), with a
#     Jamaah-<version>.apk.sha256 sidecar next to it, which is what the app's
#     in-app updater verifies a download against.
#
# recognised tags, e.g.  tool\build_release.ps1  (from the repository root)
# The APK stays under the ignored build/ directory; attach both files
# (not the source) to the matching GitHub release.
#
# Requires .env (Copy-Item .env.example .env, then fill in your own values).

$ErrorActionPreference = 'Stop'
Push-Location (Join-Path $PSScriptRoot '..')
try {
    if (-not (Test-Path -LiteralPath '.env')) {
        throw 'Create .env first: Copy-Item .env.example .env (see README).'
    }

    $version = ((Select-String -Path pubspec.yaml -Pattern '^version:').Line -split '\s+')[1]
    if (-not $version) { throw 'Could not read the version from pubspec.yaml.' }
    $commit = (git rev-parse --short HEAD).Trim()
    git diff --quiet -- . ':!android/app/build.gradle.kts'
    if ($LASTEXITCODE -ne 0) { $commit += '+' }
    $date = Get-Date -Format 'yyyy-MM-dd'

    Write-Host "Building Jama'ah $version (commit $commit, $date)..."
    flutter build apk --release --dart-define-from-file=.env `
        --dart-define="APP_VERSION=$version" `
        --dart-define="GIT_COMMIT=$commit" `
        --dart-define="BUILD_DATE=$date"
    if ($LASTEXITCODE -ne 0) { throw 'Release APK build failed.' }

    $apkDir = 'build/app/outputs/flutter-apk'
    $built = Join-Path $apkDir 'app-release.apk'
    if (-not (Test-Path -LiteralPath $built)) { throw 'app-release.apk was not produced.' }

    $releaseVersion = $version.Split('+')[0]
    $apk = Join-Path $apkDir "Jamaah-$releaseVersion.apk"
    Move-Item -LiteralPath $built -Destination $apk -Force

    # A hash file without a hash verifies nothing: refuse to emit an empty one.
    $hash = (Get-FileHash -LiteralPath $apk -Algorithm SHA256).Hash.ToLowerInvariant()
    $sidecar = Join-Path $apkDir "Jamaah-$releaseVersion.apk.sha256"
    "$hash  Jamaah-$releaseVersion.apk" | Set-Content -LiteralPath $sidecar

    Write-Host ''
    Write-Host $apk
    Write-Host $sidecar
} finally {
    Pop-Location
}
