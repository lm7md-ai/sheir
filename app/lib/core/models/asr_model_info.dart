/// بيانات وحالة نموذج الذكاء الاصطناعي الصوتي
enum AsrModelStatus {
  unloaded,   // غير محمل في الذاكرة
  loading,    // جاري التحميل وتخصيص الموارد
  ready,      // جاهز للاستدلال الصوتي في الخلفية
  unloading,  // جاري تفريغ الذاكرة المؤقتة وإلغاء التخصيص
  error,      // خطأ في التحميل أو المعالجة
}

class AsrModelInfo {
  final String id;
  final String nameArabic;
  final int diskSizeMb;
  final int ramFootprintMb;
  final String assetOrFilePath;
  final bool isHeavy;
  final AsrModelStatus status;
  final String? lastError;

  const AsrModelInfo({
    required this.id,
    required this.nameArabic,
    required this.diskSizeMb,
    required this.ramFootprintMb,
    required this.assetOrFilePath,
    this.isHeavy = true,
    this.status = AsrModelStatus.unloaded,
    this.lastError,
  });

  bool get isLoaded => status == AsrModelStatus.ready;

  AsrModelInfo copyWith({
    AsrModelStatus? status,
    String? lastError,
  }) {
    return AsrModelInfo(
      id: id,
      nameArabic: nameArabic,
      diskSizeMb: diskSizeMb,
      ramFootprintMb: ramFootprintMb,
      assetOrFilePath: assetOrFilePath,
      isHeavy: isHeavy,
      status: status ?? this.status,
      lastError: lastError,
    );
  }
}
