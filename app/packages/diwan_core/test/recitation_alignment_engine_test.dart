import 'package:test/test.dart';
import 'package:diwan_core/diwan_core.dart';

void main() {
  group('RecitationAlignmentEngine Tests', () {
    test('تسميع سليم تام يحقق دقة 100% ورتبة أمير الشعراء', () {
      const expected = 'الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي';
      const heard = 'الخيل والليل والبيداء تعرفني';

      final result = RecitationAlignmentEngine.evaluate(
        expectedText: expected,
        heardText: heard,
      );

      expect(result.accuracyPercentage, equals(100.0));
      expect(result.correctCount, equals(4));
      expect(result.wrongCount, equals(0));
      expect(result.missingCount, equals(0));
      expect(result.performanceRank, equals('أمير الشعراء'));
    });

    test('اكتشاف الكلمات الساقطة من التسميع', () {
      const expected = 'وَالسَّيْفُ وَالرُّمْحُ وَالقِرْطَاسُ وَالقَلَمُ';
      const heard = 'والسيف والقرطاس والقلم'; // سقطت "والرمح"

      final result = RecitationAlignmentEngine.evaluate(
        expectedText: expected,
        heardText: heard,
      );

      expect(result.missingCount, equals(1));
      expect(result.correctCount, equals(3));
      expect(result.accuracyPercentage, lessThan(100.0));
    });

    test('اكتشاف إبدال الكلمات الخاطئة', () {
      const expected = 'مَا لِي أُكَتِّمُ حُبّاً قَدْ بَرَى جَسَدِي';
      const heard = 'ما لي أكتّم حزناً قد برى جسدي'; // أبدل حباً بحزناً

      final result = RecitationAlignmentEngine.evaluate(
        expectedText: expected,
        heardText: heard,
      );

      expect(result.wrongCount, equals(1));
      final wrongTokens = result.tokens.where((t) => t.status == RecitationWordStatus.wrong);
      expect(wrongTokens.length, equals(1));
      expect(wrongTokens.first.expectedWord, contains('حُبّاً'));
    });

    test('اكتشاف التردد وتكرار الكلمة في التسميع', () {
      const expected = 'وَاحَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ';
      const heard = 'واحر قلباه قلباه ممن قلبه شبم'; // تكرار قلباه

      final result = RecitationAlignmentEngine.evaluate(
        expectedText: expected,
        heardText: heard,
      );

      expect(result.hesitationCount, greaterThanOrEqualTo(1));
    });

    test('اكتشاف الألفاظ الزائدة الحشوية', () {
      const expected = 'قِفَا نَبْكِ مِنْ ذِكْرَى حَبِيبٍ';
      const heard = 'قفا يا صاحبي نبك من ذكرى حبيب'; // زاد "يا صاحبي"

      final result = RecitationAlignmentEngine.evaluate(
        expectedText: expected,
        heardText: heard,
      );

      expect(result.extraCount, greaterThanOrEqualTo(1));
    });
  });
}
