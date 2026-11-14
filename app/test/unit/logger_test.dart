import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/logs/diwan_logger.dart';
import 'package:diwan/core/errors/diwan_exception.dart';

void main() {
  group('DiwanLogger Tests', () {
    setUp(() {
      DiwanLogger.instance.clear();
    });

    test('تسجيل الأحداث والرسائل بدقة مع الطوابع الزمنية ومستويات الخطورة', () {
      DiwanLogger.instance.info('Database', 'تم فتح قاعدة البيانات بنجاح');
      DiwanLogger.instance.warn('Audio', 'مستوى الصوت منخفض');
      DiwanLogger.instance.error('ASR', 'تعذر فك الترميز');

      final logs = DiwanLogger.instance.getLogs();
      expect(logs.length, equals(3));
      expect(logs.first.level, equals(DiwanLogLevel.error));
      expect(logs.first.tag, equals('ASR'));
      expect(logs.first.message, contains('تعذر فك الترميز'));
    });

    test('تصفية السجلات حسب مستوى الخطورة الأدنى', () {
      DiwanLogger.instance.debug('NLP', 'تطبيع الكلمات');
      DiwanLogger.instance.info('UI', 'عرض الشاشة');
      DiwanLogger.instance.warn('Storage', 'المساحة قاربت على الامتلاء');

      final warnOnly = DiwanLogger.instance.getLogs(minLevel: DiwanLogLevel.warn);
      expect(warnOnly.length, equals(1));
      expect(warnOnly.first.tag, equals('Storage'));
    });

    test('تصدير السجل كنص متكامل للحافظة والمشاركة', () {
      DiwanLogger.instance.info('System', 'بدء جلسة جديدة');
      final text = DiwanLogger.instance.exportLogsAsString();
      expect(text, contains('سجل عمليات وتشخيص تطبيق ديوان'));
      expect(text, contains('بدء جلسة جديدة'));
    });
  });

  group('DiwanException Tests', () {
    test('توليد رسائل أخطاء عربية أدبية فصيحة لمشاكل التخزين وقواعد البيانات', () {
      final dbEx = DiwanException.database('CorruptHeader');
      expect(dbEx.titleArabic, contains('خزانة الدواوين'));
      expect(dbEx.recoveryActionArabic, isNotNull);

      final diskEx = DiwanException.diskSpace(150, 40);
      expect(diskEx.titleArabic, contains('المساحة التخزينية'));
      expect(diskEx.messageArabic, contains('150'));
      expect(diskEx.messageArabic, contains('40'));
    });
  });
}
