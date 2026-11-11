import 'calendar_date.dart';
import 'weekday.dart';

/// Source of the current time. Inject it so tests control "now".
abstract interface class Clock {
  DateTime now();
}

/// The device clock.
final class SystemClock implements Clock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Always returns the same instant. For tests.
final class FixedClock implements Clock {
  const FixedClock(this.instant);

  final DateTime instant;

  @override
  DateTime now() => instant;
}

/// Africa/Lagos is UTC+1 all year (no daylight saving).
const lagosUtcOffset = Duration(hours: 1);

/// "Today" for EMC is always Lagos time, whatever the device timezone.
extension LagosTime on Clock {
  /// Lagos wall-clock time. The result is flagged UTC, but its fields
  /// (hour, weekday, ...) read as Lagos local time.
  DateTime lagosNow() => now().toUtc().add(lagosUtcOffset);

  /// Today's date in Lagos.
  CalendarDate lagosToday() => CalendarDate.fromDateTime(lagosNow());

  /// Today's weekday in Lagos.
  Weekday lagosWeekday() => Weekday.fromDateTime(lagosNow());
}
