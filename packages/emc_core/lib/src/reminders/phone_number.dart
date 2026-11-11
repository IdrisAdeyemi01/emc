/// Why a phone can't be used for WhatsApp.
enum PhoneProblem {
  /// The cell is blank.
  empty,

  /// Contains something other than digits, spaces, dashes, brackets and a
  /// leading `+`.
  invalidCharacters,

  /// Not 11 digits (`0…`) or 13 digits (`234…`).
  wrongLength,

  /// Right length, but not starting with `0` (11 digits) or `234` (13).
  wrongPrefix,
}

/// A teacher's phone from the sheet, normalized for WhatsApp.
///
/// The phone is a teacher's identity (names vary between rows). Personal
/// data: never log it.
sealed class PhoneNumber {
  const PhoneNumber(this.raw);

  /// Normalizes [raw] following CLAUDE.md 2.4 rule 7. Never guesses.
  factory PhoneNumber.parse(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return InvalidPhone._(raw, PhoneProblem.empty, digitCount: 0);
    }
    var cleaned = trimmed.replaceAll(RegExp(r'[\s\-()\[\]]'), '');
    if (cleaned.startsWith('+')) cleaned = cleaned.substring(1);
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return InvalidPhone._(
        raw,
        PhoneProblem.invalidCharacters,
        digitCount: RegExp(r'\d').allMatches(cleaned).length,
      );
    }
    if (cleaned.length == 11 && cleaned.startsWith('0')) {
      return ValidPhone._(raw, '234${cleaned.substring(1)}');
    }
    if (cleaned.length == 13 && cleaned.startsWith('234')) {
      return ValidPhone._(raw, cleaned);
    }
    return InvalidPhone._(
      raw,
      cleaned.length == 11 || cleaned.length == 13
          ? PhoneProblem.wrongPrefix
          : PhoneProblem.wrongLength,
      digitCount: cleaned.length,
    );
  }

  /// Exactly as in the sheet.
  final String raw;
}

/// A phone in WhatsApp international format.
final class ValidPhone extends PhoneNumber {
  const ValidPhone._(super.raw, this.digits);

  /// 13 digits, `234` + 10-digit national number, no `+`. Used in `wa.me`.
  final String digits;

  /// `+234 800 000 0001`.
  String get display =>
      '+${digits.substring(0, 3)} ${digits.substring(3, 6)} '
      '${digits.substring(6, 9)} ${digits.substring(9)}';

  @override
  bool operator ==(Object other) =>
      other is ValidPhone && other.digits == digits;

  @override
  int get hashCode => digits.hashCode;

  @override
  String toString() => 'ValidPhone(…${digits.substring(digits.length - 4)})';
}

/// A phone that can't be used. The card shows a warning and disables Send.
final class InvalidPhone extends PhoneNumber {
  const InvalidPhone._(super.raw, this.problem, {required this.digitCount});

  final PhoneProblem problem;

  /// How many digits the cell contains, for messages like "has 9 digits".
  final int digitCount;

  @override
  bool operator ==(Object other) =>
      other is InvalidPhone && other.raw == raw && other.problem == problem;

  @override
  int get hashCode => Object.hash(raw, problem);

  @override
  String toString() => 'InvalidPhone(${problem.name}, $digitCount digits)';
}
