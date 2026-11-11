/// User-facing strings for the Home feature.
abstract final class HomeStrings {
  static const pageTitle = 'EMC Portal';
  static const heading = 'EMC Portal';
  static const tagline = 'Extra Mural Class · JSS 1 to SSS 3';
  static const lagosTime = 'Lagos time';

  static const remindersTitle = 'Teacher Reminders';
  static const remindersLoading = 'Loading today’s teachers…';
  static const remindersUnavailable = 'Couldn’t load today’s classes';
  static const noClassesToday = 'No classes today';
  static String teachersToday(int count) =>
      count == 1 ? '1 teacher today' : '$count teachers today';
  static String sentCount(int sent) => ' · $sent sent';
  static const ctaSend = 'Send today’s reminders';
  static const ctaOpen = 'Open reminders';
  static const progressLabel = 'Reminders sent today';
}
