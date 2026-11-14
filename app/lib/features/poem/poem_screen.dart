import 'package:flutter/material.dart';
import '../../core/data/models/poem.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/cartouche_header.dart';
import '../../core/widgets/verse_tile.dart';

class PoemScreen extends StatefulWidget {
  final Poem poem;
  final VoidCallback? onBack;
  final VoidCallback? onStartRecitation;
  final VoidCallback? onStartMemorization;

  const PoemScreen({
    super.key,
    required this.poem,
    this.onBack,
    this.onStartRecitation,
    this.onStartMemorization,
  });

  @override
  State<PoemScreen> createState() => _PoemScreenState();
}

class _PoemScreenState extends State<PoemScreen> {
  double _fontSize = 20.0;
  bool _isStacked = false;

  void _increaseFontSize() {
    if (_fontSize < 28.0) {
      setState(() => _fontSize += 2.0);
    }
  }

  void _decreaseFontSize() {
    if (_fontSize > 16.0) {
      setState(() => _fontSize -= 2.0);
    }
  }

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
          widget.poem.title,
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          // تحكم حجم الخط بخمس خطوات
          IconButton(
            icon: const Icon(Icons.text_increase_rounded),
            color: diwan.accentGold,
            tooltip: 'تكبير الخط',
            onPressed: _increaseFontSize,
          ),
          IconButton(
            icon: const Icon(Icons.text_decrease_rounded),
            color: diwan.textSecondary,
            tooltip: 'تصغير الخط',
            onPressed: _decreaseFontSize,
          ),
          // تبديل العرض المكدس أو الكلاسيكي
          IconButton(
            icon: Icon(
              _isStacked ? Icons.view_agenda_rounded : Icons.view_column_rounded,
              color: diwan.primary,
            ),
            tooltip: _isStacked ? 'تفعيل العرض المتوازي' : 'تفعيل العرض المكدس',
            onPressed: () => setState(() => _isStacked = !_isStacked),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 24.0),
              children: [
                // خرطوش التذهيب المخطوطي لترويسة القصيدة
                CartoucheHeader(
                  poemTitle: widget.poem.title,
                  poetName: widget.poem.poetName,
                  era: widget.poem.era,
                  meterName: widget.poem.meterName,
                  rawiy: widget.poem.rawiy,
                ),
                // قائمة الأبيات
                ...widget.poem.verses.map((v) {
                  return VerseTile(
                    verse: v,
                    fontSize: _fontSize,
                    isStacked: _isStacked,
                    onRecite: widget.onStartRecitation,
                    onMemorize: widget.onStartMemorization,
                  );
                }),
              ],
            ),
          ),

          // الشريط السفلي العائم للإجراءات الرئيسية
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: diwan.surfaceElevated,
              border: Border(top: BorderSide(color: diwan.border)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: diwan.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 2,
                    ),
                    onPressed: widget.onStartRecitation,
                    icon: const Icon(Icons.mic_rounded, size: 20),
                    label: Text(
                      'تسميع القصيدة',
                      style: DiwanTypography.uiTitle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: diwan.accentGold,
                      side: BorderSide(color: diwan.borderGold, width: 1.4),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: widget.onStartMemorization,
                    icon: const Icon(Icons.psychology_rounded, size: 20),
                    label: Text(
                      'تدريب الحفظ (SRS)',
                      style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
