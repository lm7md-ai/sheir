import 'verse.dart';

class Poem {
  final int id;
  final String title;
  final String poetName;
  final String era;        // جاهلي، إسلامي، أموي، عباسي، أندلسي، حديث
  final String meterName;  // الطويل، الكامل، البسيط...
  final String rawiy;      // حرف الروي (الميم، الدال، الراء...)
  final String theme;      // حكمة، فخر، غزل، رثاء، حماسة...
  final List<Verse> verses;

  const Poem({
    required this.id,
    required this.title,
    required this.poetName,
    required this.era,
    required this.meterName,
    required this.rawiy,
    required this.theme,
    this.verses = const [],
  });

  int get verseCount => verses.length;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'poet_name': poetName,
      'era': era,
      'meter_name': meterName,
      'rawiy': rawiy,
      'theme': theme,
    };
  }

  factory Poem.fromMap(Map<String, dynamic> map, {List<Verse> verses = const []}) {
    return Poem(
      id: map['id'] as int,
      title: map['title'] as String,
      poetName: map['poet_name'] as String,
      era: map['era'] as String,
      meterName: map['meter_name'] as String,
      rawiy: map['rawiy'] as String,
      theme: map['theme'] as String,
      verses: verses,
    );
  }
}
