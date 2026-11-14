#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
بناء وتجهيز قاعدتي بيانات ديوان (Diwan Database Builder)
1. poems.db: مكتبة الشعر الكلاسيكي مع جدول FTS5 للبحث الفوري
2. user_data.db: قاعدة بيانات تقدم المستخدم واستذكاره المتباعد
"""

import os
import sqlite3
import re

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

    # 1. جداول الشعراء والقصائد والأبيات
    cur.execute("""
    CREATE TABLE poets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        normalized_name TEXT NOT NULL,
        era TEXT NOT NULL,
        bio TEXT
    );
    """)

    cur.execute("""
    CREATE TABLE poems (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poet_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        normalized_title TEXT NOT NULL,
        era TEXT NOT NULL,
        meter_name TEXT NOT NULL,
        rawiy TEXT NOT NULL,
        theme TEXT NOT NULL,
        verse_count INTEGER DEFAULT 0,
        FOREIGN KEY (poet_id) REFERENCES poets(id)
    );
    """)

    cur.execute("""
    CREATE TABLE verses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_id INTEGER NOT NULL,
        verse_order INTEGER NOT NULL,
        sadr TEXT NOT NULL,
        ajuz TEXT NOT NULL,
        sadr_norm TEXT NOT NULL,
        ajuz_norm TEXT NOT NULL,
        FOREIGN KEY (poem_id) REFERENCES poems(id)
    );
    """)

    # 2. جدول البحث الفوري FTS5
    cur.execute("""
    CREATE VIRTUAL TABLE verses_fts USING fts5(
        verse_id UNINDEXED,
        poem_id UNINDEXED,
        sadr,
        ajuz,
        sadr_norm,
        ajuz_norm,
        poem_title,
        poet_name
    );
    """)

    # 3. إدراج روائع الشعر العربي الكلاسيكي
    poets_data = [
        ("أبو الطيب المتنبي", "العباسي", "أحمد بن الحسين الكندي، حكيم الشعراء وأحد مفاخر الأدب العربي."),
        ("امرؤ القيس", "الجاهلي", "حندج بن حجر الكندي، الملك الضليل ورائد المعلقات."),
        ("عنترة بن شداد", "الجاهلي", "فارس بني عبس وشاعر الحماسة والغزل العفيف."),
        ("الإمام الشافعي", "العباسي", "محمد بن إدريس الشافعي، عالم الأمة وفقيهها وناظم الحكم الخالدة."),
        ("أحمد شوقي", "الحديث", "أمير الشعراء في العصر الحديث ورائد المسرحية الشعرية."),
        ("البحتري", "العباسي", "الوليد بن عبيد، أمير الديباجة الشعرية وحسن الصياغة."),
    ]

    for p in poets_data:
        cur.execute(
            "INSERT INTO poets (name, normalized_name, era, bio) VALUES (?, ?, ?, ?)",
            (p[0], normalize_arabic(p[0]), p[1], p[2])
        )

    poems_data = [
        # 1. المتنبي - واحر قلباه
        {
            "poet_id": 1,
            "title": "واحرّ قلباه",
            "era": "العباسي",
            "meter": "البسيط",
            "rawiy": "الميم",
            "theme": "عتاب وفخر",
            "verses": [
                ("وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ", "وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ"),
                ("مَا لِي أُكَتِّمُ حُبّاً قَدْ بَرَى جَسَدِي", "وَتَدَّعِي حُبَّ سَيْفِ الدَّوْلَةِ الأُمَمُ"),
                ("إِنْ كَانَ يَجْمَعُنَا حُبٌّ لِغُرَّتِهِ", "فَلَيْتَ أَنَّا بِقَدْرِ الحُبِّ نَقْتَسِمُ"),
                ("يَا أَعْدَلَ النَّاسِ إِلَّا فِي مُعَامَلَتِي", "فِيكَ الخِصَامُ وَأَنْتَ الخَصْمُ وَالحَكَمُ"),
                ("أُعِيذُهَا نَظَرَاتٍ مِنْكَ صَادِقَةً", "أَنْ تَحْسَبَ الشَّحْمَ فِيمَنْ شَحْمُهُ وَرَمُ"),
                ("سَيَعْلَمُ الجَمْعُ مِمَّنْ ضَمَّ مَجْلِسُنَا", "بِأَنَّنِي خَيْرُ مَنْ تَسْعَى بِهِ قَدَمُ"),
                ("أَنَا الَّذِي نَظَرَ الأَعْمَى إِلَى أَدَبِي", "وَأَسْمَعَتْ كَلِمَاتِي مَنْ بِهِ صَمَمُ"),
                ("الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي", "وَالسَّيْفُ وَالرُّمْحُ وَالقِرْطَاسُ وَالقَلَمُ"),
            ]
        },
        # 2. امرؤ القيس - قفا نبك
        {
            "poet_id": 2,
            "title": "قِفَا نَبْكِ (المعلقة)",
            "era": "الجاهلي",
            "meter": "الطويل",
            "rawiy": "اللام",
            "theme": "وقوف على الأطلال",
            "verses": [
                ("قِفَا نَبْكِ مِنْ ذِكْرَى حَبِيبٍ وَمَنْزِلِ", "بِسِقْطِ اللِّوَى بَيْنَ الدَّخُولِ فَحَوْمَلِ"),
                ("فَتُوضِحَ فَالمِقْرَاةِ لَمْ يَعْفُ رَسْمُهَا", "لِمَا نَسَجَتْهَا مِنْ جَنُوبٍ وَشَمْأَلِ"),
                ("وَلَيْلٍ كَمَوْجِ البَحْرِ أَرْخَى سُدُولَهُ", "عَلَيَّ بِأَنْوَاعِ الهُمُومِ لِيَبْتَلِي"),
                ("فَقُلْتُ لَهُ لَمَّا تَمَطَّى بِصُلْبِهِ", "وَأَرْدَفَ أَعْجَازاً وَنَاءَ بِكَلْكَلِ"),
                ("أَلَا أَيُّهَا اللَّيْلُ الطَّوِيلُ أَلَا انْجَلِي", "بِصُبْحٍ وَمَا الإِصْبَاحُ مِنْكَ بِأَمْثَلِ"),
                ("مِكَرٍّ مِفَرٍّ مُقْبِلٍ مُدْبِرٍ مَعاً", "كَجُلْمُودِ صَخْرٍ حَطَّهُ السَّيْلُ مِنْ عَلِ"),
            ]
        },
        # 3. عنترة بن شداد - هل غادر الشعراء
        {
            "poet_id": 3,
            "title": "هل غادر الشعراء (المعلقة)",
            "era": "الجاهلي",
            "meter": "الكامل",
            "rawiy": "الميم",
            "theme": "حماسة وفخر",
            "verses": [
                ("هَلْ غَادَرَ الشُّعَرَاءُ مِنْ مُتَرَدَّمِ", "أَمْ هَلْ عَرَفْتَ الدَّارَ بَعْدَ تَوَهُّمِ"),
                ("يَا دَارَ عَبْلَةَ بِالجِوَاءِ تَكَلَّمِي", "وَعِمِي صَبَاحاً دَارَ عَبْلَةَ وَاسْلَمِي"),
                ("فَوَقَفْتُ فِيهَا نَاقَتِي وَكَأَنَّهَا", "فَدَنٌ لِأَقْضِيَ حَاجَةَ المُتَلَوِّمِ"),
                ("يُخْبِرْكِ مَنْ شَهِدَ الوَقِيعَةَ أَنَّنِي", "أَغْشَى الوَغَى وَأَعِفُّ عِنْدَ المَغْنَمِ"),
                ("وَلَقَدْ ذَكَرْتُكِ وَالرِّمَاحُ نَوَاهِلٌ", "مِنِّي وَبِيضُ الهِنْدِ تَقْطُرُ مِنْ دَمِي"),
                ("فَوَدِدْتُ تَقْبِيلَ السُّيُوفِ لِأَنَّهَا", "لَمَعَتْ كَبَارِقِ ثَغْرِكِ المُتَبَسِّمِ"),
            ]
        },
        # 4. الشافعي - دع الأيام
        {
            "poet_id": 4,
            "title": "دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ",
            "era": "العباسي",
            "meter": "الوافر",
            "rawiy": "الهمزة",
            "theme": "حكمة وزهد",
            "verses": [
                ("دَعِ الأَيَّامَ تَفْعَلُ مَا تَشَاءُ", "وَطِبْ نَفْساً إِذَا حَكَمَ القَضَاءُ"),
                ("وَلَا تَجْزَعْ لِحَادِثَةِ اللَّيَالِي", "فَمَا لِحَوَادِثِ الدُّنْيَا بَقَاءُ"),
                ("وَكُنْ رَجُلاً عَلَى الأَهْوَالِ جَلْداً", "وَشِيمَتُكَ السَّمَاحَةُ وَالوَفَاءُ"),
                ("وَإِنْ كَثُرَتْ عُيُوبُكَ فِي البَرَايَا", "وَسَرَّكَ أَنْ يَكُونَ لَهَا غِطَاءُ"),
                ("تَسَتَّرْ بِالسَّخَاءِ فَكُلُّ عَيْبٍ", "يُغَطِّيهِ كَمَا قِيلَ السَّخَاءُ"),
            ]
        },
        # 5. أحمد شوقي - ولد الهدى
        {
            "poet_id": 5,
            "title": "وُلِدَ الهُدَى فَالكائِنَاتُ ضِيَاءُ",
            "era": "الحديث",
            "meter": "الكامل",
            "rawiy": "الهمزة",
            "theme": "مديح نبوي",
            "verses": [
                ("وُلِدَ الهُدَى فَالكائِنَاتُ ضِيَاءُ", "وَفَمُ الزَّمَانِ تَبَسُّمٌ وَثَنَاءُ"),
                ("الرُّوحُ وَالمَلَأُ المَلَائِكُ حَوْلَهُ", "لِلدِّينِ وَالدُّنْيَا بِهِ بُشَرَاءُ"),
                ("وَالعَرْشُ يَزْهُو وَالحَظِيرَةُ تَزْدَهِي", "وَالمُنْتَهَى وَالسِّدْرَةُ العَصْمَاءُ"),
                ("يَا خَيْرَ مَنْ جَاءَ الوُجُودَ تَحِيَّةً", "مِنْ مُرْسَلِينَ إِلَى الهُدَى بِكَ جَاؤُوا"),
            ]
        }
    ]

    for p in poems_data:
        cur.execute("""
        INSERT INTO poems (poet_id, title, normalized_title, era, meter_name, rawiy, theme, verse_count)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            p["poet_id"],
            p["title"],
            normalize_arabic(p["title"]),
            p["era"],
            p["meter"],
            p["rawiy"],
            p["theme"],
            len(p["verses"])
        ))
        poem_id = cur.lastrowid

        for idx, (sadr, ajuz) in enumerate(p["verses"], start=1):
            sadr_norm = normalize_arabic(sadr)
            ajuz_norm = normalize_arabic(ajuz)

            cur.execute("""
            INSERT INTO verses (poem_id, verse_order, sadr, ajuz, sadr_norm, ajuz_norm)
            VALUES (?, ?, ?, ?, ?, ?)
            """, (poem_id, idx, sadr, ajuz, sadr_norm, ajuz_norm))
            verse_id = cur.lastrowid

            # إدراج في FTS5
            cur.execute("""
            INSERT INTO verses_fts (verse_id, poem_id, sadr, ajuz, sadr_norm, ajuz_norm, poem_title, poet_name)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """, (verse_id, poem_id, sadr, ajuz, sadr_norm, ajuz_norm, p["title"], poets_data[p["poet_id"] - 1][0]))

    # الفهارس لسرعة القراءة
    cur.execute("CREATE INDEX idx_verses_poem_id ON verses(poem_id);")
    cur.execute("CREATE INDEX idx_poems_era ON poems(era);")
    cur.execute("CREATE INDEX idx_poems_meter ON poems(meter_name);")

    conn.commit()
    conn.close()
    print(f"Successfully generated {db_path} with {len(poems_data)} poems and FTS5 search index!")

def build_user_data_db(db_path: str = "app/assets/user_data.db"):
    os.makedirs(os.path.dirname(db_path), exist_ok=True)
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    cur.execute("""
    CREATE TABLE srs_cards (
        id TEXT PRIMARY KEY,
        verse_id INTEGER NOT NULL,
        poem_id INTEGER NOT NULL,
        stability REAL NOT NULL DEFAULT 1.0,
        difficulty REAL NOT NULL DEFAULT 5.0,
        repetitions INTEGER NOT NULL DEFAULT 0,
        interval_days INTEGER NOT NULL DEFAULT 0,
        last_reviewed TEXT NOT NULL,
        next_due TEXT NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE recitation_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_id INTEGER NOT NULL,
        verse_id INTEGER,
        accuracy REAL NOT NULL,
        correct_count INTEGER NOT NULL,
        wrong_count INTEGER NOT NULL,
        hesitation_count INTEGER NOT NULL,
        missing_count INTEGER NOT NULL,
        extra_count INTEGER NOT NULL,
        audio_path TEXT,
        created_at TEXT NOT NULL
    );
    """)

    cur.execute("""
    CREATE TABLE bookmarks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        poem_id INTEGER NOT NULL,
        verse_id INTEGER,
        created_at TEXT NOT NULL,
        UNIQUE(poem_id, verse_id)
    );
    """)

    cur.execute("""
    CREATE TABLE user_profile (
        id INTEGER PRIMARY KEY,
        xp INTEGER DEFAULT 120,
        streak_days INTEGER DEFAULT 5,
        current_rank TEXT DEFAULT 'حافِظٌ مُجْتَهِد',
        last_practice_date TEXT
    );
    """)

    # بيانات افتراضية للمستخدم لتجربة الشاشات والإحصائيات فورياً
    cur.execute("""
    INSERT INTO user_profile (id, xp, streak_days, current_rank, last_practice_date)
    VALUES (1, 350, 7, 'ناظمٌ مُتْقِن', '2026-11-14')
    """)

    # بطاقات SRS نموذجية مستحقة اليوم
    cur.execute("""
    INSERT INTO srs_cards (id, verse_id, poem_id, stability, difficulty, repetitions, interval_days, last_reviewed, next_due)
    VALUES ('card_1', 1, 1, 2.5, 4.8, 3, 2, '2026-11-12T10:00:00', '2026-11-14T09:00:00'),
           ('card_2', 2, 1, 1.2, 5.2, 1, 1, '2026-11-13T10:00:00', '2026-11-14T10:00:00')
    """)

    conn.commit()
    conn.close()
    print(f"Successfully generated {db_path} schema with migrations support!")

if __name__ == "__main__":
    build_poems_db()
    build_user_data_db()
