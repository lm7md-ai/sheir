# بوابة الجودة ١: مكتبة مكونات ديوان ومعرض التصميم (GATE-1: Component Library & Design Gallery)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **مكتبة المكونات الموحدة في `/app/lib/design_system/`**:
   - `diwan_card.dart`: بطاقة ديوان ذات الإطار الهندسي المتوهج.
   - `verse_tile.dart`: بطاقة البيت الشعري مع شمسة رقم البيت المذهبة.
   - `hemistich_row.dart`: شطر البيت الكلاسيكي والمكدس مع فاصلة الروزيتا.
   - `word_chip.dart`: رقاقة الكلمة بحالات التسميع الخمس وترميزها الثنائي.
   - `accuracy_gauge.dart`: عداد الدقة الدائري الأندلسي مع الرتبة الأدبية.
   - `error_legend.dart`: شريط إرشادات دلالات التسميع.
   - `record_button.dart`: زر اللاقط النابض وتأثير الموجات الصوتية.
   - `skeleton_list.dart`: وميض التحميل المخطوطي العاجي.
   - `empty_state.dart`: حالة الخلو الأدبية مع أزرار الإجراء.
   - `section_header.dart`: ترويسة الأقسام المذهبة مع شريط الزينة.
   - `cartouche_header.dart`: خرطوش الطغراء الملكي المذهب.
   - `diwan_chips.dart`: أنماط الرقاقات الموحدة (`DiwanChip`).
   - `design_system.dart`: مكتبة التصدير الموحدة.

2. **شاشة معرض التصميم التفاعلي (Design Gallery Screen)**:
   - `app/lib/features/gallery/gallery_screen.dart`:
     - استعراض كافة المكونات في كافة حالاتها.
     - تبديل السمات التفاعلي: حبر الليل (Midnight Ink) / الرَّقّ (Parchment) / سيبيا (Sepia).
     - تبديل مقياس الخط التفاعلي: 1.0x (افتراضي) / 1.5x (مكبر).
     - يمكن الوصول إليها عبر: الإعدادات > حول التطبيق > **"معرض التصميم"** (`SettingsScreen`).

3. **اختبارات المكونات ورسم الواجهات (Golden & Widget Tests)**:
   - `app/test/golden/design_system_golden_test.dart`

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- مجموعة اختبارات `Design System Components Golden & Render Tests (Gate 1)`:
  - `1. DiwanCard renders correctly in Dark, Light, Large Font, RTL`
  - `2. VerseTile & HemistichRow render classic and stacked modes in RTL`
  - `3. WordChip renders all 5 dual-coded recitation states in RTL`
  - `4. AccuracyGauge renders circle and rank percentage in Light and Dark`
  - `5. ErrorLegend, RecordButton, SkeletonList, EmptyState, SectionHeader, DiwanChip`

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- يتم رفع مجلد نتائج الاختبارات كملف أرشفة آلي (`CI Artifact: code-coverage-report / golden-tests`).

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- تم بناء كافة المكونات بالاعتماد الحصري على رموز السمة (`context.diwan`, `DiwanSpacing`, `DiwanRadii`) دون أي أحجام أو ألوان ثابتة ومجتزأة (No hardcoded colors/sizes).
