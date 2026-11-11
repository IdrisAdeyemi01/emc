import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';

Timetable parseOk(SheetTable table) => switch (parseContactsSheet(table)) {
  Ok(:final value) => value,
  Err(:final failure) => fail('expected Ok, got $failure'),
};

void main() {
  group('headers', () {
    test('finds columns by name in any order, ignoring extra columns', () {
      final table = SheetTable(
        headers: const [
          '  start time ',
          'TEACHER',
          'Notes',
          'class',
          'Day',
          'Phone',
          'Subject',
        ],
        rows: const [
          [
            '4:00 PM',
            'Bro Yusuf Adebayo',
            'x',
            'JSS 1',
            'Monday',
            '08000000001',
            'Mathematics',
          ],
        ],
      );

      final s = parseOk(table).sessions.single;

      expect(s.day, Weekday.monday);
      expect(s.className, 'JSS 1');
      expect(s.subject, 'Mathematics');
      expect(s.teacherName, 'Bro Yusuf Adebayo');
      expect(s.rawPhone, '08000000001');
      expect(s.rawStartTime, '4:00 PM');
    });

    test('accepts "Phone number" and "Time" aliases', () {
      final table = SheetTable(
        headers: const [
          'Day',
          'Class',
          'Subject',
          'Teacher',
          'Phone number',
          'Time',
        ],
        rows: const [
          [
            'Monday',
            'JSS 1',
            'Mathematics',
            'Bro Yusuf Adebayo',
            '08000000001',
            '4pm',
          ],
        ],
      );

      final s = parseOk(table).sessions.single;

      expect(s.rawPhone, '08000000001');
      expect(s.rawStartTime, '4pm');
    });

    test(
      'prefers "Start Time" over "Time" and "Phone numbers" over "Phone"',
      () {
        final table = SheetTable(
          headers: const [
            'Time',
            'Phone',
            'Day',
            'Class',
            'Subject',
            'Teacher',
            'Start  Time',
            'Phone Numbers',
          ],
          rows: const [
            [
              'wrong',
              'wrong',
              'Monday',
              'JSS 1',
              'Mathematics',
              'Bro Yusuf Adebayo',
              '4:00 PM',
              '08000000001',
            ],
          ],
        );

        final s = parseOk(table).sessions.single;

        expect(s.rawStartTime, '4:00 PM');
        expect(s.rawPhone, '08000000001');
      },
    );

    test('reports every missing column by display name', () {
      final result = parseContactsSheet(
        const SheetTable(
          headers: ['Day', 'Class', 'Subject', 'Teacher', 'Mobile'],
          rows: [],
        ),
      );

      expect(
        result,
        const Err<Timetable>(
          MissingColumnsFailure(['Phone numbers', 'Start Time']),
        ),
      );
    });

    test('an empty header row is missing everything', () {
      final result = parseContactsSheet(
        const SheetTable(headers: [], rows: []),
      );

      expect(
        result,
        const Err<Timetable>(
          MissingColumnsFailure([
            'Day',
            'Class',
            'Subject',
            'Teacher',
            'Phone numbers',
            'Start Time',
          ]),
        ),
      );
    });
  });

  group('rows (realistic fixture)', () {
    late Timetable timetable;
    setUp(() => timetable = contactsTimetable());

    test('keeps usable rows in sheet order with sheet row numbers', () {
      expect(timetable.sessions.map((s) => s.sheetRow), [
        2,
        3,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        14,
        15,
      ]);
    });

    test('trims every cell', () {
      final kareem = timetable.sessions.singleWhere((s) => s.sheetRow == 14);

      expect(kareem.day, Weekday.saturday);
      expect(kareem.className, 'SSS 3');
      expect(kareem.subject, 'Further Mathematics');
      expect(kareem.rawPhone, '08000000005');
      expect(kareem.rawStartTime, '14:00');
      expect(
        timetable.sessions.singleWhere((s) => s.sheetRow == 8).teacherName,
        'Bro Yusuf Adebayo',
      );
    });

    test('normalizes day spellings', () {
      expect(
        timetable.sessions
            .where((s) => s.sheetRow == 5 || s.sheetRow == 6)
            .map((s) => s.day),
        [Weekday.wednesday, Weekday.wednesday],
      );
    });

    test('keeps class and time text exactly as written', () {
      final tunde = timetable.sessions.singleWhere((s) => s.sheetRow == 6);

      expect(tunde.className, 'SSS 2');
      expect(tunde.rawStartTime, '4pm');
      expect(tunde.startTime, ClassTime.tryParse('4:00 PM'));
    });

    test('pads short rows with blanks', () {
      final zainab = timetable.sessions.singleWhere((s) => s.sheetRow == 15);

      expect(zainab.teacherName, 'Sis Zainab Musa');
      expect(zainab.rawPhone, '');
      expect(zainab.rawStartTime, '');
      expect(zainab.isStartTimeMissing, isTrue);
    });

    test(
      'reports skipped rows without personal data; blank rows are silent',
      () {
        expect(timetable.skipped, const [
          SkippedRow(sheetRow: 13, reason: SkipReason.unknownDay),
          SkippedRow(sheetRow: 16, reason: SkipReason.noDetails),
          SkippedRow(sheetRow: 17, reason: SkipReason.blankDay),
        ]);
      },
    );

    test('days with classes come from the data', () {
      expect(timetable.daysWithClasses, {
        Weekday.monday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.saturday,
      });
      expect(timetable.sessionsOn(Weekday.monday).length, 2);
      expect(timetable.sessionsOn(Weekday.friday), isEmpty);
    });

    test('passes fetchedAt through', () {
      final at = DateTime.utc(2026, 11, 14, 7, 15);

      expect(parseOk(contactsSheet(fetchedAt: at)).fetchedAt, at);
    });
  });

  test('no data rows gives an empty timetable', () {
    final timetable = parseOk(
      const SheetTable(
        headers: contactsHeaders,
        rows: [
          [],
          ['  ', ''],
        ],
      ),
    );

    expect(timetable.sessions, isEmpty);
    expect(timetable.skipped, isEmpty);
    expect(timetable.daysWithClasses, isEmpty);
  });

  test('logs skipped rows by number only, never phones', () {
    final logged = <String>[];
    final originalSink = Logger.sink;
    Logger.sink = (level, name, message, error, stackTrace) =>
        logged.add(message);
    addTearDown(() => Logger.sink = originalSink);

    contactsTimetable();

    expect(logged, hasLength(1));
    expect(logged.single, contains('13 (unknownDay)'));
    expect(logged.single, isNot(contains('0800')));
  });

  test('SkippedRow and ClassSession equality', () {
    expect(
      const SkippedRow(sheetRow: 3, reason: SkipReason.blankDay).hashCode,
      const SkippedRow(sheetRow: 3, reason: SkipReason.blankDay).hashCode,
    );
    expect(
      const SkippedRow(sheetRow: 3, reason: SkipReason.blankDay).toString(),
      'SkippedRow(3, blankDay)',
    );
    expect(session(), session());
    expect(session().hashCode, session().hashCode);
    expect(session(), isNot(session(sheetRow: 3)));
    expect(session().toString(), contains('row 2'));
    expect(session().toString(), isNot(contains('0800')));
  });
}
