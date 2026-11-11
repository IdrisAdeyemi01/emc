import 'package:emc_core/emc_core.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

/// The admin's edits to messages, kept in memory only (never saved to the
/// sheet or storage). Keyed by class date + reminder id.
class DraftsController extends Notifier<Map<String, String>> {
  @override
  Map<String, String> build() => const {};

  void update(String draftKey, String text) =>
      state = {...state, draftKey: text};
}

final draftsProvider = NotifierProvider<DraftsController, Map<String, String>>(
  DraftsController.new,
);

String draftKey(CalendarDate classDate, TeacherReminder reminder) =>
    '${classDate.toIsoString()}|${reminder.id}';

/// The message to send for [reminder]: the admin's edit if any, else the
/// template ("today" when the reminder's day is [today]).
String currentMessage(
  TeacherReminder reminder, {
  required Map<String, String> drafts,
  required CalendarDate classDate,
  required Weekday today,
}) =>
    drafts[draftKey(classDate, reminder)] ??
    buildReminderMessage(reminder, isToday: reminder.day == today);
