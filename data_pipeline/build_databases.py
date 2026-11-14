#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
بناء وتجهيز وتأصيل قاعدتي بيانات ديوان (Diwan Dual-Database Builder)
1. poems.db: مكتبة الشعر الكلاسيكي المقروءة فقط مع PRAGMA user_version وجدول content_version ومعرفات ثابتة (poem_uid, verse_uid).
2. user.db: قاعدة بيانات المستخدم المستقلة مع تتبع الحفظ، المحاولات، بطاقات SRS، والمجموعات، بدون أي مفاتيح أجنبية عبر الملفات.
"""

import os
import sqlite3
import re
import hashlib

def remove_tashkeel(text: str) -> str:
    """إزالة علامات التشكيل وحركات الإعراب والتطويل لمطابقة البحث"""
    diacritics_pattern = re.compile(r'[\u064B-\u065F\u0670\u0640]')
    return diacritics_pattern.sub('', text)

def normalize_arabic(text: str) -> str:
    """تطبيع الحروف العربية لتجاهل فروق الهمزات والألف والتاء المربوطة"""
    t = remove_tashkeel(text)
    t = re.sub(r'[إأآٱ]', 'ا', t)
    t = t.replace('ة', 'ه').replace('ى', 'ي')
    return t

def build_poems_db(db_path: str = "app/assets/poems.db"):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 1. إصدار المخطط وجدول توافق المحتوى (PRAGMA user_version & content_version)
    cur.execute("PRAGMA user_version = 1;")
    cur.execute("""
    CREATE TABLE content_version (
        version INTEGER PRIMARY KEY,
        published_at TEXT NOT NULL,
        min_app_version TEXT NOT NULL,
        checksum TEXT NOT NULL,
        description TEXT
    );
    """)

    # 2. جداول الشعراء والقصائد والأبيات مع المعرفات النصية الثابتة (Stable String UIDs)
    cur.execute("""
    CREATE TABLE poets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poet_uid TEXT UNIQUE NOT NULL,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        era TEXT NOT NULL,
        era_id INTEGER DEFAULT 1,
        bio TEXT
    );
    """)

    cur.execute("""
    CREATE TABLE poems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_uid TEXT UNIQUE NOT NULL,
        poet_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        normalized_title TEXT NOT NULL,
        era TEXT NOT NULL,
        era_id INTEGER DEFAULT 1,
        meter_name TEXT NOT NULL,
        meter_id INTEGER DEFAULT 1,
        rawiy TEXT NOT NULL,
        theme TEXT NOT NULL,
        theme_id INTEGER DEFAULT 1,
        sort_key INTEGER UNIQUE NOT NULL,
        verse_count INTEGER DEFAULT 0,
        FOREIGN KEY (poet_id) REFERENCES poets(id)
    );
    """)

    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_uid TEXT UNIQUE NOT NULL,
        poem_id INTEGER NOT NULL,
        position INTEGER NOT NULL,
        verse_order INTEGER NOT NULL,
        sadr TEXT NOT NULL,
        ajuz TEXT NOT NULL,
        sadr_norm TEXT NOT NULL,
        ajuz_norm TEXT NOT NULL,
        FOREIGN KEY (poem_id) REFERENCES poems(id)
    );
    """)

    # 3. جدول البحث الفوري FTS5
    cur.execute("""
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        verse_uid UNINDEXED,
        poem_uid UNINDEXED,
        sadr,
        ajuz,
        sadr_norm,
        ajuz_norm,
        poem_title,
        poet_name,
        tokenize='unicode61 remove_diacritics 2'
    );
    """)

    # 4. فهارس التصفح الصفحي المفتاحي السريع لـ 100k+
    cur.execute("CREATE INDEX idx_poems_poet_id ON poems(poet_id);")
    cur.execute("CREATE INDEX idx_poems_era_id ON poems(era_id);")
    cur.execute("CREATE INDEX idx_poems_meter_id ON poems(meter_id);")
    cur.execute("CREATE INDEX idx_poems_theme_id ON poems(theme_id);")
    cur.execute("CREATE INDEX idx_poems_sort_key ON poems(sort_key);")
    cur.execute("CREATE INDEX idx_verses_poem_pos ON verses(poem_id, position);")

    # 5. إدراج روائع الشعر العربي
    poets_data = [
        ("poet_mutanabbi", "أبو الطيب المتنبي", "العباسي", 4, "أحمد بن الحسين الكندي، حكيم الشعراء وأحد مفاخر الأدب العربي."),
        ("poet_imru_qais", "امرؤ القيس", "الجاهلي", 1, "حندج بن حجر الكندي، الملك الضليل ورائد المعلقات."),
        ("poet_antarah", "عنترة بن شداد", "الجاهلي", 1, "فارس بني عبس وشاعر الحماسة والغزل العفيف."),
        ("poet_shafii", "الإمام الشافعي", "العباسي", 4, "محمد بن إدريس الشافعي، عالم الأمة وفقيهها وناظم الحكم الخالدة."),
        ("poet_shawqi", "أحمد شوقي", "الحديث", 6, "أمير الشعراء في العصر الحديث ورائد المسرحية الشعرية."),
        ("poet_buhturi", "البحتري", "العباسي", 4, "الوليد بن عبيد، أمير الديباجة الشعرية وحسن الصياغة."),
    ]

    for p in poets_data:
        cur.execute(
            "INSERT INTO poets (poet_uid, name, normalized_name, era, era_id, bio) VALUES (?, ?, ?, ?, ?, ?)",
            (p[0], p[1], normalize_arabic(p[1]), p[2], p[3], p[4])
        )

    poems_data = [
        # 1. المتنبي
        {
            "poet_id": 1,
            "poem_uid": "poem_mutanabbi_wa_harra",
            "title": "واحرّ قلباه",
            "era": "العباسي",
            "era_id": 4,
            "meter": "البسيط",
            "meter_id": 3,
            "rawiy": "الميم",
            "theme": "عتاب وفخر",
            "theme_id": 1,
            "sort_key": 10001,
            "verses": [
                ("verse_mutanabbi_01", "وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ", "وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ"),
                ("verse_mutanabbi_02", "مَا لِي أُكَتِّمُ حُبّاً قَدْ بَرَى جَسَدِي", "وَتَدَّعِي حُبَّ سَيْفِ الدَّوْلَةِ الأُمَمُ"),
                ("verse_mutanabbi_03", "إِنْ كَانَ يَجْمَعُنَا حُبٌّ لِغُرَّتِهِ", "فَلَيْتَ أَنَّا بِقَدْرِ الحُبِّ نَقْتَسِمُ"),
                ("verse_mutanabbi_04", "يَا أَعْدَلَ النَّاسِ إِلَّا فِي مُعَامَلَتِي", "فِيكَ الخِصَامُ وَأَنْتَ الخَصْمُ وَالحَكَمُ"),
                ("verse_mutanabbi_05", "أُعِيذُهَا نَظَرَاتٍ مِنْكَ صَادِقَةً", "أَنْ تَحْسَبَ الشَّحْمَ فِيمَنْ شَحْمُهُ وَرَمُ"),
                ("verse_mutanabbi_06", "سَيَعْلَمُ الجَمْعُ مِمَّنْ ضَمَّ مَجْلِسُنَا", "بِأَنَّنِي خَيْرُ مَنْ تَسْعَى بِهِ قَدَمُ"),
                ("verse_mutanabbi_07", "أَنَا الَّذِي نَظَرَ الأَعْمَى إِلَى أَدَبِي", "وَأَسْمَعَتْ كَلِمَاتِي مَنْ بِهِ صَمَمُ"),
                ("verse_mutanabbi_08", "الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي", "وَالسَّيْفُ وَالرُّمْحُ وَالقِرْطَاسُ وَالقَلَمُ"),
            ]
        },
        # 2. امرؤ القيس
        {
            "poet_id": 2,
            "poem_uid": "poem_imru_qifa_nabki",
            "title": "قِفَا نَبْكِ (المعلقة)",
            "era": "الجاهلي",
            "era_id": 1,
            "meter": "الطويل",
            "meter_id": 1,
            "rawiy": "اللام",
            "theme": "وقوف على الأطلال",
            "theme_id": 2,
            "sort_key": 10002,
            "verses": [
                ("verse_imru_01", "قِفَا نَبْكِ مِنْ ذِكْرَى حَبِيبٍ وَمَنْزِلِ", "بِسِقْطِ اللِّوَى بَيْنَ الدَّخُولِ فَحَوْمَلِ"),
                ("verse_imru_02", "فَتُوضِحَ فَالمِقْرَاةِ لَمْ يَعْفُ رَسْمُهَا", "لِمَا نَسَجَتْهَا مِنْ جَنُوبٍ وَشَمْأَلِ"),
                ("verse_imru_03", "وَلَيْلٍ كَمَوْجِ البَحْرِ أَرْخَى سُدُولَهُ", "عَلَيَّ بِأَنْوَاعِ الهُمُومِ لِيَبْتَلِي"),
                ("verse_imru_04", "فَقُلْتُ لَهُ لَمَّا تَمَطَّى بِصُلْبِهِ", "وَأَرْدَفَ أَعْجَازاً وَنَاءَ بِكَلْكَلِ"),
                ("verse_imru_05", "أَلَا أَيُّهَا اللَّيْلُ الطَّوِيلُ أَلَا انْجَلِي", "بِصُبْحٍ وَمَا الإِصْبَاحُ مِنْكَ بِأَمْثَلِ"),
                ("verse_imru_06", "مِكَرٍّ مِفَرٍّ مُقْبِلٍ مُدْبِرٍ مَعاً", "كَجُلْمُودِ صَخْرٍ حَطَّهُ السَّيْلُ مِنْ عَلِ"),
            ]
        },
        # 3. عنترة بن شداد
        {
            "poet_id": 3,
            "poem_uid": "poem_antarah_hal_ghadara",
            "title": "هل غادر الشعراء (المعلقة)",
            "era": "الجاهلي",
            "era_id": 1,
            "meter": "الكامل",
            "meter_id": 2,
            "rawiy": "الميم",
            "theme": "حماسة وفخر",
            "theme_id": 3,
            "sort_key": 10003,
            "verses": [
                ("verse_antarah_01", "هَلْ غَادَرَ الشُّعَرَاءُ مِنْ مُتَرَدَّمِ", "أَمْ هَلْ عَرَفْتَ الدَّارَ بَعْدَ تَوَهُّمِ"),
                ("verse_antarah_02", "يَا دَارَ عَبْلَةَ بِالجِوَاءِ تَكَلَّمِي", "وَعِمِي صَبَاحاً دَارَ عَبْلَةَ وَاسْلَمِي"),
                ("verse_antarah_03", "فَوَقَفْتُ فِيهَا نَاقَتِي وَكَأَنَّهَا", "فَدَنٌ لِأَقْضِيَ حَاجَةَ المُتَلَوِّمِ"),
                ("verse_antarah_04", "يُخْبِرْكِ مَنْ شَهِدَ الوَقِيعَةَ أَنَّنِي", "أَغْشَى الوَغَى وَأَعِفُّ عِنْدَ المَغْنَمِ"),
                ("verse_antarah_05", "وَلَقَدْ ذَكَرْتُكِ وَالرِّمَاحُ نَوَاهِلٌ", "مِنِّي وَبِيضُ الهِنْدِ تَقْطُرُ مِنْ دَمِي"),
                ("verse_antarah_06", "فَوَدِدْتُ تَقْبِيلَ السُّيُوفِ لِأَنَّهَا", "لَمَعَتْ كَبَارِقِ ثَغْرِكِ المُتَبَسِّمِ"),
            ]
        },
        # 4. الشافعي
        {
            "poet_id": 4,
            "poem_uid": "poem_shafii_dai_al_ayyam",
            "title": "دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ",
            "era": "العباسي",
            "era_id": 4,
            "meter": "الوافر",
            "meter_id": 4,
            "rawiy": "الهمزة",
            "theme": "حكمة وزهد",
            "theme_id": 4,
            "sort_key": 10004,
            "verses": [
                ("verse_shafii_01", "دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ", "وَطِبْ نَفْساً إِذَا حَكَمَ القَضَاءُ"),
                ("verse_shafii_02", "وَلَا تَجْزَعْ لِحَادِثَةِ اللَّيَالِي", "فَمَا لِحَوَادِثِ الدُّنْيَا بَقَاءُ"),
                ("verse_shafii_03", "وَكُنْ رَجُلاً عَلَى الأَهْوَالِ جَلْداً", "وَشِيمَتُكَ السَّمَاحَةُ وَالوَفَاءُ"),
                ("verse_shafii_04", "وَإِنْ كَثُرَتْ عُيُوبُكَ فِي البَرَايَا", "وَسَرَّكَ أَنْ يَكُونَ لَهَا غِطَاءُ"),
                ("verse_shafii_05", "تَسَتَّرْ بِالسَّخَاءِ فَكُلُّ عَيْبٍ", "يُغَطِّيهِ كَمَا قِيلَ السَّخَاءُ"),
            ]
        },
        # 5. أحمد شوقي
        {
            "poet_id": 5,
            "poem_uid": "poem_shawqi_wulida_al_huda",
            "title": "وُلِدَ الهُدَى فَالكائِنَاتُ ضِيَاءُ",
            "era": "الحديث",
            "era_id": 6,
            "meter": "الكامل",
            "meter_id": 2,
            "rawiy": "الهمزة",
            "theme": "مديح نبوي",
            "theme_id": 5,
            "sort_key": 10005,
            "verses": [
                ("verse_shawqi_01", "وُلِدَ الهُدَى فَالكائِنَاتُ ضِيَاءُ", "وَفَمُ الزَّمَانِ تَبَسُّمٌ وَثَنَاءُ"),
                ("verse_shawqi_02", "الرُّوحُ وَالمَلَأُ المَلَائِكُ حَوْلَهُ", "لِلدِّينِ وَالدُّنْيَا بِهِ بُشَرَاءُ"),
                ("verse_shawqi_03", "وَالعَرْشُ يَزْهُو وَالحَظِيرَةُ تَزْدَهِي", "وَالمُنْتَهَى وَالسِّدْرَةُ العَصْمَاءُ"),
                ("verse_shawqi_04", "يَا خَيْرَ مَنْ جَاءَ الوُجُودَ تَحِيَّةً", "مِنْ مُرْسَلِينَ إِلَى الهُدَى بِكَ جَاؤُوا"),
            ]
        }
    ]

    for p in poems_data:
        cur.execute("""
        INSERT INTO poems (poem_uid, poet_id, title, normalized_title, era, era_id, meter_name, meter_id, rawiy, theme, theme_id, sort_key, verse_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            p["poem_uid"],
            p["poet_id"],
            p["title"],
            normalize_arabic(p["title"]),
            p["era"],
            p["era_id"],
            p["meter"],
            p["meter_id"],
            p["rawiy"],
            p["theme"],
            p["theme_id"],
            p["sort_key"],
            len(p["verses"])
        ))
        poem_id = cur.lastrowid

        for idx, (v_uid, sadr, ajuz) in enumerate(p["verses"], start=1):
            sadr_norm = normalize_arabic(sadr)
            ajuz_norm = normalize_arabic(ajuz)

            cur.execute("""
            INSERT INTO verses (verse_uid, poem_id, position, verse_order, sadr, ajuz, sadr_norm, ajuz_norm)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (v_uid, poem_id, idx, idx, sadr, ajuz, sadr_norm, ajuz_norm))

            # إدراج في FTS5
            cur.execute("""
            INSERT INTO verses_fts (verse_uid, poem_uid, sadr, ajuz, sadr_norm, ajuz_norm, poem_title, poet_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (v_uid, p["poem_uid"], sadr, ajuz, sadr_norm, ajuz_norm, p["title"], poets_data[p["poet_id"] - 1][1]))

    # تسجيل بيانات إصدار المحتوى
    cur.execute("""
    INSERT INTO content_version (version, published_at, min_app_version, checksum, description)
    VALUES (1, '2026-11-14T12:00:00Z', '1.0.0', 'sha256_mock_checksum', 'الإصدار المرجعي الأول لمكتبة ديوان الكلاسيكية')
    """)

    conn.commit()
    conn.close()
    print(f"Successfully generated {db_path} with PRAGMA user_version=1 and stable UIDs!")

def build_user_db(db_path: str = "app/assets/user.db"):
    """بناء قاعدة بيانات المستخدم المستقلة مع تتبع الحفظ والبطاقات والمحاولات (user.db)"""

    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("PRAGMA user_version = 2;")

    # 1. بطاقات المراجعة المتباعدة (SRS Cards) مربوطة بالمعرف الثابت verse_uid
    cur.execute("""
    CREATE TABLE srs_cards (
        id TEXT PRIMARY KEY,
        verse_uid TEXT NOT NULL,
        poem_uid TEXT NOT NULL,
        stability REAL NOT NULL DEFAULT 1.0,
        difficulty REAL NOT NULL DEFAULT 5.0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 0,
        last_reviewed TEXT NOT NULL,
        next_due TEXT NOT NULL,
        is_orphaned INTEGER DEFAULT 0
    );
    """)

    # 2. تقدم الحفظ العام (Progress)
    cur.execute("""
    CREATE TABLE progress (
        poem_uid TEXT PRIMARY KEY,
        memorized_verses INTEGER DEFAULT 0,
        total_verses INTEGER DEFAULT 0,
        is_completed INTEGER DEFAULT 0,
        last_interacted_at TEXT NOT NULL
    );
    """)

    # 3. جلسات ومحاولات التسميع (Attempts)
    cur.execute("""
    CREATE TABLE attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        verse_uid TEXT NOT NULL,
        poem_uid TEXT NOT NULL,
        accuracy REAL NOT NULL,
        rank_title TEXT NOT NULL,
        duration_seconds INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
    );
    """)

    # 4. سجل أخطاء التسميع التحليلي (Attempt Errors)
    cur.execute("""
    CREATE TABLE attempt_errors (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        attempt_id INTEGER NOT NULL,
        error_type TEXT NOT NULL, -- wrong, hesitation, missing, extra
        expected_word TEXT NOT NULL,
        heard_word TEXT,
        position INTEGER,
        FOREIGN KEY (attempt_id) REFERENCES attempts(id)
    );
    """)

    # 5. المفضلة (Favorites)
    cur.execute("""
    CREATE TABLE favorites (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_uid TEXT NOT NULL,
        verse_uid TEXT,
        created_at TEXT NOT NULL,
        UNIQUE(poem_uid, verse_uid)
    );
    """)

    # 6. إعدادات المستخدم المحفوظة محلياً (Settings Key-Value)
    cur.execute("""
    CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
    );
    """)

    # 7. المجموعات الشعرية الخاصة بالمستخدم (Collections)
    cur.execute("""
    CREATE TABLE collections (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        poem_uids_json TEXT NOT NULL,
        created_at TEXT NOT NULL
    );
    """)

    # 8. ملف المستخدم ونقاط الخبرة
    cur.execute("""
    CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        xp INTEGER DEFAULT 120,
        streak_days INTEGER DEFAULT 5,
        current_rank TEXT DEFAULT 'حافِظٌ مُجْتَهِد',
        last_practice_date TEXT
    );
    """)

    # إدراج بيانات تجريبية أولية
    cur.execute("""
    INSERT INTO user_profile (id, xp, streak_days, current_rank, last_practice_date)
    VALUES (1, 350, 7, 'ناظمٌ مُتْقِن', '2026-11-14')
    """)

    cur.execute("""
    INSERT INTO srs_cards (id, verse_uid, poem_uid, stability, difficulty, repetitions, interval_days, last_reviewed, next_due)
    VALUES ('card_1', 'verse_mutanabbi_01', 'poem_mutanabbi_wa_harra', 2.5, 4.8, 3, 2, '2026-11-12T10:00:00', '2026-11-14T09:00:00'),
           ('card_2', 'verse_mutanabbi_02', 'poem_mutanabbi_wa_harra', 1.2, 5.2, 1, 1, '2026-11-13T10:00:00', '2026-11-14T10:00:00')
    """)

    cur.execute("""
    INSERT INTO favorites (poem_uid, verse_uid, created_at)
    VALUES ('poem_mutanabbi_wa_harra', 'verse_mutanabbi_01', '2026-11-14T10:00:00')
    """)

    cur.execute("""
    INSERT INTO settings (key, value) VALUES
    ('theme', 'midnightInk'),
    ('font_scale', '1.0'),
    ('dialect_tolerance', 'true')
    """)

    conn.commit()
    conn.close()
    print(f"Successfully generated {db_path} schema with version 2 and full collections/attempts support!")

def build_user_data_db(db_path: str = "app/assets/user_data.db"):
    """دالة توافق خلفي لبناء قاعدة بيانات المستخدم"""
    return build_user_db(db_path)

if __name__ == "__main__":
    build_poems_db("app/assets/poems.db")
    build_user_db("app/assets/user.db")
    # وأيضاً user_data.db للحفاظ على التوافق الخلفي
    build_user_db("app/assets/user_data.db")
