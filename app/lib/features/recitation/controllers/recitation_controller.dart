import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/logs/diwan_logger.dart';
import '../../../core/models/asr_model_manager.dart';
import '../../../core/nlp/recitation_alignment_engine.dart';

class RecitationState {
  final bool isRecording;
  final bool isAnalyzing;
  final int activeWordIndex;
  final List<String> spokenWords;
  final RecitationEvaluationResult? evaluationResult;
  final String statusPrompt;

  const RecitationState({
    required this.isRecording,
    required this.isAnalyzing,
    required this.activeWordIndex,
    required this.spokenWords,
    this.evaluationResult,
    required this.statusPrompt,
  });

  factory RecitationState.initial() {
    return const RecitationState(
      isRecording: false,
      isAnalyzing: false,
      activeWordIndex: 0,
      spokenWords: [],
      statusPrompt: 'اضغط على اللاقط وابدأ التسميع بصوت فصيح',
    );
  }

  RecitationState copyWith({
    bool? isRecording,
    bool? isAnalyzing,
    int? activeWordIndex,
    List<String>? spokenWords,
    RecitationEvaluationResult? evaluationResult,
    String? statusPrompt,
  }) {
    return RecitationState(
      isRecording: isRecording ?? this.isRecording,
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      activeWordIndex: activeWordIndex ?? this.activeWordIndex,
      spokenWords: spokenWords ?? this.spokenWords,
      evaluationResult: evaluationResult ?? this.evaluationResult,
      statusPrompt: statusPrompt ?? this.statusPrompt,
    );
  }
}

class RecitationController extends StateNotifier<RecitationState> {
  final AsrModelManager _modelManager;
  Timer? _simulationTimer;

  RecitationController({required AsrModelManager modelManager})
      : _modelManager = modelManager,
        super(RecitationState.initial());

  void startRecording({required String expectedVerse}) {
    state = state.copyWith(
      isRecording: true,
      isAnalyzing: false,
      activeWordIndex: 0,
      spokenWords: [],
      evaluationResult: null,
      statusPrompt: 'ديوان ينصت إلى إلقائك بخشوع...',
    );

    DiwanLogger.instance.info('RecitationController', 'Started recording session');

    // محاكاة استلام عينات الصوت
    final words = expectedVerse.split(RegExp(r'\s+'));
    var currentIdx = 0;

    _simulationTimer = Timer.periodic(const Duration(milliseconds: 600), (timer) {
      if (currentIdx < words.length) {
        state = state.copyWith(
          activeWordIndex: currentIdx + 1,
          spokenWords: [...state.spokenWords, words[currentIdx]],
        );
        currentIdx++;
      } else {
        timer.cancel();
        stopAndEvaluate(expectedVerse: expectedVerse);
      }
    });
  }

  Future<void> stopAndEvaluate({
    required String expectedVerse,
    bool dialectTolerance = true,
  }) async {
    _simulationTimer?.cancel();
    _simulationTimer = null;

    state = state.copyWith(
      isRecording: false,
      isAnalyzing: true,
      statusPrompt: 'جاري الاستدلال والمحاذاة في Isolate الخلفية...',
    );

    DiwanLogger.instance.info(
      'RecitationController',
      'Running inference safely off-UI isolate',
    );

    // تشغيل الاستدلال في خيط خلفي (Background Isolate) عبر مدير النماذج
    final dummyPcm = List<double>.filled(16000, 0.0);
    final response = await _modelManager.runSafeInference(
      audioSamples: dummyPcm,
      expectedVerse: expectedVerse,
      dialectTolerance: dialectTolerance,
    );

    state = state.copyWith(
      isAnalyzing: false,
      evaluationResult: response.evaluation,
      statusPrompt: 'اكتمل تقييم التسميع بنجاح',
    );

    DiwanLogger.instance.info(
      'RecitationController',
      'Evaluation completed: ${response.evaluation.accuracyPercentage}% (${response.evaluation.performanceRank})',
    );
  }

  void reset() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    state = RecitationState.initial();
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }
}

final recitationControllerProvider = StateNotifierProvider<RecitationController, RecitationState>((ref) {
  final modelManager = ref.watch(asrModelManagerProvider);
  return RecitationController(modelManager: modelManager);
});
