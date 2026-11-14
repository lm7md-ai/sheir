# بوابة الجودة ٢: حظر المظهر الافتراضي وتأصيل الهوية المخطوطية (GATE-2: No Default Flutter Look)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **منظومة السمات والرموز البصرية المخصصة (Custom Theme & Tokens)**:
   - `app/lib/core/theme/diwan_colors.dart`: لوحة ألوان حبر الليل والرق والسيبيا وألوان التسميع الثنائية.
   - `app/lib/core/theme/theme_extension.dart`: فئة `DiwanThemeExtension` بالسمات الثلاث (Midnight Ink, Parchment, Sepia).
   - `app/lib/core/theme/typography.dart`: فئة `DiwanTypography` مع ضبط ارتفاع الأسطر (2.1 - 2.4) وحظر `letterSpacing`.
   - `app/lib/core/theme/spacing.dart`: مقاييس التباعد الموحدة `DiwanSpacing`.
   - `app/lib/core/theme/radii.dart`: أنصاف الأقطار الهندسية الموحدة `DiwanRadii`.

2. **الخطوط العربية المضمنة محلياً ورخص الـ OFL (Offline Bundled Fonts & OFL Licenses)**:
   - `app/assets/fonts/Amiri-Regular.ttf`, `Amiri-Bold.ttf`, `AmiriQuran.ttf`
   - `app/assets/fonts/ArefRuqaa-Regular.ttf`, `ArefRuqaa-Bold.ttf`
   - `app/assets/fonts/Cairo-VariableFont.ttf`
   - رخص الخطوط الرسمية: `app/assets/licenses/OFL-Amiri.txt`, `OFL-ArefRuqaa.txt`, `OFL-Cairo.txt`
   - تعريف الأصول في: `app/pubspec.yaml` (بدون أي استدعاء خارجي أو google_fonts).

3. **أيقونة التطبيق الأصلية المتكيفة والأحادية (Adaptive & Monochrome Launcher Icons)**:
   - `app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`
   - `app/android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_round.xml`
   - `app/android/app/src/main/res/drawable/ic_launcher_background.xml`
   - `app/android/app/src/main/res/drawable/ic_launcher_foreground.xml` (شمسة الهلال وقلم القصب الذهبي)
   - `app/android/app/src/main/res/drawable/ic_launcher_monochrome.xml` (لسمات Android 13+ Themed Icons)
   - `app/android/app/src/main/res/values/colors.xml`

4. **اختبارات وفحوصات التحقق الصارم (Assertions & Grep CI Check)**:
   - `app/test/theme/theme_contract_test.dart`
   - `scripts/check_clean_architecture.py` (فحص حظر `Colors.blue`, `Icons.flutter_dash`, `Roboto`).

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- مجموعة اختبارات العقد البصري `Diwan Theme Contract & Non-Material Assertion (Gate 2)`:
  - `السمة الداكنة لا تستخدم اللون الأزرق الافتراضي وتعتمد الزمردي الأندلسي`
  - `السمة الفاتحة (Parchment) تستخدم الرق والعاج والزمردي المعتمد`
  - `ملحق السمة DiwanThemeExtension يحتوي كافة رموز الألوان والتسميع الدلالية`
  - `رموز المسافات والأنصاف الدائرية (Spacing & Radii) معرفة ومطابقة للمواصفات`
  - `حظر letterSpacing على النصوص العربية لمنع كسر التماسك الخطي`
- فحص النص الصارم عبر البايثون: `scripts/check_clean_architecture.py` بنتيجة 0 مخالفات.

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- الفحص مدمج كخطوة إلزامية تفشل البناء في حال وجود أي رمز لوني أو خط أو أيقونة افتراضية.

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- تم استبدال كافة الأيقونات الافتراضية؛ تقتصر واجهات التطبيق حصرياً على الأيقونات المستديرة المتجانسة (`Icons.*_rounded`) والأصول المتجهة الأصلية (`SVG`).
