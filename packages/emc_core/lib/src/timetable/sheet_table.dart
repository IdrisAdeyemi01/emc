/// The `Teachers' Contacts` tab as the backend returns it: raw header row and
/// raw data rows (display values), before any parsing.
final class SheetTable {
  const SheetTable({required this.headers, required this.rows, this.fetchedAt});

  final List<String> headers;
  final List<List<String>> rows;

  /// When the backend read the sheet, if it said.
  final DateTime? fetchedAt;
}
