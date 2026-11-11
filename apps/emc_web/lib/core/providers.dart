import 'package:emc_core/emc_core.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import 'browser/browser_key_value_store.dart';
import 'browser/clipboard.dart';
import 'browser/key_value_store.dart';
import 'data/demo_timetable_repository.dart';
import 'data/timetable_repository_factory.dart';
import 'env.dart';

/// "Now". Tests override it; demo mode pins it to the design's Saturday.
final clockProvider = Provider<Clock>(
  (ref) => Env.demo ? FixedClock(demoNow) : const SystemClock(),
);

/// Where the timetable comes from; null when the build isn't configured.
final timetableRepositoryProvider = Provider<TimetableRepository?>(
  (ref) =>
      Env.demo ? const DemoTimetableRepository() : createTimetableRepository(),
);

/// Persistent storage for "sent" marks.
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) =>
      Env.demo ? MemoryKeyValueStore(demoSentKeys) : BrowserKeyValueStore(),
);

final clipboardProvider = Provider<ClipboardWriter>(
  (ref) => const BrowserClipboard(),
);
