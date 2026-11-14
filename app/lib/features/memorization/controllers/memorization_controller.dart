import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/data/repositories/user_data_repository.dart';
import '../../../core/logs/diwan_logger.dart';
import '../../../core/srs/spaced_repetition_engine.dart';

enum ClozeMode { rhyme, ajuz, cloze, full }

class MemorizationState {
  final ClozeMode mode;
  final Set<int> revealedIndices;
  final bool showFirstLetterHint;
  final SrsCardState cardState;
  final Map<SrsRating, String> intervalPreviews;

  const MemorizationState({
    required this.mode,
    required this.revealedIndices,
    required this.showFirstLetterHint,
    required this.cardState,
    required this.intervalPreviews,
  });

  factory MemorizationState.initial(int verseId) {
    final initialCard = SrsCardState.initial(verseId);
    return MemorizationState(
      mode: ClozeMode.rhyme,
      revealedIndices: const {},
      showFirstLetterHint: false,
      cardState: initialCard,
      intervalPreviews: _calculatePreviews(initialCard),
    );
  }

  static Map<SrsRating, String> _calculatePreviews(SrsCardState card) {
    final againCard = SpacedRepetitionEngine.calculateNextState(card, SrsRating.again);
    final hardCard = SpacedRepetitionEngine.calculateNextState(card, SrsRating.hard);
    final goodCard = SpacedRepetitionEngine.calculateNextState(card, SrsRating.good);
    final easyCard = SpacedRepetitionEngine.calculateNextState(card, SrsRating.easy);

    return {
      SrsRating.again: againCard.intervalDays == 0 ? '١٠ دقائق' : '${againCard.intervalDays} يوم',
      SrsRating.hard: '${hardCard.intervalDays} يوم',
      SrsRating.good: '${goodCard.intervalDays} يوم',
      SrsRating.easy: '${easyCard.intervalDays} يوم',
    };
  }

  MemorizationState copyWith({
    ClozeMode? mode,
    Set<int>? revealedIndices,
    bool? showFirstLetterHint,
    SrsCardState? cardState,
    Map<SrsRating, String>? intervalPreviews,
  }) {
    return MemorizationState(
      mode: mode ?? this.mode,
      revealedIndices: revealedIndices ?? this.revealedIndices,
      showFirstLetterHint: showFirstLetterHint ?? this.showFirstLetterHint,
      cardState: cardState ?? this.cardState,
      intervalPreviews: intervalPreviews ?? this.intervalPreviews,
    );
  }
}

class MemorizationController extends StateNotifier<MemorizationState> {
  final IUserDataRepository _userDataRepo;

  MemorizationController({
    required int verseId,
    required IUserDataRepository userDataRepo,
  })  : _userDataRepo = userDataRepo,
        super(MemorizationState.initial(verseId));

  void setClozeMode(ClozeMode mode) {
    state = state.copyWith(
      mode: mode,
      revealedIndices: const {},
    );
  }

  void toggleFirstLetterHint() {
    state = state.copyWith(showFirstLetterHint: !state.showFirstLetterHint);
  }

  void toggleWordPeek(int globalWordIndex) {
    final current = Set<int>.from(state.revealedIndices);
    if (current.contains(globalWordIndex)) {
      current.remove(globalWordIndex);
    } else {
      current.add(globalWordIndex);
    }
    state = state.copyWith(revealedIndices: current);
  }

  Future<void> submitRating(SrsRating rating) async {
    final nextCard = SpacedRepetitionEngine.calculateNextState(state.cardState, rating);
    await _userDataRepo.saveSrsCard(nextCard);

    DiwanLogger.instance.info(
      'MemorizationController',
      'Card ${nextCard.cardId} updated: rating=$rating, next interval=${nextCard.intervalDays} days',
    );

    state = state.copyWith(
      cardState: nextCard,
      intervalPreviews: MemorizationState._calculatePreviews(nextCard),
      revealedIndices: const {},
    );
  }
}

final memorizationControllerProvider = StateNotifierProvider.family<MemorizationController, MemorizationState, int>(
  (ref, verseId) {
    final repo = ref.watch(userDataRepositoryProvider);
    return MemorizationController(verseId: verseId, userDataRepo: repo);
  },
);
