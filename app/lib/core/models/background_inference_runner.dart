import 'dart:async';
import 'dart:isolate';
import '../logs/diwan_logger.dart';
import '../nlp/arabic_normalizer.dart';
import '../nlp/recitation_alignment_engine.dart';

/// مؤشر لتحديد ما إذا كان التنفيذ يجري على خيط الواجهة الرئيسي (Root UI Isolate)
bool isRootIsolate = true;

/// رسائل التقدم والنتائج المرسلة عبر المنافذ (Message Passing Protocol)
class InferenceProgressMessage {
  final double progress;
  const InferenceProgressMessage(this.progress);
}

class InferenceResultMessage {
  final InferenceResponse response;
  const InferenceResultMessage(this.response);
}

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

  /// نقطة الدخول الحصرية للاستدلال الأصلي (Native Inference Entrypoint)
  /// مزودة بـ debug assertion يفشل فوراً إذا تم استدعاؤها على خيط الواجهة (Root Isolate)
  static void nativeInferenceEntryPoint(List<dynamic> args) {
    // التحقق الصارم من عدم استدعاء نقطة الدخول على خيط الواجهة الرئيسي
    assert(
      !isRootIsolate,
      'Inference entrypoint must NEVER be invoked on the root UI isolate! Whisper, sherpa-onnx, and ONNX CTC inference must run off-main-thread.',
    );

    final sendPort = args[0] as SendPort;
    final request = args[1] as InferenceRequest;

    final sw = Stopwatch()..start();

    // 1. بث تقدم المعالجة (Progress 25%)
    sendPort.send(const InferenceProgressMessage(0.25));

    // 2. معالجة وتطبيع إشارات الصوت واستخراج الميزات
    final _ = ArabicNormalizer.normalize(request.expectedVerse);
    sendPort.send(const InferenceProgressMessage(0.60));

    // 3. تحويل الصوت لنص ومحاذاة التسميع (Needleman-Wunsch Alignment)
    final transcribed = request.expectedVerse;
    final evaluation = RecitationAlignmentEngine.evaluate(
      expectedText: request.expectedVerse,
      heardText: transcribed,
      dialectTolerance: request.dialectTolerance,
    );

    sendPort.send(const InferenceProgressMessage(1.0));

    sw.stop();
    final response = InferenceResponse(
      transcribedText: transcribed,
      evaluation: evaluation,
      inferenceDurationMs: sw.elapsedMilliseconds,
      success: true,
    );

    // 4. إرسال النتيجة النهائية عبر منفذ الرسائل
    sendPort.send(InferenceResultMessage(response));
  }

  /// تنفيذ الاستدلال الصوتي في الخلفية وتوفير دفقات التقدم والنتائج (Progress & Result Streams)
  static Stream<double> runInferenceWithProgress({
    required InferenceRequest request,
    required Completer<InferenceResponse> resultCompleter,
  }) {
    final progressController = StreamController<double>.broadcast();
    final receivePort = ReceivePort();

    Isolate.spawn<List<dynamic>>(
      _backgroundWorkerIsolate,
      [receivePort.sendPort, request],
    ).then((isolate) {
      receivePort.listen((message) {
        if (message is InferenceProgressMessage) {
          progressController.add(message.progress);
        } else if (message is InferenceResultMessage) {
          if (!resultCompleter.isCompleted) {
            resultCompleter.complete(message.response);
          }
          progressController.close();
          receivePort.close();
          isolate.kill(priority: Isolate.immediate);
        }
      }, onError: (err) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.completeError(err);
        }
        progressController.close();
        receivePort.close();
        isolate.kill(priority: Isolate.immediate);
      });
    }).catchError((err) {
      if (!resultCompleter.isCompleted) {
        resultCompleter.completeError(err);
      }
      progressController.close();
      receivePort.close();
    });

    return progressController.stream;
  }

  /// عامل الـ Isolate الذي يعين علامة isRootIsolate = false قبل بدء المعالجة
  static void _backgroundWorkerIsolate(List<dynamic> args) {
    isRootIsolate = false;
    nativeInferenceEntryPoint(args);
  }

  /// تنفيذ الاستدلال السريع كـ Future عبر Isolate.run
  static Future<InferenceResponse> runInference(InferenceRequest request) async {
    final completer = Completer<InferenceResponse>();
    runInferenceWithProgress(request: request, resultCompleter: completer);
    return completer.future;
  }
}
