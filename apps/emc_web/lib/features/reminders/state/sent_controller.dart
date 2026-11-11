import 'package:emc_core/emc_core.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../core/providers.dart';
import 'reminders_providers.dart';

const _sentPrefix = 'emc.sent.';

/// How long "sent" marks are kept before being cleaned up.
const sentRetention = Duration(days: 14);

/// The set of `sentStorageKey`s marked sent, mirrored in storage.
class SentController extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    final store = ref.watch(keyValueStoreProvider);
    final oldest = ref
        .watch(todayDateProvider)
        .addDays(-sentRetention.inDays)
        .toIsoString();
    final kept = <String>{};
    for (final key in store.keys()) {
      if (!key.startsWith(_sentPrefix)) continue;
      final date = key.substring(_sentPrefix.length).split('.').first;
      if (date.compareTo(oldest) < 0) {
        store.remove(key);
      } else {
        kept.add(key);
      }
    }
    return kept;
  }

  bool isSent(TeacherReminder reminder, CalendarDate classDate) =>
      state.contains(sentStorageKey(classDate, reminder));

  void setSent(
    TeacherReminder reminder,
    CalendarDate classDate, {
    required bool sent,
  }) {
    final key = sentStorageKey(classDate, reminder);
    final store = ref.read(keyValueStoreProvider);
    if (sent) {
      store.write(key, '1');
      state = {...state, key};
    } else {
      store.remove(key);
      state = {...state}..remove(key);
    }
  }
}

final sentProvider = NotifierProvider<SentController, Set<String>>(
  SentController.new,
);

/// "3 of 7 sent" for the selected day.
final progressProvider = Provider<SentProgress>((ref) {
  final sentKeys = ref.watch(sentProvider);
  final date = ref.watch(classDateProvider);
  return sentProgress(
    ref.watch(remindersProvider),
    (r) => sentKeys.contains(sentStorageKey(date, r)),
  );
});

/// Today's progress, for the Home tile.
final todayProgressProvider = Provider<SentProgress>((ref) {
  final sentKeys = ref.watch(sentProvider);
  final date = ref.watch(todayDateProvider);
  return sentProgress(
    ref.watch(todayRemindersProvider),
    (r) => sentKeys.contains(sentStorageKey(date, r)),
  );
});
