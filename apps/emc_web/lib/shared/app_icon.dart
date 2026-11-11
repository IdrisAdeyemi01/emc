import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// The app's icons: 24px stroke SVGs in `currentColor` (no icon fonts, no
/// WhatsApp logo).
enum AppIcon {
  back('<path d="M15 5l-7 7 7 7"/>'),
  forward('<path d="M9 5l7 7-7 7"/>'),
  refresh('<path d="M20 11a8 8 0 1 0-2.3 5.7"/><path d="M20 4v7h-7"/>'),
  send('<path d="M21 3 3 10.5l7 2.5 2.5 7L21 3Z"/><path d="m10 13 4-4"/>'),
  copy(
    '<rect x="9" y="9" width="11" height="11" rx="1.5"/>'
    '<path d="M5 15V5a1 1 0 0 1 1-1h10"/>',
  ),
  chevronDown('<path d="m6 9 6 6 6-6"/>'),
  notSent('<circle cx="12" cy="12" r="8"/>'),
  warning(
    '<path d="M12 3 2 21h20L12 3Z"/><path d="M12 10v5"/><path d="M12 17.5v.5"/>',
  ),
  alert(
    '<circle cx="12" cy="12" r="9"/><path d="M12 7v6"/><path d="M12 16.5v.5"/>',
  ),
  calendar(
    '<rect x="3" y="5" width="18" height="16" rx="2"/>'
    '<path d="M3 10h18M8 3v4M16 3v4"/>',
  ),
  undo('<path d="M3 12a9 9 0 1 0 3-6.7"/><path d="M3 4v5h5"/>'),
  settings(
    '<circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1 7 17M17 7l2.1-2.1"/>',
  ),
  spinner('<path d="M12 3a9 9 0 1 1-9 9"/>');

  const AppIcon(this.paths);

  final String paths;
}

/// Renders an [AppIcon]. Decorative (hidden from screen readers): the text
/// next to it carries the meaning.
class Icon extends StatelessComponent {
  const Icon(this.icon, {this.size = 20, this.spinning = false, super.key});

  final AppIcon icon;
  final int size;
  final bool spinning;

  @override
  Component build(BuildContext context) {
    return span(
      classes: spinning ? 'icon spin' : 'icon',
      styles: Styles(width: size.px, height: size.px),
      attributes: const {'aria-hidden': 'true'},
      [
        RawText(
          '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" '
          'stroke-width="2" stroke-linecap="round" stroke-linejoin="round" '
          'focusable="false">${icon.paths}</svg>',
        ),
      ],
    );
  }
}

/// The filled "sent" check (filled circle + white tick), used in badges.
class SentCheckIcon extends StatelessComponent {
  const SentCheckIcon({this.size = 14, super.key});

  final int size;

  @override
  Component build(BuildContext context) {
    return span(
      classes: 'icon',
      styles: Styles(width: size.px, height: size.px),
      attributes: const {'aria-hidden': 'true'},
      [
        const RawText(
          '<svg viewBox="0 0 24 24" focusable="false">'
          '<circle cx="12" cy="12" r="10" fill="currentColor"/>'
          '<path d="m7.5 12.5 3 3 6-7" fill="none" stroke="var(--color-success-bg)" '
          'stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round"/>'
          '</svg>',
        ),
      ],
    );
  }
}
