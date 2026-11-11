import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_router/jaspr_router.dart';

import '../../../core/router.dart';
import '../../../shared/brand_logo.dart';
import '../home_strings.dart';

/// Home (`/`). M1 placeholder; the approved design is built in M4.
class HomePage extends StatelessComponent {
  const HomePage({super.key});

  @override
  Component build(BuildContext context) {
    return main_(classes: 'container stack', [
      header(classes: 'page-header', [
        const BrandLogo(decorative: true),
        div([
          h1([Component.text(HomeStrings.heading)]),
          p(classes: 'muted', [Component.text(HomeStrings.tagline)]),
        ]),
      ]),
      Link(
        to: AppPaths.reminders,
        classes: 'text-link',
        child: Component.text(HomeStrings.remindersLink),
      ),
    ]);
  }
}
