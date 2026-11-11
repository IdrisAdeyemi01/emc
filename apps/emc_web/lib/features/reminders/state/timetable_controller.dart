import 'package:emc_core/emc_core.dart';
import 'package:jaspr_riverpod/jaspr_riverpod.dart';

import '../../../core/providers.dart';
import '../reminders_strings.dart';
import 'toast_controller.dart';

/// What the page knows about the timetable.
sealed class TimetableState {
  const TimetableState();
}

/// First load in progress (skeletons).
final class TimetableLoading extends TimetableState {
  const TimetableLoading();
}

/// The build has no API URL or key.
final class TimetableNotConfigured extends TimetableState {
  const TimetableNotConfigured();
}

final class TimetableLoaded extends TimetableState {
  const TimetableLoaded(
    this.timetable, {
    required this.loadedAt,
    this.refreshing = false,
  });

  final Timetable timetable;

  /// When this data arrived (fallback for the sheet's fetchedAt).
  final DateTime loadedAt;

  /// A refresh is running; the old data stays on screen.
  final bool refreshing;

  /// When the sheet was read, for "Updated 8:15 AM".
  DateTime get updatedAt => timetable.fetchedAt ?? loadedAt;
}

final class TimetableFailed extends TimetableState {
  const TimetableFailed(this.failure, {this.retrying = false});

  final Failure failure;
  final bool retrying;
}

/// Loads the sheet on first use and on [refresh]. Never throws.
class TimetableController extends Notifier<TimetableState> {
  @override
  TimetableState build() {
    final repository = ref.watch(timetableRepositoryProvider);
    if (repository == null) return const TimetableNotConfigured();
    Future.microtask(() => _load(repository));
    return const TimetableLoading();
  }

  /// Reloads from the sheet, keeping what's on screen meanwhile.
  Future<void> refresh() async {
    final repository = ref.read(timetableRepositoryProvider);
    if (repository == null) return;
    switch (state) {
      case TimetableLoaded(
        :final timetable,
        :final loadedAt,
        refreshing: false,
      ):
        state = TimetableLoaded(
          timetable,
          loadedAt: loadedAt,
          refreshing: true,
        );
      case TimetableFailed(:final failure, retrying: false):
        state = TimetableFailed(failure, retrying: true);
      default:
        return; // already loading
    }
    await _load(repository);
  }

  Future<void> _load(TimetableRepository repository) async {
    final result = await repository.loadTimetable();
    if (!ref.mounted) return;
    final now = ref.read(clockProvider).now();
    final previous = state;
    switch (result) {
      case Ok(:final value):
        state = TimetableLoaded(value, loadedAt: now);
      case Err(:final failure):
        if (previous case TimetableLoaded(:final timetable, :final loadedAt)) {
          state = TimetableLoaded(timetable, loadedAt: loadedAt);
          ref
              .read(toastProvider.notifier)
              .show(RemindersStrings.refreshFailed, success: false);
        } else {
          state = TimetableFailed(failure);
        }
    }
  }
}

final timetableProvider = NotifierProvider<TimetableController, TimetableState>(
  TimetableController.new,
);
