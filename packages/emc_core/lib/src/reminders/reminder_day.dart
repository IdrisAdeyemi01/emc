import '../common/calendar_date.dart';
import '../common/weekday.dart';
import '../timetable/timetable.dart';
import 'teacher_reminder.dart';

/// Days to offer as chips: every day with classes, plus [today] even when it
/// has none (so the "No classes scheduled for Friday" state is reachable).
/// Monday first.
List<Weekday> selectableDays(Timetable timetable, {required Weekday today}) {
  final days = timetable.daysWithClasses;
  return [
    for (final day in Weekday.values)
      if (days.contains(day) || day == today) day,
  ];
}

/// localStorage key for "this reminder was sent", per date and teacher.
///
/// Which date to pass (the day it was sent, or the class date) is decided
/// when sent tracking is built (M4).
String sentStorageKey(CalendarDate date, TeacherReminder reminder) =>
    'emc.sent.${date.toIsoString()}.${reminder.id}';

/// "4 of 7 sent". Every reminder counts toward [total], including ones that
/// can't be sent (invalid phone), as in the approved design.
final class SentProgress {
  const SentProgress({required this.sent, required this.total});

  final int sent;
  final int total;

  /// All reminders sent (false when there are none).
  bool get isComplete => total > 0 && sent >= total;

  /// 0.0 to 1.0, for the progress bar.
  double get fraction => total == 0 ? 0 : sent / total;

  @override
  bool operator ==(Object other) =>
      other is SentProgress && other.sent == sent && other.total == total;

  @override
  int get hashCode => Object.hash(sent, total);

  @override
  String toString() => 'SentProgress($sent of $total)';
}

/// Counts how many of [reminders] are sent according to [isSent].
SentProgress sentProgress(
  List<TeacherReminder> reminders,
  bool Function(TeacherReminder reminder) isSent,
) =>
    SentProgress(sent: reminders.where(isSent).length, total: reminders.length);
