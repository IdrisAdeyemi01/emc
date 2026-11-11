// Reminder helpers for tests. FAKE data only.

import 'package:emc_core/emc_core.dart';

/// A reminder built from [classes] (already in the order to keep).
TeacherReminder reminder(
  List<ClassSession> classes, {
  Weekday day = Weekday.saturday,
}) => TeacherReminder(
  day: day,
  displayName: classes.first.teacherName,
  phone: PhoneNumber.parse(classes.first.rawPhone),
  classes: classes,
);
