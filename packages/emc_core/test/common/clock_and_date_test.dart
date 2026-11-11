import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  group('Lagos time', () {
    test('is UTC+1 regardless of the clock\'s timezone', () {
      // 23:30 UTC Friday is 00:30 Saturday in Lagos.
      final clock = FixedClock(DateTime.utc(2026, 11, 13, 23, 30));

      expect(clock.lagosNow().hour, 0);
      expect(clock.lagosNow().minute, 30);
      expect(clock.lagosWeekday(), Weekday.saturday);
      expect(clock.lagosToday(), const CalendarDate(2026, 11, 14));
    });

    test('a local DateTime is converted through UTC', () {
      final instant = DateTime.utc(2026, 11, 14, 9);
      final clock = FixedClock(instant.toLocal());

      expect(clock.lagosNow(), DateTime.utc(2026, 11, 14, 10));
    });

    test('just before midnight Lagos stays on the same day', () {
      final clock = FixedClock(DateTime.utc(2026, 11, 14, 22, 59));

      expect(clock.lagosToday(), const CalendarDate(2026, 11, 14));
      expect(clock.lagosWeekday(), Weekday.saturday);
    });

    test('SystemClock returns the current time', () {
      final before = DateTime.now();
      final now = const SystemClock().now();

      expect(now.difference(before).inSeconds, lessThan(5));
    });
  });

  group('CalendarDate', () {
    test('formats as yyyy-MM-dd', () {
      expect(const CalendarDate(2026, 1, 5).toIsoString(), '2026-01-05');
      expect(const CalendarDate(2026, 11, 14).toString(), '2026-11-14');
    });

    test('knows its weekday', () {
      expect(const CalendarDate(2026, 11, 14).weekday, Weekday.saturday);
    });

    test('adds days across months and years', () {
      expect(
        const CalendarDate(2026, 12, 31).addDays(1),
        const CalendarDate(2027, 1, 1),
      );
      expect(
        const CalendarDate(2026, 3, 1).addDays(-1),
        const CalendarDate(2026, 2, 28),
      );
    });

    test('next occurrence of a weekday, today included', () {
      const friday = CalendarDate(2026, 11, 13);

      expect(friday.nextOccurrenceOf(Weekday.friday), friday);
      expect(
        friday.nextOccurrenceOf(Weekday.saturday),
        const CalendarDate(2026, 11, 14),
      );
      expect(
        friday.nextOccurrenceOf(Weekday.thursday),
        const CalendarDate(2026, 11, 19),
      );
    });

    test('fromDateTime and equality', () {
      final date = CalendarDate.fromDateTime(DateTime.utc(2026, 11, 14, 23));

      expect(date, const CalendarDate(2026, 11, 14));
      expect(date.hashCode, const CalendarDate(2026, 11, 14).hashCode);
      expect(date, isNot(const CalendarDate(2026, 11, 15)));
    });
  });
}
