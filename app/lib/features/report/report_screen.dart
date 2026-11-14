import 'package:flutter/material.dart';
import '../../core/nlp/recitation_alignment_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/accuracy_gauge.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/error_legend.dart';
import '../../core/widgets/word_chip.dart';

class ReportScreen extends StatelessWidget {
  final RecitationEvaluationResult result;
  final VoidCallback? onRetryMistakesOnly;
  final VoidCallback? onSaveProgress;
  final VoidCallback? onClose;

  const ReportScreen({
    super.key,
    required this.result,
    this.onRetryMistakesOnly,
    this.onSaveProgress,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: diwan.accentGold),
          onPressed: onClose ?? () => Navigator.maybePop(context),
        ),
        title: Text(
          'صحيفة تقرير التسميع',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          children: [
            // عداد الدقة والرتبة الأدبية
            Center(
              child: AccuracyGauge(
                percentage: result.accuracyPercentage,
                rankTitle: result.performanceRank,
                size: 190,
              ),
            ),
            const SizedBox(height: 20),

            // دليل علامات التسميع
            const ErrorLegend(),
            const SizedBox(height: 18),

            // بطاقة تحليل الأبيات والكلمات
            DiwanCard(
              hasGoldBorder: true,
              padding: const EdgeInsets.all(18.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    'تفصيل كلمات البيت ومواضع الإتقان:',
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    textDirection: TextDirection.rtl,
                    spacing: 6,
                    runSpacing: 8,
                    children: result.tokens.map((token) {
                      return WordChip(token: token);
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: diwan.border),
                  const SizedBox(height: 8),
                  // إحصاء سريع
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    textDirection: TextDirection.rtl,
                    children: [
                      _buildStat('${result.correctCount}', 'صحيحة', diwan.recitationCorrect, diwan),
                      _buildStat('${result.wrongCount}', 'خاطئة', diwan.recitationWrong, diwan),
                      _buildStat('${result.hesitationCount}', 'تردد', diwan.recitationHesitation, diwan),
                      _buildStat('${result.missingCount}', 'سقطت', diwan.recitationMissing, diwan),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // أزرار العمليات
            if (result.wrongCount > 0 || result.missingCount > 0) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: diwan.surfaceElevated,
                  foregroundColor: diwan.accentGold,
                  side: BorderSide(color: diwan.borderGold, width: 1.2),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onRetryMistakesOnly,
                icon: const Icon(Icons.refresh_rounded),
                label: Text(
                  'أعد تسميع الأخطاء فقط',
                  style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 12),
            ],

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: diwan.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onSaveProgress,
              icon: const Icon(Icons.bookmark_added_rounded),
              label: Text(
                'حفظ النتيجة في سجل الحفظ',
                style: DiwanTypography.uiTitle(color: Colors.white, fontSize: 14),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(String val, String label, Color color, DiwanThemeExtension diwan) {
    return Column(
      children: [
        Text(
          val,
          style: DiwanTypography.uiNumber(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 11),
        ),
      ],
    );
  }
}
