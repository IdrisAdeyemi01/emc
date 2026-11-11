/// Pure-Dart core of the EMC Portal: models, sheet parsing, business rules
/// and message building, shared by the Jaspr site and the future Flutter app.
///
/// This package must never import Jaspr, Flutter, `dart:html`/`dart:js_interop`
/// or `package:web`.
///
/// Layout (filled in from M2):
/// - `src/common/`     Clock, Result, failures, Weekday, time parsing, logger
/// - `src/timetable/`  ClassSession, sheet row parser, TimetableRepository
/// - `src/reminders/`  TeacherReminder, grouping, PhoneNumber, ReminderTemplate
library;

export 'src/common/logger.dart';
