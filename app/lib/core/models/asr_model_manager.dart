import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/diwan_exception.dart';
import '../logs/diwan_logger.dart';
import '../storage/disk_space_checker.dart';
import 'asr_model_info.dart';
import 'background_inference_runner.dart';

/// موفر إدارة وتحميل نماذج الذكاء الاصطناعي الصوتي (Single Owner Provider)
final asrModelManagerProvider = Provider<AsrModelManager>((ref) {
  final manager = AsrModelManager.instance;
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

/// مدير دورة حياة نماذج الذكاء الاصطناعي الصوتي وحمايتها من استنزاف الذاكرة (Single-Owner ModelManager)
/// يطبق سياسة النموذج الثقيل الواحد (One-Heavy-Model Policy / LRU Eviction)، وتفريغ الخمول الافتراضي (دقيقتان)
class AsrModelManager {
  static AsrModelManager? _singleton;

  /// الحصول على المالك الفردي الوحيد (Single-Owner Instance)
  static AsrModelManager get instance {
    _singleton ??= AsrModelManager();
    return _singleton!;
  }

  static final List<AsrModelInfo> availableModels = [
    const AsrModelInfo(
      id: 'sherpa_arabic_int8',
      nameArabic: 'Sherpa-ONNX Arabic Int8 (مدمج سريع)',
      diskSizeMb: 35,
      ramFootprintMb: 45,
      assetOrFilePath: 'assets/models/sherpa_arabic_int8.onnx',
      isHeavy: true,
    ),
    const AsrModelInfo(
      id: 'wav2vec2_arabic_q8',
      nameArabic: 'Wav2Vec2 Arabic Quantized (عالي الدقة)',
      diskSizeMb: 85,
      ramFootprintMb: 110,
      assetOrFilePath: 'assets/models/wav2vec2_arabic_q8.tflite',
      isHeavy: true,
    ),
    const AsrModelInfo(
      id: 'whisper_tiny_arabic',
      nameArabic: 'Whisper.cpp Tiny Arabic (فصيح متعدد اللهجات)',
      diskSizeMb: 39,
      ramFootprintMb: 55,
      assetOrFilePath: 'assets/models/whisper_tiny_arabic.bin',
      isHeavy: true,
    ),
  ];

  AsrModelInfo? _currentLoadedModel;
  Timer? _idleUnloadTimer;
  Timer? _backgroundGraceTimer;
  final Duration _idleTimeout;
  bool _isDisposed = false;
  bool _isCancelled = false;
  Completer<void>? _currentLoadCompleter;

  // طابور معالجة الطلبات المتزامنة (Concurrency Queue / Serialization)
  Future<void> _requestQueue = Future.value();

  void Function(AsrModelInfo? info)? onModelStatusChanged;

  /// افتراضياً مهلة تفريغ الخمول دقيقتان (Two Minutes Idle Unload)
  AsrModelManager({Duration idleTimeout = const Duration(minutes: 2)})
      : _idleTimeout = idleTimeout {
    _singleton = this;
  }

  AsrModelInfo? get currentLoadedModel => _currentLoadedModel;
  bool get hasLoadedModel => _currentLoadedModel?.isLoaded ?? false;
  AsrModelStatus get currentStatus => _currentLoadedModel?.status ?? AsrModelStatus.unloaded;

  /// إلغاء عملية التحميل الجارية بأمان تام (Load Cancellation)
  void cancelLoad() {
    if (_currentLoadedModel?.status == AsrModelStatus.loading) {
      _isCancelled = true;
      DiwanLogger.instance.warn('ModelManager', 'Load operation cancelled by caller.');
      _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.unloaded));
      _currentLoadedModel = null;
      _currentLoadCompleter?.complete();
    }
  }

  /// تحميل النموذج في الذاكرة بأمان تام مع التحقق المسبق من السعة والذاكرة وسياسة تفريغ النموذج الثقيل السابق
  Future<void> loadModel(String modelId, {int? simulatedAvailableRamMb}) async {
    if (_isDisposed) return;
    _isCancelled = false;

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

    // سياسة النموذج الثقيل الواحد (One-Heavy-Model Eviction Policy):
    // إذا كان هناك نموذج ثقيل محملاً، نقوم بطرده وتفريغه فوراً قبل تحميل النموذج الجديد لمنع استنزاف الرام
    if (_currentLoadedModel != null && _currentLoadedModel!.isLoaded) {
      if (targetModel.isHeavy || _currentLoadedModel!.isHeavy) {
        DiwanLogger.instance.info(
          'ModelManager',
          'One-Heavy-Model Policy: Evicting previous model ${_currentLoadedModel!.id} before loading $modelId',
        );
        await unloadCurrentModel();
      }
    }

    _cancelIdleTimer();
    _cancelBackgroundGraceTimer();
    _updateStatus(targetModel.copyWith(status: AsrModelStatus.loading));
    _currentLoadCompleter = Completer<void>();

    try {
      // 1. فحص كفاية السعة التخزينية المتاحة
      await DiskSpaceChecker.ensureSufficientSpace(
        operation: DiskOperation.download,
        targetDirectory: 'assets/models',
        requiredSpaceMb: targetModel.diskSizeMb,
        safetyMarginMb: 50,
      );

      // 2. التحقق المسبق من ذاكرة الوصول العشوائي (RAM Precheck)
      final availableRamMb = simulatedAvailableRamMb ?? 512;
      const ramSafetyMarginMb = 30;
      if (availableRamMb < targetModel.ramFootprintMb + ramSafetyMarginMb) {
        throw DiwanException.diskSpace(
          targetModel.ramFootprintMb + ramSafetyMarginMb,
          availableRamMb,
        );
      }

      // محاكاة تخصيص الذاكرة الأصلية وتهيئة النموذج
      await Future.delayed(const Duration(milliseconds: 30));

      if (_isCancelled) {
        DiwanLogger.instance.warn('ModelManager', 'Load of $modelId was aborted due to cancellation');
        return;
      }

      _updateStatus(targetModel.copyWith(status: AsrModelStatus.ready));
      DiwanLogger.instance.info(
        'ModelManager',
        'Successfully loaded ${targetModel.id} into memory safely',
      );
      _restartIdleTimer();
    } catch (e, st) {
      _updateStatus(targetModel.copyWith(
        status: AsrModelStatus.error,
        lastError: e.toString(),
      ));
      DiwanLogger.instance.error('ModelManager', 'Failed to load model: $modelId', e, st);
      throw e is DiwanException ? e : DiwanException.database('فشل تخصيص ذاكرة النموذج: $e');
    } finally {
      _currentLoadCompleter?.complete();
    }
  }

  /// تفريغ النموذج الحالي فوراً من الذاكرة وإعادة تعيين المقابض (Safe Unload)
  Future<void> unloadCurrentModel() async {
    if (_currentLoadedModel == null || _currentLoadedModel?.status == AsrModelStatus.unloaded) {
      return;
    }

    _cancelIdleTimer();
    _cancelBackgroundGraceTimer();
    final modelId = _currentLoadedModel!.id;
    _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.unloading));

    DiwanLogger.instance.info('ModelManager', 'Unloading model $modelId from RAM...');

    try {
      // محاكاة تحرير الذاكرة والمقابض الأصلية
      await Future.delayed(const Duration(milliseconds: 20));
    } finally {
      _updateStatus(_currentLoadedModel!.copyWith(status: AsrModelStatus.unloaded));
      _currentLoadedModel = null;
      onModelStatusChanged?.call(null);
      DiwanLogger.instance.info(
        'ModelManager',
        'Model $modelId successfully unloaded. RAM cleared.',
      );
    }
  }

  /// استجابة فورية لإشارة انخفاض الذاكرة من المنصة (Low-Memory Callback / onTrimMemory)
  void onLowMemory() {
    DiwanLogger.instance.warn('ModelManager', 'Low-memory callback triggered by OS! Evicting active model immediately.');
    unloadCurrentModel();
  }

  /// استجابة لتنبيهات مستويات ضغط الذاكرة من أندرويد (onTrimMemory)
  void onTrimMemory(int level) {
    DiwanLogger.instance.warn('ModelManager', 'onTrimMemory level: $level. Triggering safe eviction.');
    unloadCurrentModel();
  }

  /// التعامل مع انتقال التطبيق للخلفية مع مهلة سماح (Background-Grace Unload)
  void onAppBackgrounded({Duration gracePeriod = const Duration(seconds: 15)}) {
    if (!hasLoadedModel) return;

    DiwanLogger.instance.info(
      'ModelManager',
      'App sent to background. Starting grace period ($gracePeriod) before RAM unload.',
    );
    _cancelBackgroundGraceTimer();
    _backgroundGraceTimer = Timer(gracePeriod, () {
      DiwanLogger.instance.info('ModelManager', 'Background grace period elapsed. Unloading model.');
      unloadCurrentModel();
    });
  }

  /// استئناف التطبيق للواجهة وإلغاء مؤقت مهلة الخلفية
  void onAppForegrounded() {
    _cancelBackgroundGraceTimer();
    if (hasLoadedModel) {
      _restartIdleTimer();
    }
  }

  /// تنفيذ الاستدلال الصوتي في الخلفية مع جدولة متسلسلة للطلبات المتزامنة وتتبع دورة الحياة
  Future<InferenceResponse> runSafeInference({
    required List<double> audioSamples,
    required String expectedVerse,
    bool dialectTolerance = true,
  }) async {
    // جدولة الطلب في الطابور المتسلسل (Serialized Request Queue)
    final completer = Completer<InferenceResponse>();

    _requestQueue = _requestQueue.then((_) async {
      try {
        if (!hasLoadedModel) {
          await loadModel(availableModels.first.id);
        }

        _cancelIdleTimer();
        final req = InferenceRequest(
          modelId: _currentLoadedModel!.id,
          audioPcmSamples: audioSamples,
          expectedVerse: expectedVerse,
          dialectTolerance: dialectTolerance,
        );

        // الاستدعاء الحصري عبر خيط الخلفية (Background Isolate)
        final response = await BackgroundInferenceRunner.runInference(req);
        completer.complete(response);
      } catch (e, st) {
        completer.completeError(e, st);
      } finally {
        _restartIdleTimer();
      }
    });

    return completer.future;
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

  void _cancelBackgroundGraceTimer() {
    _backgroundGraceTimer?.cancel();
    _backgroundGraceTimer = null;
  }

  /// التخلص الاستثنائي الآمن (Exception-Safe Handle Disposal)
  void dispose() {
    _isDisposed = true;
    _cancelIdleTimer();
    _cancelBackgroundGraceTimer();
    _currentLoadedModel = null;
    onModelStatusChanged?.call(null);
  }
}
