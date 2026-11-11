import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  late List<(LogLevel, String, String)> entries;
  late LogSink originalSink;
  late LogLevel originalLevel;

  setUp(() {
    entries = [];
    originalSink = Logger.sink;
    originalLevel = Logger.minLevel;
    Logger.sink = (level, name, message, error, stackTrace) =>
        entries.add((level, name, message));
  });

  tearDown(() {
    Logger.sink = originalSink;
    Logger.minLevel = originalLevel;
  });

  test('sends entries at or above minLevel to the sink', () {
    Logger.minLevel = LogLevel.info;
    const log = Logger('timetable');

    log.debug('hidden');
    log.info('loaded');
    log.warning('slow');
    log.error('failed');

    expect(entries, [
      (LogLevel.info, 'timetable', 'loaded'),
      (LogLevel.warning, 'timetable', 'slow'),
      (LogLevel.error, 'timetable', 'failed'),
    ]);
  });

  test('debug entries pass when minLevel is debug', () {
    Logger.minLevel = LogLevel.debug;

    const Logger('core').debug('details');

    expect(entries, [(LogLevel.debug, 'core', 'details')]);
  });

  test('passes error and stack trace through', () {
    Object? seenError;
    StackTrace? seenTrace;
    Logger.sink = (level, name, message, error, stackTrace) {
      seenError = error;
      seenTrace = stackTrace;
    };
    final trace = StackTrace.current;

    const Logger('core').error('boom', StateError('x'), trace);

    expect(seenError, isA<StateError>());
    expect(seenTrace, same(trace));
  });
}
