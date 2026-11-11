import '../common/failure.dart';
import '../common/logger.dart';
import '../common/result.dart';
import '../common/weekday.dart';
import 'class_session.dart';
import 'sheet_table.dart';
import 'timetable.dart';

/// A column of the `Teachers' Contacts` tab and the header names accepted
/// for it (compared case-insensitively, trimmed, inner spaces collapsed).
enum ContactsColumn {
  day('Day', ['day']),
  className('Class', ['class']),
  subject('Subject', ['subject']),
  teacher('Teacher', ['teacher']),
  phone('Phone numbers', ['phone numbers', 'phone number', 'phone']),
  startTime('Start Time', ['start time', 'time']);

  const ContactsColumn(this.displayName, this.aliases);

  /// Name shown when the column is missing.
  final String displayName;

  /// Accepted headers, most specific first.
  final List<String> aliases;
}

const _log = Logger('timetable');

/// Turns the raw tab into a [Timetable].
///
/// Columns are found by header name, never by position, so admins can
/// reorder or add columns. Every cell is trimmed; short rows are padded;
/// fully blank rows are dropped silently; other unusable rows are reported
/// in [Timetable.skipped].
Result<Timetable> parseContactsSheet(SheetTable table) {
  final headers = [for (final h in table.headers) _normalizeHeader(h)];
  final indexes = <ContactsColumn, int>{};
  final missing = <String>[];
  for (final column in ContactsColumn.values) {
    final index = _findColumn(headers, column);
    if (index == null) {
      missing.add(column.displayName);
    } else {
      indexes[column] = index;
    }
  }
  if (missing.isNotEmpty) return Err(MissingColumnsFailure(missing));

  final sessions = <ClassSession>[];
  final skipped = <SkippedRow>[];
  for (var i = 0; i < table.rows.length; i++) {
    final row = table.rows[i];
    final sheetRow = i + 2; // header is row 1
    if (row.every((cell) => cell.trim().isEmpty)) continue;

    String cell(ContactsColumn column) {
      final index = indexes[column]!;
      return index < row.length ? row[index].trim() : '';
    }

    final rawDay = cell(ContactsColumn.day);
    final day = Weekday.tryParse(rawDay);
    if (day == null) {
      skipped.add(
        SkippedRow(
          sheetRow: sheetRow,
          reason: rawDay.isEmpty ? SkipReason.blankDay : SkipReason.unknownDay,
        ),
      );
      continue;
    }

    final session = ClassSession(
      day: day,
      className: cell(ContactsColumn.className),
      subject: cell(ContactsColumn.subject),
      teacherName: cell(ContactsColumn.teacher),
      rawPhone: cell(ContactsColumn.phone),
      rawStartTime: cell(ContactsColumn.startTime),
      sheetRow: sheetRow,
    );
    if (session.className.isEmpty &&
        session.subject.isEmpty &&
        session.teacherName.isEmpty &&
        session.rawPhone.isEmpty) {
      skipped.add(SkippedRow(sheetRow: sheetRow, reason: SkipReason.noDetails));
      continue;
    }
    sessions.add(session);
  }

  if (skipped.isNotEmpty) {
    _log.warning(
      'Skipped ${skipped.length} row(s): '
      '${skipped.map((s) => '${s.sheetRow} (${s.reason.name})').join(', ')}',
    );
  }
  return Ok(
    Timetable(sessions: sessions, skipped: skipped, fetchedAt: table.fetchedAt),
  );
}

String _normalizeHeader(String header) =>
    header.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

int? _findColumn(List<String> headers, ContactsColumn column) {
  for (final alias in column.aliases) {
    final index = headers.indexOf(alias);
    if (index != -1) return index;
  }
  return null;
}
