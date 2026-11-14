import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/theme/typography.dart';

/// رأس قسم مخطوطي مع خط تذهيب وزر خيار اختياري
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: diwan.accentGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            textDirection: TextDirection.rtl,
            style: DiwanTypography.displayCartouche(
              color: diwan.accentGold,
              fontSize: 19,
            ),
          ),
          const Spacer(),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: DiwanTypography.uiBody(
                  color: diwan.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
