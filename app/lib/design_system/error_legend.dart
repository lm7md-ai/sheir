import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/theme/typography.dart';

/// دليل علامات التسميع المتاح للجميع بالترميز المزدوج (Error Legend)
class ErrorLegend extends StatelessWidget {
  const ErrorLegend({super.key});

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: diwan.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: diwan.border),
      ),
      child: Wrap(
        textDirection: TextDirection.rtl,
        alignment: WrapAlignment.center,
        spacing: 12,
        runSpacing: 8,
        children: [
          _buildItem(
            label: 'صحيح',
            icon: '✓',
            color: diwan.recitationCorrect,
            isUnderline: true,
          ),
          _buildItem(
            label: 'خطأ',
            icon: '✕',
            color: diwan.recitationWrong,
            isWavy: true,
          ),
          _buildItem(
            label: 'تردد',
            icon: '⏳',
            color: diwan.recitationHesitation,
            isDotted: true,
          ),
          _buildItem(
            label: 'سقطت',
            icon: '∅',
            color: diwan.recitationMissing,
            isStrikethrough: true,
          ),
          _buildItem(
            label: 'زائدة',
            icon: '+',
            color: diwan.recitationExtra,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required String label,
    required String icon,
    required Color color,
    bool isUnderline = false,
    bool isWavy = false,
    bool isDotted = false,
    bool isStrikethrough = false,
  }) {
    TextDecoration decoration = TextDecoration.none;
    TextDecorationStyle decorationStyle = TextDecorationStyle.solid;

    if (isUnderline) {
      decoration = TextDecoration.underline;
      decorationStyle = TextDecorationStyle.solid;
    } else if (isWavy) {
      decoration = TextDecoration.underline;
      decorationStyle = TextDecorationStyle.wavy;
    } else if (isDotted) {
      decoration = TextDecoration.underline;
      decorationStyle = TextDecorationStyle.dotted;
    } else if (isStrikethrough) {
      decoration = TextDecoration.lineThrough;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      textDirection: TextDirection.rtl,
      children: [
        Container(
          width: 18,
          height: 18,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.5)),
          ),
          child: Text(
            icon,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: DiwanTypography.uiBody(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ).copyWith(
            decoration: decoration,
            decorationColor: color,
            decorationStyle: decorationStyle,
          ),
        ),
      ],
    );
  }
}
