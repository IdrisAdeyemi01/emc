/// Pure-Dart core of the EMC Portal: models, sheet parsing, business rules
/// and message building, shared by the Jaspr site and the future Flutter app.
///
/// This package must never import Jaspr, Flutter, `dart:html`/`dart:js_interop`
/// or `package:web`.
library;

// common: time, days, results, logging
export 'src/common/calendar_date.dart';
export 'src/common/class_time.dart';
export 'src/common/clock.dart';
export 'src/common/failure.dart';
export 'src/common/logger.dart';
export 'src/common/result.dart';
export 'src/common/weekday.dart';
// timetable: the Teachers' Contacts tab
export 'src/timetable/class_session.dart';
export 'src/timetable/sheet_parser.dart';
export 'src/timetable/sheet_table.dart';
export 'src/timetable/timetable.dart';
export 'src/timetable/timetable_repository.dart';
// reminders: grouping, phones, the message
export 'src/reminders/build_reminders.dart';
export 'src/reminders/phone_number.dart';
export 'src/reminders/reminder_day.dart';
export 'src/reminders/reminder_template.dart';
export 'src/reminders/teacher_reminder.dart';
export 'src/reminders/whatsapp_link.dart';
