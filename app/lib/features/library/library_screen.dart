import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/data/models/poem.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/skeleton_list.dart';
import 'controllers/library_controller.dart';

/// شاشة خزانة الدواوين مع دعم التمرير الكسول اللانهائي (Lazy Infinite Scrolling)
/// تلتزم بالمعمارية النظيفة وعزل منطق الأعمال تماماً عن الواجهة عبر Riverpod Controller
class LibraryScreen extends ConsumerStatefulWidget {
  final List<Poem> poems;
  final Function(Poem poem)? onPoemSelected;

  const LibraryScreen({
    super.key,
    required this.poems,
    this.onPoemSelected,
  });

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      ref.read(libraryControllerProvider(widget.poems).notifier).loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    final state = ref.watch(libraryControllerProvider(widget.poems));
    final controller = ref.read(libraryControllerProvider(widget.poems).notifier);

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        title: Text(
          'خزانة الدواوين (فهرس FTS5)',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diwan.surfaceElevated,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: diwan.borderGold.withOpacity(0.3)),
                ),
                child: Text(
                  '${state.queryDurationMs}ms (<15ms)',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 10,
                    color: diwan.accentGold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط البحث المباشر
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (val) => controller.updateSearchQuery(val),
              style: DiwanTypography.uiBody(color: diwan.textPrimary),
              decoration: InputDecoration(
                hintText: 'ابحث عن بيت، شاعر، عصر، أو قافية...',
                hintTextDirection: TextDirection.rtl,
                hintStyle: DiwanTypography.uiBody(color: diwan.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: diwan.accentGold),
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
                  borderSide: BorderSide(color: diwan.accentGold, width: 1.5),
                ),
              ),
            ),
          ),

          // شريط تصفية العصور الأدبية
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              children: [
                _buildFilterChip('الكل', state.selectedEra == 'الكل', () => controller.selectEra('الكل'), diwan),
                _buildFilterChip('الجاهلي', state.selectedEra == 'الجاهلي', () => controller.selectEra('الجاهلي'), diwan),
                _buildFilterChip('العباسي', state.selectedEra == 'العباسي', () => controller.selectEra('العباسي'), diwan),
                _buildFilterChip('الحديث', state.selectedEra == 'الحديث', () => controller.selectEra('الحديث'), diwan),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // القائمة الكسولة عالية الكفاءة (Lazy ListView.builder مع RepaintBoundary و itemExtent)
          Expanded(
            child: state.displayedPoems.isEmpty
                ? const EmptyState(
                    title: 'لم يُعثر على قصيدة تطابق بحثك',
                    subtitle: 'تأكد من صحة الكلمات أو حاول البحث باسم الشاعر أو بحر القصيدة.',
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemExtent: 140.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: state.displayedPoems.length + (state.isLoadingMore ? 1 : 0),
                    itemBuilder: (ctx, idx) {
                      if (idx == state.displayedPoems.length) {
                        return const RepaintBoundary(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 12.0),
                            child: SkeletonList(itemCount: 1),
                          ),
                        );
                      }

                      final p = state.displayedPoems[idx];
                      return RepaintBoundary(
                        key: ValueKey('poem_${p.id}'),
                        child: Padding(
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
        side: BorderSide(color: isSelected ? diwan.accentGold : diwan.border),
      ),
    );
  }

  Widget _buildTag(String text, Color color, DiwanThemeExtension diwan) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
