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

    # Tier 0 (2026-11-06): tell Sentry about this release so issues get
    # "new in release", suspect commits, and deploy markers. Best-effort
    # only: telemetry must never fail a release build that already succeeded.
    try {
        $envFile = Get-Content -LiteralPath '.env' -Raw
        $token = ([regex]::Match($envFile, '(?m)^SENTRY_AUTH_TOKEN=(.*)$')).Groups[1].Value.Trim()
        if (-not $token) {
            Write-Host 'Sentry release tracking skipped (SENTRY_AUTH_TOKEN empty in .env).'
        } elseif (-not (Get-Command sentry-cli -ErrorAction SilentlyContinue)) {
            Write-Host 'Sentry release tracking skipped (sentry-cli not on PATH).'
        } else {
            $org = ([regex]::Match($envFile, '(?m)^SENTRY_ORG=(.*)$')).Groups[1].Value.Trim()
            if (-not $org) { $org = 'lonelycactus-e0' }
            $project = ([regex]::Match($envFile, '(?m)^SENTRY_PROJECT=(.*)$')).Groups[1].Value.Trim()
            if (-not $project) { $project = 'flutter' }
            $url = ([regex]::Match($envFile, '(?m)^SENTRY_URL=(.*)$')).Groups[1].Value.Trim()
            if (-not $url) { $url = 'https://de.sentry.io' }
            $envName = ([regex]::Match($envFile, '(?m)^SENTRY_ENVIRONMENT=(.*)$')).Groups[1].Value.Trim()
            if (-not $envName) { $envName = 'tester' }
            # SDK auto-release is "<package>@<version>+<build>", e.g. dev.jamaah.app@1.0.8+10.
            $sentryRelease = "dev.jamaah.app@$version"
            $env:SENTRY_AUTH_TOKEN = $token
            Write-Host "Creating Sentry release $sentryRelease (org $org, project $project, env $envName)..."
            # sentry-cli 3.x: --url is a global flag and must precede the
            # subcommand; --org/--project belong to the subcommand.
            sentry-cli --url $url releases new $sentryRelease --org $org --project $project
            sentry-cli --url $url releases set-commits $sentryRelease --auto --org $org --project $project
            sentry-cli --url $url deploys new -r $sentryRelease -e $envName --org $org --project $project
            sentry-cli --url $url releases finalize $sentryRelease --org $org --project $project
            Write-Host 'Sentry release created.'
        }
    } catch {
        Write-Warning "Sentry release tracking failed (non-fatal): $($_.Exception.Message)"
    }
} finally {
    Pop-Location
}
