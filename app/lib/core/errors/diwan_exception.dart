/// أصناف الاستثناءات والأخطاء المترجمة بلغة أدبية فصيحة وإجراءات استرداد واضحة
/// تم تصميمها لإعطاء المستخدم تجربة متكاملة وخالية من المصطلحات التقنية المعقدة
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

  /// خطأ قراءة أو فهرسة قواعد بيانات الشعر (SQLite / FTS5)
  factory DiwanException.database(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'تعثر في فتح خزانة الدواوين',
      messageArabic: 'لم يتمكن ديوان من قراءة فهرس الأشعار ($details). تأكد من سلامة ملف قاعدة البيانات.',
      recoveryActionArabic: 'أعد تشغيل التطبيق أو تحقق من خيار استعادة البيانات من شاشة الإعدادات.',
      originalError: err,
      stackTrace: st,
    );
  }

  /// خطأ التقاط الصوت أو قنوات التسجيل الأصلية
  factory DiwanException.audio(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'تعذر تشغيل اللاقط الصوتي',
      messageArabic: 'لم يتمكن التطبيق من التقاط الصوت ($details).',
      recoveryActionArabic: 'يُرجى التحقق من منح صلاحية الميكروفون لديوان من إعدادات النظام ومعاودة التجربة.',
      originalError: err,
      stackTrace: st,
    );
  }

  /// خطأ نفاد المساحة التخزينية قبل التحميل
  factory DiwanException.diskSpace(int requiredMb, int availableMb) {
    return DiwanException(
      titleArabic: 'المساحة التخزينية غير كافية',
      messageArabic: 'يتطلب تحميل النموذج أو حزمة الدواوين $requiredMb ميغابايت، في حين أن المساحة المتبقية هي $availableMb ميغابايت فقط.',
      recoveryActionArabic: 'يُرجى تحرير بعض المساحة التخزينية على الهاتف قبل معاودة التحميل.',
    );
  }

  /// خطأ انقطاع الشبكة أثناء تنزيل النماذج
  factory DiwanException.download(String details, [Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'انقطاع استجلاب حزمة البيانات',
      messageArabic: 'تعثر الاتصال أثناء تحميل الملف ($details). تم حفظ الجزء المكتمل لاستئنافه تلقائياً.',
      recoveryActionArabic: 'تحقق من اتصال الإنترنت والواي فاي ثم اضغط على زر استئناف التحميل.',
      originalError: err,
      stackTrace: st,
    );
  }

  /// خطأ عام في الاتصال بالشبكة
  factory DiwanException.network([String? details, Object? err, StackTrace? st]) {
    return DiwanException(
      titleArabic: 'تعذر الاتصال بالشبكة',
      messageArabic: details != null
          ? 'تعذر الوصول إلى الخادم الخارجي: $details'
          : 'لم نتمكن من الوصول إلى خادم التحديثات أو مستودع النماذج الصوتية.',
      recoveryActionArabic: 'تأكد من تفعيل الاتصال بالإنترنت والواي فاي ثم أعد المحاولة.',
      originalError: err,
      stackTrace: st,
    );
  }

  /// خطأ أذونات الوصول المرفوضة
  factory DiwanException.permission(String permissionName) {
    return DiwanException(
      titleArabic: 'إذن الوصول مطلوب',
      messageArabic: 'يحتاج ديوان إلى صلاحية ($permissionName) لإتمام التسميع وحفظ التقدم.',
      recoveryActionArabic: 'انتقل إلى إعدادات الهاتف وامنح تطبيق ديوان الإذن المطلوب.',
    );
  }

  /// خطأ ملفات تالفة أو غير صالحة
  factory DiwanException.corruptedData(String resourceName) {
    return DiwanException(
      titleArabic: 'تعذر قراءة ملف البيانات',
      messageArabic: 'يبدو أن ملف ($resourceName) يحوي بيانات غير صالحة أو تعرض للتلف.',
      recoveryActionArabic: 'يمكنك إعادة تنزيل حزمة الدواوين من قسم إدارة النماذج والبيانات في الإعدادات.',
    );
  }

  @override
  String toString() => '$titleArabic: $messageArabic';
}
