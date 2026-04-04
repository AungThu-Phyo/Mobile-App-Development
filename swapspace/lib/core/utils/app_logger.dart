import 'package:flutter/foundation.dart';

class AppLogger {
  static void debug(String message) {
    if (!kReleaseMode) {
      debugPrint(message);
    }
  }

  static void error(String message, Object error, [StackTrace? stackTrace]) {
    if (kReleaseMode) return;
    debugPrint('$message: $error');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }
}
