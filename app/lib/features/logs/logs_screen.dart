import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/logs/diwan_logger.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';

/// شاشة سجلات التشخيص والعمليات الداخلية للتطبيق (In-App Logs Screen)
/// تدعم التصفية حسب المستوى، البحث النصي، نسخ السجل، ومشاركة تقرير الأخطاء
class LogsScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const LogsScreen({super.key, this.onBack});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  DiwanLogLevel? _filterLevel;
  String _searchQuery = '';

  void _copyAllLogs(BuildContext context) {
    final exported = DiwanLogger.instance.exportLogsAsString();
    Clipboard.setData(ClipboardData(text: exported));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ كامل سجل العمليات إلى الحافظة بنجاح'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _shareDiagnosticReport(BuildContext context) {
    final exported = DiwanLogger.instance.exportLogsAsString();
    Clipboard.setData(ClipboardData(text: exported));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ تقرير التشخيص؛ جاهز للمشاركة وإرساله للمطورين'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _copySingleEntry(BuildContext context, DiwanLogEntry entry) {
    final text = '[${entry.formattedTime}] [${entry.level.name.toUpperCase()}] [${entry.tag}] ${entry.message}'
        '${entry.stackTrace != null ? "\n${entry.stackTrace}" : ""}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('تم نسخ السجل [${entry.tag}] إلى الحافظة'),
        duration: const Duration(seconds: 1),
      ),
    );
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
          'سجل العمليات والتشخيص',
          style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 17),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            color: diwan.accentGold,
            tooltip: 'مشاركة تقرير التشخيص',
            onPressed: () => _shareDiagnosticReport(context),
          ),
          IconButton(
            icon: const Icon(Icons.copy_all_rounded),
            color: diwan.accentGold,
            tooltip: 'نسخ كامل السجل',
            onPressed: () => _copyAllLogs(context),
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            color: diwan.recitationWrong,
            tooltip: 'مسح السجلات',
            onPressed: () {
              setState(() {
                DiwanLogger.instance.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إفراغ سجل العمليات')),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // شريط التصفية والبحث
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    textDirection: TextDirection.rtl,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: DiwanTypography.uiBody(color: diwan.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'ابحث في السجلات (الوسم، الرسالة)...',
                      hintTextDirection: TextDirection.rtl,
                      hintStyle: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded, color: diwan.accentGold, size: 18),
                      filled: true,
                      fillColor: diwan.surface,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: diwan.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // خيارات التصفية حسب مستوى الخطورة
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14.0),
            child: Row(
              children: [
                _buildFilterChip('الكل', _filterLevel == null, () => setState(() => _filterLevel = null), diwan),
                _buildFilterChip('معلومات (Info)', _filterLevel == DiwanLogLevel.info, () => setState(() => _filterLevel = DiwanLogLevel.info), diwan),
                _buildFilterChip('تحذيرات (Warn)', _filterLevel == DiwanLogLevel.warn, () => setState(() => _filterLevel = DiwanLogLevel.warn), diwan),
                _buildFilterChip('أخطاء (Error)', _filterLevel == DiwanLogLevel.error, () => setState(() => _filterLevel = DiwanLogLevel.error), diwan),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // قائمة السجلات الحية
          Expanded(
            child: ValueListenableBuilder<List<DiwanLogEntry>>(
              valueListenable: DiwanLogger.instance.logsNotifier,
              builder: (context, allLogs, child) {
                final filtered = allLogs.where((entry) {
                  if (_filterLevel != null && entry.level != _filterLevel) return false;
                  if (_searchQuery.isNotEmpty) {
                    final q = _searchQuery.toLowerCase();
                    final matchTag = entry.tag.toLowerCase().contains(q);
                    final matchMsg = entry.message.toLowerCase().contains(q);
                    if (!matchTag && !matchMsg) return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'لا توجد سجلات تطابق البحث الحالي',
                      style: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 13),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, idx) {
                    final log = filtered[idx];
                    Color levelColor = diwan.primary;
                    if (log.level == DiwanLogLevel.warn) levelColor = diwan.recitationHesitation;
                    if (log.level == DiwanLogLevel.error) levelColor = diwan.recitationWrong;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: DiwanCard(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              textDirection: TextDirection.rtl,
                              children: [
                                Row(
                                  children: [
                                    Text(log.levelIcon),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: levelColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: levelColor.withOpacity(0.4)),
                                      ),
                                      child: Text(
                                        log.tag,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: levelColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Text(
                                      log.formattedTime,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontFamily: 'monospace',
                                        color: diwan.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 14),
                                      color: diwan.textMuted,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: 'نسخ هذا السجل',
                                      onPressed: () => _copySingleEntry(context, log),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              log.message,
                              textDirection: TextDirection.rtl,
                              style: DiwanTypography.uiBody(
                                color: diwan.textPrimary,
                                fontSize: 13,
                              ),
                            ),
                            if (log.stackTrace != null) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: diwan.surfaceElevated,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  log.stackTrace!,
                                  textDirection: TextDirection.ltr,
                                  maxLines: 4,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 10,
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  },
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
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide(color: isSelected ? diwan.accentGold : diwan.border),
      ),
    );
  }
}
