import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/nlp/arabic_normalizer.dart';
import 'package:diwan/core/nlp/recitation_alignment_engine.dart';
import 'package:diwan/core/srs/spaced_repetition_engine.dart';
import 'package:diwan/core/srs/cloze_generator.dart';

void main() {
  group('Realistic Arabic Poetry Fixtures Tests (نصوص شعرية كلاسيكية محققة)', () {
    // ١. المتنبي - واحر قلباه (البسيط)
    test('اختبارات المتنبي: واحر قلباه', () {
      const sadr = 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ';
      const ajuz = 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ';

      final normSadr = ArabicNormalizer.normalize(sadr);
      expect(normSadr, equals('وا حر قلباه ممن قلبه شبم'));

      // محاكاة تسميع مع إبدال كلمة
      final eval = RecitationAlignmentEngine.evaluate(
        expectedText: '$sadr $ajuz',
        heardText: 'وا حر قلباه ممن قلبه بارد ومن بجسمي وحالي عنده سقم',
      );
      expect(eval.wrongCount, greaterThanOrEqualTo(1));
    });

    // ٢. امرؤ القيس - قفا نبك (الطويل)
    test('اختبارات امرؤ القيس: المعلقة', () {
      const verse = 'قِفَا نَبْكِ مِنْ ذِكْرَى حَبِيبٍ وَمَنْزِلِ بِسِقْطِ اللِّوَى بَيْنَ الدَّخُولِ فَحَوْمَلِ';
      final tokens = ArabicNormalizer.tokenize(verse, keepDiacritics: false);
      expect(tokens.length, equals(11));
      expect(tokens.first, equals('قفا'));
      expect(tokens.last, equals('فحومل'));

      // تجربة الإخفاء التدريجي
      final clozeWords = ClozeGenerator.generate(text: verse, mode: ClozeMode.hideRhymeWords);
      expect(clozeWords.last.isHidden, isTrue);
      expect(clozeWords.last.firstLetterHint, equals('ف'));
    });

    // ٣. عنترة بن شداد - هل غادر الشعراء (الكامل)
    test('اختبارات عنترة: معلقة الحماسة', () {
      const verse = 'هَلْ غَادَرَ الشُّعَرَاءُ مِنْ مُتَرَدَّمِ أَمْ هَلْ عَرَفْتَ الدَّارَ بَعْدَ تَوَهُّمِ';
      
      // تسميع مطابق مع التسامح الصوتي
      final eval = RecitationAlignmentEngine.evaluate(
        expectedText: verse,
        heardText: 'هل غادر الشعراء من متردم ام هل عرفت الدار بعد توهم',
        dialectTolerance: true,
      );
      expect(eval.accuracyPercentage, equals(100.0));
      expect(eval.performanceRank, equals('أمير الشعراء'));
    });

    // ٤. الإمام الشافعي - دع الأيام (الوافر)
    test('اختبارات الإمام الشافعي: دع الأيام تفعل ما تشاء', () {
      const verse = 'دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ وَطِبْ نَفْساً إِذَا حَكَمَ القَضَاءُ';
      final clozeWords = ClozeGenerator.generate(text: verse, mode: ClozeMode.progressiveCloze);
      expect(clozeWords, isNotEmpty);

      final card = SrsCardState.initial(4);

      // مراجعات متتالية (Good ثم Good ثم Easy)
      final step1 = SpacedRepetitionEngine.calculateNextState(card, SrsRating.good);
      expect(step1.repetitions, equals(1));
      expect(step1.intervalDays, equals(2));

      final step2 = SpacedRepetitionEngine.calculateNextState(step1, SrsRating.good);
      expect(step2.repetitions, equals(2));
      expect(step2.intervalDays, greaterThan(step1.intervalDays));

      final step3 = SpacedRepetitionEngine.calculateNextState(step2, SrsRating.easy);
      expect(step3.intervalDays, greaterThan(step2.intervalDays));
    });

    // ٥. أحمد شوقي - ولد الهدى (الكامل)
    test('اختبارات أحمد شوقي: ولد الهدى فالكائنات ضياء', () {
      const verse = 'وُلِدَ الهُدَى فَالكائِنَاتُ ضِيَاءُ وَفَمُ الزَّمَانِ تَبَسُّمٌ وَثَنَاءُ';
      
      // تسميع سقطت منه كلمة "وفم"
      final eval = RecitationAlignmentEngine.evaluate(
        expectedText: verse,
        heardText: 'ولد الهدى فالكائنات ضياء الزمان تبسم وثناء',
      );
      expect(eval.missingCount, greaterThanOrEqualTo(1));
    });
  });
}
