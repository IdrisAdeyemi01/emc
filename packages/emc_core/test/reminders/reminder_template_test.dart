// Golden strings for the admin's template (CLAUDE.md 2.5). These must match
// character for character: curly apostrophe, *bold*, blank lines, and the
// trailing space after "today." / "on Saturday.". Trailing spaces are
// written as \u0020 so editors and formatters can't strip them.

import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';
import '../fixtures/reminder_fixtures.dart';

void main() {
  test('single class, today (the admin\'s own example values)', () {
    final r = reminder([
      session(className: 'SS3', subject: 'Mathematics', rawStartTime: '4pm'),
    ]);

    expect(buildReminderMessage(r, isToday: true), '''
Assalamu Alaykum Warahmotullahi Wabarakaatuhu

Hope you’re doing great today.

This is to remind you of your class at EMC today.\u0020

Details below:
*Class* : SS3
*Subject* : Mathematics
*Start Time* : 4pm

Kindly take note.
Jazzakumullahu khayran

Signed: EMC Admin''');
  });

  test('multiple classes, today', () {
    final r = reminder([
      session(className: 'SSS 1', subject: 'English', rawStartTime: '10:00 AM'),
      session(
        className: 'SSS 1',
        subject: 'Literature',
        rawStartTime: '12:00 PM',
      ),
    ]);

    expect(buildReminderMessage(r, isToday: true), '''
Assalamu Alaykum Warahmotullahi Wabarakaatuhu

Hope you’re doing great today.

This is to remind you of your classes at EMC today.\u0020

Details below:
*Class* : SSS 1
*Subject* : English
*Start Time* : 10:00 AM

*Class* : SSS 1
*Subject* : Literature
*Start Time* : 12:00 PM

Kindly take note.
Jazzakumullahu khayran

Signed: EMC Admin''');
  });

  test('not today: "on Saturday", greeting line unchanged', () {
    final r = reminder([
      session(className: 'JSS 1', subject: 'Arabic', rawStartTime: '10:00 AM'),
    ]);

    expect(buildReminderMessage(r, isToday: false), '''
Assalamu Alaykum Warahmotullahi Wabarakaatuhu

Hope you’re doing great today.

This is to remind you of your class at EMC on Saturday.\u0020

Details below:
*Class* : JSS 1
*Subject* : Arabic
*Start Time* : 10:00 AM

Kindly take note.
Jazzakumullahu khayran

Signed: EMC Admin''');
  });

  test('missing start time leaves the line for the admin to fill', () {
    final r = reminder([
      session(className: 'SSS 1', subject: 'Chemistry', rawStartTime: ''),
    ]);

    expect(buildReminderMessage(r, isToday: true), '''
Assalamu Alaykum Warahmotullahi Wabarakaatuhu

Hope you’re doing great today.

This is to remind you of your class at EMC today.\u0020

Details below:
*Class* : SSS 1
*Subject* : Chemistry
*Start Time* :\u0020

Kindly take note.
Jazzakumullahu khayran

Signed: EMC Admin''');
  });

  test('3-class Saturday teacher from the sheet, not today', () {
    final yusuf = buildReminders(contactsTimetable(), Weekday.saturday).first;

    final message = buildReminderMessage(yusuf, isToday: false);

    expect(message, contains('your classes at EMC on Saturday. \n'));
    expect(
      message,
      contains(
        'Details below:\n'
        '*Class* : JSS 3\n*Subject* : English\n*Start Time* : 10:00 AM\n\n'
        '*Class* : SSS 1\n*Subject* : English\n*Start Time* : 12:00 PM\n\n'
        '*Class* : SSS 1\n*Subject* : Literature\n*Start Time* : 2:00 PM\n\n'
        'Kindly take note.',
      ),
    );
  });

  test('uses the curly apostrophe and no trailing newline', () {
    final message = buildReminderMessage(reminder([session()]), isToday: true);

    expect(message, contains('you’re'));
    expect(message, isNot(contains("you're")));
    expect(message.endsWith('Signed: EMC Admin'), isTrue);
  });
}
