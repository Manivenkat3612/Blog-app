/// Lightweight logging utility. In release mode, logs are suppressed.
import 'package:flutter/foundation.dart';

void logDebug(Object msg) {
  if (kDebugMode) {
    // ignore: avoid_print
    print(msg);
  }
}
