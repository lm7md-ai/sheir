import 'package:flutter/material.dart';
import '../../core/data/models/verse.dart';
import '../../core/nlp/recitation_alignment_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/accuracy_gauge.dart';
import '../../core/widgets/cartouche_header.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_legend.dart';
import '../../core/widgets/hemistich_row.dart';
import '../../core/widgets/record_button.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/skeleton_list.dart';
import '../../core/widgets/verse_tile.dart';
import '../../core/widgets/word_chip.dart';

class GalleryScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const GalleryScreen({super.key, this.onBack});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  bool _isRecButtonActive = false;

  final sampleVerse = const Verse(
    id: 1,
    poemId: 1,
    verseOrder: 1,
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ',
  );

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Scaffold(
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
          const SectionHeader(title: '٢. شطر البيت والتنسيق الكلاسيكي (VerseTile)'),
          VerseTile(
            verse: sampleVerse,
            fontSize: 20,
            isStacked: false,
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
                  'انقر على أي كلمة لاستعراض صحيفة التفصيل والنطق المرجعي:',
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

          // 4. AccuracyGauge
          const SectionHeader(title: '٤. عداد الدقة والرتبة الأدبية (AccuracyGauge)'),
          const Center(
            child: AccuracyGauge(
              percentage: 94.5,
              rankTitle: 'أمير الشعراء',
              size: 180,
            ),
          ),
          const SizedBox(height: 16),

          // 5. ErrorLegend
          const SectionHeader(title: '٥. دليل علامات التسميع (ErrorLegend)'),
          const ErrorLegend(),
          const SizedBox(height: 16),

          // 6. RecordButton
          const SectionHeader(title: '٦. زر اللاقط النابض (RecordButton)'),
          Center(
            child: RecordButton(
              isRecording: _isRecButtonActive,
              onToggle: () => setState(() => _isRecButtonActive = !_isRecButtonActive),
              size: 76,
            ),
          ),
          const SizedBox(height: 16),

          // 7. SkeletonList
          const SectionHeader(title: '٧. وميض التحميل العاجي (SkeletonList)'),
          const SkeletonList(itemCount: 2),
          const SizedBox(height: 16),

          // 8. EmptyState
          const SectionHeader(title: '٨. حالة الخلو الأدبية (EmptyState)'),
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
    );
  }
}
