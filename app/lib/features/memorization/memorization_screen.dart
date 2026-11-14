import 'package:flutter/material.dart';
import '../../core/data/models/verse.dart';
import '../../core/srs/cloze_generator.dart';
import '../../core/srs/spaced_repetition_engine.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/hemistich_row.dart';

class MemorizationScreen extends StatefulWidget {
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
  State<MemorizationScreen> createState() => _MemorizationScreenState();
}

class _MemorizationScreenState extends State<MemorizationScreen> {
  ClozeMode _currentMode = ClozeMode.hideRhymeWords;
  final Set<int> _revealedWordIndices = {};
  bool _showFirstLetterHint = false;

  void _toggleWordReveal(int index) {
    setState(() {
      if (_revealedWordIndices.contains(index)) {
        _revealedWordIndices.remove(index);
      } else {
        _revealedWordIndices.add(index);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    final card = SrsCardState.initial(widget.verse.id);

    final sadrWords = ClozeGenerator.generate(
      text: widget.verse.sadr,
      mode: _currentMode,
      isAjuz: false,
    );

    final ajuzWords = ClozeGenerator.generate(
      text: widget.verse.ajuz,
      mode: _currentMode,
      isAjuz: true,
    );

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
                  _buildModeChip('١: قراءة كاملة', ClozeMode.full, diwan),
                  _buildModeChip('٢: إخفاء القوافي', ClozeMode.hideRhymeWords, diwan),
                  _buildModeChip('٣: إخفاء العجز', ClozeMode.hideAjuz, diwan),
                  _buildModeChip('٤: إخفاء تدريجي', ClozeMode.progressiveCloze, diwan),
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
                  // شطر الصدر
                  _buildHemistichCloze(sadrWords, 0, diwan),
                  const SizedBox(height: 16),
                  const RosetteDivider(size: 26),
                  const SizedBox(height: 16),
                  // شطر العجز
                  _buildHemistichCloze(ajuzWords, sadrWords.length, diwan),
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
                  selected: _showFirstLetterHint,
                  onSelected: (val) => setState(() => _showFirstLetterHint = val),
                  selectedColor: diwan.accentGold.withOpacity(0.2),
                  backgroundColor: diwan.surface,
                  labelStyle: DiwanTypography.uiBody(
                    color: _showFirstLetterHint ? diwan.accentGold : diwan.textSecondary,
                    fontSize: 13,
                  ),
                  avatar: Icon(Icons.lightbulb_outline_rounded,
                      color: _showFirstLetterHint ? diwan.accentGold : diwan.textMuted, size: 18),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // أزرار التقييم الأربعة لجدولة التكرار المتباعد (FSRS Ratings)
            Text(
              'ما مدى رسوخ استذكارك للبيت؟',
              textAlign: TextAlign.center,
              style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 15),
            ),
            const SizedBox(height: 12),

            Row(
              textDirection: TextDirection.rtl,
              children: [
                _buildSrsButton('نسيت', '١٠ دقائق', diwan.recitationWrong, SrsRating.again, diwan),
                const SizedBox(width: 8),
                _buildSrsButton('صعب', 'غداً', diwan.recitationHesitation, SrsRating.hard, diwan),
                const SizedBox(width: 8),
                _buildSrsButton('جيد', 'يومان', diwan.primary, SrsRating.good, diwan),
                const SizedBox(width: 8),
                _buildSrsButton('سهل', '٤ أيام', diwan.accentGold, SrsRating.easy, diwan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHemistichCloze(List<ClozeWord> words, int offset, DiwanThemeExtension diwan) {
    return Wrap(
      textDirection: TextDirection.rtl,
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 10,
      children: words.asMap().entries.map((e) {
        final globalIdx = offset + e.key;
        final word = e.value;
        final isRevealed = _revealedWordIndices.contains(globalIdx);

        if (!word.isHidden || isRevealed) {
          return InkWell(
            onTap: word.isHidden ? () => _toggleWordReveal(globalIdx) : null,
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
          onTap: () => _toggleWordReveal(globalIdx),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: diwan.surfaceElevated,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: diwan.borderGold.withOpacity(0.5)),
            ),
            child: Text(
              _showFirstLetterHint ? '${word.firstLetterHint}....' : '.......',
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

  Widget _buildModeChip(String label, ClozeMode mode, DiwanThemeExtension diwan) {
    final isSelected = _currentMode == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() {
          _currentMode = mode;
          _revealedWordIndices.clear();
        }),
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
    SrsRating rating,
    DiwanThemeExtension diwan,
  ) {
    return Expanded(
      child: InkWell(
        onTap: () => widget.onRatingSubmitted?.call(rating),
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
