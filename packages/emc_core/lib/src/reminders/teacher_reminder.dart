import '../common/class_time.dart';
import '../common/weekday.dart';
import '../timetable/class_session.dart';
import 'phone_number.dart';

/// One reminder: a teacher and all their classes on one day.
final class TeacherReminder {
  TeacherReminder({
    required this.day,
    required this.displayName,
    required this.phone,
    required List<ClassSession> classes,
  }) : assert(classes.isNotEmpty),
       classes = List.unmodifiable(classes);

  final Weekday day;

  /// Teacher name from this phone's first row in the sheet that day.
  final String displayName;

  final PhoneNumber phone;

  /// The day's classes, ordered by start time, then class name. Classes
  /// without a readable time come last, in sheet order.
  final List<ClassSession> classes;

  /// Stable identity within a day: the normalized phone when valid; for
  /// unusable phones, the raw phone (or the teacher name when it's blank).
  String get id => reminderGroupKey(phone, displayName);

  /// Whether Send on WhatsApp can be enabled.
  bool get hasValidPhone => phone is ValidPhone;

  /// Whether any class has a blank Start Time (the admin must type it into
  /// the message before sending).
  bool get hasMissingStartTime => classes.any((c) => c.isStartTimeMissing);

  /// Earliest readable start time, or null if none can be read.
  ClassTime? get earliestStartTime => classes.first.startTime;

  @override
  String toString() =>
      'TeacherReminder($displayName, ${day.label}, ${classes.length} class(es))';
}

/// Grouping key for rows on one day. Phone is the identity; unusable phones
/// fall back to the raw cell, and blank phones to the teacher name.
String reminderGroupKey(PhoneNumber phone, String teacherName) =>
    switch (phone) {
      ValidPhone(:final digits) => 'tel:$digits',
      InvalidPhone(problem: PhoneProblem.empty) =>
        'name:${teacherName.trim().toLowerCase()}',
      InvalidPhone(:final raw) => 'raw:${raw.replaceAll(RegExp(r'\s'), '')}',
    };
