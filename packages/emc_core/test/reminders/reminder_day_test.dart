import 'package:emc_core/emc_core.dart';
import 'package:test/test.dart';

import '../fixtures/contacts_sheet.dart';
import '../fixtures/reminder_fixtures.dart';

void main() {
  group('selectableDays', () {
    test('days with classes, Monday first', () {
      expect(selectableDays(contactsTimetable(), today: Weekday.saturday), [
        Weekday.monday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.saturday,
      ]);
    });

    test('adds today even when it has no classes', () {
      expect(selectableDays(contactsTimetable(), today: Weekday.friday), [
        Weekday.monday,
        Weekday.wednesday,
        Weekday.thursday,
        Weekday.friday,
        Weekday.saturday,
      ]);
    });

    test('empty timetable: only today', () {
      expect(
        selectableDays(Timetable(sessions: const []), today: Weekday.sunday),
        [Weekday.sunday],
      );
    });
  });

  test('sentStorageKey combines date and reminder id', () {
    final r = reminder([session(rawPhone: '+234 800 000 0001')]);

    expect(
      sentStorageKey(const CalendarDate(2026, 11, 14), r),
      'emc.sent.2026-11-14.tel:2348000000001',
    );
  });

  group('sentProgress', () {
    final reminders = buildReminders(contactsTimetable(), Weekday.saturday);

    test('counts every reminder in the total, including invalid phones', () {
      final progress = sentProgress(
        reminders,
        (r) => r.displayName.startsWith('Bro'),
      );

      expect(progress, const SentProgress(sent: 3, total: 5));
      expect(progress.isComplete, isFalse);
      expect(progress.fraction, closeTo(0.6, 1e-9));
      expect(progress.toString(), 'SentProgress(3 of 5)');
      expect(progress.hashCode, const SentProgress(sent: 3, total: 5).hashCode);
    });

    test('complete when all are sent', () {
      final progress = sentProgress(reminders, (_) => true);

      expect(progress.isComplete, isTrue);
      expect(progress.fraction, 1);
    });

    test('nothing to send is not "complete"', () {
      final progress = sentProgress(const [], (_) => true);

      expect(progress, const SentProgress(sent: 0, total: 0));
      expect(progress.isComplete, isFalse);
      expect(progress.fraction, 0);
    });
  });
}
