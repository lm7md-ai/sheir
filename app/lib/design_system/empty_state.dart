import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/theme/typography.dart';
import 'hemistich_row.dart';

/// حالة الخلو المخطوطية بعبارات أدبية فصيحة (Manuscript Empty State)
class EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? buttonText;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    this.title = 'ما زال هذا الديوان بكراً',
    this.subtitle = 'لم تُدوَّن فيه أبياتٌ بعد، اختر قصيدة وابدأ مسيرة الحفظ والاستظهار.',
    this.buttonText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const RosetteDivider(size: 48),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.displayCartouche(
                color: diwan.accentGold,
                fontSize: 22,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.uiBody(
                color: diwan.textSecondary,
                fontSize: 14,
              ),
            ),
            if (buttonText != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: diwan.surfaceElevated,
                  foregroundColor: diwan.accentGold,
                  side: BorderSide(color: diwan.borderGold, width: 1.2),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: onAction,
                child: Text(
                  buttonText!,
                  style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
