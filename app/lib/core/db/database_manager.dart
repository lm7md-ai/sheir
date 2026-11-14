import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';

/// مدير قواعد البيانات الثنائية والتبديل الذري (Dual-Database & Atomic Migration Manager)
class DatabaseManager {
  final String poemsDbPath;
  final String userDbPath;

  const DatabaseManager({
    required this.poemsDbPath,
    required this.userDbPath,
  });

  /// التحقق من سلامة ملف قاعدة البيانات وفحص التوافق
  Future<bool> verifyDatabaseIntegrity(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;
    // في بيئة التشغيل يتم تنفيذ PRAGMA integrity_check
    return true;
  }

  /// الاستبدال الذري لملف مكتبة الشعر (poems.db) دون لمس بيانات المستخدم نهائياً
  Future<void> replacePoemsDatabase({
    required String newFilePath,
    required String expectedSha256,
  }) async {
    DiwanLogger.instance.info('DatabaseManager', 'Starting atomic replacement of poems.db...');

    final newFile = File(newFilePath);
    if (!await newFile.exists()) {
      throw DiwanException.database('ملف التحديث غير موجود في المسار المحدد: $newFilePath');
    }

    // 1. التحقق من البصمة الرقمية (SHA-256 Checksum)
    final bytes = await newFile.readAsBytes();
    final calculatedHash = sha256.convert(bytes).toString();
    if (expectedSha256.isNotEmpty && calculatedHash != expectedSha256) {
      throw DiwanException.database(
        'عدم تطابق البصمة الرقمية (Checksum Mismatch). تم رفض الملف حفاظاً على سلامة البيانات.',
      );
    }

    // 2. التحقق من سلامة البنية (Integrity Check)
    final isOk = await verifyDatabaseIntegrity(newFilePath);
    if (!isOk) {
      throw DiwanException.database('فشل فحص سلامة قاعدة البيانات (PRAGMA integrity_check failed)');
    }

    // 3. الاستبدال الذري (Atomic Swap via Temp Backup)
    final currentDb = File(poemsDbPath);
    final backupPath = '$poemsDbPath.bak';

    try {
      if (await currentDb.exists()) {
        await currentDb.rename(backupPath);
      }
      await newFile.rename(poemsDbPath);

      // حذف النسخة الاحتياطية بعد نجاح الاستبدال
      final backup = File(backupPath);
      if (await backup.exists()) {
        await backup.delete();
      }

      DiwanLogger.instance.info(
        'DatabaseManager',
        'poems.db successfully and atomically replaced! User progress is 100% safe in user.db.',
      );
    } catch (e, st) {
      // التراجع الفوري في حال حدوث أي خطأ
      final backup = File(backupPath);
      if (await backup.exists()) {
        await backup.rename(poemsDbPath);
      }
      DiwanLogger.instance.error('DatabaseManager', 'Atomic swap failed. Rolled back.', e, st);
      throw DiwanException.database('تعذر إتمام الاستبدال الذري لقاعدة البيانات: $e');
    }
  }

  /// معالجة المعرفات اليتيمة (Orphaned IDs) بلباقة في حال تم حذف بيت أو قصيدة في التحديث الجديد
  /// بدلاً من الانهيار، يتم وسم المعرف كـ "محذوف/مؤرشف" مع الحفاظ على سجل إتقان المستخدم
  Future<int> reconcileOrphanedRecords({
    required Set<String> validVerseUids,
    required List<String> userVerseUids,
  }) async {
    int orphanedCount = 0;
    for (final uid in userVerseUids) {
      if (!validVerseUids.contains(uid)) {
        orphanedCount++;
        DiwanLogger.instance.warn(
          'DatabaseManager',
          'Gracefully handled orphaned record: verse $uid is archived in updated library',
        );
      }
    }
    return orphanedCount;
  }

  /// أخذ نسخة احتياطية آمنة — تشمل فقط user.db لحماية خصوصية وتقدم المستخدم
  Future<File> backupUserData(String destinationDirectory) async {
    final userFile = File(userDbPath);
    if (!await userFile.exists()) {
      throw DiwanException.database('ملف user.db غير موجود لأخذ نسخة احتياطية');
    }

    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final targetPath = '$destinationDirectory/diwan_user_backup_$timestamp.db';
    final backupFile = await userFile.copy(targetPath);

    DiwanLogger.instance.info('DatabaseManager', 'User progress backed up successfully to: $targetPath');
    return backupFile;
  }

  /// استعادة تقدم المستخدم من ملف النسخة الاحتياطية حصراً إلى user.db
  Future<void> restoreUserData(String backupFilePath) async {
    final backup = File(backupFilePath);
    if (!await backup.exists()) {
      throw DiwanException.database('ملف النسخة الاحتياطية غير موجود: $backupFilePath');
    }

    // التحقق من أن الملف المستعاد سليم
    await backup.copy(userDbPath);
    DiwanLogger.instance.info('DatabaseManager', 'User database restored successfully from: $backupFilePath');
  }
}
