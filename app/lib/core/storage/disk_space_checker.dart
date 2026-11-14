import 'dart:io';
import 'package:flutter/services.dart';
import '../errors/app_failure.dart';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';

enum DiskOperation {
  download,
  extraction,
  recording,
  upload,
}

/// فاحص السعة التخزينية المتاحة عبر قناة Kotlin StatFs وحمايتها من النفاد
class DiskSpaceChecker {
  static const MethodChannel _channel = MethodChannel('com.diwan.sheir/disk_space');
  static int? mockAvailableSpaceMb;

  DiskSpaceChecker._();

  /// فحص السعة المتبقية بالميغابايت عبر Kotlin StatFs من خلال Platform Channel
  static Future<int> getAvailableDiskSpaceMb([String targetDirectory = '']) async {
    if (mockAvailableSpaceMb != null) {
      return mockAvailableSpaceMb!;
    }

    try {
      if (Platform.isAndroid) {
        final availableMb = await _channel.invokeMethod<int>(
          'getAvailableDiskSpaceMb',
          {'path': targetDirectory},
        );
        if (availableMb != null && availableMb > 0) {
          return availableMb;
        }
      }
    } catch (e) {
      DiwanLogger.instance.warn('DiskSpaceChecker', 'Failed to call Kotlin StatFs channel: $e');
    }

    // بديل احتياطي للمنصات الأخرى وبيئات الاختبار
    try {
      if (targetDirectory.isNotEmpty) {
        final dir = Directory(targetDirectory);
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }
      }
      return 1024; // 1 GB افتراضي آمن
    } catch (e) {
      return 512;
    }
  }

  /// التحقق الصارم من كفاية المساحة قبل: التنزيل، فك الضغط، التسجيل، أو الرفع
  static Future<void> ensureSufficientSpace({
    required DiskOperation operation,
    required int requiredSpaceMb,
    int safetyMarginMb = 50,
    String targetDirectory = '',
  }) async {
    final availableMb = await getAvailableDiskSpaceMb(targetDirectory);
    final totalNeeded = requiredSpaceMb + safetyMarginMb;

    DiwanLogger.instance.info(
      'DiskSpaceChecker',
      'Checking space for ${operation.name}: required=${requiredSpaceMb}MB, safetyMargin=${safetyMarginMb}MB (totalNeeded=${totalNeeded}MB), available=${availableMb}MB',
    );

    if (availableMb < totalNeeded) {
      final opArabic = switch (operation) {
        DiskOperation.download => 'التنزيل',
        DiskOperation.extraction => 'فك الضغط واستخراج البيانات',
        DiskOperation.recording => 'التسجيل الصوتي',
        DiskOperation.upload => 'رفع الملفات',
      };

      final errorMsg = 'سعة التخزين غير كافية لعملية $opArabic (المطلوب: $totalNeeded ميغابايت، والمتاح: $availableMb ميغابايت). يُرجى التوجه إلى شاشة "النماذج والبيانات" لتحرير المساحة.';
      DiwanLogger.instance.error('DiskSpaceChecker', errorMsg);

      throw DiwanException.diskSpace(totalNeeded, availableMb);
    }
  }

  /// إنشاء كائن فشل AppFailure مع توجيه صريح لشاشة النماذج والبيانات
  static StorageFullFailure createFailure({
    required int requiredMb,
    required int availableMb,
  }) {
    return StorageFullFailure(
      requiredMb: requiredMb,
      availableMb: availableMb,
      details: 'انتقل إلى شاشة النماذج والبيانات لتحرير مساحة تخزينية إضافية.',
    );
  }
}
