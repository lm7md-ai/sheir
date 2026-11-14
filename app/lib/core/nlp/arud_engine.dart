import 'arabic_normalizer.dart';

/// بحر الشعر العربي الكلاسيكي
class ClassicalMeter {
  final String id;
  final String name;
  final String mnemonic; // مفتاح البحر
  final String tafila;   // التفعيلات الأساسية

  const ClassicalMeter({
    required this.id,
    required this.name,
    required this.mnemonic,
    required this.tafila,
  });
}

/// محرك علم العروض والقوافي والأوزان الشعرية الستة عشر
class ArudEngine {
  ArudEngine._();

  /// البحور الشعرية الستة عشر التي وضعها الخليل بن أحمد الفراهيدي والأخفش
  static const List<ClassicalMeter> classicalMeters = [
    ClassicalMeter(
      id: 'tawil',
      name: 'الطويل',
      mnemonic: 'طويلٌ لهُ دونَ البحورِ فضائلُ ... فعولن مفاعيلن فعولن مفاعيلُ',
      tafila: 'فَعُولُنْ مَفَاعِيلُنْ فَعُولُنْ مَفَاعِيلُنْ',
    ),
    ClassicalMeter(
      id: 'kamil',
      name: 'الكامل',
      mnemonic: 'كَمُلَ الجمالُ من البحورِ الكاملُ ... متفاعلن متفاعلن متفاعلُ',
      tafila: 'مُتَفَاعِلُنْ مُتَفَاعِلُنْ مُتَفَاعِلُنْ',
    ),
    ClassicalMeter(
      id: 'basit',
      name: 'البسيط',
      mnemonic: 'إنَّ البسيطَ لديهِ يبسطُ الأملُ ... مستفعلن فاعلن مستفعلن فَعِلُ',
      tafila: 'مُسْتَفْعِلُنْ فَاعِلُنْ مُسْتَفْعِلُنْ فَاعِلُنْ',
    ),
    ClassicalMeter(
      id: 'wafir',
      name: 'الوافر',
      mnemonic: 'بحورُ الشعرِ وافرها جميلُ ... مفاعلتن مفاعلتن فعولُ',
      tafila: 'مُفَاعَلَتُنْ مُفَاعَلَتُنْ فَعُولُنْ',
    ),
    ClassicalMeter(
      id: 'khafif',
      name: 'الخفيف',
      mnemonic: 'يا خفيفاً خفّتْ به الحركاتُ ... فاعلاتن مستفعلن فاعلاتُ',
      tafila: 'فَاعِلَاتُنْ مُسْتَفْعِلُنْ فَاعِلَاتُنْ',
    ),
    ClassicalMeter(
      id: 'rajaz',
      name: 'الرجز',
      mnemonic: 'في أبحرِ الأرجازِ بحرٌ يسهلُ ... مستفعلن مستفعلن مستفعلُ',
      tafila: 'مُسْتَفْعِلُنْ مُسْتَفْعِلُنْ مُسْتَفْعِلُنْ',
    ),
    ClassicalMeter(
      id: 'ramal',
      name: 'الرمل',
      mnemonic: 'رَمَلُ الأبحرِ ترويهِ الثقاتُ ... فاعلاتن فاعلاتن فاعلاتُ',
      tafila: 'فَاعِلَاتُنْ فَاعِلَاتُنْ فَاعِلَاتُنْ',
    ),
    ClassicalMeter(
      id: 'mutaqarib',
      name: 'المتقارب',
      mnemonic: 'عن المتقاربِ قالَ الخليلُ ... فعولن فعولن فعولن فعولُ',
      tafila: 'فَعُولُنْ فَعُولُنْ فَعُولُنْ فَعُولُنْ',
    ),
    ClassicalMeter(
      id: 'sari',
      name: 'السريع',
      mnemonic: 'بحرٌ سريعٌ مالهُ ساحلُ ... مستفعلن مستفعلن فاعلُ',
      tafila: 'مُسْتَفْعِلُنْ مُسْتَفْعِلُنْ فَاعِلُنْ',
    ),
    ClassicalMeter(
      id: 'munsarih',
      name: 'المنسرح',
      mnemonic: 'منسرحٌ فيهِ يُضربُ المثلُ ... مستفعلن مفعولاتُ مفتعلُ',
      tafila: 'مُسْتَفْعِلُنْ مَفْعُولَاتُ مُسْتَفْعِلُنْ',
    ),
    ClassicalMeter(
      id: 'hazaj',
      name: 'الهزج',
      mnemonic: 'على الأهزاجِ تسهيلُ ... مفاعيلن مفاعيلُ',
      tafila: 'مَفَاعِيلُنْ مَفَاعِيلُنْ',
    ),
    ClassicalMeter(
      id: 'madid',
      name: 'المديد',
      mnemonic: 'لمديدِ الشعرِ عندي صفاتُ ... فاعلاتن فاعلن فاعلاتُ',
      tafila: 'فَاعِلَاتُنْ فَاعِلُنْ فَاعِلَاتُنْ',
    ),
    ClassicalMeter(
      id: 'muqtadab',
      name: 'المقتضب',
      mnemonic: 'اقتضبْ كما سألوا ... مَفْعُولاتُ مُفْتَعِلُ',
      tafila: 'مَفْعُولَاتُ مُسْتَفْعِلُنْ',
    ),
    ClassicalMeter(
      id: 'mujtath',
      name: 'المجتث',
      mnemonic: 'إنْ جُثَّتِ الحركاتُ ... مستفعلن فاعلاتُ',
      tafila: 'مُسْتَفْعِلُنْ فَاعِلَاتُنْ',
    ),
    ClassicalMeter(
      id: 'mudari',
      name: 'المضارع',
      mnemonic: 'تُعدُّ المضارعاتُ ... مفاعيلُ فاعلاتُ',
      tafila: 'مَفَاعِيلُ فَاعِلَاتُنْ',
    ),
    ClassicalMeter(
      id: 'mutadarak',
      name: 'المتدارك (المحدث)',
      mnemonic: 'حركاتُ المُحْدَثِ تنتقلُ ... فَعِلُنْ فَعِلُنْ فَعِلُنْ فَعِلُ',
      tafila: 'فَاعِلُنْ فَاعِلُنْ فَاعِلُنْ فَاعِلُنْ',
    ),
  ];

  /// استخراج حرف الروي من عجز البيت الشعري
  /// يراعي أحكام القافية (استبعاد حروف المد والهاء الزائدة كوصل إذا سبقتها حركة)
  static String extractRawiy(String ajuzText) {
    final cleaned = ArabicNormalizer.stripPunctuation(ajuzText).trim();
    if (cleaned.isEmpty) return 'غير محدد';

    final words = cleaned.split(RegExp(r'\s+'));
    final lastWord = words.last;
    final unvowelled = ArabicNormalizer.stripTashkeel(lastWord);

    if (unvowelled.isEmpty) return 'غير محدد';

    // فحص الحرف الأخير
    int index = unvowelled.length - 1;
    String candidate = unvowelled[index];

    // إذا كان الحرف الأخير حرف مد (ألف أو واو أو ياء) فإن الروي هو الحرف الذي قبله
    if (['ا', 'ى', 'و', 'ي'].contains(candidate) && unvowelled.length > 1) {
      index--;
      candidate = unvowelled[index];
    }

    // إذا كان الحرف الأخير هاء وصل ساكنة أو مسبوقة بحركة
    if (candidate == 'ه' && unvowelled.length > 1) {
      index--;
      candidate = unvowelled[index];
    }

    return candidate;
  }

  /// البحث عن البحر بالاسم أو المعرف
  static ClassicalMeter? findMeterByName(String name) {
    final normalized = ArabicNormalizer.normalize(name);
    for (final meter in classicalMeters) {
      if (ArabicNormalizer.normalize(meter.name) == normalized ||
          meter.id == name.toLowerCase()) {
        return meter;
      }
    }
    return null;
  }
}
