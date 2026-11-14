# بوابة الجودة ٦: ترحيل المخططات وقاعدتا البيانات المستقلتان (GATE-6: Versioned Migrations & Separate User DB)

---

## (أ) الملفات المنفذة للبوابة (Exact File Paths Implementing It)
1. **قاعدتا البيانات المنفصلتان فيزيائياً**:
   - `app/assets/poems.db`: مكتبة الشعر المقروءة فقط مع `PRAGMA user_version = 1` وجدول `content_version` ومعرفات نصية ثابتة (`poem_uid`, `verse_uid`).
   - `app/assets/user.db`: قاعدة بيانات تقدم المستخدم وحفظه ومراجعاته مع `PRAGMA user_version = 2` دون أي مفاتيح أجنبية عبر الملفات.
   - `data_pipeline/build_databases.py`: خط توليد وتحديث المخططات المستقلة وفهارس الاستعلام المفتاحي.

2. **مدير التبديل الذري والنسخ الاحتياطي (Database Manager)**:
   - `app/lib/core/db/database_manager.dart`:
     - فحص سلامة الملفات عبر البصمة الرقمية (`SHA-256 Checksum`) و `PRAGMA integrity_check`.
     - الاستبدال الذري لـ `poems.db` بملف مؤقت دون لمس `user.db`.
     - معالجة المعرفات اليتيمة (`Orphaned IDs`) بوسمها كـ `is_orphaned` دون أي انهيار.
     - قصر النسخ الاحتياطي والاستعادة حصرياً على `user.db`.

3. **اختبارات الترحيل والتوافق (Automated Tests)**:
   - `data_pipeline/tests/test_versioned_migrations.py`

---

## (ب) أسماء الاختبارات المثبتة (Test Names That Prove It)
- مجموعة اختبارات الترحيل وقواعد البيانات (`data_pipeline/tests/test_versioned_migrations.py`):
  - `test_database_versions_and_content_version_table`: التحقق من إصدارات المخططات `PRAGMA user_version` وخلو `user.db` من جداول المحتوى.
  - `test_atomic_replacement_keeps_user_progress`: استبدال `poems.db` بنسخة أحدث وإثبات بقاء تقدم المستخدم سليماً عبر المعرفات الثابتة.
  - `test_graceful_orphaned_id_handling`: معالجة المعرفات المحذوفة أو المؤرشفة بلباقة دون انهيار التطبيق.
  - `test_backup_and_restore_covers_user_db_only`: إثبات أن النسخ والاستعادة يغطي حصرياً `user.db`.

---

## (ج) رابط ومؤشر خط العمل في CI (CI Run Link)
- خط العمل: `https://github.com/lm7md-ai/sheir/actions`
- يتم تنفيذ اختبارات الترحيل ضمن وظيفة `python-pipeline-tests`.

---

## (د) القيود والملاحظات المعروفة (Known Limitations)
- يمنع منعاً باتاً إنشاء أي علاقات مفاتيح أجنبية (`FOREIGN KEY`) بين الملفين؛ الربط يتم حصرياً عبر المعرفات النصية المرجعية الثابتة (`poem_uid`, `verse_uid`).
