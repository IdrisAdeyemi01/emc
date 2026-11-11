import 'calendar_date.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

/// `8:15 AM`, `12:00 PM`, `12:05 AM`, using [time]'s fields as given (pass a
/// Lagos time from `Clock.lagosNow()` or [toLagos]).
String formatClockTime(DateTime time) {
  final hour12 = time.hour % 12 == 0 ? 12 : time.hour % 12;
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour12:$minute ${time.hour < 12 ? 'AM' : 'PM'}';
}

/// `Saturday, 14 November`.
String formatLongDate(CalendarDate date) =>
    '${date.weekday.label}, ${date.day} ${_months[date.month - 1]}';

/// [instant] as Lagos wall-clock time (UTC+1).
DateTime toLagos(DateTime instant) =>
    instant.toUtc().add(const Duration(hours: 1));
