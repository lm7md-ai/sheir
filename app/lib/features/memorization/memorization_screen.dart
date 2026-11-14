import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/verse.dart';
import '../../core/srs/cloze_generator.dart';
import '../../core/srs/spaced_repetition_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/hemistich_row.dart';
import 'controllers/memorization_controller.dart' as ctrl;

/// شاشة مختبر الحفظ والاستدعاء النشط
/// تفصل منطق الأعمال (FSRS/SM-2 والإخفاء) في Controller مستقل بنمط Feature-First Clean Architecture
class MemorizationScreen extends ConsumerWidget {
  final Verse verse;
  final Function(SrsRating rating)? onRatingSubmitted;
  final VoidCallback? onBack;

  const MemorizationScreen({
    super.key,
    required this.verse,
    this.onRatingSubmitted,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final diwan = context.diwan;
    final state = ref.watch(ctrl.memorizationControllerProvider(verse.id));
    final controller = ref.read(ctrl.memorizationControllerProvider(verse.id).notifier);

    // تحويل نمط الإخفاء إلى نوع ClozeGenerator
    ClozeMode genMode;
    switch (state.mode) {
      case ctrl.ClozeMode.full:
        genMode = ClozeMode.full;
        break;
      case ctrl.ClozeMode.rhyme:
        genMode = ClozeMode.hideRhymeWords;
        break;
      case ctrl.ClozeMode.ajuz:
        genMode = ClozeMode.hideAjuz;
        break;
      case ctrl.ClozeMode.cloze:
        genMode = ClozeMode.progressiveCloze;
        break;
    }

    final sadrWords = ClozeGenerator.generate(
      text: verse.sadr,
      mode: genMode,
      isAjuz: false,
    );

    final ajuzWords = ClozeGenerator.generate(
      text: verse.ajuz,
      mode: genMode,
      isAjuz: true,
    );

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios_rounded, color: diwan.accentGold),
          onPressed: onBack ?? () => Navigator.maybePop(context),
        ),
        title: Text(
          'مختبر الحفظ والاستدعاء النشط',
          style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // شريط اختيار مستوى الإخفاء (Progressive Stepper)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildModeChip('١: قراءة كاملة', ctrl.ClozeMode.full, state.mode, controller, diwan),
                  _buildModeChip('٢: إخفاء القوافي', ctrl.ClozeMode.rhyme, state.mode, controller, diwan),
                  _buildModeChip('٣: إخفاء العجز', ctrl.ClozeMode.ajuz, state.mode, controller, diwan),
                  _buildModeChip('٤: إخفاء تدريجي', ctrl.ClozeMode.cloze, state.mode, controller, diwan),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // لوح البيت مع الفراغات والتلميحات
            DiwanCard(
              hasGoldBorder: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                children: [
                  _buildHemistichCloze(sadrWords, 0, state, controller, diwan),
                  const SizedBox(height: 16),
                  const RosetteDivider(size: 26),
                  const SizedBox(height: 16),
                  _buildHemistichCloze(ajuzWords, sadrWords.length, state, controller, diwan),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // خيارات التلميح المساعدة
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilterChip(
                  label: const Text('تلميح الحرف الأول'),
                  selected: state.showFirstLetterHint,
                  onSelected: (_) => controller.toggleFirstLetterHint(),
                  selectedColor: diwan.accentGold.withOpacity(0.2),
                  labelStyle: DiwanTypography.uiBody(
                    color: state.showFirstLetterHint ? diwan.accentGold : diwan.textSecondary,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: state.showFirstLetterHint ? diwan.accentGold : diwan.border),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // أزرار التقييم الأربعة وفق خوارزمية FSRS/SM-2
            Text(
              'ما مدى تمكنك من استذكار هذا البيت؟',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.uiBody(
                color: diwan.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _buildSrsButton(
                  'نسيت',
                  state.intervalPreviews[SrsRating.again] ?? '١٠ دقائق',
                  diwan.recitationWrong,
                  () {
                    controller.submitRating(SrsRating.again);
                    onRatingSubmitted?.call(SrsRating.again);
                  },
                  diwan,
                ),
                const SizedBox(width: 8),
                _buildSrsButton(
                  'صعب',
                  state.intervalPreviews[SrsRating.hard] ?? '١ يوم',
                  diwan.recitationHesitation,
                  () {
                    controller.submitRating(SrsRating.hard);
                    onRatingSubmitted?.call(SrsRating.hard);
                  },
                  diwan,
                ),
                const SizedBox(width: 8),
                _buildSrsButton(
                  'جيد',
                  state.intervalPreviews[SrsRating.good] ?? '٢ يوم',
                  diwan.primary,
                  () {
                    controller.submitRating(SrsRating.good);
                    onRatingSubmitted?.call(SrsRating.good);
                  },
                  diwan,
                ),
                const SizedBox(width: 8),
                _buildSrsButton(
                  'سهل',
                  state.intervalPreviews[SrsRating.easy] ?? '٤ أيام',
                  diwan.accentGold,
                  () {
                    controller.submitRating(SrsRating.easy);
                    onRatingSubmitted?.call(SrsRating.easy);
                  },
                  diwan,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHemistichCloze(
    List<ClozeWord> words,
    int offset,
    ctrl.MemorizationState state,
    ctrl.MemorizationController controller,
    DiwanThemeExtension diwan,
  ) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: words.asMap().entries.map((e) {
        final globalIdx = offset + e.key;
        final word = e.value;
        final isRevealed = state.revealedIndices.contains(globalIdx);

        if (!word.isHidden || isRevealed) {
          return InkWell(
            onTap: word.isHidden ? () => controller.toggleWordPeek(globalIdx) : null,
            child: Text(
              word.text,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.verseStyle(
                color: isRevealed ? diwan.accentGold : diwan.textPrimary,
                fontSize: 21,
                fontWeight: isRevealed ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }

        // الكلمة المخفية (Tap-to-peek)
        return GestureDetector(
          onTap: () => controller.toggleWordPeek(globalIdx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: diwan.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: diwan.borderGold.withOpacity(0.5)),
            ),
            child: Text(
              state.showFirstLetterHint ? '${word.firstLetterHint}....' : '.......',
              style: DiwanTypography.uiBody(
                color: diwan.accentGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildModeChip(
    String label,
    ctrl.ClozeMode mode,
    ctrl.ClozeMode currentMode,
    ctrl.MemorizationController controller,
    DiwanThemeExtension diwan,
  ) {
    final isSelected = currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => controller.setClozeMode(mode),
        selectedColor: diwan.primary.withOpacity(0.2),
        backgroundColor: diwan.surface,
        labelStyle: DiwanTypography.uiBody(
          color: isSelected ? diwan.primary : diwan.textSecondary,
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? diwan.primary : diwan.border),
      ),
    );
  }

  Widget _buildSrsButton(
    String label,
    String timePreview,
    Color color,
    VoidCallback onTap,
    DiwanThemeExtension diwan,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withOpacity(0.6), width: 1.2),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: DiwanTypography.uiTitle(
                  color: color,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                timePreview,
                style: DiwanTypography.uiBody(
                  color: diwan.textMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
