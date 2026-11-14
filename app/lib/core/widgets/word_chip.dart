import 'package:flutter/material.dart';
import '../nlp/recitation_alignment_engine.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

/// رقاقة الكلمة التفاعلية الداعمة للترميز الثنائي (Dual-Coding) وحالات التسميع الخمس
class WordChip extends StatelessWidget {
  final RecitationWordToken token;
  final VoidCallback? onTap;
  final double fontSize;

  const WordChip({
    super.key,
    required this.token,
    this.onTap,
    this.fontSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    Color wordColor;
    TextDecoration decoration;
    Color decorationColor;
    TextDecorationStyle decorationStyle;
    String statusIcon;
    Color chipBackground;

    switch (token.status) {
      case RecitationWordStatus.correct:
        wordColor = diwan.recitationCorrect;
        decoration = TextDecoration.underline;
        decorationColor = diwan.recitationCorrect.withOpacity(0.6);
        decorationStyle = TextDecorationStyle.solid;
        statusIcon = '✓';
        chipBackground = diwan.recitationCorrect.withOpacity(0.12);
        break;

      case RecitationWordStatus.wrong:
        wordColor = diwan.recitationWrong;
        decoration = TextDecoration.underline;
        decorationColor = diwan.recitationWrong;
        decorationStyle = TextDecorationStyle.wavy;
        statusIcon = '✕';
        chipBackground = diwan.recitationWrong.withOpacity(0.14);
        break;

      case RecitationWordStatus.hesitation:
        wordColor = diwan.recitationHesitation;
        decoration = TextDecoration.underline;
        decorationColor = diwan.recitationHesitation;
        decorationStyle = TextDecorationStyle.dotted;
        statusIcon = '⏳';
        chipBackground = diwan.recitationHesitation.withOpacity(0.12);
        break;

      case RecitationWordStatus.missing:
        wordColor = diwan.recitationMissing;
        decoration = TextDecoration.lineThrough;
        decorationColor = diwan.recitationMissing;
        decorationStyle = TextDecorationStyle.solid;
        statusIcon = '∅';
        chipBackground = diwan.recitationMissing.withOpacity(0.10);
        break;

      case RecitationWordStatus.extra:
        wordColor = diwan.recitationExtra;
        decoration = TextDecoration.none;
        decorationColor = Colors.transparent;
        decorationStyle = TextDecorationStyle.solid;
        statusIcon = '+';
        chipBackground = diwan.recitationExtra.withOpacity(0.12);
        break;
    }

    final displayText = token.status == RecitationWordStatus.extra
        ? (token.heardWord ?? '[زائد]')
        : token.expectedWord;

    return InkWell(
      onTap: onTap ?? () => _showDetailSheet(context, diwan),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: chipBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: wordColor.withOpacity(0.35),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              displayText,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.verseStyle(
                color: wordColor,
                fontSize: fontSize,
                lineHeight: 1.6,
                fontWeight: FontWeight.w600,
              ).copyWith(
                decoration: decoration,
                decorationColor: decorationColor,
                decorationStyle: decorationStyle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              statusIcon,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: wordColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, DiwanThemeExtension diwan) {
    showModalBottomSheet(
      context: context,
      backgroundColor: diwan.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            textDirection: TextDirection.rtl,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: diwan.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'تفصيل الكلمة في التسميع',
                textDirection: TextDirection.rtl,
                style: DiwanTypography.uiTitle(
                  color: diwan.accentGold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 14),
              _buildDetailRow('الكلمة المتوقعة:', token.expectedWord, diwan.textPrimary, diwan),
              const SizedBox(height: 8),
              _buildDetailRow(
                'ما التقطه النظام:',
                token.heardWord ?? 'لم يُنطق',
                token.heardWord != null ? diwan.textSecondary : diwan.recitationMissing,
                diwan,
              ),
              const SizedBox(height: 8),
              _buildDetailRow('الحالة والتشخيص:', token.note, diwan.primary, diwan),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: diwan.surfaceElevated,
                  foregroundColor: diwan.accentGold,
                  side: BorderSide(color: diwan.borderGold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.volume_up_rounded),
                label: Text(
                  'استمع للنطق المرجعي الصحيح',
                  style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    Color valueColor,
    DiwanThemeExtension diwan,
  ) {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        Text(
          label,
          style: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 14),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: DiwanTypography.uiTitle(color: valueColor, fontSize: 15),
        ),
      ],
    );
  }
}
