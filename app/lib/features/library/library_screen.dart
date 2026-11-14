import 'package:flutter/material.dart';
import '../../core/data/models/poem.dart';
import '../../core/nlp/arabic_normalizer.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/empty_state.dart';

class LibraryScreen extends StatefulWidget {
  final List<Poem> poems;
  final Function(Poem poem)? onPoemSelected;

  const LibraryScreen({
    super.key,
    required this.poems,
    this.onPoemSelected,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedEra = 'الكل';
  String _selectedMeter = 'الكل';
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Poem> get _filteredPoems {
    return widget.poems.where((p) {
      if (_selectedEra != 'الكل' && p.era != _selectedEra) return false;
      if (_selectedMeter != 'الكل' && p.meterName != _selectedMeter) return false;

      if (_searchQuery.trim().isEmpty) return true;

      final normQuery = ArabicNormalizer.normalize(_searchQuery);
      final normTitle = ArabicNormalizer.normalize(p.title);
      final normPoet = ArabicNormalizer.normalize(p.poetName);
      final normTheme = ArabicNormalizer.normalize(p.theme);

      return normTitle.contains(normQuery) ||
          normPoet.contains(normQuery) ||
          normTheme.contains(normQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    final results = _filteredPoems;

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        title: Text(
          'خزانة الدواوين',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // شريط البحث الفوري غير الحساس للتشكيل
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: DiwanTypography.uiBody(color: diwan.textPrimary, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'ابحث عن بيت، شاعر، قصيدة أو غرض شعر...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded, color: diwan.accentGold),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, color: diwan.textMuted),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: diwan.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: diwan.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: diwan.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: diwan.accentGold, width: 1.4),
                ),
              ),
            ),
          ),

          // خيارات التصفية السريعة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                _buildFilterChip('الكل', _selectedEra == 'الكل', () {
                  setState(() => _selectedEra = 'الكل');
                }, diwan),
                _buildFilterChip('الجاهلي', _selectedEra == 'الجاهلي', () {
                  setState(() => _selectedEra = 'الجاهلي');
                }, diwan),
                _buildFilterChip('العباسي', _selectedEra == 'العباسي', () {
                  setState(() => _selectedEra = 'العباسي');
                }, diwan),
                _buildFilterChip('الحديث', _selectedEra == 'الحديث', () {
                  setState(() => _selectedEra = 'الحديث');
                }, diwan),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // قائمة نتائج القصائد
          Expanded(
            child: results.isEmpty
                ? const EmptyState(
                    title: 'لم يُعثر على قصيدة تطابق بحثك',
                    subtitle: 'تأكد من صحة الكلمات أو حاول البحث باسم الشاعر أو بحر القصيدة.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: results.length,
                    itemBuilder: (ctx, idx) {
                      final p = results[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: DiwanCard(
                          onTap: () => widget.onPoemSelected?.call(p),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            textDirection: TextDirection.rtl,
                            children: [
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  Text(
                                    p.title,
                                    style: DiwanTypography.displayCartouche(
                                      color: diwan.accentGold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: diwan.surfaceElevated,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: diwan.borderGold.withOpacity(0.4)),
                                    ),
                                    child: Text(
                                      '${p.verseCount} أبيات',
                                      style: DiwanTypography.uiNumber(
                                        color: diwan.accentGold,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'الشاعر: ${p.poetName}',
                                textDirection: TextDirection.rtl,
                                style: DiwanTypography.uiBody(
                                  color: diwan.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                textDirection: TextDirection.rtl,
                                children: [
                                  _buildTag(p.era, diwan.primary, diwan),
                                  const SizedBox(width: 6),
                                  _buildTag('بحر ${p.meterName}', diwan.accentGold, diwan),
                                  const SizedBox(width: 6),
                                  _buildTag('روي: ${p.rawiy}', diwan.secondaryBurgundy, diwan),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onSelect, DiwanThemeExtension diwan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelect(),
        selectedColor: diwan.accentGold.withOpacity(0.2),
        backgroundColor: diwan.surface,
        labelStyle: DiwanTypography.uiBody(
          color: isSelected ? diwan.accentGold : diwan.textSecondary,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(
          color: isSelected ? diwan.accentGold : diwan.border,
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color color, DiwanThemeExtension diwan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: DiwanTypography.uiBody(color: color, fontSize: 11),
      ),
    );
  }
}
