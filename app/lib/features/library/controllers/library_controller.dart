import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/models/poem.dart';
import '../../../core/data/paged_poem_repository.dart';
import '../../../core/data/repositories/poem_repository.dart';
import '../../../core/logs/diwan_logger.dart';
import '../../../core/nlp/arabic_normalizer.dart';

class LibraryState {
  final String selectedEra;
  final String searchQuery;
  final int currentPage;
  final int pageSize;
  final bool isLoadingMore;
  final bool hasMore;
  final List<Poem> displayedPoems;
  final int queryDurationMs;
  final int totalCount;

  const LibraryState({
    required this.selectedEra,
    required this.searchQuery,
    required this.currentPage,
    required this.pageSize,
    required this.isLoadingMore,
    required this.hasMore,
    required this.displayedPoems,
    required this.queryDurationMs,
    required this.totalCount,
  });

  factory LibraryState.initial([List<Poem>? seed]) {
    final list = seed ?? [];
    return LibraryState(
      selectedEra: 'الكل',
      searchQuery: '',
      currentPage: 1,
      pageSize: 15,
      isLoadingMore: false,
      hasMore: list.length > 15,
      displayedPoems: list.take(15).toList(),
      queryDurationMs: 1,
      totalCount: list.length,
    );
  }

  LibraryState copyWith({
    String? selectedEra,
    String? searchQuery,
    int? currentPage,
    int? pageSize,
    bool? isLoadingMore,
    bool? hasMore,
    List<Poem>? displayedPoems,
    int? queryDurationMs,
    int? totalCount,
  }) {
    return LibraryState(
      selectedEra: selectedEra ?? this.selectedEra,
      searchQuery: searchQuery ?? this.searchQuery,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      displayedPoems: displayedPoems ?? this.displayedPoems,
      queryDurationMs: queryDurationMs ?? this.queryDurationMs,
      totalCount: totalCount ?? this.totalCount,
    );
  }
}

class LibraryController extends StateNotifier<LibraryState> {
  final IPagedPoemRepository _poemRepo;
  final List<Poem> _allSeedPoems;

  IPagedPoemRepository get poemRepo => _poemRepo;

  LibraryController({
    required IPagedPoemRepository poemRepo,
    required List<Poem> seedPoems,
  })  : _poemRepo = poemRepo,
        _allSeedPoems = seedPoems,
        super(LibraryState.initial(seedPoems));

  void selectEra(String era) {
    if (state.selectedEra == era) return;
    state = state.copyWith(
      selectedEra: era,
      currentPage: 1,
    );
    _applyFilterAndPaging();
  }

  void updateSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      currentPage: 1,
    );
    _applyFilterAndPaging();
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    DiwanLogger.instance.debug('LibraryController', 'Fetching page ${state.currentPage + 1}');

    await Future.delayed(const Duration(milliseconds: 250));

    final nextPage = state.currentPage + 1;
    final limit = nextPage * state.pageSize;
    final filtered = _getFilteredList();

    final hasMore = limit < filtered.length;
    final slice = filtered.take(limit).toList();

    state = state.copyWith(
      currentPage: nextPage,
      displayedPoems: slice,
      isLoadingMore: false,
      hasMore: hasMore,
    );
  }

  void _applyFilterAndPaging() {
    final sw = Stopwatch()..start();
    final filtered = _getFilteredList();
    final slice = filtered.take(state.currentPage * state.pageSize).toList();
    sw.stop();

    state = state.copyWith(
      displayedPoems: slice,
      totalCount: filtered.length,
      hasMore: slice.length < filtered.length,
      queryDurationMs: sw.elapsedMilliseconds,
    );
  }

  List<Poem> _getFilteredList() {
    return _allSeedPoems.where((p) {
      if (state.selectedEra != 'الكل' && p.era != state.selectedEra) return false;

      if (state.searchQuery.trim().isEmpty) return true;

      final normQuery = ArabicNormalizer.normalize(state.searchQuery);
      final normTitle = ArabicNormalizer.normalize(p.title);
      final normPoet = ArabicNormalizer.normalize(p.poetName);
      final normTheme = ArabicNormalizer.normalize(p.theme);

      return normTitle.contains(normQuery) ||
          normPoet.contains(normQuery) ||
          normTheme.contains(normQuery);
    }).toList();
  }
}

/// موفر متحكم مكتبة الدواوين المفهرسة
final libraryControllerProvider = StateNotifierProvider.family<LibraryController, LibraryState, List<Poem>>(
  (ref, seedPoems) {
    final repo = ref.watch(poemRepositoryProvider);
    return LibraryController(poemRepo: repo, seedPoems: seedPoems);
  },
);
