import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

/// بطاقة ديوان المخطوطية الفاخرة ذات اللمسات الأندلسية والتذهيب الهادئ
class DiwanCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hasGoldBorder;
  final double? width;
  final double? height;

  const DiwanCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18.0),
    this.onTap,
    this.hasGoldBorder = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: diwan.surface,
        borderRadius: BorderRadius.circular(diwan.cardRadius),
        border: Border.all(
          color: hasGoldBorder ? diwan.borderGold : diwan.border,
          width: hasGoldBorder ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: hasGoldBorder
                ? diwan.accentGold.withOpacity(0.08)
                : Colors.black.withOpacity(0.18),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(diwan.cardRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(diwan.cardRadius),
          onTap: onTap,
          highlightColor: diwan.accentGold.withOpacity(0.05),
          splashColor: diwan.primary.withOpacity(0.08),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}
