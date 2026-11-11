import 'package:universal_web/web.dart' as web;

import 'key_value_store.dart';

/// localStorage, wrapped so it never throws (private mode, blocked storage,
/// quota). On the first failure it switches to memory for the rest of the
/// visit (CLAUDE.md 2.6).
final class BrowserKeyValueStore implements KeyValueStore {
  final _memory = MemoryKeyValueStore();
  bool _useMemory = false;

  T _guard<T>(T Function(web.Storage storage) action, T Function() fallback) {
    if (_useMemory) return fallback();
    try {
      return action(web.window.localStorage);
    } catch (_) {
      _useMemory = true;
      return fallback();
    }
  }

  @override
  String? read(String key) =>
      _guard((s) => s.getItem(key), () => _memory.read(key));

  @override
  void write(String key, String value) {
    _memory.write(key, value);
    _guard((s) => s.setItem(key, value), () {});
  }

  @override
  void remove(String key) {
    _memory.remove(key);
    _guard((s) => s.removeItem(key), () {});
  }

  @override
  List<String> keys() => _guard(
    (s) => [for (var i = 0; i < s.length; i++) ?s.key(i)],
    _memory.keys,
  );
}
