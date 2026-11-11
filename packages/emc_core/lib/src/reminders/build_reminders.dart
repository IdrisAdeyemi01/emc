import '../common/weekday.dart';
import '../timetable/class_session.dart';
import '../timetable/timetable.dart';
import 'phone_number.dart';
import 'teacher_reminder.dart';

/// The reminders for [day]: one per teacher (grouped by phone), each listing
/// all their classes that day.
///
/// Cards are ordered by earliest class time, then name; teachers with no
/// readable time go last. See CLAUDE.md 2.4.
List<TeacherReminder> buildReminders(Timetable timetable, Weekday day) {
  final groups = <String, List<ClassSession>>{};
  final phones = <String, PhoneNumber>{};
  for (final session in timetable.sessionsOn(day)) {
    final phone = PhoneNumber.parse(session.rawPhone);
    final key = reminderGroupKey(phone, session.teacherName);
    phones.putIfAbsent(key, () => phone);
    groups.putIfAbsent(key, () => []).add(session);
  }

  final reminders = [
    for (final MapEntry(:key, value: sessions) in groups.entries)
      TeacherReminder(
        day: day,
        displayName: sessions.first.teacherName,
        phone: phones[key]!,
        classes: [...sessions]..sort(compareClasses),
      ),
  ];
  return reminders..sort(compareReminders);
}

/// Order within a card: start time, then class name; unreadable times after
/// readable ones, in sheet order.
int compareClasses(ClassSession a, ClassSession b) {
  final timeA = a.startTime;
  final timeB = b.startTime;
  if (timeA != null && timeB != null) {
    final byTime = timeA.compareTo(timeB);
    if (byTime != 0) return byTime;
    final byClass = a.className.toLowerCase().compareTo(
      b.className.toLowerCase(),
    );
    if (byClass != 0) return byClass;
  } else if (timeA != null) {
    return -1;
  } else if (timeB != null) {
    return 1;
  }
  return a.sheetRow.compareTo(b.sheetRow);
}

/// Order of cards: earliest start time, then name; no readable time last.
int compareReminders(TeacherReminder a, TeacherReminder b) {
  final timeA = a.earliestStartTime;
  final timeB = b.earliestStartTime;
  if (timeA != null && timeB != null) {
    final byTime = timeA.compareTo(timeB);
    if (byTime != 0) return byTime;
  } else if (timeA != null) {
    return -1;
  } else if (timeB != null) {
    return 1;
  }
  final byName = a.displayName.toLowerCase().compareTo(
    b.displayName.toLowerCase(),
  );
  if (byName != 0) return byName;
  return a.classes.first.sheetRow.compareTo(b.classes.first.sheetRow);
}
