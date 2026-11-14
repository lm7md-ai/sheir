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

def test_paged_fts5_under_15ms():
    conn = sqlite3.connect(":memory:")
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY,
        sadr TEXT,
        ajuz TEXT,
        sadr_norm TEXT,
        ajuz_norm TEXT
    );
    """)

    cur.execute("""
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        verse_id UNINDEXED,
        sadr,
        ajuz,
        sadr_norm,
        ajuz_norm
    );
    """)

    verses = []
    fts_rows = []
    for i in range(1, 5001):
        sadr = f"بَيْتٌ شِعْرِيٌّ رَقْمُ {i} فِي المَجْدِ"
        ajuz = f"وَقَافِيَةٌ عَذْبَةٌ تُحَاكِي النُّجُومَ {i}"
        s_norm = normalize_arabic(sadr)
        a_norm = normalize_arabic(ajuz)
        verses.append((i, sadr, ajuz, s_norm, a_norm))
        fts_rows.append((i, sadr, ajuz, s_norm, a_norm))

    cur.executemany("INSERT INTO verses VALUES (?, ?, ?, ?, ?)", verses)
    cur.executemany("INSERT INTO verses_fts VALUES (?, ?, ?, ?, ?)", fts_rows)
    conn.commit()

    q = normalize_arabic("المجد")
    t0 = time.perf_counter()
    cur.execute("""
    SELECT verse_id, sadr, ajuz 
    FROM verses_fts 
    WHERE sadr_norm MATCH ? 
    LIMIT 20 OFFSET 100
    """, (q,))
    rows = cur.fetchall()
    elapsed_ms = (time.perf_counter() - t0) * 1000.0

    conn.close()

    assert len(rows) == 20
    assert elapsed_ms < 15.0, f"Query took {elapsed_ms:.2f}ms which exceeds 15ms budget!"
