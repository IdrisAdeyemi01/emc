import 'dart:convert';

import '../common/failure.dart';
import '../common/result.dart';
import 'sheet_parser.dart';
import 'sheet_table.dart';
import 'timetable.dart';

/// Decodes the backend's `action=contacts` JSON (contract v1, CLAUDE.md 2.7)
/// into the raw tab, or a [Failure].
///
/// Failure details are for logs only and never contain the body (which holds
/// phone numbers).
Result<SheetTable> decodeContactsResponse(String body) {
  final Object? json;
  try {
    json = jsonDecode(body);
  } on FormatException {
    final isHtml = body.trimLeft().startsWith('<');
    return Err(
      UnexpectedResponseFailure(
        isHtml
            ? 'HTML instead of JSON (is the web app access set to "Anyone"?)'
            : 'not JSON',
      ),
    );
  }

  if (json is! Map<String, Object?>) {
    return const Err(UnexpectedResponseFailure('not a JSON object'));
  }

  switch (json['ok']) {
    case false:
      return Err(switch (json['error']) {
        'unauthorized' => const UnauthorizedFailure(),
        'sheet_not_found' => const SheetNotFoundFailure(),
        final error => UnexpectedResponseFailure('backend error: $error'),
      });
    case true:
      break;
    default:
      return const Err(UnexpectedResponseFailure('missing "ok"'));
  }

  final headers = _stringList(json['headers']);
  if (headers == null) {
    return const Err(
      UnexpectedResponseFailure('"headers" is not a list of strings'),
    );
  }
  final rawRows = json['rows'];
  if (rawRows is! List<Object?>) {
    return const Err(UnexpectedResponseFailure('"rows" is not a list'));
  }
  final rows = <List<String>>[];
  for (final rawRow in rawRows) {
    final row = _stringList(rawRow);
    if (row == null) {
      return const Err(
        UnexpectedResponseFailure('"rows" contains a non-text row'),
      );
    }
    rows.add(row);
  }

  final fetchedAt = switch (json['fetchedAt']) {
    final String text => DateTime.tryParse(text),
    _ => null,
  };
  return Ok(SheetTable(headers: headers, rows: rows, fetchedAt: fetchedAt));
}

/// [decodeContactsResponse] followed by [parseContactsSheet].
Result<Timetable> timetableFromResponse(String body) =>
    switch (decodeContactsResponse(body)) {
      Ok(:final value) => parseContactsSheet(value),
      Err(:final failure) => Err(failure),
    };

List<String>? _stringList(Object? value) {
  if (value is! List<Object?>) return null;
  final strings = <String>[];
  for (final item in value) {
    if (item is! String) return null;
    strings.add(item);
  }
  return strings;
}
