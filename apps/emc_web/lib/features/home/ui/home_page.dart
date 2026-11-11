import 'package:emc_core/emc_core.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../../core/router.dart';
import '../../../shared/app_icon.dart';
import '../../../shared/brand_logo.dart';
import '../../../shared/progress_bar.dart';
import '../../reminders/state/reminders_providers.dart';
import '../../reminders/state/sent_controller.dart';
import '../../reminders/state/timetable_controller.dart';
import '../home_strings.dart';

/// Home (`/`): logo, today's date and one tile per feature.
class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    final today = context.watch(todayDateProvider);
    // One root element per page: Jaspr can't detach a top-level fragment when
    // the router swaps pages ("Cannot remove fragment from a different parent").
    return div(classes: 'page', [
      header(classes: 'home-header', [
        div(classes: 'home-header-inner', [
          const BrandLogo(),
          div([
            h1(classes: 'home-title', [Component.text(HomeStrings.heading)]),
            p(classes: 'muted', [
              small([Component.text(HomeStrings.tagline)]),
            ]),
          ]),
        ]),
      ]),
      main_(classes: 'home-main', [
        p(classes: 'home-date', [
          strong([Component.text(formatLongDate(today))]),
          span(classes: 'muted', [
            Component.text(' · ${HomeStrings.lagosTime}'),
          ]),
        ]),
        div(classes: 'tiles', [const _RemindersTile()]),
      ]),
    ]);
  }
}

class _RemindersTile extends StatelessComponent {
  const _RemindersTile();

  @override
  Component build(BuildContext context) {
    final state = context.watch(timetableProvider);
    final progress = context.watch(todayProgressProvider);
    final hasClasses = progress.total > 0;

    final Component summary = switch (state) {
      TimetableLoading() => Component.text(HomeStrings.remindersLoading),
      TimetableLoaded() when !hasClasses => Component.text(
        HomeStrings.noClassesToday,
      ),
      TimetableLoaded() => Component.fragment([
        strong([Component.text(HomeStrings.teachersToday(progress.total))]),
        span(classes: 'muted', [
          Component.text(HomeStrings.sentCount(progress.sent)),
        ]),
      ]),
      _ => Component.text(HomeStrings.remindersUnavailable),
    };

    return Link(
      to: AppPaths.reminders,
      classes: 'tile',
      children: [
        div(classes: 'tile-top', [
          span(classes: 'tile-icon', [const Icon(AppIcon.send, size: 26)]),
          const Icon(AppIcon.forward, size: 22),
        ]),
        div(classes: 'tile-body', [
          h2(classes: 'tile-title', [
            Component.text(HomeStrings.remindersTitle),
          ]),
          p(classes: 'tile-text', [summary]),
        ]),
        if (state is TimetableLoaded && hasClasses)
          ProgressBar(
            value: progress.sent,
            max: progress.total,
            ariaLabel: HomeStrings.progressLabel,
          ),
        span(classes: 'tile-cta', [
          Component.text(
            state is TimetableLoaded && hasClasses && !progress.isComplete
                ? HomeStrings.ctaSend
                : HomeStrings.ctaOpen,
          ),
        ]),
      ],
    );
  }
}
