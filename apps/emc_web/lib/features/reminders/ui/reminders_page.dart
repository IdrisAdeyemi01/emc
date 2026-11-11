import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../shared/toast.dart';
import '../state/toast_controller.dart';
import 'reminders_body.dart';
import 'reminders_header.dart';

/// Teacher Reminders (`/reminders`), approved "Card stack" layout.
class RemindersPage extends StatelessComponent {
  const RemindersPage({super.key});

  @override
  Component build(BuildContext context) {
    final toast = context.watch(toastProvider);
    // One root element per page: Jaspr can't detach a top-level fragment when
    // the router swaps pages ("Cannot remove fragment from a different parent").
    return div(classes: 'page', [
      const RemindersHeader(),
      const RemindersBody(),
      ToastRegion(message: toast?.text, success: toast?.success ?? true),
    ]);
  }
}
