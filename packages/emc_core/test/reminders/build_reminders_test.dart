import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';
import '../fixtures/reminder_fixtures.dart';

void main() {
  group('Saturday (realistic fixture)', () {
    late List<TeacherReminder> reminders;
    setUp(
      () => reminders = buildReminders(contactsTimetable(), Weekday.saturday),
    );

    test('one card per phone, ordered by earliest time then name', () {
      expect(reminders.map((r) => r.displayName), [
        'Bro Yusuf Adebayo', // 10:00 AM
        'Sis Halima Bello', // 10:00 AM
        'Sis Maryam Lawal', // 12:00 PM
        'Bro Kareem Hassan', // 14:00
        'Bro Ibrahim Salami', // no start time: last
      ]);
      expect(reminders.every((r) => r.day == Weekday.saturday), isTrue);
    });

    test('groups a teacher\'s classes by phone across name variants', () {
      final yusuf = reminders.first;

      expect(yusuf.classes.map((c) => c.sheetRow), [8, 7, 9]);
      expect(yusuf.phone, PhoneNumber.parse('08000000001'));
      expect(yusuf.id, 'tel:2348000000001');
    });

    test('3-class teacher: classes ordered by start time', () {
      final yusuf = reminders.first;

      expect(
        yusuf.classes.map(
          (c) => '${c.className} ${c.subject} ${c.rawStartTime}',
        ),
        [
          'JSS 3 English 10:00 AM',
          'SSS 1 English 12:00 PM',
          'SSS 1 Literature 2:00 PM',
        ],
      );
    });

    test('display name comes from the first row for that phone that day', () {
      // Row 7 ("Bro Yusuf Adebayo") comes before the "(Yus)" variant on row 9.
      expect(reminders.first.displayName, 'Bro Yusuf Adebayo');
    });

    test('flags invalid phones and missing start times', () {
      final maryam = reminders.singleWhere(
        (r) => r.displayName == 'Sis Maryam Lawal',
      );
      final ibrahim = reminders.singleWhere(
        (r) => r.displayName == 'Bro Ibrahim Salami',
      );

      expect(maryam.hasValidPhone, isFalse);
      expect((maryam.phone as InvalidPhone).digitCount, 9);
      expect(maryam.hasMissingStartTime, isFalse);
      expect(ibrahim.hasValidPhone, isTrue);
      expect(ibrahim.hasMissingStartTime, isTrue);
      expect(ibrahim.earliestStartTime, isNull);
    });
  });

  test(
    'Wednesday: "Weds" and "wednesday " rows are the same day; 4pm == 4:00 PM',
    () {
      final reminders = buildReminders(contactsTimetable(), Weekday.wednesday);

      // Same time, so ordered by name.
      expect(reminders.map((r) => r.displayName), [
        'Mr Tunde Okafor',
        'Sis Aishat Ogunleye',
      ]);
    },
  );

  test('a day with no classes gives no reminders', () {
    expect(buildReminders(contactsTimetable(), Weekday.friday), isEmpty);
  });

  test('blank phone rows are grouped by teacher name', () {
    final timetable = Timetable(
      sessions: [
        session(
          teacherName: 'Sis Zainab Musa',
          rawPhone: '',
          className: 'SSS 3',
          sheetRow: 2,
        ),
        session(
          teacherName: 'Bro Musa Ade',
          rawPhone: '',
          className: 'JSS 1',
          sheetRow: 3,
        ),
        session(
          teacherName: 'sis zainab musa ',
          rawPhone: ' ',
          className: 'SSS 2',
          sheetRow: 4,
        ),
      ],
    );

    final reminders = buildReminders(timetable, Weekday.saturday);

    expect(reminders.map((r) => r.displayName), [
      'Bro Musa Ade',
      'Sis Zainab Musa',
    ]);
    expect(reminders.last.classes.map((c) => c.sheetRow), [4, 2]);
    expect(reminders.last.id, 'name:sis zainab musa');
  });

  test(
    'the same invalid phone typed with different spacing is one teacher',
    () {
      final timetable = Timetable(
        sessions: [
          session(rawPhone: '0800 000 12', className: 'JSS 1', sheetRow: 2),
          session(rawPhone: '080000012', className: 'JSS 2', sheetRow: 3),
        ],
      );

      final reminders = buildReminders(timetable, Weekday.saturday);

      expect(reminders, hasLength(1));
      expect(reminders.single.id, 'raw:080000012');
    },
  );

  group('class order within a card', () {
    test('same time: by class name, case-insensitive', () {
      final classes = [
        session(className: 'SSS 1', sheetRow: 2),
        session(className: 'jss 3', sheetRow: 3),
        session(className: 'JSS 1', sheetRow: 4),
      ]..sort(compareClasses);

      expect(classes.map((c) => c.className), ['JSS 1', 'jss 3', 'SSS 1']);
    });

    test('unreadable times go after readable ones, in sheet order', () {
      final classes = [
        session(rawStartTime: 'after Asr', className: 'A', sheetRow: 2),
        session(rawStartTime: '2:00 PM', className: 'B', sheetRow: 3),
        session(rawStartTime: '', className: 'C', sheetRow: 4),
        session(rawStartTime: '10am', className: 'D', sheetRow: 5),
      ]..sort(compareClasses);

      expect(classes.map((c) => c.className), ['D', 'B', 'A', 'C']);
    });

    test('the comparator is symmetric for timed vs untimed', () {
      final timed = session(rawStartTime: '10am');
      final untimed = session(rawStartTime: '');

      expect(compareClasses(timed, untimed), -1);
      expect(compareClasses(untimed, timed), 1);
    });

    test('identical time and class fall back to sheet order', () {
      final classes = [
        session(subject: 'Second', sheetRow: 9),
        session(subject: 'First', sheetRow: 3),
      ]..sort(compareClasses);

      expect(classes.map((c) => c.subject), ['First', 'Second']);
    });
  });

  group('card order', () {
    test('untimed cards by name, then sheet order', () {
      final timetable = Timetable(
        sessions: [
          session(
            teacherName: 'Sis B',
            rawPhone: '08000000002',
            rawStartTime: '',
            sheetRow: 2,
          ),
          session(
            teacherName: 'Bro A',
            rawPhone: '08000000003',
            rawStartTime: 'tbc',
            sheetRow: 3,
          ),
          session(
            teacherName: 'Sis B',
            rawPhone: '08000000004',
            rawStartTime: '',
            sheetRow: 4,
          ),
          session(
            teacherName: 'Bro C',
            rawPhone: '08000000005',
            rawStartTime: '9am',
            sheetRow: 5,
          ),
        ],
      );

      final reminders = buildReminders(timetable, Weekday.saturday);

      expect(reminders.map((r) => r.classes.first.sheetRow), [5, 3, 2, 4]);
    });
  });

  test('TeacherReminder.toString has no phone', () {
    final r = reminder([session()]);

    expect(
      r.toString(),
      'TeacherReminder(Bro Yusuf Adebayo, Saturday, 1 class(es))',
    );
  });
}
