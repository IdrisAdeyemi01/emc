import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

import '../../../shared/app_icon.dart';
import '../reminders_strings.dart';

/// Collapsible, editable message. Edits go to [onChanged] (kept in memory).
class MessagePreview extends StatelessComponent {
  const MessagePreview({
    required this.id,
    required this.message,
    required this.onChanged,
    this.initiallyOpen = false,
    this.invalid = false,
    this.describedBy,
    super.key,
  });

  final String id;
  final String message;
  final ValueChanged<String> onChanged;
  final bool initiallyOpen;

  /// Highlights the field (blank start time).
  final bool invalid;
  final String? describedBy;

  @override
  Component build(BuildContext context) {
    final lines = '\n'.allMatches(message).length + 1;
    return details(classes: 'preview', open: initiallyOpen, [
      summary([
        span(classes: 'summary-show', [
          Component.text(RemindersStrings.showMessage),
        ]),
        span(classes: 'summary-hide', [
          Component.text(RemindersStrings.hideMessage),
        ]),
        const Icon(AppIcon.chevronDown, size: 18),
      ]),
      label(classes: 'field-hint', htmlFor: id, [
        Component.text(RemindersStrings.editHint),
      ]),
      textarea(
        id: id,
        classes: invalid ? 'message message-invalid' : 'message',
        rows: lines.clamp(6, 26),
        spellCheck: SpellCheck.isFalse,
        attributes: {
          if (invalid) 'aria-invalid': 'true',
          'aria-describedby': ?describedBy,
        },
        onInput: onChanged,
        [Component.text(message)],
      ),
    ]);
  }
}
