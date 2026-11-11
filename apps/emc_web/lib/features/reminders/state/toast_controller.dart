import 'dart:async';

import 'package:jaspr_riverpod/jaspr_riverpod.dart';

/// A toast to show; null when none.
typedef ToastMessage = ({String text, bool success});

/// Shows one short message at a time for [duration].
class ToastController extends Notifier<ToastMessage?> {
  static const duration = Duration(seconds: 3);

  Timer? _timer;

  @override
  ToastMessage? build() {
    ref.onDispose(() => _timer?.cancel());
    return null;
  }

  void show(String text, {bool success = true}) {
    _timer?.cancel();
    state = (text: text, success: success);
    _timer = Timer(duration, () => state = null);
  }
}

final toastProvider = NotifierProvider<ToastController, ToastMessage?>(
  ToastController.new,
);
