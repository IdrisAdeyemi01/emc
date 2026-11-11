import 'package:universal_web/js_interop.dart';
import 'package:universal_web/web.dart' as web;

/// Copies text. Returns false instead of throwing when it can't.
abstract interface class ClipboardWriter {
  Future<bool> writeText(String text);
}

/// The browser clipboard. Tries the async Clipboard API first, then the
/// older select-and-copy approach (works in more WebViews and when the page
/// isn't focused).
final class BrowserClipboard implements ClipboardWriter {
  const BrowserClipboard();

  @override
  Future<bool> writeText(String text) async {
    try {
      await web.window.navigator.clipboard.writeText(text).toDart;
      return true;
    } catch (_) {
      return _legacyCopy(text);
    }
  }

  bool _legacyCopy(String text) {
    try {
      final document = web.document;
      final area = document.createElement('textarea') as web.HTMLTextAreaElement
        ..value = text
        ..setAttribute('readonly', '')
        ..style.position = 'fixed'
        ..style.top = '-1000px'
        ..style.opacity = '0';
      document.body!.append(area);
      area.select();
      final ok = document.execCommand('copy');
      area.remove();
      return ok;
    } catch (_) {
      return false;
    }
  }
}
