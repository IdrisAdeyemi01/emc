import 'package:emc_core/emc_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../core/router.dart';
import '../../../shared/app_bar.dart';
import '../../../shared/app_icon.dart';
import '../../../shared/day_chips.dart';
import '../../../shared/progress_bar.dart';
import '../../../shared/skeleton_card.dart';
import '../reminders_strings.dart';
import '../state/reminders_providers.dart';
import '../state/sent_controller.dart';
import '../state/timetable_controller.dart';

/// Sticky header: title, Refresh, day chips, progress and "Updated".
class RemindersHeader extends StatelessComponent {
  const RemindersHeader({super.key});

  @override
  Component build(BuildContext context) {
    final state = context.watch(timetableProvider);
    final busy = switch (state) {
      TimetableLoading() => true,
      TimetableLoaded(:final refreshing) => refreshing,
      TimetableFailed(:final retrying) => retrying,
      TimetableNotConfigured() => false,
    };

    return AppBar(
      title: RemindersStrings.heading,
      backTo: AppPaths.home,
      backLabel: RemindersStrings.backToHome,
      actions: [
        if (state is! TimetableNotConfigured)
          button(
            type: ButtonType.button,
            classes: 'icon-btn',
            disabled: busy,
            attributes: {
              'aria-label': busy
                  ? RemindersStrings.refreshing
                  : RemindersStrings.refreshLabel,
              if (busy) 'aria-busy': 'true',
            },
            onClick: () => context.read(timetableProvider.notifier).refresh(),
            [Icon(AppIcon.refresh, size: 22, spinning: busy)],
          ),
      ],
      below: switch (state) {
        TimetableLoading() => const [SkeletonChips(), _ProgressSkeleton()],
        TimetableLoaded() => [_Controls(state)],
        _ => const [],
      },
    );
  }
}

class _Controls extends StatelessComponent {
  const _Controls(this.state);

  final TimetableLoaded state;

  @override
  Component build(BuildContext context) {
    final today = context.watch(todayProvider);
    final selected = context.watch(selectedDayProvider);
    final days = context.watch(dayOptionsProvider);
    final progress = context.watch(progressProvider);
    return div(classes: 'header-controls', [
      DayChips(
        groupLabel: RemindersStrings.dayGroup,
        todayLabel: RemindersStrings.today,
        options: [
          for (final day in days)
            (
              label: day.shortLabel,
              isToday: day == today,
              selected: day == selected,
            ),
        ],
        onSelect: (index) => context
            .read(selectedDayOverrideProvider.notifier)
            .select(days[index]),
      ),
      if (progress.total > 0)
        ProgressBar(
          value: progress.sent,
          max: progress.total,
          ariaLabel: RemindersStrings.progressLabel,
          label: Component.fragment([
            strong([
              Component.text(
                RemindersStrings.sentOf(progress.sent, progress.total),
              ),
            ]),
            Component.text(RemindersStrings.sentSuffix),
          ]),
          meta: Component.text(
            RemindersStrings.updatedAt(
              formatClockTime(toLagos(state.updatedAt)),
            ),
          ),
        )
      else
        p(classes: 'progress-meta', [
          Component.text(
            RemindersStrings.updatedAt(
              formatClockTime(toLagos(state.updatedAt)),
            ),
          ),
        ]),
    ]);
  }
}

class _ProgressSkeleton extends StatelessComponent {
  const _ProgressSkeleton();

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'progress shimmer',
      attributes: const {'aria-hidden': 'true'},
      [
        span(
          classes: 'skel',
          styles: Styles(width: 140.px, height: 14.px),
          [],
        ),
        span(
          classes: 'skel',
          styles: Styles(width: 100.percent, height: 10.px),
          [],
        ),
      ],
    );
  }
}
