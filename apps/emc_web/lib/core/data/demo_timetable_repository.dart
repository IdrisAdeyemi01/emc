import 'package:emc_core/emc_core.dart';

/// Demo mode only (`EMC_DEMO=true`): the fake Saturday from the approved
/// designs. FAKE names and numbers.
final class DemoTimetableRepository implements TimetableRepository {
  const DemoTimetableRepository({
    this.delay = const Duration(milliseconds: 600),
  });

  final Duration delay;

  @override
  Future<Result<Timetable>> loadTimetable() async {
    await Future<void>.delayed(delay);
    return parseContactsSheet(
      SheetTable(
        headers: const [
          'Day',
          'Class',
          'Subject',
          'Teacher',
          'Phone numbers',
          'Start Time',
        ],
        rows: demoRows,
        fetchedAt: demoNow,
      ),
    );
  }
}

/// Saturday 14 November 2026, 8:15 AM in Lagos.
final demoNow = DateTime.utc(2026, 11, 14, 7, 15);

/// Reminders already marked sent in the demo ("3 of 7 sent").
const demoSentKeys = {
  'emc.sent.2026-11-14.tel:2348000000003': '1',
  'emc.sent.2026-11-14.tel:2348000000002': '1',
  'emc.sent.2026-11-14.tel:2348000000005': '1',
};

const demoRows = <List<String>>[
  [
    'Monday',
    'JSS 1',
    'Mathematics',
    'Bro Yusuf Adebayo',
    '08000000001',
    '4:00 PM',
  ],
  ['Monday', 'JSS 2', 'English', 'Sis Halima Bello', '08000000002', '4:00 PM'],
  ['Tuesday', 'SSS 2', 'Physics', 'Mr Tunde Okafor', '08000000003', '4:00 PM'],
  [
    'Wednesday',
    'JSS 3',
    'Basic Science',
    'Sis Aishat Ogunleye',
    '08000000006',
    '4:00 PM',
  ],
  [
    'Thursday',
    'SSS 3',
    'Further Mathematics',
    'Bro Kareem Hassan',
    '08000000005',
    '4:00 PM',
  ],
  [
    'Saturday',
    'JSS 3',
    'English',
    'Bro Yusuf Adebayo',
    '08000000001',
    '10:00 AM',
  ],
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
    'SSS 1',
    'Literature',
    'Bro Yusuf Adebayo',
    '08000000001',
    '2:00 PM',
  ],
  [
    'Saturday',
    'SSS 2',
    'Physics',
    'Mr Tunde Okafor',
    '08000000003',
    '10:00 AM',
  ],
  [
    'Saturday',
    'SSS 3',
    'Physics',
    'Mr Tunde Okafor',
    '08000000003',
    '12:00 PM',
  ],
  [
    'Saturday',
    'JSS 1',
    'Arabic',
    'Sis Halima Bello',
    '08000000002',
    '10:00 AM',
  ],
  [
    'Saturday',
    'JSS 2',
    'Mathematics',
    'Sis Maryam Lawal',
    '0800 000 12',
    '12:00 PM',
  ],
  [
    'Saturday',
    'SSS 3',
    'Further Mathematics',
    'Bro Kareem Hassan',
    '08000000005',
    '2:00 PM',
  ],
  [
    'Saturday',
    'JSS 3',
    'Basic Science',
    'Sis Aishat Ogunleye',
    '08000000006',
    '2:00 PM',
  ],
  ['Saturday', 'SSS 1', 'Chemistry', 'Bro Ibrahim Salami', '08000000007', ''],
];
