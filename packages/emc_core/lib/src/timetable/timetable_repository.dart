import '../common/result.dart';
import 'timetable.dart';

/// The only way the apps load timetable data. Implementations: the Apps Script
/// HTTP client (M3), fakes in tests, maybe Firebase later.
///
/// Implementations fetch the raw tab, pass it to `parseContactsSheet`, and map
/// every problem to a `Failure` instead of throwing.
abstract interface class TimetableRepository {
  /// Reads the `Teachers' Contacts` tab fresh (no caching).
  Future<Result<Timetable>> loadTimetable();
}
