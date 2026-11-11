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
