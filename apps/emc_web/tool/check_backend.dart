// Checks the live Apps Script backend end to end, through the same repository
// and rules the site uses. Prints counts only: no names, no phone numbers.
//
// Usage (from apps/emc_web):
//   dart run tool/check_backend.dart [path/to/.env.local]
//
// Exit code 0 when the timetable loads, 1 otherwise.

import 'dart:io';

import 'package:emc_core/emc_core.dart';
import 'package:emc_web/core/data/apps_script_timetable_repository.dart';

Future<void> main(List<String> args) async {
  final envFile = File(
    args.isNotEmpty
        ? args.first
        : Platform.script.resolve('../../../.env.local').toFilePath(),
  );
  if (!envFile.existsSync()) {
    stderr.writeln('No env file at ${envFile.path}. Copy .env.example first.');
    exit(1);
  }
  final env = _readEnv(envFile);
  final url = Uri.tryParse(env['EMC_API_URL'] ?? '');
  final key = env['EMC_API_KEY'] ?? '';
  if (url == null || url.scheme != 'https' || key.isEmpty) {
    stderr.writeln('EMC_API_URL (https) and EMC_API_KEY must both be set.');
    exit(1);
  }

  Logger.sink = (level, name, message, error, stackTrace) {}; // quiet
  final repository = AppsScriptTimetableRepository(baseUrl: url, apiKey: key);
  final stopwatch = Stopwatch()..start();
  final result = await repository.loadTimetable();
  stopwatch.stop();
  repository.close();

  switch (result) {
    case Err(:final failure):
      stdout.writeln(
        'FAILED after ${stopwatch.elapsedMilliseconds} ms: $failure',
      );
      exit(1);
    case Ok(value: final timetable):
      _printSummary(timetable, stopwatch.elapsed);
  }
}

void _printSummary(Timetable timetable, Duration elapsed) {
  final today = const SystemClock().lagosWeekday();
  stdout.writeln('OK in ${elapsed.inMilliseconds} ms');
  stdout.writeln('Usable rows: ${timetable.sessions.length}');
  stdout.writeln(
    'Skipped rows: ${timetable.skipped.length}'
    '${timetable.skipped.isEmpty ? '' : ' (${timetable.skipped.map((s) => 'row ${s.sheetRow}: ${s.reason.name}').join(', ')})'}',
  );
  stdout.writeln('Today in Lagos: ${today.label}');
  for (final day in selectableDays(timetable, today: today)) {
    final reminders = buildReminders(timetable, day);
    final classes = reminders.fold(0, (n, r) => n + r.classes.length);
    final invalid = reminders.where((r) => !r.hasValidPhone).length;
    final missingTime = reminders.where((r) => r.hasMissingStartTime).length;
    final unreadable = reminders
        .expand((r) => r.classes)
        .where((c) => !c.isStartTimeMissing && c.startTime == null)
        .length;
    final maxClasses = reminders.fold(
      0,
      (n, r) => r.classes.length > n ? r.classes.length : n,
    );
    stdout.writeln(
      '  ${day.shortLabel}: ${reminders.length} teachers, $classes classes'
      ' (max $maxClasses per teacher)'
      '${invalid > 0 ? ', $invalid invalid phone' : ''}'
      '${missingTime > 0 ? ', $missingTime missing start time' : ''}'
      '${unreadable > 0 ? ', $unreadable unreadable time' : ''}',
    );
  }
}

Map<String, String> _readEnv(File file) {
  final values = <String, String>{};
  for (final line in file.readAsLinesSync()) {
    final trimmed = line.trim();
    if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
    final eq = trimmed.indexOf('=');
    if (eq <= 0) continue;
    values[trimmed.substring(0, eq).trim()] = trimmed.substring(eq + 1).trim();
  }
  return values;
}
