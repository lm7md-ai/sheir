/// بيانات وحالة نموذج الذكاء الاصطناعي الصوتي
enum AsrModelStatus {
  unloaded,   // غير محمل في الذاكرة
  loading,    // جاري التحميل وتخصيص الموارد
  ready,      // جاهز للاستدلال الصوتي في الخلفية
  busy,       // جاري معالجة إشارة صوتية في Isolate مستقل
  unloading,  // جاري تفريغ الذاكرة المؤقتة وإلغاء التخصيص
  failed,     // فشل التحميل
}

class AsrModelInfo {
  final String id;
  final String nameArabic;
  final int diskSizeMb;
  final int ramFootprintMb;
  final String assetOrFilePath;
  final AsrModelStatus status;
  final String? lastError;

  const AsrModelInfo({
    required this.id,
    required this.nameArabic,
    required this.diskSizeMb,
    required this.ramFootprintMb,
    required this.assetOrFilePath,
    this.status = AsrModelStatus.unloaded,
    this.lastError,
  });

  bool get isLoaded => status == AsrModelStatus.ready || status == AsrModelStatus.busy;

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
      status: status ?? this.status,
      lastError: lastError,
    );
  }
}
