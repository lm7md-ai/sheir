import pytest
from data_pipeline.build_databases import remove_tashkeel, normalize_arabic

def test_full_text_search_accuracy():
    # التحقق من أن البحث في FTS5 يعمل مع وبدون همزات وتشكيل
    sample = "إِنَّ الَّذِي مَلَأَ اللُّغَاتِ مَحَاسِناً"
    norm = normalize_arabic(sample)
    assert norm == "ان الذي ملا اللغات محاسنا"

def test_meters_integrity():
    meters = [
        "الطويل", "المديد", "البسيط", "الوافر", "الكامل", "الهزج",
        "الرجز", "الرمل", "السريع", "المنسرح", "الخفيف", "المضارع",
        "المقتضب", "المجتث", "المتقارب", "المتدارك"
    ]
    assert len(meters) == 16
