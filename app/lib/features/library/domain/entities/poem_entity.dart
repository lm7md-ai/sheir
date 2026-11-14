/// كيان القصيدة النقي في طبقة النطاق (Domain Entity)
class PoemEntity {
  final String uid; // معرف ثابت دائم مثل "mutanabbi_wa_harra_01"
  final int id;
  final String title;
  final String poetName;
  final String era;
  final String meterName;
  final String rawiy;
  final String theme;
  final int verseCount;
  final List<VerseEntity> verses;

  const PoemEntity({
    required this.uid,
    required this.id,
    required this.title,
    required this.poetName,
    required this.era,
    required this.meterName,
    required this.rawiy,
    required this.theme,
    required this.verseCount,
    this.verses = const [],
  });
}

class VerseEntity {
  final String uid; // معرف البيت الثابت
  final int id;
  final int poemId;
  final int order;
  final String sadr;
  final String ajuz;

  const VerseEntity({
    required this.uid,
    required this.id,
    required this.poemId,
    required this.order,
    required this.sadr,
    required this.ajuz,
  });
}
