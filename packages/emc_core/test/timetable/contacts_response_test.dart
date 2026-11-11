import 'dart:convert';

import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';

String okBody({
  Object? headers = contactsHeaders,
  Object? rows = contactsRows,
  Object? fetchedAt = '2026-11-14T07:15:00Z',
}) => jsonEncode({
  'ok': true,
  'fetchedAt': fetchedAt,
  'sheet': "Teachers' Contacts",
  'headers': headers,
  'rows': rows,
});

void main() {
  group('decodeContactsResponse', () {
    test('decodes headers, rows and fetchedAt', () {
      final result = decodeContactsResponse(okBody());

      final table = (result as Ok<SheetTable>).value;
      expect(table.headers, contactsHeaders);
      expect(table.rows, contactsRows);
      expect(table.fetchedAt, DateTime.utc(2026, 11, 14, 7, 15));
    });

    test('missing or unreadable fetchedAt is null, not an error', () {
      for (final value in [null, 'yesterday', 42]) {
        final result = decodeContactsResponse(okBody(fetchedAt: value));

        expect((result as Ok<SheetTable>).value.fetchedAt, isNull);
      }
    });

    test('backend errors map to failures', () {
      Result<SheetTable> error(Object? code) =>
          decodeContactsResponse(jsonEncode({'ok': false, 'error': code}));

      expect(
        error('unauthorized'),
        const Err<SheetTable>(UnauthorizedFailure()),
      );
      expect(
        error('sheet_not_found'),
        const Err<SheetTable>(SheetNotFoundFailure()),
      );
      expect(
        error('not_bound'),
        const Err<SheetTable>(
          UnexpectedResponseFailure('backend error: not_bound'),
        ),
      );
      expect(
        error(null),
        const Err<SheetTable>(UnexpectedResponseFailure('backend error: null')),
      );
    });

    test('an HTML page (Google sign-in) explains the likely cause', () {
      final result = decodeContactsResponse(
        '  <!DOCTYPE html><html><title>Sign in</title></html>',
      );

      expect(
        result,
        const Err<SheetTable>(
          UnexpectedResponseFailure(
            'HTML instead of JSON (is the web app access set to "Anyone"?)',
          ),
        ),
      );
    });

    test('malformed shapes are unexpected responses', () {
      const cases = {
        'nope': 'not JSON',
        '[]': 'not a JSON object',
        '{}': 'missing "ok"',
        '{"ok":"yes"}': 'missing "ok"',
        '{"ok":true,"rows":[]}': '"headers" is not a list of strings',
        '{"ok":true,"headers":["Day",1],"rows":[]}':
            '"headers" is not a list of strings',
        '{"ok":true,"headers":[]}': '"rows" is not a list',
        '{"ok":true,"headers":[],"rows":{}}': '"rows" is not a list',
        '{"ok":true,"headers":[],"rows":[["a"],"b"]}':
            '"rows" contains a non-text row',
        '{"ok":true,"headers":[],"rows":[["a",null]]}':
            '"rows" contains a non-text row',
      };
      cases.forEach((body, detail) {
        expect(
          decodeContactsResponse(body),
          Err<SheetTable>(UnexpectedResponseFailure(detail)),
          reason: body,
        );
      });
    });

    test('failure details never include row contents', () {
      final result = decodeContactsResponse(
        '{"ok":true,"headers":[],"rows":[["08000000001", 5]]}',
      );

      expect(
        (result as Err<SheetTable>).failure.toString(),
        isNot(contains('0800')),
      );
    });
  });

  group('timetableFromResponse', () {
    test('decodes then parses', () {
      final result = timetableFromResponse(okBody());

      final timetable = (result as Ok<Timetable>).value;
      expect(timetable.sessions, hasLength(12));
      expect(timetable.fetchedAt, DateTime.utc(2026, 11, 14, 7, 15));
    });

    test('passes decoding failures through', () {
      expect(
        timetableFromResponse('{"ok":false,"error":"unauthorized"}'),
        const Err<Timetable>(UnauthorizedFailure()),
      );
    });

    test('reports missing columns from the parser', () {
      final result = timetableFromResponse(
        okBody(headers: ['Day', 'Class', 'Subject', 'Teacher', 'Phone']),
      );

      expect(
        result,
        const Err<Timetable>(MissingColumnsFailure(['Start Time'])),
      );
    });
  });
}
