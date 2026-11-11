import 'package:jaspr_router/jaspr_router.dart';

import '../features/home/home_strings.dart';
import '../features/home/ui/home_page.dart';
import '../features/reminders/reminders_strings.dart';
import '../features/reminders/ui/reminders_page.dart';

/// Every route path in the app, so links never hardcode strings.
abstract final class AppPaths {
  static const home = '/';
  static const reminders = '/reminders';
}

/// Route table. Add new features here.
List<RouteBase> appRoutes() => [
  Route(
    path: AppPaths.home,
    title: HomeStrings.pageTitle,
    builder: (context, state) => const HomePage(),
  ),
  Route(
    path: AppPaths.reminders,
    title: RemindersStrings.pageTitle,
    builder: (context, state) => const RemindersPage(),
  ),
];
