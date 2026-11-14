import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/verse.dart';
import '../../core/nlp/recitation_alignment_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../design_system/record_button.dart';
import 'controllers/recitation_controller.dart';

/// شاشة أستوديو التسميع الذكي
/// تفصل منطق المعالجة الصوتية والاستدلال في خيط الخلفية (Background Isolate) بعيداً عن الواجهة
class RecitationScreen extends ConsumerWidget {
  final Verse verse;
  final Function(RecitationEvaluationResult result)? onEvaluationComplete;
  final VoidCallback? onCancel;

  const RecitationScreen({
    super.key,
    required this.verse,
    this.onEvaluationComplete,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diwan = context.diwan;
    final state = ref.watch(recitationControllerProvider);
    final controller = ref.read(recitationControllerProvider.notifier);

    final expectedText = '${verse.sadr} ${verse.ajuz}';
    final allWords = expectedText.split(RegExp(r'\s+'));

    // الاستماع لاكتمال التقييم
    ref.listen<RecitationState>(recitationControllerProvider, (prev, next) {
      if (next.evaluationResult != null && !next.isAnalyzing && !next.isRecording) {
        onEvaluationComplete?.call(next.evaluationResult!);
      }
    });

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: diwan.textSecondary),
          onPressed: () {
            controller.reset();
            (onCancel ?? () => Navigator.maybePop(context))();
          },
        ),
        title: Text(
          'أستوديو التسميع والإلقاء',
          style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // نص البيت المركز عالي التباين مع تحديث الكلمات لحظياً
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Wrap(
                textDirection: TextDirection.rtl,
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 12,
                children: allWords.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final word = entry.value;
                  final isSpoken = idx < state.activeWordIndex;
                  final isCurrent = idx == state.activeWordIndex && state.isRecording;

                  Color textColor = diwan.textMuted;
                  if (isSpoken) textColor = diwan.primary;
                  if (isCurrent) textColor = diwan.accentGold;

                  return AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: DiwanTypography.verseStyle(
                      color: textColor,
                      fontSize: isCurrent ? 26 : 24,
                      fontWeight: (isSpoken || isCurrent) ? FontWeight.bold : FontWeight.normal,
                    ),
                    child: Text(word, textDirection: TextDirection.rtl),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // مؤشر الحالة النصي
            Text(
              state.statusPrompt,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.uiBody(
                color: state.isAnalyzing ? diwan.primary : diwan.textSecondary,
                fontSize: 13,
              ),
            ),

            if (state.isAnalyzing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(diwan.accentGold),
                ),
              ),
            ],

            const Spacer(),

            // زر التسجيل التفاعلي
            Padding(
              padding: const EdgeInsets.only(bottom: 48.0),
              child: RecordButton(
                isRecording: state.isRecording,
                onToggle: () {
                  if (state.isRecording) {
                    controller.stopAndEvaluate(expectedVerse: expectedText);
                  } else {
                    controller.startRecording(expectedVerse: expectedText);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
