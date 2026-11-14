# بوابة الجودة ٧: إدارة الأخطاء، السجلات الدوارة، التنزيل المرن، وحماية السعة (GATE-7: Errors, Logs, Downloads, Disk Space)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **حاجز الأخطاء العالمي والرسائل الفصيحة (Global Error Boundary & Sealed Failures)**:
   - `app/lib/core/errors/app_failure.dart`: هرمية الفشل المختومة (`NetworkFailure`, `StorageFullFailure`, `ChecksumFailure`, `CorruptDbFailure`, `ModelLoadFailure`, `MicPermissionFailure`, `AsrFailedFailure`) مع الإجراءات المقترحة.
   - `app/lib/core/errors/diwan_error_boundary.dart`: حاجز الأخطاء الشامل المرتبط بـ `FlutterError.onError` و `PlatformDispatcher.instance.onError` و `ErrorWidget.builder`.

2. **مسجل الملفات الدوار وشاشة السجلات (Rotating File Logger & In-App Logs)**:
   - `app/lib/core/logging/rotating_file_logger.dart`: تدوير 3 ملفات بسقف 2 ميغابايت لكل ملف، متضمناً الإصدار ومعلومات المنصة.
   - `app/lib/features/logs/logs_screen.dart`: شاشة السجلات مع النسخ، الفلترة حسب المستوى، البحث، والمشاركة (`share_plus`).

3. **مدير التنزيل عالي المرونة (Resumable Download Manager)**:
   - `app/lib/core/network/resumable_downloader.dart`: دعم استئناف القطع (`.part`) عبر ترويسة `Range: bytes=X-`، والتحقق من بصمة `SHA-256`، والتراجع الأسي مع الجيتر (Jitter).

4. **فاحص السعة التخزينية في أندرويد عبر StatFs**:
   - `app/android/app/src/main/kotlin/com/diwan/sheir/MainActivity.kt`: استدعاء `android.os.StatFs` لحساب المساحة الفعلية المتبقية.
   - `app/lib/core/storage/disk_space_checker.dart`: فحص المساحة مع هامش أمان بنسبة 20% قبل الشروع في التنزيل.

5. **اختبارات التحقق الآلي (Automated Tests)**:
   - `data_pipeline/tests/test_download_manager_and_errors.py`

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- مجموعة اختبارات المرونة وتنزيل الملفات (`data_pipeline/tests/test_download_manager_and_errors.py`):
  - `test_interrupted_download_resumes_from_right_byte`: إثبات أن التنزيل المقاطع يستأنف من موضع البايت الصحيح عبر خادم محاكٍ لترويسة `Range`.
  - `test_checksum_mismatch_rejection`: إثبات رفض وحذف الملف عند عدم تطابق بصمة `SHA-256`.
  - `test_low_disk_simulation_blocks_download`: حظر التنزيل عند عدم كفاية السعة المتاحة مع هامش أمان 20%.
  - `test_rotating_file_logger_rotates_on_cap`: إثبات تدوير ملفات السجلات عند بلوغ الحد الأقصى دون استنزاف الذاكرة.

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- يتم تنفيذ اختبارات الخادم والمحاكاة لـ HTTP Range والبصمات ضمن `python-pipeline-tests`.

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- في بيئات المتصفح (Web Preview) يتم محاكاة فحص مساحة القرص بقيم تقديرية آمنة، بينما تعمل `StatFs` الحقيقية في بيئة أندرويد الأصلية.
