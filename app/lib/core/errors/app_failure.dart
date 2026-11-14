/// هرمية الفشل والأخطاء المصنفة بلغة عربية أدبية وإجراءات تعافٍ واضحة (Sealed AppFailure Hierarchy)
sealed class AppFailure {
  final String titleArabic;
  final String messageArabic;
  final String suggestedActionArabic;
  final String? technicalDetails;

  const AppFailure({
    required this.titleArabic,
    required this.messageArabic,
    required this.suggestedActionArabic,
    this.technicalDetails,
  });

  @override
  String toString() => '$titleArabic: $messageArabic';
}

final class NetworkFailure extends AppFailure {
  const NetworkFailure({String? details})
      : super(
          titleArabic: 'تعذر الاتصال بالشبكة',
          messageArabic: 'لم نتمكن من الوصول إلى خادم التحديثات أو مستودع النماذج الصوتية.',
          suggestedActionArabic: 'تأكد من تفعيل الاتصال بالإنترنت والواي فاي ثم أعد المحاولة.',
          technicalDetails: details,
        );
}

final class StorageFullFailure extends AppFailure {
  final int requiredMb;
  final int availableMb;

  const StorageFullFailure({
    required this.requiredMb,
    required this.availableMb,
    String? details,
  }) : super(
          titleArabic: 'المساحة التخزينية غير كافية',
          messageArabic: 'يتطلب التنزيل $requiredMb ميغابايت، في حين أن المساحة المتبقية على جهازك هي $availableMb ميغابايت فقط.',
          suggestedActionArabic: 'يُرجى تحرير بعض المساحة التخزينية أو التوجه لشاشة إدارة النماذج والبيانات.',
          technicalDetails: details,
        );
}

final class ChecksumFailure extends AppFailure {
  const ChecksumFailure({String? details})
      : super(
          titleArabic: 'فشل التحقق من سلامة الملف',
          messageArabic: 'بصمة الملف الرقمية غير مطابقة للبصمة المعتمدة (Checksum Mismatch). تم رفض الملف لحماية سلامة ديوانك.',
          suggestedActionArabic: 'أعد محاولة التنزيل لاستجلاب نسخة أصلية غير منقوصة.',
          technicalDetails: details,
        );
}

final class CorruptDbFailure extends AppFailure {
  const CorruptDbFailure({String? details})
      : super(
          titleArabic: 'تعثر في فتح خزانة الدواوين',
          messageArabic: 'يبدو أن ملف قاعدة البيانات غير صالح أو تعرض للتلف أثناء التثبيت.',
          suggestedActionArabic: 'توجه إلى الإعدادات > إدارة البيانات واضغط على "استعادة النسخة الاحتياطية".',
          technicalDetails: details,
        );
}

final class ModelLoadFailure extends AppFailure {
  const ModelLoadFailure({String? details})
      : super(
          titleArabic: 'تعذر تحميل النموذج الصوتي',
          messageArabic: 'واجه النظام صعوبة في تخصيص الذاكرة الكافية للنموذج الصوتي.',
          suggestedActionArabic: 'أغلق التطبيقات غير المستخدمة لتحرير الرام أو اختر نموذجاً أخف وزناً.',
          technicalDetails: details,
        );
}

final class MicPermissionFailure extends AppFailure {
  const MicPermissionFailure({String? details})
      : super(
          titleArabic: 'إذن اللاقط الصوتي مطلوب',
          messageArabic: 'يحتاج ديوان إلى صلاحية الميكروفون ليتمكن من الاستماع إلى إلقائك وتقييمه.',
          suggestedActionArabic: 'انتقل إلى إعدادات الهاتف وامنح ديوان إذن الميكروفون.',
          technicalDetails: details,
        );
}

final class AsrFailedFailure extends AppFailure {
  const AsrFailedFailure({String? details})
      : super(
          titleArabic: 'تعذر التعرف على الإلقاء',
          messageArabic: 'لم يتمكن المحرك الصوتي من استخلاص الكلمات بوضوح، قد يكون الصوت منخفضاً أو مشوشاً.',
          suggestedActionArabic: 'اقترب من اللاقط وألقِ البيت بصوت جهوري فصيح.',
          technicalDetails: details,
        );
}
