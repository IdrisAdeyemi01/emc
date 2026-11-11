import '../common/class_time.dart';
import '../common/weekday.dart';

/// One row of the `Teachers' Contacts` tab: a class a teacher takes on a day.
///
/// Text fields are trimmed sheet values, kept exactly as the admin wrote them
/// (e.g. `SSS 1`, `4:00 PM`), because cards and messages show them verbatim.
final class ClassSession {
  const ClassSession({
    required this.day,
    required this.className,
    required this.subject,
    required this.teacherName,
    required this.rawPhone,
    required this.rawStartTime,
    required this.sheetRow,
  });

  final Weekday day;
  final String className;
  final String subject;
  final String teacherName;

  /// Phone exactly as in the sheet. Personal data: never log it.
  final String rawPhone;

  /// Start time exactly as in the sheet; empty when the cell is blank.
  final String rawStartTime;

  /// 1-based row number in the sheet (the header is row 1).
  final int sheetRow;

  /// Parsed [rawStartTime] for ordering; null if blank or unreadable.
  ClassTime? get startTime => ClassTime.tryParse(rawStartTime);

  /// True when the sheet's Start Time cell is blank.
  bool get isStartTimeMissing => rawStartTime.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is ClassSession &&
      other.day == day &&
      other.className == className &&
      other.subject == subject &&
      other.teacherName == teacherName &&
      other.rawPhone == rawPhone &&
      other.rawStartTime == rawStartTime &&
      other.sheetRow == sheetRow;

  @override
  int get hashCode => Object.hash(
    day,
    className,
    subject,
    teacherName,
    rawPhone,
    rawStartTime,
    sheetRow,
  );

  @override
  String toString() =>
      'ClassSession(row $sheetRow, ${day.label}, $className, $subject, '
      '$rawStartTime)';
}
