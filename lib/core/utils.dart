import 'package:flutter/foundation.dart';

/// Logs only in debug builds. Use for verbose/diagnostic output that should
/// not spam release builds (see docs/OPTIMIZACIONES.md §1.1).
void logD(Object? message) {
  if (kDebugMode) debugPrint(message?.toString());
}

/// Logs in all builds. Use for real errors/warnings worth keeping in release.
void logE(Object? message, [StackTrace? stackTrace]) {
  if (kDebugMode && stackTrace != null) {
    debugPrint('$message\n$stackTrace');
  } else {
    debugPrint(message?.toString());
  }
}
