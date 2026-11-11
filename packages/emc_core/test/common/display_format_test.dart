import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  test('formatClockTime', () {
    expect(formatClockTime(DateTime.utc(2026, 11, 14, 8, 15)), '8:15 AM');
    expect(formatClockTime(DateTime.utc(2026, 11, 14, 12)), '12:00 PM');
    expect(formatClockTime(DateTime.utc(2026, 11, 14, 0, 5)), '12:05 AM');
    expect(formatClockTime(DateTime.utc(2026, 11, 14, 18, 42)), '6:42 PM');
  });

  test('formatLongDate', () {
    expect(
      formatLongDate(const CalendarDate(2026, 11, 14)),
      'Saturday, 14 November',
    );
    expect(formatLongDate(const CalendarDate(2027, 1, 4)), 'Monday, 4 January');
  });

  test('toLagos is UTC+1 from any timezone', () {
    final instant = DateTime.utc(2026, 11, 14, 7, 15);

    expect(toLagos(instant), DateTime.utc(2026, 11, 14, 8, 15));
    expect(toLagos(instant.toLocal()), DateTime.utc(2026, 11, 14, 8, 15));
  });
}
