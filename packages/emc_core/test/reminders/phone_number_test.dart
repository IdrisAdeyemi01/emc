import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

void main() {
  group('valid phones normalize to 234…', () {
    const cases = {
      '08000000001': '2348000000001',
      ' 08000000001 ': '2348000000001',
      '0800 000 0001': '2348000000001',
      '0800-000-0001': '2348000000001',
      '(0800) 000-0001': '2348000000001',
      '[0800] 000 0001': '2348000000001',
      '+234 800 000 0001': '2348000000001',
      '+2348000000001': '2348000000001',
      '2348000000001': '2348000000001',
      '234 800 000 0001': '2348000000001',
      '0800 000 0001': '2348000000001', // non-breaking spaces
    };
    cases.forEach((raw, digits) {
      test('"$raw"', () {
        final phone = PhoneNumber.parse(raw);

        expect(phone, isA<ValidPhone>());
        expect((phone as ValidPhone).digits, digits);
        expect(phone.raw, raw);
      });
    });
  });

  group('invalid phones are never guessed', () {
    const cases = {
      '': (PhoneProblem.empty, 0),
      '   ': (PhoneProblem.empty, 0),
      '080000012': (PhoneProblem.wrongLength, 9),
      '8000000001': (PhoneProblem.wrongLength, 10),
      '080000000012': (PhoneProblem.wrongLength, 12),
      '18000000001': (PhoneProblem.wrongPrefix, 11),
      '4478000000001': (PhoneProblem.wrongPrefix, 13),
      '0800 000 000l': (PhoneProblem.invalidCharacters, 10),
      '0800.000.0001': (PhoneProblem.invalidCharacters, 11),
      '++2348000000001': (PhoneProblem.invalidCharacters, 13),
      '08000000001 / 08000000002': (PhoneProblem.invalidCharacters, 22),
    };
    cases.forEach((raw, expected) {
      test('"$raw" → ${expected.$1.name}', () {
        final phone = PhoneNumber.parse(raw);

        expect(phone, isA<InvalidPhone>());
        expect((phone as InvalidPhone).problem, expected.$1);
        expect(phone.digitCount, expected.$2);
      });
    });
  });

  test('display format', () {
    final phone = PhoneNumber.parse('08000000001') as ValidPhone;

    expect(phone.display, '+234 800 000 0001');
  });

  test('valid phones are equal by digits, whatever the raw text', () {
    expect(
      PhoneNumber.parse('08000000001'),
      PhoneNumber.parse('+234 800 000 0001'),
    );
    expect(
      PhoneNumber.parse('08000000001').hashCode,
      PhoneNumber.parse('+234 800 000 0001').hashCode,
    );
    expect(
      PhoneNumber.parse('08000000001'),
      isNot(PhoneNumber.parse('08000000002')),
    );
  });

  test('invalid phones are equal by raw text and problem', () {
    expect(PhoneNumber.parse('080000012'), PhoneNumber.parse('080000012'));
    expect(
      PhoneNumber.parse('080000012').hashCode,
      PhoneNumber.parse('080000012').hashCode,
    );
    expect(
      PhoneNumber.parse('080000012'),
      isNot(PhoneNumber.parse('080000013')),
    );
  });

  test('toString never shows the full number', () {
    expect(PhoneNumber.parse('08000000001').toString(), 'ValidPhone(…0001)');
    expect(
      PhoneNumber.parse('080000012').toString(),
      'InvalidPhone(wrongLength, 9 digits)',
    );
  });
}
