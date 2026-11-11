import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  group('Weekday.tryParse', () {
    const cases = {
      'Monday': Weekday.monday,
      'mon': Weekday.monday,
      'Tuesday': Weekday.tuesday,
      'Tue': Weekday.tuesday,
      'TUES': Weekday.tuesday,
      'Wednesday': Weekday.wednesday,
      'Weds': Weekday.wednesday,
      'Wed': Weekday.wednesday,
      'wednesday ': Weekday.wednesday,
      '  WEDNESDAY': Weekday.wednesday,
      'wed.': Weekday.wednesday,
      'Thursday': Weekday.thursday,
      'Thu': Weekday.thursday,
      'Thur': Weekday.thursday,
      'thurs': Weekday.thursday,
      'Friday': Weekday.friday,
      'Fri': Weekday.friday,
      'Saturday': Weekday.saturday,
      'Sat': Weekday.saturday,
      'Sunday': Weekday.sunday,
      'sun': Weekday.sunday,
    };
    cases.forEach((raw, expected) {
      test('"$raw" → ${expected.label}', () {
        expect(Weekday.tryParse(raw), expected);
      });
    });

    for (final raw in ['', '   ', 'Satday', 'Mo', 'Saturday/Sunday', '1']) {
      test('"$raw" → null', () => expect(Weekday.tryParse(raw), isNull));
    }
  });

  test('labels', () {
    expect(Weekday.saturday.label, 'Saturday');
    expect(Weekday.saturday.shortLabel, 'Sat');
    expect(Weekday.values.first, Weekday.monday);
  });

  test('fromDateTime uses the date fields as given', () {
    expect(Weekday.fromDateTime(DateTime.utc(2026, 11, 14)), Weekday.saturday);
    expect(Weekday.fromDateTime(DateTime.utc(2026, 11, 16)), Weekday.monday);
    expect(Weekday.fromDateTime(DateTime.utc(2026, 11, 15)), Weekday.sunday);
  });
}
