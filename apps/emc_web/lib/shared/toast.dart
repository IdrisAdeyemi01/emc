import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app_icon.dart';

/// A short confirmation at the bottom of the screen. Lives in a polite live
/// region so screen readers announce it.
class ToastRegion extends StatelessComponent {
  const ToastRegion({this.message, this.success = true, super.key});

  /// Nothing is shown when null.
  final String? message;
  final bool success;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'toast-region',
      attributes: const {'role': 'status', 'aria-live': 'polite'},
      [
        if (message != null)
          div(classes: 'toast', [
            if (success)
              span(
                styles: const Styles(
                  color: Color.variable('--color-success-text'),
                ),
                [const SentCheckIcon(size: 20)],
              )
            else
              span(
                styles: const Styles(
                  color: Color.variable('--color-warning-text'),
                ),
                [const Icon(AppIcon.warning)],
              ),
            span([Component.text(message!)]),
          ]),
      ],
    );
  }
}
