/// Build information provided via --dart-define.
///
/// Example:
/// ```bash
///
/// COMMIT_HASH=$(git rev-parse --short HEAD)
/// BUILD_DATE=$(date -u +"%Y-%m-%d %H:%M UTC")
///
/// flutter test --exclude-tags mac \
///   --dart-define=COMMIT_HASH=$COMMIT_HASH \
///   --dart-define=BUILD_DATE="$BUILD_DATE"
/// ```
class BuildInfo {
  const BuildInfo._();

  /// The Git commit hash of the build.
  static const String commitHash = String.fromEnvironment(
    'COMMIT_HASH',
    defaultValue: 'devel',
  );

  /// The build date and time.
  // TODO(bramp): Convert this to a real date type.
  static const String buildDate = String.fromEnvironment(
    'BUILD_DATE',
    defaultValue: 'unknown',
  );

  /// Returns a combined version string.
  static String get version => '$commitHash ($buildDate)';

  /// Returns a shorter version string for footers.
  static String get shortVersion => '$commitHash • $buildDate';
}
