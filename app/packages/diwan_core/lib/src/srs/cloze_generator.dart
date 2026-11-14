import '../nlp/arabic_normalizer.dart';

enum ClozeMode {
  full,             // عرض كامل البيت (القراءة والاستظهار الأولي)
  hideAjuz,         // إخفاء العجز بالكامل (اختبار شطر البيت)
  hideRhymeWords,   // إخفاء كلمات القافية فقط
  progressiveCloze, // إخفاء تدريجي لكلمات متفرقة
}

/// كلمة في تمرين الاستذكار النشط
class ClozeWord {
  final String text;
  final bool isHidden;
  final String firstLetterHint;
  final bool isRevealed;

  const ClozeWord({
    required this.text,
    required this.isHidden,
    required this.firstLetterHint,
    this.isRevealed = false,
  });

  ClozeWord reveal() => ClozeWord(
        text: text,
        isHidden: isHidden,
        firstLetterHint: firstLetterHint,
        isRevealed: true,
      );
}

/// مولد تمارين الإخفاء التدريجي والاستدعاء النشط (Progressive Cloze Generator)
class ClozeGenerator {
  ClozeGenerator._();

  /// توليد كلمات الشطر أو البيت مع تطبيق نمط الإخفاء المطلوب
  static List<ClozeWord> generate({
    required String text,
    required ClozeMode mode,
    bool isAjuz = false,
  }) {
    final words = ArabicNormalizer.tokenize(text, keepDiacritics: true);
    if (words.isEmpty) return [];

    switch (mode) {
      case ClozeMode.full:
        return words.map((w) => ClozeWord(
              text: w,
              isHidden: false,
              firstLetterHint: _getFirstLetter(w),
            )).toList();

      case ClozeMode.hideAjuz:
        return words.asMap().entries.map((e) {
          final isHidden = isAjuz;
          return ClozeWord(
            text: e.value,
            isHidden: isHidden,
            firstLetterHint: _getFirstLetter(e.value),
          );
        }).toList();

      case ClozeMode.hideRhymeWords:
        return words.asMap().entries.map((e) {
          // إخفاء الكلمة الأخيرة من الشطر
          final isLast = e.key == words.length - 1;
          return ClozeWord(
            text: e.value,
            isHidden: isLast,
            firstLetterHint: _getFirstLetter(e.value),
          );
        }).toList();

      case ClozeMode.progressiveCloze:
        return words.asMap().entries.map((e) {
          // إخفاء الكلمات الفردية لتوليد فراغات متناوبة
          final isHidden = e.key % 2 != 0;
          return ClozeWord(
            text: e.value,
            isHidden: isHidden,
            firstLetterHint: _getFirstLetter(e.value),
          );
        }).toList();
    }
  }

  static String _getFirstLetter(String word) {
    final stripped = ArabicNormalizer.stripTashkeel(word).trim();
    if (stripped.isEmpty) return '';
    return stripped.substring(0, 1);
  }
}
