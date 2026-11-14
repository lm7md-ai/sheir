import '../entities/poem_entity.dart';

class KeysetPage<T> {
  final List<T> items;
  final String? nextCursor; // مفتاح الفرز للصفحة القادمة (WHERE sort_key > ?)
  final bool hasMore;
  final int queryDurationMs;

  const KeysetPage({
    required this.items,
    this.nextCursor,
    required this.hasMore,
    required this.queryDurationMs,
  });
}

/// واجهة مستودع خزانة الدواوين في طبقة النطاق (Repository Interface)
abstract class ILibraryRepository {
  Future<KeysetPage<PoemEntity>> getPoemsKeyset({
    String? afterCursor,
    int limit = 50,
    String? era,
    String? meter,
  });

  Future<List<VerseEntity>> searchVersesFts({
    required String query,
    int limit = 50,
  });

  Future<PoemEntity?> getPoemByUid(String uid);
}
