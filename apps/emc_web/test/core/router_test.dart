import 'package:emc_core/emc_core.dart';
import 'package:emc_web/core/browser/key_value_store.dart';
import 'package:emc_web/core/providers.dart';
import 'package:emc_web/core/router.dart';
import 'package:emc_web/features/home/ui/home_page.dart';
import 'package:emc_web/features/reminders/ui/reminders_page.dart';
import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';
import 'package:jaspr_router/jaspr_router.dart';
import 'package:jaspr_test/jaspr_test.dart';

class _EmptyRepository implements TimetableRepository {
  @override
  Future<Result<Timetable>> loadTimetable() async =>
      Ok(Timetable(sessions: const []));
}

Component _app() => ProviderScope(
  overrides: [
    timetableRepositoryProvider.overrideWithValue(_EmptyRepository()),
    clockProvider.overrideWithValue(
      FixedClock(DateTime.utc(2026, 11, 14, 7, 15)),
    ),
    keyValueStoreProvider.overrideWithValue(MemoryKeyValueStore()),
  ],
  child: Router(routes: appRoutes()),
);

/// The component a page's build returns (its root).
Component _pageRoot(Type pageType) {
  final page = find.byType(pageType).evaluate().single;
  late Component root;
  page.visitChildren((child) => root = child.component);
  return root;
}

void main() {
  // Regression: a page whose top level is a fragment crashes the browser
  // renderer when the router swaps pages ("Cannot remove fragment from a
  // different parent"), leaving the old page on screen.
  for (final (path, pageType) in [
    (AppPaths.home, HomePage),
    (AppPaths.reminders, RemindersPage),
  ]) {
    testComponents('$path renders one root element', (tester) async {
      tester.pumpComponent(_app());
      await tester.pump();

      final root = _pageRoot(pageType);
      expect(root, isA<div>());
      expect((root as div).classes, 'page');
    }, url: path);
  }
}
