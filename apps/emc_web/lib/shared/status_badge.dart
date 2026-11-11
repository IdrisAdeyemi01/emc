import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app_icon.dart';

enum BadgeKind { notSent, sent, warning, danger }

/// Status shown with an icon and text, never color alone.
class StatusBadge extends StatelessComponent {
  const StatusBadge(this.kind, this.label, {super.key});

  final BadgeKind kind;
  final String label;

  @override
  Component build(BuildContext context) {
    final (cssClass, icon) = switch (kind) {
      BadgeKind.notSent => (
        'badge-todo',
        const Icon(AppIcon.notSent, size: 14),
      ),
      BadgeKind.sent => ('badge-sent', const SentCheckIcon()),
      BadgeKind.warning => (
        'badge-warn',
        const Icon(AppIcon.warning, size: 14),
      ),
      BadgeKind.danger => ('badge-danger', const Icon(AppIcon.alert, size: 14)),
    };
    return span(classes: 'badge $cssClass', [icon, Component.text(label)]);
  }
}
