/// Browser entrypoint, compiled to `main.client.dart.js` and loaded by
/// `web/index.html`.
library;

import 'package:emc_core/emc_core.dart';
import 'package:jaspr/client.dart';

import 'app.dart';
import 'core/env.dart';

void main() {
  const Logger('app').info('Started (API configured: ${Env.isConfigured})');
  runApp(const App());
}
