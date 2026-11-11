import 'teacher_reminder.dart';

/// The admin's reminder template, reproduced exactly: her spelling, the curly
/// apostrophe in "you’re", WhatsApp `*bold*`, blank lines and the trailing
/// space after "today.". Do not "correct" it (CLAUDE.md 2.5).
abstract final class ReminderTemplate {
  static const greeting = 'Assalamu Alaykum Warahmotullahi Wabarakaatuhu';
  static const wellWishes = 'Hope you’re doing great today.';
  static const detailsHeading = 'Details below:';
  static const closing = 'Kindly take note.\nJazzakumullahu khayran';
  static const signature = 'Signed: EMC Admin';

  /// "This is to remind you of your class at EMC today. " (note the trailing
  /// space), with "classes" for several and "on Saturday" when not today.
  static String reminderLine({required bool plural, required String when}) =>
      'This is to remind you of your ${plural ? 'classes' : 'class'} '
      'at EMC $when. ';

  /// One class block. Values are inserted exactly as in the sheet; a blank
  /// start time leaves `*Start Time* : ` for the admin to complete.
  static String classBlock({
    required String className,
    required String subject,
    required String startTime,
  }) =>
      '*Class* : $className\n'
      '*Subject* : $subject\n'
      '*Start Time* : $startTime';
}

/// Builds the WhatsApp message for [reminder].
///
/// [isToday] is true when the reminder's day is today in Lagos; otherwise the
/// message says "on Saturday" (the reminder's weekday) instead of "today".
String buildReminderMessage(TeacherReminder reminder, {required bool isToday}) {
  final blocks = [
    for (final c in reminder.classes)
      ReminderTemplate.classBlock(
        className: c.className,
        subject: c.subject,
        startTime: c.rawStartTime,
      ),
  ];
  return [
    ReminderTemplate.greeting,
    '',
    ReminderTemplate.wellWishes,
    '',
    ReminderTemplate.reminderLine(
      plural: reminder.classes.length > 1,
      when: isToday ? 'today' : 'on ${reminder.day.label}',
    ),
    '',
    ReminderTemplate.detailsHeading,
    blocks.join('\n\n'),
    '',
    ReminderTemplate.closing,
    '',
    ReminderTemplate.signature,
  ].join('\n');
}
