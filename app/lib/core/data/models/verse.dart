class Verse {
  final int id;
  final int poemId;
  final int verseOrder;
  final String sadr; // الصدر
  final String ajuz; // العجز

  const Verse({
    required this.id,
    required this.poemId,
    required this.verseOrder,
    required this.sadr,
    required this.ajuz,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'poem_id': poemId,
      'verse_order': verseOrder,
      'sadr': sadr,
      'ajuz': ajuz,
    };
  }

  factory Verse.fromMap(Map<String, dynamic> map) {
    return Verse(
      id: map['id'] as int,
      poemId: map['poem_id'] as int,
      verseOrder: map['verse_order'] as int,
      sadr: map['sadr'] as String,
      ajuz: map['ajuz'] as String,
    );
  }
}
