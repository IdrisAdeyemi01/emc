import 'package:emc_core/emc_core.dart';

/// User-facing strings for the Teacher Reminders feature (one place, ready
/// for localization). The WhatsApp message itself lives in emc_core.
abstract final class RemindersStrings {
  static const pageTitle = 'Teacher Reminders · EMC Portal';
  static const heading = 'Teacher Reminders';
  static const backToHome = 'Back to home';
  static const refresh = 'Refresh';
  static const refreshLabel = 'Refresh from sheet';
  static const refreshing = 'Refreshing';
  static const dayGroup = 'Day';
  static const today = 'Today';
  static const loading = 'Loading today’s teachers…';
  static const progressLabel = 'Reminders sent';

  static String sentOf(int sent, int total) => '$sent of $total';
  static const sentSuffix = ' sent';
  static String updatedAt(String time) => 'Updated $time';

  // Card
  static const notSent = 'Not sent';
  static const sent = 'Sent';
  static const invalidPhone = 'Invalid phone';
  static const startTimeMissing = 'Start time missing';
  static const noTime = 'No time';
  static const showMessage = 'Show message';
  static const hideMessage = 'Hide message';
  static const editHint = 'Edit before sending. Edits aren’t saved.';
  static const sendOnWhatsApp = 'Send on WhatsApp';
  static const copyMessage = 'Copy message';
  static const markNotSent = 'Mark as not sent';

  /// Invalid-phone cards only: the admin copied the message and sent it
  /// another way.
  static const markSentManually = 'Mark as sent';
  static const addStartTimeToSend = 'Add the start time to send';
  static const missingTimeNoticeBefore = 'The sheet has no start time for ';
  static String missingTimeNoticeWhat(int count) =>
      count == 1 ? 'this class' : 'some of these classes';
  static const missingTimeNoticeAfter = '. Type it after ';
  static const missingTimeNoticeEnd = ' in the message to send.';
  static const startTimeLabel = '*Start Time* :';

  static String invalidPhoneReason(
    InvalidPhone phone,
  ) => switch (phone.problem) {
    PhoneProblem.empty =>
      'Can’t open WhatsApp: there’s no phone number in the sheet. Add it, then refresh.',
    PhoneProblem.wrongLength =>
      'Can’t open WhatsApp: this number has ${phone.digitCount} digits. '
          'Nigerian numbers need 11 (like 080…). Fix it in the sheet, then refresh.',
    PhoneProblem.wrongPrefix =>
      'Can’t open WhatsApp: this number doesn’t start with 0 or 234. '
          'Fix it in the sheet, then refresh.',
    PhoneProblem.invalidCharacters =>
      'Can’t open WhatsApp: this number contains letters or symbols. '
          'Fix it in the sheet, then refresh.',
  };

  // Toasts
  static const copied = 'Message copied';
  static const copyFailed =
      'Couldn’t copy. Open the message, then press and hold to copy it.';
  static const refreshFailed =
      'Couldn’t refresh. Showing the last loaded timetable.';

  // States
  static String allSentTitle(int count) =>
      count == 1 ? 'The teacher is reminded' : 'All $count teachers reminded';
  static String allSentBody(Weekday day, {required bool isToday}) => isToday
      ? 'Every reminder for today is marked sent. You’re done for today.'
      : 'Every reminder for ${day.label} is marked sent.';
  static const sentSection = 'Sent';

  static String emptyTitle(Weekday day) =>
      'No classes scheduled for ${day.label}';
  static String emptyBody({
    required bool isToday,
    Weekday? next,
    int nextCount = 0,
  }) {
    final first = isToday
        ? 'Nobody needs a reminder today.'
        : 'Nobody needs a reminder that day.';
    if (next == null) return first;
    final teachers = nextCount == 1 ? '1 teacher' : '$nextCount teachers';
    return '$first ${next.label} has $teachers.';
  }

  static String seeDay(Weekday day) => 'See ${day.label}’s teachers';

  static String skippedRows(int count) => count == 1
      ? '1 row in the sheet couldn’t be read (no recognizable day). It isn’t shown here.'
      : '$count rows in the sheet couldn’t be read (no recognizable day). They aren’t shown here.';

  static const errorTitle = 'Couldn’t load the timetable';
  static const tryAgain = 'Try again';

  static String errorBody(Failure failure) => switch (failure) {
    NetworkFailure() =>
      'Check your internet connection and try again. Nothing you’ve marked as sent is lost.',
    UnauthorizedFailure() =>
      'The site’s access key was refused. Whoever set up the site needs to update the key.',
    SheetNotFoundFailure() =>
      'The “Teachers’ Contacts” tab couldn’t be found. Check its name hasn’t changed.',
    MissingColumnsFailure(:final missing) =>
      'The sheet is missing ${missing.length == 1 ? 'this column' : 'these columns'}: '
          '${missing.join(', ')}. Check the header row.',
    UnexpectedResponseFailure() =>
      'The timetable service sent something unexpected. Try again in a minute.',
  };

  static const notConfiguredTitle = 'This site isn’t set up yet';
  static const notConfiguredBody =
      'The timetable address and key weren’t included when the site was built '
      '(EMC_API_URL and EMC_API_KEY).';
}
