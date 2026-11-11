import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../../core/router.dart';
import '../reminders_strings.dart';

/// Teacher Reminders (`/reminders`). M1 placeholder; the approved
/// "Card stack" design is built in M4.
class RemindersPage extends StatelessComponent {
  const RemindersPage({super.key});

  @override
  Component build(BuildContext context) {
    return main_(classes: 'container stack', [
      Link(
        to: AppPaths.home,
        classes: 'text-link',
        child: Component.text(RemindersStrings.backToHome),
      ),
      h1([Component.text(RemindersStrings.heading)]),
      p(classes: 'muted', [Component.text(RemindersStrings.placeholder)]),
    ]);
  }
}
