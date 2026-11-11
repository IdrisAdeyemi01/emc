import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app_icon.dart';

enum NoticeTone { warning, danger, info }

/// Inline explanation inside a card (why Send is disabled, etc.).
class Notice extends StatelessComponent {
  const Notice({
    required this.tone,
    required this.children,
    this.id,
    super.key,
  });

  final NoticeTone tone;
  final List<Component> children;

  /// Referenced by `aria-describedby` on the control it explains.
  final String? id;

  @override
  Component build(BuildContext context) {
    final (cssClass, icon) = switch (tone) {
      NoticeTone.warning => ('notice-warn', AppIcon.warning),
      NoticeTone.danger => ('notice-danger', AppIcon.alert),
      NoticeTone.info => ('notice-info', AppIcon.alert),
    };
    return p(id: id, classes: 'notice $cssClass', [
      Icon(icon, size: 18),
      span(children),
    ]);
  }
}
