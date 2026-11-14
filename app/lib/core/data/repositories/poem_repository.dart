import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/poem.dart';
import '../models/verse.dart';
import '../paged_poem_repository.dart';

/// موفر مستودع القصائد العام بنمط العزل المعماري
final poemRepositoryProvider = Provider<IPagedPoemRepository>((ref) {
  // يمكن تمرير بذور أولية أو الاتصال بقاعدة SQLite
  return PagedPoemRepository();
});

/// موفر استعلام القصائد حسب العصر والصفحة
final pagedPoemsProvider = FutureProvider.family<PagedResult<Poem>, ({int page, int pageSize, String? era})>(
  (ref, params) async {
    final repo = ref.watch(poemRepositoryProvider);
    return repo.getPoemsPaged(
      page: params.page,
      pageSize: params.pageSize,
      era: params.era,
    );
  },
);

/// موفر البحث الفوري في الأبيات بتقنية FTS5
final searchVersesProvider = FutureProvider.family<PagedResult<Verse>, ({String query, int page, int pageSize})>(
  (ref, params) async {
    final repo = ref.watch(poemRepositoryProvider);
    return repo.searchVersesPaged(
      query: params.query,
      page: params.page,
      pageSize: params.pageSize,
    );
  },
);
