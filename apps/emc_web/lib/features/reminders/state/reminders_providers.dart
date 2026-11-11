import 'package:emc_core/emc_core.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../core/providers.dart';
import 'timetable_controller.dart';

/// Today's weekday and date in Lagos (read once per page load).
final todayProvider = Provider<Weekday>(
  (ref) => ref.watch(clockProvider).lagosWeekday(),
);

final todayDateProvider = Provider<CalendarDate>(
  (ref) => ref.watch(clockProvider).lagosToday(),
);

/// The day the admin picked; null means "today".
class SelectedDayController extends Notifier<Weekday?> {
  @override
  Weekday? build() => null;

  void select(Weekday day) => state = day;
}

final selectedDayOverrideProvider =
    NotifierProvider<SelectedDayController, Weekday?>(
      SelectedDayController.new,
    );

final selectedDayProvider = Provider<Weekday>(
  (ref) => ref.watch(selectedDayOverrideProvider) ?? ref.watch(todayProvider),
);

/// The date of the selected day's classes: today, or the next such weekday.
/// "Sent" marks belong to this date, so reminders sent the night before
/// still show as sent on the day.
final classDateProvider = Provider<CalendarDate>(
  (ref) => ref
      .watch(todayDateProvider)
      .nextOccurrenceOf(ref.watch(selectedDayProvider)),
);

/// The loaded timetable, or null while loading / on error.
final loadedTimetableProvider = Provider<Timetable?>((ref) {
  final state = ref.watch(timetableProvider);
  return state is TimetableLoaded ? state.timetable : null;
});

/// Day chips: days with classes plus today.
final dayOptionsProvider = Provider<List<Weekday>>((ref) {
  final timetable = ref.watch(loadedTimetableProvider);
  if (timetable == null) return const [];
  return selectableDays(timetable, today: ref.watch(todayProvider));
});

/// Reminders for the selected day.
final remindersProvider = Provider<List<TeacherReminder>>((ref) {
  final timetable = ref.watch(loadedTimetableProvider);
  if (timetable == null) return const [];
  return buildReminders(timetable, ref.watch(selectedDayProvider));
});

/// Reminders for today (Home tile).
final todayRemindersProvider = Provider<List<TeacherReminder>>((ref) {
  final timetable = ref.watch(loadedTimetableProvider);
  if (timetable == null) return const [];
  return buildReminders(timetable, ref.watch(todayProvider));
});

/// The next day after the selected one that has classes (for the empty
/// state), with its teacher count.
final nextDayWithClassesProvider = Provider<({Weekday day, int teachers})?>((
  ref,
) {
  final timetable = ref.watch(loadedTimetableProvider);
  if (timetable == null) return null;
  final selected = ref.watch(selectedDayProvider);
  for (var offset = 1; offset < 7; offset++) {
    final day = Weekday.values[(selected.index + offset) % 7];
    final reminders = buildReminders(timetable, day);
    if (reminders.isNotEmpty) return (day: day, teachers: reminders.length);
  }
  return null;
});
