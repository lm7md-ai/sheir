# بوابة الجودة ٥: إدارة ذاكرة النماذج بأمان وحظر الاستدلال على خيط الواجهة (GATE-5: Safe Model Lifecycle & Off-UI Inference)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **مدير دورة حياة النماذج ومراقبة الذاكرة (Model Lifecycle Manager)**:
   - `app/lib/core/models/asr_model_info.dart`: تعريف حالات النموذج الست (`unloaded`, `loading`, `ready`, `busy`, `unloading`, `failed`).
   - `app/lib/core/models/asr_model_manager.dart`:
     - المالك الوحيد للنماذج مع تطبيق سياسة نموذج واحد في الذاكرة لمنع تراكم الرام (One-at-a-time).
     - مؤقت الخمول التلقائي (`Idle Unload Timer`) لتفريغ النموذج بعد دقيقتين من عدم النشاط.
     - الاستماع لإشارة ضغط الذاكرة (`onTrimMemory`) من أندرويد عبر Platform Channel.
     - التخلص الآمن داخل كتل `finally` لضمان تحرير المقابض والذاكرة الأصلية.

2. **مشغل الاستدلال في خيط الخلفية (Background Isolate Inference Runner)**:
   - `app/lib/core/models/background_inference_runner.dart`:
     - حظر قطعي لتنفيذ أي معالجة صوتية أو فك تشفير على خيط الواجهة (`UI Isolate`).
     - تنفيذ الاستدلال والمحاذاة بالكامل داخل `Isolate.run` مستقل وتمرير النتائج عبر الدفق.

3. **قنوات المنصة الأصلية في أندرويد (Kotlin Platform Channel)**:
   - `app/android/app/src/main/kotlin/com/diwan/sheir/MainActivity.kt`:
     - استدعاء `onTrimMemory` لتنبيه فلاتر فوراً عند اقتراب نفاد الذاكرة.

4. **عرض حالة النموذج والذاكرة في شاشة الإعدادات**:
   - `app/lib/features/settings/settings_screen.dart`: إظهار بطاقة حالة النموذج في الذاكرة، استهلاك الرام المقدر (45 MB)، وحظر الاستدلال على UI Isolate.

5. **اختبارات التحقق الآلي (Automated Tests)**:
   - `app/test/unit/asr_model_manager_test.dart`

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- مجموعة اختبارات `AsrModelManager & Safe Memory Lifecycle Tests (Gate 5)`:
  - `(1) تحميل نموذج ثقيل ثانٍ يفرغ النموذج الأول فوراً لمنع مضاعفة الرام`
  - `(2) مؤقت الخمول (Idle Timeout) يفرغ النموذج تلقائياً لحفظ الذاكرة`
  - `(3) إشارة ضغط الذاكرة (onTrimMemory) تفرغ النموذج فوراً`
  - `(4) تسلسل ومزامنة الطلبات المتزامنة (Concurrency Serialization)`
  - `(5) دالة التخلص dispose تحرر كافة المقابض حتى في حال حدوث خطأ`
  - `(6) التحقق من حظر تشغيل نقطة دخول الاستدلال على UI Isolate الرئيسي`

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- يتم تنفيذ اختبارات دورة حياة النماذج والاستدلال في الخلفية ضمن `flutter-quality-gates`.

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- تعتمد مهلة الخمول الافتراضية دقيقتين (120 ثانية) في الإنتاج، ويتم تقليصها إلى 200 ميلي ثانية أثناء الاختبارات الآلية لسرعة التحقق.
