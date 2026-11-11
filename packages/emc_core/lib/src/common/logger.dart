import 'dart:developer' as developer;

/// Severity of a log entry, lowest first.
enum LogLevel { debug, info, warning, error }

/// Receives every log entry at or above [Logger.minLevel].
typedef LogSink =
    void Function(
      LogLevel level,
      String name,
      String message,
      Object? error,
      StackTrace? stackTrace,
    );

/// Tiny logger used instead of `print`.
///
/// Never log personal data: no phone numbers, no message bodies.
final class Logger {
  const Logger(this.name);

  /// Area of the app that logs, e.g. `timetable`.
  final String name;

  /// Lowest level that reaches [sink].
  static LogLevel minLevel = LogLevel.info;

  /// Where entries go. Defaults to `dart:developer` (browser console / DevTools).
  /// Tests replace it to capture output.
  static LogSink sink = developerSink;

  void debug(String message) => _log(LogLevel.debug, message);

  void info(String message) => _log(LogLevel.info, message);

  void warning(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.warning, message, error, stackTrace);

  void error(String message, [Object? error, StackTrace? stackTrace]) =>
      _log(LogLevel.error, message, error, stackTrace);

  void _log(
    LogLevel level,
    String message, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (level.index < minLevel.index) return;
    sink(level, name, message, error, stackTrace);
  }

  /// Default sink, writing through `dart:developer`.
  static void developerSink(
    LogLevel level,
    String name,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    developer.log(
      message,
      name: 'emc.$name',
      level: _developerLevels[level]!,
      error: error,
      stackTrace: stackTrace,
    );
  }

  // Values from package:logging's Level, which `dart:developer` mirrors.
  static const _developerLevels = {
    LogLevel.debug: 500,
    LogLevel.info: 800,
    LogLevel.warning: 900,
    LogLevel.error: 1000,
  };
}
