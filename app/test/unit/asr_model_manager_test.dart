import 'dart:isolate';
import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/models/asr_model_info.dart';
import 'package:diwan/core/models/asr_model_manager.dart';
import 'package:diwan/core/models/background_inference_runner.dart';

void main() {
  group('AsrModelManager & Safe Memory Lifecycle Tests (Gate 5)', () {
    late AsrModelManager manager;

    setUp(() {
      manager = AsrModelManager(idleTimeout: const Duration(milliseconds: 200));
    });

    tearDown(() {
      manager.dispose();
    });

    test('(1) إثبات طرد النموذج الثقيل الأول عند تحميل نموذج ثقيل ثانٍ (Second-Heavy-Model Eviction)', () async {
      // 1. تحميل النموذج الثقيل الأول
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.currentLoadedModel?.id, equals('sherpa_arabic_int8'));
      expect(manager.hasLoadedModel, isTrue);

      // 2. تحميل نموذج ثقيل ثانٍ: يتم إخلاء وطرد الأول فوراً لحفظ الذاكرة
      await manager.loadModel('wav2vec2_arabic_q8');
      expect(manager.currentLoadedModel?.id, equals('wav2vec2_arabic_q8'));
      expect(manager.currentLoadedModel?.status, equals(AsrModelStatus.ready));
    });

    test('(2) إثبات تفريغ النموذج عند انقضاء مهلة الخمول (Idle-Timeout Unload)', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // انتظار انقضاء مهلة الخمول المحددة (200ms)
      await Future.delayed(const Duration(milliseconds: 300));
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(3) إثبات تفريغ النموذج عند ضغط الذاكرة ونفادها (Memory-Pressure Unload)', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // محاكاة إشعار النظام بانخفاض الذاكرة (onLowMemory)
      manager.onLowMemory();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(4) إثبات تسلسل وجدولة الطلبات المتزامنة في طابور محمي (Serialized Concurrency)', () async {
      await manager.loadModel('sherpa_arabic_int8');

      final dummyPcm = List<double>.filled(16000, 0.0);
      const verse = 'الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي';

      // إرسال طلبين في اللحظة ذاتها
      final req1 = manager.runSafeInference(audioSamples: dummyPcm, expectedVerse: verse);
      final req2 = manager.runSafeInference(audioSamples: dummyPcm, expectedVerse: verse);

      final results = await Future.wait([req1, req2]);
      expect(results[0].success, isTrue);
      expect(results[1].success, isTrue);
    });

    test('(5) إثبات التخلص الآمن من المقابض والموارد عند حدوث خطأ (Handle Disposal on Error)', () async {
      // محاكاة تحميل نموذج مع فشل فحص الذاكرة (RAM Precheck Failure)
      try {
        await manager.loadModel('wav2vec2_arabic_q8', simulatedAvailableRamMb: 20); // 20MB متاح فقط
      } catch (e) {
        // متوقع حدوث استثناء لعدم كفاية الرام
      }

      expect(manager.currentStatus, equals(AsrModelStatus.error));
      expect(manager.hasLoadedModel, isFalse);

      // استدعاء التخلص الآمن
      manager.dispose();
      expect(manager.currentLoadedModel, isNull);
    });

    test('(6) إثبات تفريغ النموذج بعد مهلة السماح عند انتقال التطبيق للخلفية (Background-Grace Unload)', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // انتقال التطبيق للخلفية مع مهلة سماح قصيرة 100ms
      manager.onAppBackgrounded(gracePeriod: const Duration(milliseconds: 100));

      // قبل انقضاء المهلة: لا يزال النموذج محملاً
      await Future.delayed(const Duration(milliseconds: 40));
      expect(manager.hasLoadedModel, isTrue);

      // بعد انقضاء المهلة: يتم التفريغ التلقائي
      await Future.delayed(const Duration(milliseconds: 120));
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(7) إثبات إمكانية إلغاء عملية التحميل بأمان (Load Cancellation)', () async {
      final loadFuture = manager.loadModel('whisper_tiny_arabic');
      manager.cancelLoad();

      await loadFuture;
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(8) تأكيد فشل استدعاء نقطة دخول الاستدلال عند تشغيلها على خيط الـ UI الرئيسي (Assertion Failure)', () {
      final receivePort = ReceivePort();

      // بما أننا على خيط الاختبار/الواجهة الرئيسي فإن isRootIsolate تكون true
      expect(
        () => BackgroundInferenceRunner.nativeInferenceEntryPoint([
          receivePort.sendPort,
          const InferenceRequest(
            modelId: 'sherpa_arabic_int8',
            audioPcmSamples: [],
            expectedVerse: 'وَتَدَّعِي حُبَّ سَيْفِ الدَّوْلَةِ الأُمَمُ',
          ),
        ]),
        throwsA(isA<AssertionError>()),
      );

      receivePort.close();
    });
  });
}
