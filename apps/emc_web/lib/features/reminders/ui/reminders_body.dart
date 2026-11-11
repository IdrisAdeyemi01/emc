import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../shared/app_button.dart';
import '../../../shared/app_icon.dart';
import '../../../shared/notice.dart';
import '../../../shared/skeleton_card.dart';
import '../../../shared/state_panel.dart';
import '../reminders_strings.dart';
import '../state/reminders_providers.dart';
import '../state/sent_controller.dart';
import '../state/timetable_controller.dart';
import 'reminder_card.dart';

/// The page body for each timetable state.
class RemindersBody extends StatelessComponent {
  const RemindersBody({super.key});

  @override
  Component build(BuildContext context) {
    final state = context.watch(timetableProvider);
    return main_(classes: 'reminders-list', switch (state) {
      TimetableLoading() => const [
        p(
          classes: 'sr-only',
          attributes: {'role': 'status'},
          [Component.text(RemindersStrings.loading)],
        ),
        SkeletonCard(),
        SkeletonCard(nameWidth: 140, bodyHeight: 44),
        SkeletonCard(nameWidth: 190, bodyHeight: 44),
      ],
      TimetableNotConfigured() => const [
        StatePanel(
          icon: AppIcon.settings,
          tone: StatePanelTone.danger,
          isAlert: true,
          title: RemindersStrings.notConfiguredTitle,
          body: RemindersStrings.notConfiguredBody,
        ),
      ],
      TimetableFailed(:final failure, :final retrying) => [
        StatePanel(
          icon: AppIcon.alert,
          tone: StatePanelTone.danger,
          isAlert: true,
          title: RemindersStrings.errorTitle,
          body: RemindersStrings.errorBody(failure),
          action: AppButton(
            label: RemindersStrings.tryAgain,
            icon: AppIcon.refresh,
            fullWidth: false,
            loading: retrying,
            onPressed: () => context.read(timetableProvider.notifier).refresh(),
          ),
        ),
      ],
      TimetableLoaded(:final timetable) => [
        if (timetable.skipped.isNotEmpty)
          Notice(
            tone: NoticeTone.info,
            children: [
              Component.text(
                RemindersStrings.skippedRows(timetable.skipped.length),
              ),
            ],
          ),
        const _ReminderList(),
      ],
    });
  }
}

class _ReminderList extends StatelessComponent {
  const _ReminderList();

  @override
  Component build(BuildContext context) {
    final reminders = context.watch(remindersProvider);
    final selected = context.watch(selectedDayProvider);
    final isToday = selected == context.watch(todayProvider);

    if (reminders.isEmpty) {
      final next = context.watch(nextDayWithClassesProvider);
      return StatePanel(
        icon: AppIcon.calendar,
        title: RemindersStrings.emptyTitle(selected),
        body: RemindersStrings.emptyBody(
          isToday: isToday,
          next: next?.day,
          nextCount: next?.teachers ?? 0,
        ),
        action: next == null
            ? null
            : AppButton(
                label: RemindersStrings.seeDay(next.day),
                variant: ButtonVariant.secondary,
                fullWidth: false,
                onPressed: () => context
                    .read(selectedDayOverrideProvider.notifier)
                    .select(next.day),
              ),
      );
    }

    final progress = context.watch(progressProvider);
    return Component.fragment([
      if (progress.isComplete)
        StatePanel(
          tone: StatePanelTone.done,
          title: RemindersStrings.allSentTitle(progress.total),
          body: RemindersStrings.allSentBody(selected, isToday: isToday),
        ),
      div(classes: 'reminders-cards', [
        for (final reminder in reminders)
          ReminderCard(
            reminder,
            key: ValueKey('${selected.name}|${reminder.id}'),
          ),
      ]),
    ]);
  }
}
