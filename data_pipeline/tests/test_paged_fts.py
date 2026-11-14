import time
import sqlite3
import pytest
from data_pipeline.build_databases import normalize_arabic

def test_keyset_pagination_and_query_plan():
    """التحقق من التقطيع المفتاحي Keyset وخطة الاستعلام EXPLAIN QUERY PLAN لـ Gate 4"""
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE poems (
        id INTEGER PRIMARY KEY,
        poem_uid TEXT UNIQUE,
        sort_key INTEGER UNIQUE,
        title TEXT
    );
    """)

    cur.execute("CREATE INDEX idx_poems_sort_key ON poems(sort_key);")

    # إدراج 10,000 قصيدة تجريبية
    batch = [(i, f"poem_{i}", i, f"قصيدة {i}") for i in range(1, 10001)]
    cur.executemany("INSERT INTO poems VALUES (?, ?, ?, ?)", batch)
    conn.commit()

    # 1. فحص EXPLAIN QUERY PLAN
    cur.execute("""
    EXPLAIN QUERY PLAN
    SELECT id, sort_key, title FROM poems
    WHERE sort_key > ?
    ORDER BY sort_key ASC
    LIMIT 50;
    """, (1000,))
    plan_rows = cur.fetchall()
    assert any("USING INDEX idx_poems_sort_key" in str(r) for r in plan_rows)
    assert not any("SCAN TABLE poems" in str(r) for r in plan_rows)

    # 2. قياس زمن الصفحة الأولى والصفحة العميقة
    t0 = time.perf_counter()
    cur.execute("SELECT id, sort_key, title FROM poems WHERE sort_key > 0 ORDER BY sort_key ASC LIMIT 50;")
    first_page = cur.fetchall()
    t_first_ms = (time.perf_counter() - t0) * 1000.0

    t0 = time.perf_counter()
    cur.execute("SELECT id, sort_key, title FROM poems WHERE sort_key > 8000 ORDER BY sort_key ASC LIMIT 50;")
    deep_page = cur.fetchall()
    t_deep_ms = (time.perf_counter() - t0) * 1000.0

    conn.close()

    assert len(first_page) == 50
    assert len(deep_page) == 50
    assert t_first_ms < 50.0
    assert t_deep_ms < 50.0

def test_external_content_fts5_with_bm25_and_prefix():
    """التحقق من جدول FTS5 ذو المحتوى الخارجي مع حقل مجرد من التشكيل وفهارس السوابق وترتيب bm25 والتقطيع الصفحي"""
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_uid TEXT UNIQUE NOT NULL,
        poem_uid TEXT NOT NULL,
        sadr TEXT NOT NULL,
        ajuz TEXT NOT NULL,
        sadr_norm TEXT NOT NULL,
        ajuz_norm TEXT NOT NULL,
        text_norm TEXT NOT NULL
    );
    """)

    cur.execute("""
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        sadr,
        ajuz,
        text_norm,
        content='verses',
        content_rowid='id',
        prefix='2 3',
        tokenize='unicode61 remove_diacritics 2'
    );
    """)

    cur.execute("""
    CREATE TRIGGER verses_ai AFTER INSERT ON verses BEGIN
        INSERT INTO verses_fts(rowid, sadr, ajuz, text_norm)
        VALUES (new.id, new.sadr, new.ajuz, new.text_norm);
    END;
    """)

    verses = []
    for i in range(1, 2001):
        sadr = f"بَيْتٌ شِعْرِيٌّ رَقْمُ {i} فِي المَجْدِ وَالعُلَا"
        ajuz = f"وَقَافِيَةٌ عَذْبَةٌ تُحَاكِي النُّجُومَ {i}"
        s_norm = normalize_arabic(sadr)
        a_norm = normalize_arabic(ajuz)
        text_norm = f"{s_norm} {a_norm}"
        verses.append((f"v_{i}", f"p_{i}", sadr, ajuz, s_norm, a_norm, text_norm))

    cur.executemany("""
    INSERT INTO verses (verse_uid, poem_uid, sadr, ajuz, sadr_norm, ajuz_norm, text_norm)
    VALUES (?, ?, ?, ?, ?, ?, ?)
    """, verses)
    conn.commit()

    # استعلام مع مطابقة سوابق prefix*، وترتيب bm25، وتقطيع بـ LIMIT و OFFSET
    q = "المجد*"
    t0 = time.perf_counter()
    cur.execute("""
    SELECT v.verse_uid, v.sadr, v.ajuz, bm25(verses_fts) AS rank
    FROM verses_fts
    JOIN verses v ON v.id = verses_fts.rowid
    WHERE verses_fts MATCH ?
    ORDER BY rank
    LIMIT 20 OFFSET 40;
    """, (q,))
    rows = cur.fetchall()
    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    conn.close()

    assert len(rows) == 20
    assert elapsed_ms < 15.0, f"Query took {elapsed_ms:.2f}ms which exceeds 15ms budget!"
    assert rows[0][3] is not None
