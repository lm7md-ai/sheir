/// أصناف الاستثناءات والأخطاء المترجمة بلغة أدبية فصيحة وإجراءات استرداد واضحة
class DiwanException implements Exception {
  final String titleArabic;
  final String messageArabic;
  final String? recoveryActionArabic;
  final Object? originalError;
  final StackTrace? stackTrace;

  const DiwanException({
    required this.titleArabic,
    required this.messageArabic,
    this.recoveryActionArabic,
    this.originalError,
    this.stackTrace,
  });

  factory DiwanException.database(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'تعثر في فتح خزانة الدواوين',
      messageArabic: 'لم يتمكن ديوان من قراءة فهرس الأشعار ($details). تأكد من سلامة ملف قاعدة البيانات.',
      recoveryActionArabic: 'أعد تشغيل التطبيق أو تحقق من خيار استعادة البيانات في الإعدادات.',
      originalError: err,
      stackTrace: st,
    );
  }

  factory DiwanException.audio(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'تعذر تشغيل اللاقط الصوتي',
      messageArabic: 'لم يتمكن التطبيق من التقاط الصوت ($details).',
      recoveryActionArabic: 'يُرجى التحقق من منح صلاحية الميكروفون لديوان من إعدادات النظام.',
      originalError: err,
      stackTrace: st,
    );
  }

  factory DiwanException.diskSpace(int requiredMb, int availableMb) {
    return DiwanException(
      titleArabic: 'المساحة التخزينية غير كافية',
      messageArabic: 'يتطلب تحميل النموذج $requiredMb ميغابايت، في حين أن المساحة المتبقية هي $availableMb ميغابايت فقط.',
      recoveryActionArabic: 'يُرجى تحرير مساحة كافية على الهاتف قبل معاودة التحميل.',
    );
  }

  factory DiwanException.download(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'انقطاع استجلاب حزمة البيانات',
      messageArabic: 'تعثر الاتصال أثناء تحميل الملف ($details). تم حفظ الجزء المكتمل لاستئنافه لاحقاً.',
      recoveryActionArabic: 'تحقق من اتصال الإنترنت ثم اضغط على زر استئناف التحميل.',
      originalError: err,
      stackTrace: st,
    );
  }

  @override
  String toString() => '$titleArabic: $messageArabic';
}
