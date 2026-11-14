/// محرك التطبيع والمعالجة الإملائية والصوتية للغة العربية
/// متوافق مع كافة حالات التشكيل، وتوحيد الألف، والهمزات، والتاء المربوطة
class ArabicNormalizer {
  ArabicNormalizer._();

  // علامات التشكيل وحركات الإعراب والتطويل
  static final RegExp _diacriticsRegex = RegExp(r'[\u064B-\u065F\u0670]');
  static final RegExp _tatweelRegex = RegExp(r'\u0640');
  static final RegExp _punctuationRegex = RegExp(r'[.,،؛:!؟?()\[\]{}"«»\-–—/\\]');
  static final RegExp _multipleWhitespaceRegex = RegExp(r'\s+');

  /// إزالة التشكيل وحركات الإعراب كاملة
  static String stripTashkeel(String input) {
    return input.replaceAll(_diacriticsRegex, '');
  }

  /// إزالة التطويل (الكشيدة)
  static String stripTatweel(String input) {
    return input.replaceAll(_tatweelRegex, '');
  }

  /// إزالة علامات الترقيم والفواصل
  static String stripPunctuation(String input) {
    return input.replaceAll(_punctuationRegex, ' ');
  }

  /// تطبيع شامل لمقارنة الكلمات وتجاهل الفروق الإملائية الشكلية
  /// مع خيارات مرنة للتسامح مع اللهجات المحلية
  static String normalize(
    String input, {
    bool normalizeAlef = true,
    bool normalizeTaaMarbuta = true,
    bool normalizeYaa = true,
    bool stripDiacritics = true,
    bool stripKashida = true,
  }) {
    String text = input;

    if (stripKashida) {
      text = stripTatweel(text);
    }

    if (stripDiacritics) {
      text = stripTashkeel(text);
    }

    if (normalizeAlef) {
      // توحيد الهمزات والألف الممدودة والمقصورة
      text = text
          .replaceAll(RegExp(r'[إأآٱ]'), 'ا')
          .replaceAll('ء', 'ء');
    }

    if (normalizeTaaMarbuta) {
      // تحويل التاء المربوطة إلى هاء
      text = text.replaceAll('ة', 'ه');
    }

    if (normalizeYaa) {
      // تحويل الألف المقصورة إلى ياء
      text = text.replaceAll('ى', 'ي');
    }

    // تنظيف المسافات الزائدة
    text = stripPunctuation(text);
    return text.replaceAll(_multipleWhitespaceRegex, ' ').trim();
  }

  /// تقسيم النص إلى قائمة كلمات نقية مع الاحتفاظ بنسخها الأصلية
  static List<String> tokenize(String input, {bool keepDiacritics = true}) {
    final cleaned = keepDiacritics
        ? stripTatweel(stripPunctuation(input))
        : normalize(input);
    return cleaned
        .split(_multipleWhitespaceRegex)
        .where((token) => token.trim().isNotEmpty)
        .toList();
  }

  /// التحقق من تطابق كلمتين بعد التطبيع
  static bool areWordsEquivalent(
    String word1,
    String word2, {
    bool dialectTolerance = false,
  }) {
    final norm1 = normalize(word1);
    final norm2 = normalize(word2);

    if (norm1 == norm2) return true;

    if (dialectTolerance) {
      // التسامح الصوتي في لهجات الإلقاء (مثل القاف والهمزة، والضاد والظاء)
      final d1 = _applyDialectRules(norm1);
      final d2 = _applyDialectRules(norm2);
      return d1 == d2;
    }

    return false;
  }

  static String _applyDialectRules(String input) {
    return input
        .replaceAll('ظ', 'ض')
        .replaceAll('ذ', 'ز')
        .replaceAll('ث', 'س');
  }
}
