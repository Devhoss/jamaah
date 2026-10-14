/// Which build this is, so a tester can say exactly what they are running
/// (2026-10-14). Passed in at build time by tool/build_apk.sh; a build made
/// another way says "dev".
const kAppVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');
const kGitCommit = String.fromEnvironment('GIT_COMMIT', defaultValue: 'dev');
const kBuildDate = String.fromEnvironment('BUILD_DATE');

/// "1.0.0+1 · ebfbe6d · 2026-10-14". Not translated: it is read out to the
/// developer, and Arabic digits would garble the commit.
String buildLabel() => [
  kAppVersion,
  kGitCommit,
  if (kBuildDate.isNotEmpty) kBuildDate,
].join(' · ');
