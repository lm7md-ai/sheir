import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/nlp/arabic_normalizer.dart';

void main() {
  group('ArabicNormalizer Tests', () {
    test('إزالة التشكيل وحركات الإعراب والتطويل بدقة', () {
      const vowelled = 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُـ';
      final stripped = ArabicNormalizer.stripTashkeel(vowelled);
      expect(stripped, contains('وا حر قلباه'));
      expect(stripped, isNot(contains('َ')));
      expect(stripped, isNot(contains('ْ')));
      expect(stripped, isNot(contains('ُ')));
    });

    test('إزالة الكشيدة والتطويل', () {
      const withTatweel = 'المتـنـبـي';
      final clean = ArabicNormalizer.stripTatweel(withTatweel);
      expect(clean, equals('المتنبي'));
    });

    test('تطبيع الهمزات والتاء المربوطة والألف المقصورة', () {
      const input = 'إِنَّ الأُمَّةَ تَسْعَى إِلَى المَجْدِ';
      final norm = ArabicNormalizer.normalize(input);
      expect(norm, equals('ان الامه تسعي الي المجد'));
    });

    test('تطابق الكلمات مع تفعيل التسامح الصوتي في اللهجات', () {
      expect(ArabicNormalizer.areWordsEquivalent('قَلْبُهُ', 'قلبه'), isTrue);
      // التسامح بين الظاء والضاد
      expect(
        ArabicNormalizer.areWordsEquivalent('الظلام', 'الضلام', dialectTolerance: true),
        isTrue,
      );
      // عدم التسامح عند تعطيل الخيار
      expect(
        ArabicNormalizer.areWordsEquivalent('الظلام', 'الضلام', dialectTolerance: false),
        isFalse,
      );
    });

    test('تقسيم البيت إلى كلمات نقية مع الاحتفاظ بالحركات', () {
      const verse = 'الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي';
      final tokens = ArabicNormalizer.tokenize(verse, keepDiacritics: true);
      expect(tokens.length, equals(4));
      expect(tokens[0], equals('الخَيْلُ'));
      expect(tokens[3], equals('تَعْرِفُنِي'));
    });
  });
}
