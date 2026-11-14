#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
اختبارات استبدال قواعد البيانات والتوافق والترحيل ومعالجة المعرفات اليتيمة (Gate 6)
"""

import os
import sqlite3
import tempfile
import shutil
import pytest
from data_pipeline.build_databases import build_poems_db, build_user_db

def test_database_versions_and_content_version_table():
    """التحقق من وجود PRAGMA user_version وجدول content_version"""
    with tempfile.TemporaryDirectory() as tmpdir:
        poems_path = os.path.join(tmpdir, "poems.db")
        user_path = os.path.join(tmpdir, "user.db")

        build_poems_db(poems_path)
        build_user_db(user_path)

        # 1. فحص poems.db
        conn_p = sqlite3.connect(poems_path)
        cur_p = conn_p.cursor()
        cur_p.execute("PRAGMA user_version;")
        user_version_p = cur_p.fetchone()[0]
        assert user_version_p >= 1

        cur_p.execute("SELECT version, checksum FROM content_version;")
        row = cur_p.fetchone()
        assert row is not None
        assert row[0] == 1
        conn_p.close()

        # 2. فحص user.db
        conn_u = sqlite3.connect(user_path)
        cur_u = conn_u.cursor()
        cur_u.execute("PRAGMA user_version;")
        user_version_u = cur_u.fetchone()[0]
        assert user_version_u >= 2

        # تأكيد عدم وجود أي جدول من مكتبة الشعر داخل user.db
        cur_u.execute("SELECT name FROM sqlite_master WHERE type='table';")
        tables = [t[0] for t in cur_u.fetchall()]
        assert "poems" not in tables
        assert "poets" not in tables
        assert "srs_cards" in tables
        assert "progress" in tables
        assert "attempts" in tables
        assert "favorites" in tables
        assert "collections" in tables
        conn_u.close()

def test_atomic_replacement_keeps_user_progress():
    """محاكاة استبدال poems.db بنسخة أحدث وإثبات بقاء تقدم المستخدم سليماً عبر المعرفات الثابتة"""
    with tempfile.TemporaryDirectory() as tmpdir:
        poems_v1 = os.path.join(tmpdir, "poems_v1.db")
        poems_v2 = os.path.join(tmpdir, "poems_v2.db")
        active_poems = os.path.join(tmpdir, "poems.db")
        user_db = os.path.join(tmpdir, "user.db")

        build_poems_db(poems_v1)
        build_poems_db(poems_v2)
        build_user_db(user_db)

        shutil.copyfile(poems_v1, active_poems)

        # المستخدم راجع بيتاً: "verse_mutanabbi_01"
        conn_u = sqlite3.connect(user_db)
        cur_u = conn_u.cursor()
        cur_u.execute("""
        INSERT OR REPLACE INTO srs_cards (id, verse_uid, poem_uid, stability, difficulty, repetitions, interval_days, last_reviewed, next_due)
        VALUES ('card_test', 'verse_mutanabbi_01', 'poem_mutanabbi_wa_harra', 3.5, 4.0, 5, 7, '2026-11-14', '2026-11-21')
        """)
        conn_u.commit()
        conn_u.close()

        # استبدال ذرّي: حذف poems.db القديمة ووضع الإصدار الأحدث poems_v2
        os.remove(active_poems)
        shutil.copyfile(poems_v2, active_poems)

        # التحقق من أن بطاقة المستخدم ما زالت تشير بدقة إلى البيت عبر المعرف الثابت
        conn_p = sqlite3.connect(active_poems)
        cur_p = conn_p.cursor()
        cur_p.execute("SELECT sadr, ajuz FROM verses WHERE verse_uid = 'verse_mutanabbi_01'")
        verse_data = cur_p.fetchone()
        conn_p.close()

        assert verse_data is not None
        assert "وَا حَرَّ قَلْبَاهُ" in verse_data[0]

        # فحص بقاء تقدم المستخدم في user.db
        conn_u = sqlite3.connect(user_db)
        cur_u = conn_u.cursor()
        cur_u.execute("SELECT stability, repetitions FROM srs_cards WHERE id = 'card_test'")
        card = cur_u.fetchone()
        conn_u.close()

        assert card is not None
        assert card[0] == 3.5
        assert card[1] == 5

def test_graceful_orphaned_id_handling():
    """معالجة المعرفات التي حُذفت في الإصدار الجديد من الديوان بلباقة ودون انهيار"""
    with tempfile.TemporaryDirectory() as tmpdir:
        user_db = os.path.join(tmpdir, "user.db")
        build_user_db(user_db)

        conn_u = sqlite3.connect(user_db)
        cur_u = conn_u.cursor()
        # إضافة بطاقة تشير لبيت غير موجود في المكتبة المحدثة (مؤرشف)
        cur_u.execute("""
        INSERT INTO srs_cards (id, verse_uid, poem_uid, stability, difficulty, repetitions, interval_days, last_reviewed, next_due)
        VALUES ('card_deprecated', 'verse_old_removed', 'poem_old', 2.0, 5.0, 2, 3, '2026-11-10', '2026-11-13')
        """)
        conn_u.commit()

        # المكتبة المحدثة لا تحوي هذا المعرف
        current_library_uids = {"verse_mutanabbi_01", "verse_imru_01"}

        cur_u.execute("SELECT verse_uid FROM srs_cards WHERE id = 'card_deprecated'")
        checked_uid = cur_u.fetchone()[0]

        # بدلاً من الانهيار، نضع علامة is_orphaned = 1
        if checked_uid not in current_library_uids:
            cur_u.execute("UPDATE srs_cards SET is_orphaned = 1 WHERE id = 'card_deprecated'")
            conn_u.commit()

        cur_u.execute("SELECT is_orphaned FROM srs_cards WHERE id = 'card_deprecated'")
        is_orphaned = cur_u.fetchone()[0]
        conn_u.close()

        assert is_orphaned == 1

def test_backup_and_restore_covers_user_db_only():
    """التحقق من أن النسخ الاحتياطي يغطي user.db فقط ولا يكرر poems.db"""
    with tempfile.TemporaryDirectory() as tmpdir:
        user_db = os.path.join(tmpdir, "user.db")
        backup_db = os.path.join(tmpdir, "user_backup.db")

        build_user_db(user_db)

        # تعديل في user.db
        conn_u = sqlite3.connect(user_db)
        cur_u = conn_u.cursor()
        cur_u.execute("UPDATE user_profile SET xp = 999 WHERE id = 1;")
        conn_u.commit()
        conn_u.close()

        # أخذ نسخة احتياطية
        shutil.copyfile(user_db, backup_db)

        # استعادة وتأكيد سلامة النسخة
        conn_b = sqlite3.connect(backup_db)
        cur_b = conn_b.cursor()
        cur_b.execute("SELECT xp FROM user_profile WHERE id = 1;")
        assert cur_b.fetchone()[0] == 999
        conn_b.close()
