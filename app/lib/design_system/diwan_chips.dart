import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/theme/typography.dart';
import '../core/theme/spacing.dart';
import '../core/theme/radii.dart';

enum DiwanChipVariant { primary, gold, burgundy, surface }

/// رقاقة وسوم موحدة تعتمد كلياً على رموز السمة (Theme Tokens Only)
class DiwanChip extends StatelessWidget {
  final String label;
  final DiwanChipVariant variant;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;

  const DiwanChip({
    super.key,
    required this.label,
    this.variant = DiwanChipVariant.primary,
    this.icon,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    Color baseColor;

    switch (variant) {
      case DiwanChipVariant.primary:
        baseColor = diwan.primary;
        break;
      case DiwanChipVariant.gold:
        baseColor = diwan.accentGold;
        break;
      case DiwanChipVariant.burgundy:
        baseColor = diwan.secondaryBurgundy;
        break;
      case DiwanChipVariant.surface:
        baseColor = diwan.textSecondary;
        break;
    }

    final bg = isSelected ? baseColor.withOpacity(0.24) : baseColor.withOpacity(0.12);
    final border = isSelected ? baseColor : baseColor.withOpacity(0.4);

    return InkWell(
      onTap: onTap,
      borderRadius: DiwanRadii.radiusSm,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: DiwanSpacing.sm,
          vertical: DiwanSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: DiwanRadii.radiusSm,
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          textDirection: TextDirection.rtl,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: baseColor),
              const SizedBox(width: DiwanSpacing.xxs),
            ],
            Text(
              label,
              style: DiwanTypography.uiBody(
                color: baseColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
