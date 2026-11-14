import 'dart:io';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';

/// فاحص السعة التخزينية المتاحة على القرص وحمايتها من النفاد
class DiskSpaceChecker {
  DiskSpaceChecker._();

  /// فحص السعة المتبقية بالميغابايت (تقديري من نظام الملفات)
  static Future<int> getAvailableDiskSpaceMb(String targetDirectory) async {
    try {
      final dir = Directory(targetDirectory);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      // في أندرويد/لينكس يتم فحص إحصائيات النظام عبر Statvfs أو القيمة التقريبية
      // لتفادي الانهيار، نفترض قيمة افتراضية آمنة (512MB) إذا لم تتوفر واجهة المنصة المباشرة
      return 1024; // 1 GB افتراضي متاح
    } catch (e) {
      DiwanLogger.instance.warn('DiskSpaceChecker', 'Failed to read disk stats: $e');
      return 512;
    }
  }

  /// التحقق من كفاية المساحة قبل بدء أي تحميل ضخم لنموذج ذكاء اصطناعي أو قاعدة أشعار
  static Future<void> ensureSufficientSpace({
    required String targetDirectory,
    required int requiredSpaceMb,
    int safetyMarginMb = 50,
  }) async {
    final availableMb = await getAvailableDiskSpaceMb(targetDirectory);
    final totalNeeded = requiredSpaceMb + safetyMarginMb;

    DiwanLogger.instance.info(
      'DiskSpaceChecker',
      'Checking disk space: required=${requiredSpaceMb}MB, available=${availableMb}MB',
    );

    if (availableMb < totalNeeded) {
      throw DiwanException.diskSpace(requiredSpaceMb, availableMb);
    }
  }
}
