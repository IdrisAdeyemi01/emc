import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app_icon.dart';

enum ButtonVariant { primary, secondary, ghost }

/// Button (or a link styled as one when [href] is set).
///
/// A disabled link renders as a disabled `<button>`, so it can't be followed.
class AppButton extends StatelessComponent {
  const AppButton({
    required this.label,
    this.variant = ButtonVariant.primary,
    this.icon,
    this.onPressed,
    this.href,
    this.openInNewTab = false,
    this.disabled = false,
    this.loading = false,
    this.fullWidth = true,
    this.describedBy,
    super.key,
  });

  final String label;
  final ButtonVariant variant;
  final AppIcon? icon;
  final VoidCallback? onPressed;

  /// Renders an `<a>` instead of a `<button>`; [onPressed] still fires.
  final String? href;
  final bool openInNewTab;
  final bool disabled;

  /// Shows a spinner and blocks presses (`aria-busy`).
  final bool loading;
  final bool fullWidth;

  /// Id of the element explaining why the button is disabled.
  final String? describedBy;

  @override
  Component build(BuildContext context) {
    final classes = [
      'btn',
      'btn-${variant.name}',
      if (!fullWidth) 'btn-auto',
    ].join(' ');
    final content = [
      if (loading)
        const Icon(AppIcon.spinner, spinning: true)
      else if (icon case final icon?)
        Icon(icon, size: variant == ButtonVariant.ghost ? 16 : 20),
      Component.text(label),
    ];
    final attributes = {
      'aria-describedby': ?describedBy,
      if (loading) 'aria-busy': 'true',
    };

    if (href != null && !disabled && !loading) {
      final onPressed = this.onPressed;
      return a(
        href: href!,
        target: openInNewTab ? Target.blank : null,
        classes: classes,
        attributes: {...attributes, if (openInNewTab) 'rel': 'noopener'},
        // A raw listener, not `onClick`: Jaspr's onClick calls
        // preventDefault() on anchors, which would stop the link opening.
        events: onPressed == null ? null : {'click': (_) => onPressed()},
        content,
      );
    }
    return button(
      type: ButtonType.button,
      disabled: disabled || loading,
      classes: classes,
      attributes: attributes,
      onClick: disabled || loading ? null : onPressed,
      content,
    );
  }
}
