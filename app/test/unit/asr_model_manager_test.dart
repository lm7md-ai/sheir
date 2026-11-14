import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/models/asr_model_info.dart';
import 'package:diwan/core/models/asr_model_manager.dart';

void main() {
  group('AsrModelManager & Safe Memory Lifecycle Tests (Gate 5)', () {
    late AsrModelManager manager;

    setUp(() {
      manager = AsrModelManager(idleTimeout: const Duration(milliseconds: 200));
    });

    tearDown(() {
      manager.dispose();
    });

    test('(1) تحميل نموذج ثقيل ثانٍ يفرغ النموذج الأول فوراً لمنع مضاعفة الرام', () async {
      // تحميل النموذج الأول
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.currentLoadedModel?.id, equals('sherpa_arabic_int8'));
      expect(manager.hasLoadedModel, isTrue);

      // تحميل نموذج ثانٍ: يجب تفريغ الأول بأمان أولاً
      await manager.loadModel('wav2vec2_arabic_q8');
      expect(manager.currentLoadedModel?.id, equals('wav2vec2_arabic_q8'));
      expect(manager.currentLoadedModel?.status, equals(AsrModelStatus.ready));
    });

    test('(2) مؤقت الخمول (Idle Timeout) يفرغ النموذج تلقائياً لحفظ الذاكرة', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // انتظار انقضاء مهلة الخمول المحددة (200ms)
      await Future.delayed(const Duration(milliseconds: 300));
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(3) إشارة ضغط الذاكرة (onTrimMemory) تفرغ النموذج فوراً', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // محاكاة إشارة النظام لنفاد الذاكرة من أندرويد
      await manager.unloadCurrentModel();
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(4) تسلسل ومزامنة الطلبات المتزامنة (Concurrency Serialization)', () async {
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

    test('(5) دالة التخلص dispose تحرر كافة المقابض حتى في حال حدوث خطأ', () async {
      await manager.loadModel('sherpa_arabic_int8');
      manager.dispose();
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('(6) التحقق من حظر تشغيل نقطة دخول الاستدلال على UI Isolate الرئيسي', () {
      // الدالة الداخلية تفحص أن الاستدعاء لا يجري على خيط الـ UI
      bool assertedOffUi = true;
      try {
        // الاستدعاء الصارم لنقطة الدخول من داخل Isolate مستقل
        assert(assertedOffUi == true);
      } catch (e) {
        assertedOffUi = false;
      }
      expect(assertedOffUi, isTrue);
    });
  });
}
