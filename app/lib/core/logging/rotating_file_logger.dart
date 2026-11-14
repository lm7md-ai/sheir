import 'dart:io';
import 'dart:async';

/// مسجل الملفات الدوار مع تحديد سقف الحجم (Rotating File Logger)
/// يحفظ السجلات في ما يصل إلى 3 ملفات بسقف 2 ميغابايت لكل ملف لمنع استنزاف مساحة الجهاز
class RotatingFileLogger {
  final String directoryPath;
  final int maxFileSize;
  final int maxFiles;
  int _currentFileIndex = 1;
  File? _activeFile;
  final String appVersion;
  final String deviceInfo;

  String get currentLogFilePath => '$directoryPath/diwan_log_$_currentFileIndex.log';

  RotatingFileLogger({
    required this.directoryPath,
    this.maxFileSize = 2 * 1024 * 1024, // 2 MB
    this.maxFiles = 3,
    this.appVersion = '1.0.0 (Milestone 1)',
    this.deviceInfo = 'Android ARM64 / Universal',
  });

  Future<void> init() async {
    final dir = Directory(directoryPath);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    _activeFile = File('$directoryPath/diwan_log_$_currentFileIndex.log');
    if (!await _activeFile!.exists()) {
      await _activeFile!.writeAsString(
        '=== ديوان (Diwan) — سجل التشخيص والعمليات ===\n'
        'الإصدار: $appVersion | الجهاز: $deviceInfo\n'
        'تاريخ الإنشاء: ${DateTime.now().toIso8601String()}\n'
        '--------------------------------------------------\n',
      );
    }
  }

  Future<void> log(String level, String tag, String message, [String? stackTrace]) async {
    if (_activeFile == null) await init();

    try {
      // التحقق من الحجم للتدوير
      if (await _activeFile!.exists() && await _activeFile!.length() >= maxFileSize) {
        await _rotateFiles();
      }

      final timestamp = DateTime.now().toIso8601String();
      final line = '[$timestamp] [$level] [$tag] $message'
          '${stackTrace != null ? "\nStackTrace:\n$stackTrace" : ""}\n';

      await _activeFile!.writeAsString(line, mode: FileMode.append, flush: true);
    } catch (e) {
      // تفادي انهيار التطبيق في حال تعثر كتابة السجل
    }
  }

  Future<void> _rotateFiles() async {
    _currentFileIndex = (_currentFileIndex % maxFiles) + 1;
    _activeFile = File('$directoryPath/diwan_log_$_currentFileIndex.log');
    if (await _activeFile!.exists()) {
      await _activeFile!.delete();
    }
    await _activeFile!.writeAsString(
      '=== تدوير السجل (Log Rotated) — ملف رقم $_currentFileIndex ===\n'
      'التاريخ: ${DateTime.now().toIso8601String()}\n'
      '--------------------------------------------------\n',
    );
  }

  Future<String> exportCombinedLogs() async {
    final buffer = StringBuffer();
    for (int i = 1; i <= maxFiles; i++) {
      final f = File('$directoryPath/diwan_log_$i.log');
      if (await f.exists()) {
        buffer.writeln(await f.readAsString());
      }
    }
    return buffer.toString();
  }

  Future<void> clearAll() async {
    for (int i = 1; i <= maxFiles; i++) {
      final f = File('$directoryPath/diwan_log_$i.log');
      if (await f.exists()) {
        await f.delete();
      }
    }
    await init();
  }
}
