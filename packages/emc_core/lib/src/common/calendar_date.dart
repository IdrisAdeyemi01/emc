import 'weekday.dart';

/// A date without a time of day or timezone.
final class CalendarDate {
  const CalendarDate(this.year, this.month, this.day);

  /// Takes the date fields of [dateTime] as they are (no timezone conversion).
  factory CalendarDate.fromDateTime(DateTime dateTime) =>
      CalendarDate(dateTime.year, dateTime.month, dateTime.day);

  final int year;
  final int month;
  final int day;

  Weekday get weekday => Weekday.fromDateTime(_asUtc);

  /// `yyyy-MM-dd`.
  String toIsoString() =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  /// This date moved by [days] (negative to go back).
  CalendarDate addDays(int days) =>
      CalendarDate.fromDateTime(_asUtc.add(Duration(days: days)));

  /// The first date on or after this one that falls on [weekday].
  CalendarDate nextOccurrenceOf(Weekday weekday) =>
      addDays((weekday.index - this.weekday.index) % 7);

  DateTime get _asUtc => DateTime.utc(year, month, day);

  @override
  bool operator ==(Object other) =>
      other is CalendarDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => toIsoString();
}
