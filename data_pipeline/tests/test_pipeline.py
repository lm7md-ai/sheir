import sqlite3
import pytest
from data_pipeline.build_databases import remove_tashkeel, normalize_arabic, build_poems_db, build_user_data_db

def test_remove_tashkeel():
    text = "وَاحَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ"
    cleaned = remove_tashkeel(text)
    assert "َ" not in cleaned
    assert "ْ" not in cleaned
    assert "ُ" not in cleaned
    assert cleaned == "واحر قلباه ممن قلبه شبم"

def test_normalize_arabic():
    raw = "أَنَا الَّذِي نَظَرَ الأَعْمَى إِلَى أَدَبِي"
    norm = normalize_arabic(raw)
    assert "أ" not in norm
    assert "إ" not in norm
    assert norm == "انا الذي نظر الاعمي الي ادبي"

def test_fts5_search(tmp_path):
    test_db = str(tmp_path / "test_poems.db")
    build_poems_db(test_db)

    conn = sqlite3.connect(test_db)
    cur = conn.cursor()

    # فحص جدول FTS5 بالبحث غير المشكول
    search_query = "الخيل والليل"
    norm_query = normalize_arabic(search_query)

    cur.execute("""
    SELECT rowid, sadr, ajuz, poem_title, poet_name 
    FROM verses_fts 
    WHERE sadr_norm MATCH ? OR ajuz_norm MATCH ?
    """, (norm_query, norm_query))

    rows = cur.fetchall()
    assert len(rows) >= 1
    verse_id, sadr, ajuz, title, poet = rows[0]
    assert "الخَيْلُ" in sadr
    assert "المتنبي" in poet
    assert title == "واحرّ قلباه"
    conn.close()

def test_user_data_isolation(tmp_path):
    user_db = str(tmp_path / "test_user_data.db")
    build_user_data_db(user_db)

    conn = sqlite3.connect(user_db)
    cur = conn.cursor()

    cur.execute("SELECT xp, streak_days, current_rank FROM user_profile WHERE id = 1")
    profile = cur.fetchone()
    assert profile is not None
    assert profile[0] == 350 # xp
    assert profile[1] == 7   # streak

    cur.execute("SELECT count(*) FROM srs_cards")
    count = cur.fetchone()[0]
    assert count == 2
    conn.close()
