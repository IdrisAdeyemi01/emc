/// Day of the week, Monday first.
enum Weekday {
  monday('Monday', 'Mon'),
  tuesday('Tuesday', 'Tue'),
  wednesday('Wednesday', 'Wed'),
  thursday('Thursday', 'Thu'),
  friday('Friday', 'Fri'),
  saturday('Saturday', 'Sat'),
  sunday('Sunday', 'Sun');

  const Weekday(this.label, this.shortLabel);

  /// Full English name, e.g. `Saturday`.
  final String label;

  /// Three-letter label for day chips, e.g. `Sat`.
  final String shortLabel;

  /// The weekday of [dateTime]'s date fields (no timezone conversion).
  static Weekday fromDateTime(DateTime dateTime) =>
      values[dateTime.weekday - DateTime.monday];

  /// Reads a day as an admin might type it in the sheet: any case, stray
  /// whitespace, full or abbreviated (`Wednesday`, `Weds`, `wed.`).
  ///
  /// Returns null when the text isn't a recognizable day. Never guesses.
  static Weekday? tryParse(String raw) {
    var key = raw.trim().toLowerCase();
    if (key.endsWith('.')) key = key.substring(0, key.length - 1).trimRight();
    return _aliases[key];
  }

  static const _aliases = {
    'monday': monday,
    'mon': monday,
    'tuesday': tuesday,
    'tue': tuesday,
    'tues': tuesday,
    'wednesday': wednesday,
    'wed': wednesday,
    'weds': wednesday,
    'thursday': thursday,
    'thu': thursday,
    'thur': thursday,
    'thurs': thursday,
    'friday': friday,
    'fri': friday,
    'saturday': saturday,
    'sat': saturday,
    'sunday': sunday,
    'sun': sunday,
  };
}
