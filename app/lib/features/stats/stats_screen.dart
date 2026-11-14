import 'package:flutter/material.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';

class StatsScreen extends StatelessWidget {
  final int streakDays;
  final int xp;
  final String currentRank;

  const StatsScreen({
    super.key,
    this.streakDays = 7,
    this.xp = 350,
    this.currentRank = 'ناظمٌ مُتْقِن',
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        title: Text(
          'سجل الحفظ والرتب',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // بطاقة الشعلة والرتبة الحالية
            DiwanCard(
              hasGoldBorder: true,
              padding: const EdgeInsets.all(22),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔥', style: const TextStyle(fontSize: 32)),
                      const SizedBox(width: 8),
                      Text(
                        '$streakDays أيام متتالية',
                        style: DiwanTypography.uiNumber(
                          color: diwan.accentGold,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'رتبتك الأدبية الحالية: $currentRank',
                    style: DiwanTypography.displayCartouche(
                      color: diwan.primary,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'مجموع نقاط الخبرة (XP): $xp نقطة',
                    style: DiwanTypography.uiBody(
                      color: diwan.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // سلم الرتب الأدبية
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    textDirection: TextDirection.rtl,
                    children: [
                      _buildRankStep('راوٍ', true, diwan),
                      _buildRankArrow(diwan),
                      _buildRankStep('حافِظ', true, diwan),
                      _buildRankArrow(diwan),
                      _buildRankStep('ناظِم', true, diwan), // الحالي
                      _buildRankArrow(diwan),
                      _buildRankStep('شاعِر', false, diwan),
                      _buildRankArrow(diwan),
                      _buildRankStep('أمير الشعراء', false, diwan),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // تقويم أيام التسميع والممارسة (Heatmap Grid)
            DiwanCard(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                textDirection: TextDirection.rtl,
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Icon(Icons.calendar_month_rounded, color: diwan.accentGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'خريطة الممارسة والاستظهار (آخر ٣٠ يوماً):',
                        style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: 28,
                    itemBuilder: (ctx, idx) {
                      final isPracticed = idx >= 14 && idx <= 21;
                      return Container(
                        decoration: BoxDecoration(
                          color: isPracticed ? diwan.primary : diwan.surfaceElevated,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isPracticed ? diwan.accentGold.withOpacity(0.5) : diwan.border,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: DiwanTypography.uiNumber(
                              color: isPracticed ? Colors.white : diwan.textMuted,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankStep(String name, bool isAchieved, DiwanThemeExtension diwan) {
    return Column(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: isAchieved ? diwan.primary : diwan.surfaceElevated,
          child: Icon(
            isAchieved ? Icons.check : Icons.lock_outline,
            size: 12,
            color: isAchieved ? Colors.white : diwan.textMuted,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          name,
          style: DiwanTypography.uiBody(
            color: isAchieved ? diwan.accentGold : diwan.textMuted,
            fontSize: 10,
            fontWeight: isAchieved ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildRankArrow(DiwanThemeExtension diwan) {
    return Icon(Icons.arrow_back_ios_new_rounded, size: 10, color: diwan.border);
  }
}
