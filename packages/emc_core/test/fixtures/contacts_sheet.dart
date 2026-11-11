// Fixtures shaped like the real `Teachers' Contacts` tab and its quirks.
// FAKE names and numbers only (0800000000x). Never paste real data here.

import 'package:emc_core/emc_core.dart';

const contactsHeaders = [
  'Day',
  'Class',
  'Subject',
  'Teacher',
  'Phone numbers',
  'Start Time',
];

/// Sheet rows; the comment is the sheet row number (header is row 1).
const contactsRows = <List<String>>[
  // 2
  [
    'Monday',
    'JSS 1',
    'Mathematics',
    'Bro Yusuf Adebayo',
    '08000000001',
    '4:00 PM',
  ],
  // 3: spaces inside the phone
  [
    'Monday',
    'JSS 2',
    'English',
    'Sis Halima Bello',
    '0800 000 0002',
    '4:00 PM',
  ],
  // 4: fully blank row (dropped silently)
  ['', '', '', '', '', ''],
  // 5: "Weds", +234 with spaces
  [
    'Weds',
    'JSS 3',
    'Basic Science',
    'Sis Aishat Ogunleye',
    '+234 800 000 0006',
    '4:00 PM',
  ],
  // 6: "wednesday " with trailing space, 234 prefix, "4pm"
  ['wednesday ', 'SSS 2', 'Physics', 'Mr Tunde Okafor', '2348000000003', '4pm'],
  // 7-9: one teacher, three Saturday classes, out of time order, name variant
  [
    'Saturday',
    'SSS 1',
    'English',
    'Bro Yusuf Adebayo',
    '08000000001',
    '12:00 PM',
  ],
  [
    'Saturday',
    'JSS 3',
    'English',
    ' Bro Yusuf Adebayo ',
    '08000000001',
    '10:00 AM',
  ],
  [
    'Saturday',
    'SSS 1',
    'Literature',
    'Bro Yusuf Adebayo (Yus)',
    '0800-000-0001',
    '2:00 PM',
  ],
  // 10
  [
    'Saturday',
    'JSS 1',
    'Arabic',
    'Sis Halima Bello',
    '08000000002',
    '10:00 AM',
  ],
  // 11: invalid phone (9 digits)
  [
    'Saturday',
    'JSS 2',
    'Mathematics',
    'Sis Maryam Lawal',
    '080000012',
    '12:00 PM',
  ],
  // 12: blank start time
  ['Saturday', 'SSS 1', 'Chemistry', 'Bro Ibrahim Salami', '08000000007', ''],
  // 13: unrecognizable day (skipped)
  [
    'Satday',
    'SSS 2',
    'Biology',
    'Sis Ruqayyah Bakare',
    '08000000008',
    '10:00 AM',
  ],
  // 14: 24-hour time, stray spaces everywhere
  [
    '  Saturday',
    ' SSS 3 ',
    ' Further Mathematics',
    'Bro Kareem Hassan',
    ' 08000000005 ',
    ' 14:00 ',
  ],
  // 15: short row (no phone, no time cells)
  ['Thursday', 'SSS 3', 'Chemistry', 'Sis Zainab Musa'],
  // 16: day but nothing else (skipped)
  ['Friday', '', '', '', '', ''],
  // 17: blank day (skipped)
  ['', 'JSS 1', 'Mathematics', 'Bro Musa Ade', '08000000009', '4:00 PM'],
];

SheetTable contactsSheet({DateTime? fetchedAt}) => SheetTable(
  headers: contactsHeaders,
  rows: contactsRows,
  fetchedAt: fetchedAt,
);

/// The fixture parsed; fails the test if parsing fails.
Timetable contactsTimetable() => switch (parseContactsSheet(contactsSheet())) {
  Ok(:final value) => value,
  Err(:final failure) => throw StateError('fixture failed to parse: $failure'),
};

/// A session for unit tests that don't need the whole sheet.
ClassSession session({
  Weekday day = Weekday.saturday,
  String className = 'SSS 1',
  String subject = 'English',
  String teacherName = 'Bro Yusuf Adebayo',
  String rawPhone = '08000000001',
  String rawStartTime = '10:00 AM',
  int sheetRow = 2,
}) => ClassSession(
  day: day,
  className: className,
  subject: subject,
  teacherName: teacherName,
  rawPhone: rawPhone,
  rawStartTime: rawStartTime,
  sheetRow: sheetRow,
);
