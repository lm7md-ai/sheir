import 'dart:collection';
import 'package:flutter/foundation.dart';

enum DiwanLogLevel { debug, info, warn, error }

class DiwanLogEntry {
  final DateTime timestamp;
  final DiwanLogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;

  const DiwanLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    final ms = timestamp.millisecond.toString().padLeft(3, '0');
    return '$h:$m:$s.$ms';
  }

  String get levelIcon {
    switch (level) {
      case DiwanLogLevel.debug:
        return '🔍';
      case DiwanLogLevel.info:
        return 'ℹ️';
      case DiwanLogLevel.warn:
        return '⚠️';
      case DiwanLogLevel.error:
        return '🛑';
    }
  }

  String get levelArabic {
    switch (level) {
      case DiwanLogLevel.debug:
        return 'تدقيق';
      case DiwanLogLevel.info:
        return 'معلومات';
      case DiwanLogLevel.warn:
        return 'تحذير';
      case DiwanLogLevel.error:
        return 'خطأ';
    }
  }

  @override
  String toString() {
    return '[$formattedTime] [${level.name.toUpperCase()}] [$tag] $message${stackTrace != null ? '\n$stackTrace' : ''}';
  }
}

/// مدير سجلات النظام والتشخيص لديوان (Diwan Log Manager)
class DiwanLogger {
  DiwanLogger._();
  static final DiwanLogger instance = DiwanLogger._();

  static const int maxLogEntries = 1000;
  final Queue<DiwanLogEntry> _logs = Queue<DiwanLogEntry>();
  final ValueNotifier<List<DiwanLogEntry>> logsNotifier = ValueNotifier<List<DiwanLogEntry>>([]);

  void log({
    required DiwanLogLevel level,
    required String tag,
    required String message,
    String? stackTrace,
  }) {
    final entry = DiwanLogEntry(
      timestamp: DateTime.now(),
      level: level,
      tag: tag,
      message: message,
      stackTrace: stackTrace,
    );

    if (_logs.length >= maxLogEntries) {
      _logs.removeFirst();
    }
    _logs.addLast(entry);
    logsNotifier.value = _logs.toList().reversed.toList();

    if (kDebugMode) {
      debugPrint(entry.toString());
    }
  }

  void debug(String tag, String message) =>
      log(level: DiwanLogLevel.debug, tag: tag, message: message);

  void info(String tag, String message) =>
      log(level: DiwanLogLevel.info, tag: tag, message: message);

  void warn(String tag, String message) =>
      log(level: DiwanLogLevel.warn, tag: tag, message: message);

  void error(String tag, String message, [Object? error, StackTrace? st]) =>
      log(
        level: DiwanLogLevel.error,
        tag: tag,
        message: error != null ? '$message: $error' : message,
        stackTrace: st?.toString(),
      );

  List<DiwanLogEntry> getLogs({DiwanLogLevel? minLevel, String? filterTag}) {
    return _logs.where((e) {
      if (minLevel != null && e.level.index < minLevel.index) return false;
      if (filterTag != null && filterTag.isNotEmpty && !e.tag.contains(filterTag)) return false;
      return true;
    }).toList().reversed.toList();
  }

  String exportLogsAsString() {
    final buffer = StringBuffer();
    buffer.writeln('=== سجل عمليات وتشخيص تطبيق ديوان ===');
    buffer.writeln('تاريخ التصدير: ${DateTime.now().toIso8601String()}');
    buffer.writeln('إجمالي السجلات: ${_logs.length}');
    buffer.writeln('========================================\n');
    for (final entry in _logs) {
      buffer.writeln(entry.toString());
    }
    return buffer.toString();
  }

  void clear() {
    _logs.clear();
    logsNotifier.value = [];
  }
}
