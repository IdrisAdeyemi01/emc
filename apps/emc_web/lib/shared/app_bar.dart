import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import 'app_icon.dart';
import 'brand_logo.dart';

/// Sticky page header: back link, logo (from 768px), title, trailing
/// actions, and optional rows below (day chips, progress).
class AppBar extends StatelessComponent {
  const AppBar({
    required this.title,
    this.backTo,
    this.backLabel = 'Back',
    this.actions = const [],
    this.below = const [],
    super.key,
  });

  final String title;

  /// Route to go back to; no back button when null.
  final String? backTo;
  final String backLabel;
  final List<Component> actions;
  final List<Component> below;

  @override
  Component build(BuildContext context) {
    return header(classes: 'appbar', [
      div(classes: 'appbar-inner', [
        div(classes: 'appbar-top', [
          if (backTo != null)
            Link(
              to: backTo!,
              classes: 'icon-btn back',
              attributes: {'aria-label': backLabel},
              child: const Icon(AppIcon.back, size: 22),
            ),
          span(classes: 'appbar-logo', [
            const BrandLogo(size: 28, decorative: true),
          ]),
          h1(classes: 'appbar-title', [Component.text(title)]),
          ...actions,
        ]),
        ...below,
      ]),
    ]);
  }
}
