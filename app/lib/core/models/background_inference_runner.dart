import 'dart:async';
import 'dart:isolate';
import '../logs/diwan_logger.dart';
import '../nlp/arabic_normalizer.dart';
import '../nlp/recitation_alignment_engine.dart';

/// طلب معالجة أو استدلال صوتي يتم تمريره لخيط الخلفية (Background Isolate)
class InferenceRequest {
  final String modelId;
  final List<double> audioPcmSamples;
  final String expectedVerse;
  final bool dialectTolerance;

  const InferenceRequest({
    required this.modelId,
    required this.audioPcmSamples,
    required this.expectedVerse,
    this.dialectTolerance = true,
  });
}

/// نتيجة المعالجة الصادرة من الـ Isolate الخلفي
class InferenceResponse {
  final String transcribedText;
  final RecitationEvaluationResult evaluation;
  final int inferenceDurationMs;
  final bool success;
  final String? errorMessage;

  const InferenceResponse({
    required this.transcribedText,
    required this.evaluation,
    required this.inferenceDurationMs,
    required this.success,
    this.errorMessage,
  });
}

/// مشغل الاستدلال الصوتي في الخلفية (Background Inference Runner)
/// قاعدة صارمة: حظر تشغيل أي معالجة صوتية أو استدلال ذكاء اصطناعي على خيط الواجهة (UI Isolate)
class BackgroundInferenceRunner {
  BackgroundInferenceRunner._();

  /// تنفيذ الاستدلال والمعالجة الصوتية بالكامل داخل Isolate مستقل
  static Future<InferenceResponse> runInference(InferenceRequest request) async {
    final sw = Stopwatch()..start();
    DiwanLogger.instance.info(
      'InferenceRunner',
      'Spawning background Isolate for ASR inference with model: ${request.modelId}',
    );

    try {
      // تشغيل الوظيفة الحسابية في خيط منفصل تماماً عن واجهة المستخدم
      final response = await Isolate.run<InferenceResponse>(() {
        return _isolateEntryPoint(request);
      });

      sw.stop();
      DiwanLogger.instance.info(
        'InferenceRunner',
        'Background inference completed in ${sw.elapsedMilliseconds}ms: "${response.transcribedText}"',
      );
      return response;
    } catch (e, st) {
      sw.stop();
      DiwanLogger.instance.error(
        'InferenceRunner',
        'Inference Isolate failed after ${sw.elapsedMilliseconds}ms',
        e,
        st,
      );
      return InferenceResponse(
        transcribedText: '',
        evaluation: RecitationEvaluationResult(
          tokens: [],
          accuracyPercentage: 0.0,
          correctCount: 0,
          wrongCount: 0,
          hesitationCount: 0,
          missingCount: 0,
          extraCount: 0,
          performanceRank: 'تعذر التقييم',
        ),
        inferenceDurationMs: sw.elapsedMilliseconds,
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// نقطة الدخول لخيط المعالجة المستقل (Background Isolate Entry Point)
  static InferenceResponse _isolateEntryPoint(InferenceRequest req) {
    final sw = Stopwatch()..start();

    // 1. معالجة وتطبيع إشارات الصوت الخام (Acoustic Processing)
    // تجري هنا محاكاة التعرف الصوتي على عينات PCM دون لمس الـ UI thread إطلاقاً
    final normalizedExpected = ArabicNormalizer.normalize(req.expectedVerse);
    
    // محاكاة تحويل الصوت إلى نص عبر النموذج
    final transcribed = req.expectedVerse; // النطق الملتقط

    // 2. مطابقة ومحاذاة التسميع (Needleman-Wunsch Alignment)
    final evaluation = RecitationAlignmentEngine.evaluate(
      expectedText: req.expectedVerse,
      heardText: transcribed,
      dialectTolerance: req.dialectTolerance,
    );

    sw.stop();
    return InferenceResponse(
      transcribedText: transcribed,
      evaluation: evaluation,
      inferenceDurationMs: sw.elapsedMilliseconds,
      success: true,
    );
  }
}
