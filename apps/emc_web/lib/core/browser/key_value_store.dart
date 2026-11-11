/// Small string storage (localStorage in the browser, memory in tests).
abstract interface class KeyValueStore {
  String? read(String key);
  void write(String key, String value);
  void remove(String key);

  /// Every stored key.
  List<String> keys();
}

/// In-memory store: the fallback when localStorage is unavailable, and the
/// store used in tests and demo mode.
final class MemoryKeyValueStore implements KeyValueStore {
  MemoryKeyValueStore([Map<String, String>? initial]) : _values = {...?initial};

  final Map<String, String> _values;

  @override
  String? read(String key) => _values[key];

  @override
  void write(String key, String value) => _values[key] = value;

  @override
  void remove(String key) => _values.remove(key);

  @override
  List<String> keys() => _values.keys.toList();
}
