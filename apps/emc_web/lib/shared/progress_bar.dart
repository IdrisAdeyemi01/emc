import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Labelled progress bar, e.g. "3 of 7 sent".
class ProgressBar extends StatelessComponent {
  const ProgressBar({
    required this.value,
    required this.max,
    this.label,
    this.meta,
    this.ariaLabel = 'Progress',
    super.key,
  });

  final int value;
  final int max;

  /// Main text on the left (the caller bolds the count). No text row when
  /// both [label] and [meta] are null.
  final Component? label;

  /// Small text on the right ("Updated 8:15 AM").
  final Component? meta;
  final String ariaLabel;

  @override
  Component build(BuildContext context) {
    final percent = max == 0 ? 0 : (value * 100 / max).round();
    return div(classes: 'progress', [
      if (label != null || meta != null)
        div(classes: 'progress-row', [
          span([?label]),
          if (meta != null) span(classes: 'progress-meta', [meta!]),
        ]),
      div(
        classes: 'bar',
        attributes: {
          'role': 'progressbar',
          'aria-label': ariaLabel,
          'aria-valuemin': '0',
          'aria-valuemax': '$max',
          'aria-valuenow': '$value',
        },
        [span(styles: Styles(width: percent.percent), [])],
      ),
    ]);
  }
}
