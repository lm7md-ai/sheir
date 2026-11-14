import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logs/diwan_logger.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';
import '../widgets/diwan_card.dart';

/// حاجز الأخطاء الشامل (Global Error Boundary)
/// يحمي التطبيق من الانهيار المفاجئ ويعرض شاشة مخطوطية أنيقة مع أدوات نسخ وتصدير السجلات
class DiwanErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onOpenLogs;

  const DiwanErrorBoundary({
    super.key,
    required this.child,
    this.onOpenLogs,
  });

  @override
  State<DiwanErrorBoundary> createState() => _DiwanErrorBoundaryState();
}

class _DiwanErrorBoundaryState extends State<DiwanErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  void initState() {
    super.initState();
  }

  static void reportError(Object error, StackTrace? stackTrace) {
    DiwanLogger.instance.error('GlobalErrorBoundary', 'Unhandled error caught', error, stackTrace);
  }

  void _resetError() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      final diwan = context.diwan;
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: Theme.of(context),
        home: Scaffold(
          backgroundColor: diwan.background,
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: DiwanCard(
                hasGoldBorder: true,
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: diwan.recitationWrong.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: diwan.recitationWrong, width: 1.5),
                      ),
                      child: Icon(Icons.warning_amber_rounded, color: diwan.recitationWrong, size: 36),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'طرأ تعثرٌ غير متوقع في محبرة ديوان',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: DiwanTypography.displayCartouche(
                        color: diwan.accentGold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'نعتذر منك؛ واجه التطبيق خطأً غير متوقع أثناء معالجة الصفحة، وقد تم تسجيل هذا الحادث في سجلات التشخيص المحلية لمراجعته.',
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: DiwanTypography.uiBody(
                        color: diwan.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: diwan.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: diwan.border),
                      ),
                      child: Text(
                        _error.toString(),
                        textDirection: TextDirection.ltr,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: diwan.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _resetError,
                            icon: const Icon(Icons.refresh_rounded, size: 18),
                            label: const Text('إعادة المحاولة'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: diwan.accentGold,
                              side: BorderSide(color: diwan.borderGold),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: () {
                              final report = 'Diwan Error Report:\n$_error\n\nStackTrace:\n$_stackTrace';
                              Clipboard.setData(ClipboardData(text: report));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم نسخ تقرير التشخيص إلى الحافظة')),
                              );
                            },
                            icon: const Icon(Icons.copy_rounded, size: 18),
                            label: const Text('نسخ التقرير'),
                          ),
                        ),
                      ],
                    ),
                    if (widget.onOpenLogs != null) ...[
                      const SizedBox(height: 10),
                      TextButton.icon(
                        onPressed: widget.onOpenLogs,
                        icon: Icon(Icons.receipt_long_rounded, color: diwan.textMuted, size: 16),
                        label: Text(
                          'استعراض سجل العمليات والتشخيص الكامل',
                          style: DiwanTypography.uiBody(color: diwan.textMuted, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
