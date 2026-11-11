import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';

/// Placeholder card shown while the timetable loads (shimmer is turned off
/// under prefers-reduced-motion by base.css).
class SkeletonCard extends StatelessComponent {
  const SkeletonCard({this.nameWidth = 170, this.bodyHeight = 88, super.key});

  final int nameWidth;
  final int bodyHeight;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'card shimmer',
      attributes: const {'aria-hidden': 'true'},
      [
        div(classes: 'skel-row', [
          span(
            classes: 'skel',
            styles: Styles(width: nameWidth.px, height: 20.px),
            [],
          ),
          span(
            classes: 'skel',
            styles: Styles(width: 80.px, height: 30.px),
            [],
          ),
        ]),
        span(
          classes: 'skel skel-soft',
          styles: Styles(width: 100.percent, height: bodyHeight.px),
          [],
        ),
        span(
          classes: 'skel',
          styles: Styles(width: 100.percent, height: 52.px),
          [],
        ),
      ],
    );
  }
}

/// Placeholder day chips.
class SkeletonChips extends StatelessComponent {
  const SkeletonChips({this.count = 5, super.key});

  final int count;

  @override
  Component build(BuildContext context) {
    return div(
      classes: 'skel-chips shimmer',
      attributes: const {'aria-hidden': 'true'},
      [
        for (var i = 0; i < count; i++)
          span(
            classes: 'skel',
            styles: Styles(width: 56.px, height: 52.px),
            [],
          ),
      ],
    );
  }
}
