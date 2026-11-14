import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/nlp/arud_engine.dart';

void main() {
  group('ArudEngine Tests', () {
    test('التحقق من اكتمال البحور الخليلية الستة عشر', () {
      expect(ArudEngine.classicalMeters.length, equals(16));

      final meterNames = ArudEngine.classicalMeters.map((m) => m.name).toList();
      expect(meterNames, contains('الطويل'));
      expect(meterNames, contains('الكامل'));
      expect(meterNames, contains('البسيط'));
      expect(meterNames, contains('الوافر'));
      expect(meterNames, contains('الخفيف'));
      expect(meterNames, contains('المتقارب'));
    });

    test('استخراج حرف الروي بدقة مع استبعاد حروف العلة والوصل', () {
      // روي الميم: "شَبِمُ"
      expect(ArudEngine.extractRawiy('مِمَّنْ قَلْبُهُ شَبِمُ'), equals('م'));

      // روي اللام: "فَحَوْمَلِ"
      expect(ArudEngine.extractRawiy('بِسِقْطِ اللِّوَى بَيْنَ الدَّخُولِ فَحَوْمَلِ'), equals('ل'));

      // روي مع ألف مد زائدة: "مَا تَشَاءُ" -> الهمزة
      expect(ArudEngine.extractRawiy('دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ'), equals('ء'));

      // روي مع هاء وصل: "سَقَمُهْ" -> الميم
      expect(ArudEngine.extractRawiy('وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُهْ'), equals('م'));
    });

    test('البحث عن البحر الشعري بالاسم أو المعرف', () {
      final tawil = ArudEngine.findMeterByName('الطويل');
      expect(tawil, isNotNull);
      expect(tawil!.id, equals('tawil'));
      expect(tawil.tafila, contains('فَعُولُنْ'));

      final kamil = ArudEngine.findMeterByName('kamil');
      expect(kamil, isNotNull);
      expect(kamil!.name, equals('الكامل'));
    });
  });
}
