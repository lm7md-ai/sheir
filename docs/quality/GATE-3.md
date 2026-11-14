# بوابة الجودة ٣: المعمارية النظيفة القائمة على الميزات (GATE-3: Feature-First Clean Architecture)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **حزمة النواة المستقلة (Pure Dart Package)**:
   - `app/packages/diwan_core/pubspec.yaml`
   - `app/packages/diwan_core/lib/diwan_core.dart`
   - `app/packages/diwan_core/lib/src/nlp/arabic_normalizer.dart`
   - `app/packages/diwan_core/lib/src/nlp/arud_engine.dart`
   - `app/packages/diwan_core/lib/src/nlp/recitation_alignment_engine.dart`
   - `app/packages/diwan_core/lib/src/srs/spaced_repetition_engine.dart`
   - `app/packages/diwan_core/lib/src/srs/cloze_generator.dart`

2. **هيكلية الميزات النظيفة (`lib/features/<feature>/{data,domain,presentation}`)**:
   - `app/lib/features/library/domain/entities/poem_entity.dart`
   - `app/lib/features/library/domain/repositories/i_library_repository.dart`
   - `app/lib/features/library/domain/usecases/get_paged_poems_usecase.dart`
   - `app/lib/features/recitation/domain/models/recitation_session.dart`
   - `app/lib/features/recitation/domain/repositories/i_recitation_repository.dart`
   - `app/lib/features/memorization/domain/models/srs_card_entity.dart`
   - `app/lib/features/memorization/domain/repositories/i_srs_repository.dart`
   - `app/lib/features/library/presentation/controllers/library_controller.dart`
   - `app/lib/features/recitation/presentation/controllers/recitation_controller.dart`
   - `app/lib/features/memorization/presentation/controllers/memorization_controller.dart`

3. **أدوات التحقق الآلي والحدود المعمارية (Lint & Boundary Checks)**:
   - `scripts/check_clean_architecture.py`
   - `app/test/architecture/clean_architecture_lint_test.dart`
   - `docs/ARCHITECTURE.md`

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- `Clean Architecture Boundaries & Dependency Rules (Gate 3)`:
  - `طبقة النطاق (domain) نقية ولا تستورد Flutter نهائياً`
  - `طبقة العرض (presentation) لا تستورد طبقة البيانات (data) مباشرة`
  - `حزمة diwan_core مستقلة ونقية تماماً من أي تبعية لـ Flutter`
- اختبارات حزمة `diwan_core` (Dart Unit Tests):
  - `ArabicNormalizer Tests`: إزالة التشكيل، التطويل، توحيد الهمزات، التسامح الصوتي
  - `ArudEngine Tests`: كشف البحور، التقطيع العروضي، بحر البسيط، بحر الطويل
  - `RecitationAlignmentEngine Tests`: دقة التسميع 100%، الكلمات الساقطة، إبدال الكلمات، التردد، الزيادة
  - `SpacedRepetitionEngine Tests`: تقييم FSRS (Again, Hard, Good, Easy)، استقرار الذاكرة، الفواصل
  - `Realistic Arabic Poetry Fixtures Tests`: المتنبي (واحر قلباه)، امرؤ القيس (المعلقة)، عنترة (هل غادر الشعراء)، الشافعي (دع الأيام)، أحمد شوقي (ولد الهدى)
- فحص البايثون الآلي: `scripts/check_clean_architecture.py` (Exit code: 0).

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- فحص المعمارية النظيفة مدمج كخطوة إلزامية في خط سير `flutter-quality-gates` و `python-pipeline-tests`.

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- لا توجد أي استثناءات لقواعد المعمارية النظيفة؛ طبقة النطاق نقية بنسبة 100% وتمرير البيانات يتم حصرياً عبر الكيانات المجردة.
