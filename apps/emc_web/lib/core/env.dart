/// Build-time configuration, passed with `--dart-define` (see `.env.example`).
///
/// Both values end up in the public JS bundle: the key is light protection
/// against casual discovery, not real auth (CLAUDE.md section 2.7).
abstract final class Env {
  /// Apps Script web app URL.
  static const apiUrl = String.fromEnvironment('EMC_API_URL');

  /// Shared secret checked by the Apps Script.
  static const apiKey = String.fromEnvironment('EMC_API_KEY');

  /// Whether both values were provided at build time.
  static const isConfigured = apiUrl != '' && apiKey != '';

  /// `--dart-define=EMC_DEMO=true`: fake Saturday data and a fixed clock, for
  /// design checks and screenshots without real teachers' details. Compiled
  /// out of normal builds.
  static const demo = bool.fromEnvironment('EMC_DEMO');
}
