import 'package:flutter/foundation.dart';

enum LogLevel { debug, info, warning, error }

class AppLogger {
  final String name;
  final bool enabled;

  const AppLogger(this.name, {this.enabled = true});

  void _log(LogLevel level, String message, [Object? error, StackTrace? st]) {
    if (!enabled) return;
    if (kDebugMode) {
      final prefix = '[${level.name.toUpperCase()}] [$name]';
      debugPrint('$prefix $message');
      if (error != null) debugPrint('Error: $error');
      if (st != null) debugPrint('Stack: $st');
    }
  }

  void debug(String m) => _log(LogLevel.debug, m);
  void info(String m) => _log(LogLevel.info, m);
  void warning(String m, [Object? e]) => _log(LogLevel.warning, m, e);
  void error(String m, [Object? e, StackTrace? st]) => _log(LogLevel.error, m, e, st);
}
