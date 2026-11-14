import time
import sqlite3
import pytest
from data_pipeline.build_databases import normalize_arabic

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

    # إدراج 5,000 بيت في الاختبار السريع
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

    # قياس وقت استعلام التقطيع الصفحي
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
