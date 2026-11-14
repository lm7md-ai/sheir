import 'package:flutter/material.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/hemistich_row.dart';
import '../../core/widgets/section_header.dart';

class HomeScreen extends StatelessWidget {
  final Function(int poemId)? onSelectPoem;
  final VoidCallback? onStartSrsReview;
  final VoidCallback? onOpenSearch;

  const HomeScreen({
    super.key,
    this.onSelectPoem,
    this.onStartSrsReview,
    this.onOpenSearch,
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
          'دِيــوَان',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 26,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: diwan.accentGold),
            tooltip: 'البحث في الدواوين',
            onPressed: onOpenSearch,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),

            // 1. بطاقة "بيت اليوم" (Verse of the day Hero Card)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DiwanCard(
                hasGoldBorder: true,
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Icon(Icons.auto_awesome_rounded, color: diwan.accentGold, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'بَيْتُ اليَوْم',
                          style: DiwanTypography.uiTitle(
                            color: diwan.accentGold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    HemistichRow(
                      sadr: 'أَعَزُّ مَكَانٍ فِي الدُّنَى سَرْجُ سَابِحٍ',
                      ajuz: 'وَخَيْرُ جَلِيسٍ فِي الزَّمَانِ كِتَابُ',
                      fontSize: 21,
                      isStacked: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          '— أَبُو الطَّيِّبِ المُتَنَبِّي  |  بحر الطويل',
                          style: DiwanTypography.uiBody(
                            color: diwan.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 2. بطاقة أوراد الحفظ المستحقة (SRS Due Reviews)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: DiwanCard(
                padding: const EdgeInsets.all(16.0),
                onTap: onStartSrsReview,
                child: Row(
                  textDirection: TextDirection.rtl,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: diwan.primary.withOpacity(0.15),
                        border: Border.all(color: diwan.primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          '١٢',
                          style: DiwanTypography.uiNumber(
                            color: diwan.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text(
                            'أوراد المراجعة المستحقة اليوم',
                            style: DiwanTypography.uiTitle(
                              color: diwan.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '١٢ بيتاً بانتظار استظهارك وتثبيت حفظها',
                            style: DiwanTypography.uiBody(
                              color: diwan.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_back_ios_new_rounded, color: diwan.accentGold, size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 3. التصفح بالعصور الأدبية (Timeline)
            SectionHeader(title: 'العصور الأدبية'),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildEraChip('العصر الجاهلي', diwan),
                  _buildEraChip('عصر صدر الإسلام', diwan),
                  _buildEraChip('العصر الأموي', diwan),
                  _buildEraChip('العصر العباسي', diwan),
                  _buildEraChip('العصر الأندلسي', diwan),
                  _buildEraChip('العصر الحديث', diwan),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 4. بحور الشعر الستة عشر
            SectionHeader(title: 'بحور الشعر الخليلية'),
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _buildMeterChip('الطويل', diwan),
                  _buildMeterChip('الكامل', diwan),
                  _buildMeterChip('البسيط', diwan),
                  _buildMeterChip('الخفيف', diwan),
                  _buildMeterChip('الوافر', diwan),
                  _buildMeterChip('الرجز', diwan),
                  _buildMeterChip('المتقارب', diwan),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 5. أعلام الشعراء
            SectionHeader(title: 'أعلام الفحول والناظمين'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                children: [
                  _buildPoetTile('أبو الطيب المتنبي', 'حكيم الشعراء وشاغل الناس', 'العباسي', 1, diwan),
                  _buildPoetTile('امرؤ القيس الكندي', 'الملك الضليل ورائد المعلقات', 'الجاهلي', 2, diwan),
                  _buildPoetTile('عنترة بن شداد العبسي', 'فارس الحماسة والغزل العفيف', 'الجاهلي', 3, diwan),
                  _buildPoetTile('الإمام الشافعي', 'ناظم روائع الحكم والزهد', 'العباسي', 4, diwan),
                  _buildPoetTile('أحمد شوقي', 'أمير الشعراء في العصر الحديث', 'الحديث', 5, diwan),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildEraChip(String label, DiwanThemeExtension diwan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: diwan.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: diwan.border),
      ),
      child: Center(
        child: Text(
          label,
          style: DiwanTypography.uiBody(
            color: diwan.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildMeterChip(String label, DiwanThemeExtension diwan) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: diwan.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: diwan.borderGold.withOpacity(0.5)),
      ),
      child: Center(
        child: Text(
          label,
          style: DiwanTypography.uiBody(
            color: diwan.accentGold,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildPoetTile(
    String name,
    String desc,
    String era,
    int poemId,
    DiwanThemeExtension diwan,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5.0),
      child: DiwanCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        onTap: () => onSelectPoem?.call(poemId),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: diwan.surfaceElevated,
              child: Text(
                name.substring(0, 1),
                style: DiwanTypography.displayCartouche(
                  color: diwan.accentGold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                textDirection: TextDirection.rtl,
                children: [
                  Text(
                    name,
                    style: DiwanTypography.uiTitle(
                      color: diwan.textPrimary,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    desc,
                    style: DiwanTypography.uiBody(
                      color: diwan.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: diwan.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                era,
                style: DiwanTypography.uiBody(color: diwan.primary, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
