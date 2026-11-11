import '../common/weekday.dart';
import 'class_session.dart';

/// Why a non-blank sheet row was left out.
enum SkipReason {
  /// The Day cell is empty.
  blankDay,

  /// The Day cell isn't a recognizable day (e.g. a typo).
  unknownDay,

  /// A day is given, but Class, Subject, Teacher and Phone are all empty.
  noDetails,
}

/// A sheet row that couldn't be used. Holds no personal data, so the UI can
/// say "1 row couldn't be read" and logs can mention the row number.
final class SkippedRow {
  const SkippedRow({required this.sheetRow, required this.reason});

  /// 1-based row number in the sheet.
  final int sheetRow;
  final SkipReason reason;

  @override
  bool operator ==(Object other) =>
      other is SkippedRow &&
      other.sheetRow == sheetRow &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(sheetRow, reason);

  @override
  String toString() => 'SkippedRow($sheetRow, ${reason.name})';
}

/// The parsed `Teachers' Contacts` tab.
final class Timetable {
  Timetable({
    required List<ClassSession> sessions,
    List<SkippedRow> skipped = const [],
    this.fetchedAt,
  }) : sessions = List.unmodifiable(sessions),
       skipped = List.unmodifiable(skipped);

  /// Every usable row, in sheet order.
  final List<ClassSession> sessions;

  /// Non-blank rows that couldn't be used, in sheet order.
  final List<SkippedRow> skipped;

  /// When the backend read the sheet, if known.
  final DateTime? fetchedAt;

  /// Weekdays with at least one class.
  Set<Weekday> get daysWithClasses => {for (final s in sessions) s.day};

  /// Sessions on [day], in sheet order.
  List<ClassSession> sessionsOn(Weekday day) => [
    for (final s in sessions)
      if (s.day == day) s,
  ];
}
