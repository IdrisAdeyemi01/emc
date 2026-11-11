import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  group('ClassTime.tryParse reads', () {
    const cases = {
      '4:00 PM': '16:00',
      '4:00 pm': '16:00',
      '4:00PM': '16:00',
      '4pm': '16:00',
      '4 pm': '16:00',
      '4 PM': '16:00',
      '4:30 p.m.': '16:30',
      '4.30pm': '16:30',
      '10:00 AM': '10:00',
      '10am': '10:00',
      '12:00 PM': '12:00',
      '12 pm': '12:00',
      '12:00 AM': '00:00',
      '12am': '00:00',
      '2:00 PM': '14:00',
      '16:00': '16:00',
      '14:00': '14:00',
      '09:30': '09:30',
      '0:00': '00:00',
      '  4:00   PM  ': '16:00',
    };
    cases.forEach((raw, expected) {
      test('"$raw" as $expected', () {
        expect(ClassTime.tryParse(raw).toString(), expected);
      });
    });
  });

  group('ClassTime.tryParse rejects', () {
    for (final raw in [
      '',
      '  ',
      '4',
      'four pm',
      '13pm',
      '0am',
      '4:60 pm',
      '24:00',
      '16:75',
      'after Asr',
      '4:00 PM - 6:00 PM',
    ]) {
      test('"$raw"', () => expect(ClassTime.tryParse(raw), isNull));
    }
  });

  test('orders and compares by minutes', () {
    final ten = ClassTime.tryParse('10:00 AM')!;
    final noon = ClassTime.tryParse('12:00 PM')!;

    expect(ten.compareTo(noon), lessThan(0));
    expect(ten, ClassTime.tryParse('10am'));
    expect(ten.hashCode, ClassTime.tryParse('10am').hashCode);
    expect(ten.hour, 10);
    expect(ten.minute, 0);
  });
}
