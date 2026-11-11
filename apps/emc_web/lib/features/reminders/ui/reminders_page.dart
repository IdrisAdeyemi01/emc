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
    return Component.fragment([
      const RemindersHeader(),
      const RemindersBody(),
      ToastRegion(message: toast?.text, success: toast?.success ?? true),
    ]);
  }
}
