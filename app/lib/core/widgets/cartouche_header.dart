import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

/// خرطوش الطغراء والتذهيب المخطوطي لترويسة القصيدة والشاعر
class CartoucheHeader extends StatelessWidget {
  final String poemTitle;
  final String poetName;
  final String era;
  final String meterName;
  final String rawiy;

  const CartoucheHeader({
    super.key,
    required this.poemTitle,
    required this.poetName,
    required this.era,
    required this.meterName,
    required this.rawiy,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: diwan.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: diwan.borderGold, width: 1.4),
        boxShadow: [
          BoxShadow(
            color: diwan.accentGold.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // تأطير زخرفي داخلي هادئ
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: diwan.borderGold.withOpacity(0.35),
                    width: 0.8,
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // عنوان القصيدة
                Text(
                  poemTitle,
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                  style: DiwanTypography.displayCartouche(
                    color: diwan.accentGold,
                    fontSize: 24,
                  ),
                ),
                const SizedBox(height: 4),
                // اسم الشاعر والعصر
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      '۞ $poetName ۞',
                      style: DiwanTypography.uiTitle(
                        color: diwan.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // رقاقات الخصائص الشعرية
                Wrap(
                  textDirection: TextDirection.rtl,
                  spacing: 8,
                  runSpacing: 6,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildMetaChip('العصر: $era', diwan.primary, diwan),
                    _buildMetaChip('بحر: $meterName', diwan.accentGold, diwan),
                    _buildMetaChip('الروي: $rawiy', diwan.secondaryBurgundy, diwan),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaChip(String label, Color color, DiwanThemeExtension diwan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4), width: 0.8),
      ),
      child: Text(
        label,
        textDirection: TextDirection.rtl,
        style: DiwanTypography.uiBody(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
