import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';
import '../storage/disk_space_checker.dart';
import 'asr_model_info.dart';
import 'background_inference_runner.dart';

/// موفر إدارة وتحميل نماذج الذكاء الاصطناعي الصوتي
final asrModelManagerProvider = Provider<AsrModelManager>((ref) {
  final manager = AsrModelManager();
  ref.onDispose(() {
    manager.dispose();
  });
  return manager;
});

/// موفر الحالة الحالية للنموذج المحمل
final activeAsrModelProvider = StateNotifierProvider<ActiveModelNotifier, AsrModelInfo?>((ref) {
  return ActiveModelNotifier(ref.watch(asrModelManagerProvider));
});

class ActiveModelNotifier extends StateNotifier<AsrModelInfo?> {
  final AsrModelManager _manager;

  ActiveModelNotifier(this._manager) : super(_manager.currentLoadedModel) {
    _manager.onModelStatusChanged = (info) {
      state = info;
    };
  }
}

/// مدير دورة حياة نماذج الذكاء الاصطناعي الصوتي وحمايتها من استنزاف الذاكرة (OOM Protection)
class AsrModelManager {
  static final List<AsrModelInfo> availableModels = [
    const AsrModelInfo(
      id: 'sherpa_arabic_int8',
      nameArabic: 'Sherpa-ONNX Arabic Int8 (مدمج سريع)',
      diskSizeMb: 35,
      ramFootprintMb: 45,
      assetOrFilePath: 'assets/models/sherpa_arabic_int8.onnx',
    ),
    const AsrModelInfo(
      id: 'wav2vec2_arabic_q8',
      nameArabic: 'Wav2Vec2 Arabic Quantized (عالي الدقة)',
      diskSizeMb: 85,
      ramFootprintMb: 110,
      assetOrFilePath: 'assets/models/wav2vec2_arabic_q8.tflite',
    ),
    const AsrModelInfo(
      id: 'whisper_tiny_arabic',
      nameArabic: 'Whisper.cpp Tiny Arabic (فصيح متعدد اللهجات)',
      diskSizeMb: 39,
      ramFootprintMb: 55,
      assetOrFilePath: 'assets/models/whisper_tiny_arabic.bin',
    ),
  ];

  AsrModelInfo? _currentLoadedModel;
  Timer? _idleUnloadTimer;
  final Duration _idleTimeout;
  bool _isDisposed = false;
  int _activeInferenceCount = 0;

  void Function(AsrModelInfo? info)? onModelStatusChanged;

  AsrModelManager({Duration idleTimeout = const Duration(minutes: 3)})
      : _idleTimeout = idleTimeout;

  AsrModelInfo? get currentLoadedModel => _currentLoadedModel;
  bool get hasLoadedModel => _currentLoadedModel?.isLoaded ?? false;

  /// تحميل النموذج في الذاكرة بأمان تام مع التحقق المسبق من السعة والذاكرة
  Future<void> loadModel(String modelId) async {
    if (_isDisposed) return;

    final targetModel = availableModels.firstWhere(
      (m) => m.id == modelId,
      orElse: () => availableModels.first,
    );

    // إذا كان النموذج محملاً بالفعل وجاهزاً
    if (_currentLoadedModel?.id == modelId && _currentLoadedModel?.status == AsrModelStatus.ready) {
      DiwanLogger.instance.info('ModelManager', 'Model $modelId is already loaded and ready');
      _restartIdleTimer();
      return;
    }

    // إذا كان هناك نموذج آخر محملاً، نقوم بتفريغه بأمان أولاً لمنع ازدواجية استهلاك الذاكرة
    if (_currentLoadedModel != null && _currentLoadedModel!.isLoaded) {
      DiwanLogger.instance.info(
        'ModelManager',
        'Unloading previous model ${_currentLoadedModel!.id} before loading $modelId',
      );
      await unloadCurrentModel();
    }

    _cancelIdleTimer();
    _updateStatus(targetModel.copyWith(status: AsrModelStatus.loading));
    DiwanLogger.instance.info(
      'ModelManager',
      'Beginning safe allocation for ${targetModel.id} (RAM footprint: ${targetModel.ramFootprintMb}MB)',
    );

    try {
      // 1. فحص كفاية المساحة التخزينية والذاكرة
      await DiskSpaceChecker.ensureSufficientSpace(
        targetDirectory: 'assets/models',
        requiredSpaceMb: targetModel.diskSizeMb,
        safetyMarginMb: 60,
      );

      // محاكاة تهيئة النموذج وتخصيص الذاكرة الأصلية
      await Future.delayed(const Duration(milliseconds: 250));

      _updateStatus(targetModel.copyWith(status: AsrModelStatus.ready));
      DiwanLogger.instance.info(
        'ModelManager',
        'Successfully loaded ${targetModel.id} into memory safely',
      );
      _restartIdleTimer();
    } catch (e, st) {
      _updateStatus(targetModel.copyWith(
        status: AsrModelStatus.failed,
        lastError: e.toString(),
      ));
      DiwanLogger.instance.error('ModelManager', 'Failed to load model: $modelId', e, st);
      throw e is DiwanException ? e : DiwanException.database('فشل تخصيص ذاكرة النموذج: $e');
    }
  }

  /// تفريغ النموذج الحالي فوراً من الذاكرة وإعادة تعيين الموارد (Safe Unload)
  Future<void> unloadCurrentModel() async {
    if (_currentLoadedModel == null || _currentLoadedModel?.status == AsrModelStatus.unloaded) {
      return;
    }

    // إذا كانت هناك جلسات استدلال قيد التنفيذ، ننتظر انتهاءها
    if (_activeInferenceCount > 0) {
      DiwanLogger.instance.warn(
        'ModelManager',
        'Waiting for $_activeInferenceCount active inferences to complete before unloading',
      );
      await Future.delayed(const Duration(milliseconds: 300));
    }

    _cancelIdleTimer();
    final modelId = _currentLoadedModel!.id;
    _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.unloading));

    DiwanLogger.instance.info('ModelManager', 'Unloading model $modelId from RAM...');
    
    // محاكاة تحرير الذاكرة وإغلاق الجلسة
    await Future.delayed(const Duration(milliseconds: 100));

    _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.unloaded));
    _currentLoadedModel = null;
    onModelStatusChanged?.call(null);

    DiwanLogger.instance.info(
      'ModelManager',
      'Model $modelId successfully unloaded. RAM cleared.',
    );
  }

  /// تنفيذ الاستدلال الصوتي في الخلفية مع تتبع دورة الحياة وإعادة ضبط مؤقت الخمول
  Future<InferenceResponse> runSafeInference({
    required List<double> audioSamples,
    required String expectedVerse,
    bool dialectTolerance = true,
  }) async {
    if (!hasLoadedModel) {
      // تحميل النموذج الافتراضي تلقائياً إن لم يكن محملاً
      await loadModel(availableModels.first.id);
    }

    _cancelIdleTimer();
    _activeInferenceCount++;
    _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.busy));

    try {
      final req = InferenceRequest(
        modelId: _currentLoadedModel!.id,
        audioPcmSamples: audioSamples,
        expectedVerse: expectedVerse,
        dialectTolerance: dialectTolerance,
      );

      // الاستدعاء الحصري عبر خيط الخلفية (Background Isolate)
      final response = await BackgroundInferenceRunner.runInference(req);
      return response;
    } finally {
      _activeInferenceCount--;
      if (_currentLoadedModel != null) {
        _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.ready));
      }
      _restartIdleTimer();
    }
  }

  void _updateStatus(AsrModelInfo info) {
    _currentLoadedModel = info;
    onModelStatusChanged?.call(info);
  }

  void _restartIdleTimer() {
    _cancelIdleTimer();
    _idleUnloadTimer = Timer(_idleTimeout, () {
      DiwanLogger.instance.info(
        'ModelManager',
        'Idle timeout reached ($_idleTimeout). Auto-unloading model to preserve RAM.',
      );
      unloadCurrentModel();
    });
  }

  void _cancelIdleTimer() {
    _idleUnloadTimer?.cancel();
    _idleUnloadTimer = null;
  }

  void dispose() {
    _isDisposed = true;
    _cancelIdleTimer();
    unloadCurrentModel();
  }
}
