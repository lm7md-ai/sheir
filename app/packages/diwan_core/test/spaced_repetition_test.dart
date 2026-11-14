import 'package:test/test.dart';
import 'package:diwan_core/diwan_core.dart';
import 'package:diwan_core/diwan_core.dart';

void main() {
  group('SpacedRepetitionEngine Tests', () {
    test('التقييم بـ "نسيت" يعيد ضبط الاستقرار والفاصل الزمني إلى الصفر', () {
      final initial = SrsCardState.initial(1).copyWith(
        stability: 4.5,
        repetitions: 3,
        intervalDays: 7,
      );

      final next = SpacedRepetitionEngine.calculateNextState(initial, SrsRating.again);
      expect(next.intervalDays, equals(0));
      expect(next.repetitions, equals(0));
      expect(next.stability, equals(0.5));
      expect(next.difficulty, greaterThan(initial.difficulty));
    });

    test('التقييم بـ "سهل" يضاعف الفاصل الزمني ويرفع الاستقرار', () {
      final initial = SrsCardState.initial(1).copyWith(
        stability: 2.0,
        repetitions: 1,
        intervalDays: 2,
      );

      final next = SpacedRepetitionEngine.calculateNextState(initial, SrsRating.easy);
      expect(next.intervalDays, greaterThanOrEqualTo(4));
      expect(next.repetitions, equals(2));
      expect(next.stability, greaterThan(initial.stability));
    });

    test('توليد نصوص الفواصل الزمنية باللغة العربية', () {
      final card = SrsCardState.initial(1);
      expect(SpacedRepetitionEngine.getIntervalLabel(SrsRating.again, card), equals('بعد ١٠ دقائق'));
      expect(SpacedRepetitionEngine.getIntervalLabel(SrsRating.hard, card), equals('غداً'));
    });
  });

  group('ClozeGenerator Tests', () {
    const text = 'وَاحَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ';

    test('نمط العرض الكامل لا يخفي أي كلمة', () {
      final words = ClozeGenerator.generate(text: text, mode: ClozeMode.full);
      expect(words.every((w) => !w.isHidden), isTrue);
    });

    test('نمط إخفاء القوافي يخفي الكلمة الأخيرة فقط', () {
      final words = ClozeGenerator.generate(text: text, mode: ClozeMode.hideRhymeWords);
      expect(words.last.isHidden, isTrue);
      expect(words.first.isHidden, isFalse);
    });

    test('توليد تلميح الحرف الأول للكلمة المخفية', () {
      final words = ClozeGenerator.generate(text: text, mode: ClozeMode.hideRhymeWords);
      final lastWord = words.last;
      expect(lastWord.firstLetterHint, equals('ش')); // من "شَبِمُ"
    });
  });
}
