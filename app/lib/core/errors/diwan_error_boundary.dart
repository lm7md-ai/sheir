import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../logs/diwan_logger.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';
import '../widgets/diwan_card.dart';
import 'diwan_exception.dart';

class DiwanErrorState {
  final Object error;
  final StackTrace? stackTrace;
  final DateTime timestamp;

  DiwanErrorState({
    required this.error,
    this.stackTrace,
  }) : timestamp = DateTime.now();
}

/// حاجز الأخطاء الشامل (Global Error Boundary)
/// يحمي شجرة التطبيق من الانهيار المفاجئ ويعرض شاشة مخطوطية أنيقة مع رسائل عربية فصيحة وأدوات نسخ وتصدير السجلات
class DiwanErrorBoundary extends StatefulWidget {
  final Widget child;
  final VoidCallback? onOpenLogs;

  const DiwanErrorBoundary({
    super.key,
    required this.child,
    this.onOpenLogs,
  });

  /// مخزن الإشعار العام للأخطاء المعترضة
  static final ValueNotifier<DiwanErrorState?> globalErrorNotifier =
      ValueNotifier<DiwanErrorState?>(null);

  /// تسجيل واعتراض أي خطأ غير معالج وتحديث واجهة الحاجز تلقائياً
  static void reportError(Object error, StackTrace? stackTrace) {
    DiwanLogger.instance.error(
      'GlobalErrorBoundary',
      'تم اعتراض خطأ غير معالج: $error',
      error,
      stackTrace,
    );
    globalErrorNotifier.value = DiwanErrorState(
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// إعادة تعيين حالة الخطأ يدوياً
  static void clearError() {
    globalErrorNotifier.value = null;
  }

  @override
  State<DiwanErrorBoundary> createState() => _DiwanErrorBoundaryState();
}

class _DiwanErrorBoundaryState extends State<DiwanErrorBoundary> {
  DiwanErrorState? _errorState;

  @override
  void initState() {
    super.initState();
    _errorState = DiwanErrorBoundary.globalErrorNotifier.value;
    DiwanErrorBoundary.globalErrorNotifier.addListener(_onErrorNotification);
  }

  @override
  void dispose() {
    DiwanErrorBoundary.globalErrorNotifier.removeListener(_onErrorNotification);
    super.dispose();
  }

  void _onErrorNotification() {
    if (mounted) {
      setState(() {
        _errorState = DiwanErrorBoundary.globalErrorNotifier.value;
      });
    }
  }

  void _resetError() {
    DiwanErrorBoundary.clearError();
    setState(() {
      _errorState = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_errorState != null) {
      final diwan = context.diwan;
      final error = _errorState!.error;
      final stackTrace = _errorState!.stackTrace;

      final isDiwanException = error is DiwanException;
      final title = isDiwanException
          ? error.titleArabic
          : 'طرأ تعثرٌ غير متوقع في محبرة ديوان';
      final message = isDiwanException
          ? error.messageArabic
          : 'نعتذر منك؛ واجه التطبيق خطأً غير متوقع أثناء معالجة الصفحة، وقد تم تدوين تفاصيل الحادث في سجلات التشخيص لمراجعته.';
      final recovery = isDiwanException
          ? error.recoveryActionArabic
          : 'إجراء مقترح: اضغط على زر إعادة المحاولة، أو تحقق من خيارات استعادة البيانات في شاشة الإعدادات.';

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
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: diwan.recitationWrong.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: diwan.recitationWrong, width: 1.5),
                      ),
                      child: Icon(
                        Icons.warning_amber_rounded,
                        color: diwan.recitationWrong,
                        size: 38,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: DiwanTypography.displayCartouche(
                        color: diwan.accentGold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                      style: DiwanTypography.uiBody(
                        color: diwan.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    if (recovery != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: diwan.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: diwan.primary.withOpacity(0.3)),
                        ),
                        child: Text(
                          recovery,
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                          style: DiwanTypography.uiBody(
                            color: diwan.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
                        error.toString(),
                        textDirection: TextDirection.ltr,
                        maxLines: 4,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              final report = 'Diwan Error Report:\n$error\n\nStackTrace:\n$stackTrace';
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
                      const SizedBox(height: 12),
                      TextButton.icon(
                        onPressed: () {
                          _resetError();
                          widget.onOpenLogs!();
                        },
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

/// بطاقة خطأ ودية مضمنة وقابلة لإعادة الاستخدام في أي مكان داخل شاشات التطبيق
class DiwanFriendlyErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final String? recoveryAction;
  final VoidCallback? onRetry;
  final VoidCallback? onCopyReport;

  const DiwanFriendlyErrorCard({
    super.key,
    required this.title,
    required this.message,
    this.recoveryAction,
    this.onRetry,
    this.onCopyReport,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return DiwanCard(
      hasGoldBorder: true,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.info_outline_rounded, color: diwan.accentGold, size: 32),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: DiwanTypography.displayCartouche(
              color: diwan.accentGold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: DiwanTypography.uiBody(
              color: diwan.textSecondary,
              fontSize: 12,
            ),
          ),
          if (recoveryAction != null) ...[
            const SizedBox(height: 8),
            Text(
              recoveryAction!,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: DiwanTypography.uiBody(
                color: diwan.primary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (onRetry != null || onCopyReport != null) ...[
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onRetry != null)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: diwan.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('إعادة المحاولة', style: TextStyle(fontSize: 12)),
                  ),
                if (onRetry != null && onCopyReport != null)
                  const SizedBox(width: 8),
                if (onCopyReport != null)
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: diwan.accentGold,
                      side: BorderSide(color: diwan.borderGold),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onCopyReport,
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('نسخ', style: TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
