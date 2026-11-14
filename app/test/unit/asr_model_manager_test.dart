import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/models/asr_model_info.dart';
import 'package:diwan/core/models/asr_model_manager.dart';

void main() {
  group('AsrModelManager & Safe Memory Lifecycle Tests', () {
    late AsrModelManager manager;

    setUp(() {
      manager = AsrModelManager(idleTimeout: const Duration(milliseconds: 200));
    });

    tearDown(() {
      manager.dispose();
    });

    test('التحميل المبدئي يكون غير محمل (unloaded)', () {
      expect(manager.currentLoadedModel, isNull);
      expect(manager.hasLoadedModel, isFalse);
    });

    test('تحميل النموذج بأمان وتحديث الحالة إلى ready', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);
      expect(manager.currentLoadedModel?.status, equals(AsrModelStatus.ready));
      expect(manager.currentLoadedModel?.id, equals('sherpa_arabic_int8'));
    });

    test('تفريغ النموذج الآمن يحرر الذاكرة ويعيد تعيين الحالة إلى unloaded', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      await manager.unloadCurrentModel();
      expect(manager.hasLoadedModel, isFalse);
      expect(manager.currentLoadedModel, isNull);
    });

    test('تبديل النموذج يفرغ النموذج السابق أولاً لمنع مضاعفة الذاكرة المستهلكة', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.currentLoadedModel?.id, equals('sherpa_arabic_int8'));

      await manager.loadModel('whisper_tiny_arabic');
      expect(manager.currentLoadedModel?.id, equals('whisper_tiny_arabic'));
      expect(manager.currentLoadedModel?.status, equals(AsrModelStatus.ready));
    });

    test('التفريغ التلقائي للنموذج عند انتهاء مهلة الخمول (Auto Idle Unload)', () async {
      await manager.loadModel('sherpa_arabic_int8');
      expect(manager.hasLoadedModel, isTrue);

      // انتظار انقضاء مهلة الخمول (200ms)
      await Future.delayed(const Duration(milliseconds: 300));
      expect(manager.hasLoadedModel, isFalse);
    });

    test('تنفيذ الاستدلال الصوتي في الخلفية دون حظر الواجهة (Off-UI Isolate)', () async {
      const verse = 'الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي';
      final dummyPcm = List<double>.filled(16000, 0.0);

      final response = await manager.runSafeInference(
        audioSamples: dummyPcm,
        expectedVerse: verse,
      );

      expect(response.success, isTrue);
      expect(response.evaluation.accuracyPercentage, equals(100.0));
      expect(response.transcribedText, contains('الخيل'));
    });
  });
}
