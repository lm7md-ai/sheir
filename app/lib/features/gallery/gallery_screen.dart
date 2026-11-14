import 'package:flutter/material.dart';
import '../../core/data/models/verse.dart';
import '../../core/nlp/recitation_alignment_engine.dart';
import '../../core/theme/diwan_colors.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../design_system/design_system.dart';

enum GalleryThemeChoice { midnight, parchment, sepia }

class GalleryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const GalleryScreen({super.key, this.onBack});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isRecButtonActive = false;
  GalleryThemeChoice _selectedTheme = GalleryThemeChoice.midnight;
  double _fontScale = 1.0;

  final sampleVerse = const Verse(
    id: 1,
    poemId: 1,
    verseOrder: 1,
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ',
  );

  ThemeData _getThemeData(GalleryThemeChoice choice) {
    switch (choice) {
      case GalleryThemeChoice.midnight:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: DiwanColors.darkBackground,
          primaryColor: DiwanColors.darkPrimary,
          fontFamily: DiwanTypography.fontUI,
          extensions: const [DiwanThemeExtension.midnightInk],
        );
      case GalleryThemeChoice.parchment:
        return ThemeData(
          brightness: Brightness.light,
          scaffoldBackgroundColor: DiwanColors.lightBackground,
          primaryColor: DiwanColors.lightPrimary,
          fontFamily: DiwanTypography.fontUI,
          extensions: const [DiwanThemeExtension.parchment],
        );
      case GalleryThemeChoice.sepia:
        return ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: DiwanColors.sepiaBackground,
          primaryColor: DiwanColors.sepiaPrimary,
          fontFamily: DiwanTypography.fontUI,
          extensions: const [DiwanThemeExtension.sepia],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeTheme = _getThemeData(_selectedTheme);
    final diwan = activeTheme.extension<DiwanThemeExtension>() ?? DiwanThemeExtension.midnightInk;

    return Theme(
      data: activeTheme,
      child: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaleFactor: _fontScale),
        child: Scaffold(
          backgroundColor: diwan.background,
          appBar: AppBar(
            backgroundColor: diwan.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_forward_ios_rounded, color: diwan.accentGold),
              onPressed: widget.onBack ?? () => Navigator.maybePop(context),
            ),
            title: Text(
              'معرض منظومة التصميم (Design Gallery)',
              style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 16),
            ),
            centerTitle: true,
          ),
          body: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
            children: [
              // أدوات التبديل التفاعلي للسمة ومقياس الخط
              DiwanCard(
                hasGoldBorder: true,
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text('السمة المعروضة:', style: DiwanTypography.uiBody(color: diwan.textPrimary, fontSize: 13)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('حبر الليل'),
                              selected: _selectedTheme == GalleryThemeChoice.midnight,
                              onSelected: (_) => setState(() => _selectedTheme = GalleryThemeChoice.midnight),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('الرَّقّ'),
                              selected: _selectedTheme == GalleryThemeChoice.parchment,
                              onSelected: (_) => setState(() => _selectedTheme = GalleryThemeChoice.parchment),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('سيبيا'),
                              selected: _selectedTheme == GalleryThemeChoice.sepia,
                              onSelected: (_) => setState(() => _selectedTheme = GalleryThemeChoice.sepia),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text('مقياس الخط:', style: DiwanTypography.uiBody(color: diwan.textPrimary, fontSize: 13)),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('1.0x (افتراضي)'),
                              selected: _fontScale == 1.0,
                              onSelected: (_) => setState(() => _fontScale = 1.0),
                            ),
                            const SizedBox(width: 6),
                            ChoiceChip(
                              label: const Text('1.5x (مكبر)'),
                              selected: _fontScale == 1.5,
                              onSelected: (_) => setState(() => _fontScale = 1.5),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 1. CartoucheHeader
              const SectionHeader(title: '١. خرطوش الطغراء والتذهيب (CartoucheHeader)'),
              const CartoucheHeader(
                poemTitle: 'واحرّ قلباه',
                poetName: 'أبو الطيب المتنبي',
                era: 'العباسي',
                meterName: 'البسيط',
                rawiy: 'الميم',
              ),
              const SizedBox(height: 16),

              // 2. Classic VerseTile & HemistichRow
              const SectionHeader(title: '٢. شطر البيت والتنسيق الكلاسيكي (VerseTile & HemistichRow)'),
              VerseTile(
                verse: sampleVerse,
                fontSize: 20 * _fontScale,
                isStacked: false,
              ),
              const SizedBox(height: 8),
              VerseTile(
                verse: sampleVerse,
                fontSize: 18 * _fontScale,
                isStacked: true,
              ),
              const SizedBox(height: 16),

              // 3. WordChips (5 Recitation States)
              const SectionHeader(title: '٣. رقاقات الكلمات وحالات التسميع الخمس (WordChip)'),
              DiwanCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  textDirection: TextDirection.rtl,
                  children: [
                    Text(
                      'حالات التسميع الخمس بترميز ثنائي (Dual-Coded):',
                      style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      textDirection: TextDirection.rtl,
                      spacing: 6,
                      runSpacing: 8,
                      children: const [
                        WordChip(
                          token: RecitationWordToken(
                            expectedWord: 'صحيحة',
                            status: RecitationWordStatus.correct,
                            note: 'نطق سليم مطابق',
                          ),
                        ),
                        WordChip(
                          token: RecitationWordToken(
                            expectedWord: 'خاطئة',
                            heardWord: 'بديلة',
                            status: RecitationWordStatus.wrong,
                            note: 'أبدلت بكلمة أخرى',
                          ),
                        ),
                        WordChip(
                          token: RecitationWordToken(
                            expectedWord: 'مترددة',
                            status: RecitationWordStatus.hesitation,
                            note: 'تردد وتكرار',
                          ),
                        ),
                        WordChip(
                          token: RecitationWordToken(
                            expectedWord: 'سقطت',
                            status: RecitationWordStatus.missing,
                            note: 'سقطت من التسميع',
                          ),
                        ),
                        WordChip(
                          token: RecitationWordToken(
                            expectedWord: '[حشو]',
                            heardWord: 'زائدة',
                            status: RecitationWordStatus.extra,
                            note: 'لفظة إضافية',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. DiwanChips Variants
              const SectionHeader(title: '٤. أنماط الرقاقات الموحدة (DiwanChip)'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  DiwanChip(label: 'العصر العباسي', variant: DiwanChipVariant.primary),
                  DiwanChip(label: 'بحر البسيط', variant: DiwanChipVariant.gold),
                  DiwanChip(label: 'روي الميم', variant: DiwanChipVariant.burgundy),
                  DiwanChip(label: '٨ أبيات', variant: DiwanChipVariant.surface),
                ],
              ),
              const SizedBox(height: 16),

              // 5. AccuracyGauge
              const SectionHeader(title: '٥. عداد الدقة والرتبة الأدبية (AccuracyGauge)'),
              const Center(
                child: AccuracyGauge(
                  percentage: 94.5,
                  rankTitle: 'أمير الشعراء',
                  size: 180,
                ),
              ),
              const SizedBox(height: 16),

              // 6. ErrorLegend
              const SectionHeader(title: '٦. دليل علامات التسميع (ErrorLegend)'),
              const ErrorLegend(),
              const SizedBox(height: 16),

              // 7. RecordButton
              const SectionHeader(title: '٧. زر اللاقط النابض (RecordButton)'),
              Center(
                child: RecordButton(
                  isRecording: _isRecButtonActive,
                  onToggle: () => setState(() => _isRecButtonActive = !_isRecButtonActive),
                  size: 76,
                ),
              ),
              const SizedBox(height: 16),

              // 8. SkeletonList
              const SectionHeader(title: '٨. وميض التحميل العاجي (SkeletonList)'),
              const SkeletonList(itemCount: 2),
              const SizedBox(height: 16),

              // 9. EmptyState
              const SectionHeader(title: '٩. حالة الخلو الأدبية (EmptyState)'),
              DiwanCard(
                child: EmptyState(
                  title: 'ما زال هذا الديوان بكراً',
                  subtitle: 'اختر قصيدة من عيون الشعر العربي وابدأ مسيرة الحفظ والاستظهار.',
                  buttonText: 'تصفح الخزانة',
                  onAction: () {},
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
