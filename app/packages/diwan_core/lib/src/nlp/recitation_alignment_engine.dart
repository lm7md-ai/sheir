import 'arabic_normalizer.dart';

/// حالات الكلمة أثناء التسميع مع دلالات إمكانية الوصول والتصميم الثنائي
enum RecitationWordStatus {
  correct,    // صحيح: نطق سليم
  wrong,      // خطأ: كلمة بديلة أو لحن
  hesitation, // تردد: تكرار أو وقفة غير مناسبة
  missing,    // سقطت: كلمة منسية لم ينطقها القارئ
  extra,      // زائدة: كلمة حشو أضافها القارئ
}

/// نتيجة تحليل كلمة واحدة في التسميع
class RecitationWordToken {
  final String expectedWord;
  final String? heardWord;
  final RecitationWordStatus status;
  final String note;

  const RecitationWordToken({
    required this.expectedWord,
    this.heardWord,
    required this.status,
    this.note = '',
  });
}

/// النتيجة الشاملة لتسميع بيت أو مقطع شعري
class RecitationEvaluationResult {
  final List<RecitationWordToken> tokens;
  final double accuracyPercentage;
  final int correctCount;
  final int wrongCount;
  final int hesitationCount;
  final int missingCount;
  final int extraCount;
  final String performanceRank;

  const RecitationEvaluationResult({
    required this.tokens,
    required this.accuracyPercentage,
    required this.correctCount,
    required this.wrongCount,
    required this.hesitationCount,
    required this.missingCount,
    required this.extraCount,
    required this.performanceRank,
  });

  /// حساب الرتبة الأدبية التقديرية بناءً على نسبة الدقة
  static String calculateRank(double accuracy) {
    if (accuracy >= 98.0) return 'أمير الشعراء';
    if (accuracy >= 90.0) return 'شاعرٌ مُفْلِق';
    if (accuracy >= 80.0) return 'ناظمٌ مُتْقِن';
    if (accuracy >= 65.0) return 'حافِظٌ مُجْتَهِد';
    return 'راوٍ مُبْتَدِئ';
  }
}

/// محرك محاذاة وتقييم التسميع الشعري الذكي
class RecitationAlignmentEngine {
  RecitationAlignmentEngine._();

  /// محاذاة الأبيات المتوقعة مع ما التقطه محرك التعرف على الصوت
  static RecitationEvaluationResult evaluate({
    required String expectedText,
    required String heardText,
    bool dialectTolerance = true,
  }) {
    final expectedTokens = ArabicNormalizer.tokenize(expectedText, keepDiacritics: true);
    final heardTokens = ArabicNormalizer.tokenize(heardText, keepDiacritics: false);

    if (expectedTokens.isEmpty) {
      return const RecitationEvaluationResult(
        tokens: [],
        accuracyPercentage: 0.0,
        correctCount: 0,
        wrongCount: 0,
        hesitationCount: 0,
        missingCount: 0,
        extraCount: 0,
        performanceRank: 'راوٍ مُبْتَدِئ',
      );
    }

    if (heardTokens.isEmpty) {
      final missingTokens = expectedTokens.map((w) {
        return RecitationWordToken(
          expectedWord: w,
          heardWord: null,
          status: RecitationWordStatus.missing,
          note: 'سقطت من التسميع',
        );
      }).toList();

      return RecitationEvaluationResult(
        tokens: missingTokens,
        accuracyPercentage: 0.0,
        correctCount: 0,
        wrongCount: 0,
        hesitationCount: 0,
        missingCount: expectedTokens.length,
        extraCount: 0,
        performanceRank: 'راوٍ مُبْتَدِئ',
      );
    }

    // خوارزمية المحاذاة الديناميكية الموجهة (Needleman-Wunsch Dynamic Alignment)
    final n = expectedTokens.length;
    final m = heardTokens.length;

    // مصفوفة التكاليف
    final dp = List.generate(n + 1, (_) => List.filled(m + 1, 0));

    for (int i = 0; i <= n; i++) {
      dp[i][0] = i * 2; // تكلفة السقوط (Missing)
    }
    for (int j = 0; j <= m; j++) {
      dp[0][j] = j * 2; // تكلفة الزيادة (Extra)
    }

    for (int i = 1; i <= n; i++) {
      for (int j = 1; j <= m; j++) {
        final expW = expectedTokens[i - 1];
        final hrdW = heardTokens[j - 1];

        final matchCost = ArabicNormalizer.areWordsEquivalent(
          expW,
          hrdW,
          dialectTolerance: dialectTolerance,
        ) ? 0 : 2;

        dp[i][j] = [
          dp[i - 1][j - 1] + matchCost, // مطابقة أو إبدال
          dp[i - 1][j] + 2,             // حذف / سقوط
          dp[i][j - 1] + 2,             // زيادة
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    // استرجاع المسار العكسي (Backtracking)
    int i = n;
    int j = m;
    final alignedTokens = <RecitationWordToken>[];

    while (i > 0 || j > 0) {
      if (i > 0 && j > 0) {
        final expW = expectedTokens[i - 1];
        final hrdW = heardTokens[j - 1];
        final isMatch = ArabicNormalizer.areWordsEquivalent(
          expW,
          hrdW,
          dialectTolerance: dialectTolerance,
        );

        if (isMatch) {
          // فحص التردد أو التكرار
          bool isHesitation = false;
          if (j > 1 && ArabicNormalizer.areWordsEquivalent(expW, heardTokens[j - 2], dialectTolerance: dialectTolerance)) {
            isHesitation = true;
          }

          alignedTokens.add(RecitationWordToken(
            expectedWord: expW,
            heardWord: hrdW,
            status: isHesitation ? RecitationWordStatus.hesitation : RecitationWordStatus.correct,
            note: isHesitation ? 'تردد وتكرار الكلمة' : 'نطق سليم مطابق',
          ));
          i--;
          j--;
          continue;
        }
      }

      if (i > 0 && j > 0 && dp[i][j] == dp[i - 1][j - 1] + 2) {
        // خطأ إبدال
        alignedTokens.add(RecitationWordToken(
          expectedWord: expectedTokens[i - 1],
          heardWord: heardTokens[j - 1],
          status: RecitationWordStatus.wrong,
          note: 'أبدلت بكلمة: ${heardTokens[j - 1]}',
        ));
        i--;
        j--;
      } else if (i > 0 && dp[i][j] == dp[i - 1][j] + 2) {
        // كلمة سقطت من الحفظ
        alignedTokens.add(RecitationWordToken(
          expectedWord: expectedTokens[i - 1],
          heardWord: null,
          status: RecitationWordStatus.missing,
          note: 'سقطت الكلمة من التسميع',
        ));
        i--;
      } else {
        // كلمة زائدة حشو
        alignedTokens.add(RecitationWordToken(
          expectedWord: '[زيادة]',
          heardWord: heardTokens[j - 1],
          status: RecitationWordStatus.extra,
          note: 'لفظة إضافية: ${heardTokens[j - 1]}',
        ));
        j--;
      }
    }

    final resultTokens = alignedTokens.reversed.toList();

    int correct = 0;
    int wrong = 0;
    int hesitation = 0;
    int missing = 0;
    int extra = 0;

    for (final t in resultTokens) {
      switch (t.status) {
        case RecitationWordStatus.correct:
          correct++;
          break;
        case RecitationWordStatus.wrong:
          wrong++;
          break;
        case RecitationWordStatus.hesitation:
          hesitation++;
          break;
        case RecitationWordStatus.missing:
          missing++;
          break;
        case RecitationWordStatus.extra:
          extra++;
          break;
      }
    }

    // حساب النسبة المئوية الدقيقة
    final totalExpected = expectedTokens.length;
    double accuracy = ((correct + (hesitation * 0.7)) / totalExpected) * 100.0;
    // حسم جزئي عن الألفاظ الزائدة
    accuracy = (accuracy - (extra * 2.0)).clamp(0.0, 100.0);

    return RecitationEvaluationResult(
      tokens: resultTokens,
      accuracyPercentage: double.parse(accuracy.toStringAsFixed(1)),
      correctCount: correct,
      wrongCount: wrong,
      hesitationCount: hesitation,
      missingCount: missing,
      extraCount: extra,
      performanceRank: RecitationEvaluationResult.calculateRank(accuracy),
    );
  }
}
