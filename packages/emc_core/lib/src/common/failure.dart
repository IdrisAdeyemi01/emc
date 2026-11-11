import 'list_equality.dart';

/// Why loading the timetable failed. The UI maps each case to a human message
/// and a Retry button.
sealed class Failure {
  const Failure();
}

/// No connection, timeout or a non-JSON / server error response.
final class NetworkFailure extends Failure {
  const NetworkFailure([this.detail]);

  /// Technical detail for logs. Never shown to the admin.
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is NetworkFailure && other.detail == detail;

  @override
  int get hashCode => Object.hash(NetworkFailure, detail);

  @override
  String toString() => 'NetworkFailure($detail)';
}

/// The backend rejected the API key.
final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure();

  @override
  bool operator ==(Object other) => other is UnauthorizedFailure;

  @override
  int get hashCode => (UnauthorizedFailure).hashCode;

  @override
  String toString() => 'UnauthorizedFailure()';
}

/// The `Teachers' Contacts` tab doesn't exist.
final class SheetNotFoundFailure extends Failure {
  const SheetNotFoundFailure();

  @override
  bool operator ==(Object other) => other is SheetNotFoundFailure;

  @override
  int get hashCode => (SheetNotFoundFailure).hashCode;

  @override
  String toString() => 'SheetNotFoundFailure()';
}

/// Required columns weren't found in the header row.
final class MissingColumnsFailure extends Failure {
  const MissingColumnsFailure(this.missing);

  /// Display names of the missing columns, e.g. `['Phone numbers']`.
  final List<String> missing;

  @override
  bool operator ==(Object other) =>
      other is MissingColumnsFailure && listEquals(other.missing, missing);

  @override
  int get hashCode => Object.hashAll(missing);

  @override
  String toString() => 'MissingColumnsFailure($missing)';
}

/// The backend answered, but not in the agreed shape.
final class UnexpectedResponseFailure extends Failure {
  const UnexpectedResponseFailure([this.detail]);

  /// Technical detail for logs. Never shown to the admin.
  final String? detail;

  @override
  bool operator ==(Object other) =>
      other is UnexpectedResponseFailure && other.detail == detail;

  @override
  int get hashCode => Object.hash(UnexpectedResponseFailure, detail);

  @override
  String toString() => 'UnexpectedResponseFailure($detail)';
}
