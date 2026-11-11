import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import 'app_icon.dart';

enum StatePanelTone { neutral, danger, done }

/// Centered panel for empty, error, setup and "all done" states.
class StatePanel extends StatelessComponent {
  const StatePanel({
    required this.title,
    this.body,
    this.icon,
    this.tone = StatePanelTone.neutral,
    this.action,
    this.isAlert = false,
    super.key,
  });

  final String title;
  final String? body;
  final AppIcon? icon;
  final StatePanelTone tone;
  final Component? action;

  /// Announce to screen readers (`role="alert"`); use for errors.
  final bool isAlert;

  @override
  Component build(BuildContext context) {
    return div(
      classes: tone == StatePanelTone.done ? 'state state-done' : 'state',
      attributes: {'role': isAlert ? 'alert' : 'status'},
      [
        if (tone == StatePanelTone.done)
          const _DoneMark()
        else if (icon != null)
          span(
            classes: tone == StatePanelTone.danger
                ? 'state-icon state-icon-danger'
                : 'state-icon',
            styles: Styles(
              color: tone == StatePanelTone.danger
                  ? const Color.variable('--color-danger-text')
                  : const Color.variable('--color-brand'),
            ),
            [Icon(icon!, size: 28)],
          ),
        h2(classes: 'state-title', [Component.text(title)]),
        if (body != null) p(classes: 'state-body', [Component.text(body!)]),
        ?action,
      ],
    );
  }
}

/// Square brand-green check for the completion moment.
class _DoneMark extends StatelessComponent {
  const _DoneMark();

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'icon',
      styles: Styles(width: 56.px, height: 56.px),
      attributes: const {'aria-hidden': 'true'},
      [
        const RawText(
          '<svg viewBox="0 0 24 24" focusable="false">'
          '<rect x="1" y="1" width="22" height="22" rx="2" fill="var(--color-brand)"/>'
          '<path d="m6.5 12.5 3.5 3.5 7.5-8" fill="none" stroke="var(--color-on-action)" '
          'stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>'
          '</svg>',
        ),
      ],
    );
  }
}
