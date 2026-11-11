/// A class start time, used only for ordering. Cards and messages always show
/// the sheet's original text.
final class ClassTime implements Comparable<ClassTime> {
  const ClassTime(this.minutesSinceMidnight)
    : assert(minutesSinceMidnight >= 0 && minutesSinceMidnight < 24 * 60);

  final int minutesSinceMidnight;

  int get hour => minutesSinceMidnight ~/ 60;

  int get minute => minutesSinceMidnight % 60;

  /// Reads `4:00 PM`, `4pm`, `4 pm`, `4:00pm`, `4.30 p.m.`, `12:00 PM` (noon),
  /// `12 AM` (midnight) and 24-hour `16:00`.
  ///
  /// Returns null for anything else, including a bare `4`. Never guesses.
  static ClassTime? tryParse(String raw) {
    final text = raw.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return null;

    final twelveHour = _twelveHour.firstMatch(text);
    if (twelveHour != null) {
      final hour = int.parse(twelveHour.group(1)!);
      final minute = int.parse(twelveHour.group(2) ?? '0');
      if (hour < 1 || hour > 12 || minute > 59) return null;
      final isPm = twelveHour.group(3)!.startsWith('p');
      return ClassTime((hour % 12 + (isPm ? 12 : 0)) * 60 + minute);
    }

    final twentyFourHour = _twentyFourHour.firstMatch(text);
    if (twentyFourHour != null) {
      final hour = int.parse(twentyFourHour.group(1)!);
      final minute = int.parse(twentyFourHour.group(2)!);
      if (hour > 23 || minute > 59) return null;
      return ClassTime(hour * 60 + minute);
    }

    return null;
  }

  static final _twelveHour = RegExp(
    r'^(\d{1,2})(?:[:.](\d{2}))? ?([ap])\.?m\.?$',
  );
  static final _twentyFourHour = RegExp(r'^(\d{1,2})[:.](\d{2})$');

  @override
  int compareTo(ClassTime other) =>
      minutesSinceMidnight.compareTo(other.minutesSinceMidnight);

  @override
  bool operator ==(Object other) =>
      other is ClassTime && other.minutesSinceMidnight == minutesSinceMidnight;

  @override
  int get hashCode => minutesSinceMidnight.hashCode;

  /// `HH:mm`, for debugging only.
  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}
