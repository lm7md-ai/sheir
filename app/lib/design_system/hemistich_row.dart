import 'package:flutter/material.dart';
import '../core/theme/theme_extension.dart';
import '../core/theme/typography.dart';

/// شمسة فاصلة بين شطري البيت الشعري (Rosette Hemistich Divider)
class RosetteDivider extends StatelessWidget {
  final double size;

  const RosetteDivider({super.key, this.size = 22.0});

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return CustomPaint(
      size: Size(size, size),
      painter: _RosettePainter(goldColor: diwan.accentGold),
    );
  }
}

class _RosettePainter extends CustomPainter {
  final Color goldColor;

  _RosettePainter({required this.goldColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = goldColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = goldColor.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // الدائرة المركزية
    canvas.drawCircle(center, size.width * 0.14, paint);

    // حلقة منقطة محيطة
    canvas.drawCircle(center, size.width * 0.42, linePaint);

    // أربع ورقات زخرفية متقاطعة
    final r = size.width * 0.38;
    canvas.drawCircle(Offset(center.dx, center.dy - r), 1.8, paint);
    canvas.drawCircle(Offset(center.dx, center.dy + r), 1.8, paint);
    canvas.drawCircle(Offset(center.dx - r, center.dy), 1.8, paint);
    canvas.drawCircle(Offset(center.dx + r, center.dy), 1.8, paint);
  }

  @override
  bool shouldRepaint(covariant _RosettePainter oldDelegate) =>
      oldDelegate.goldColor != goldColor;
}

/// شمسة أرقام الأبيات المخطوطية (Verse Number Rosette)
class VerseRosette extends StatelessWidget {
  final int number;
  final double size;

  const VerseRosette({
    super.key,
    required this.number,
    this.size = 32.0,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: diwan.surfaceElevated,
        border: Border.all(color: diwan.borderGold, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: diwan.accentGold.withOpacity(0.12),
            blurRadius: 6,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: DiwanTypography.uiNumber(
          color: diwan.accentGold,
          fontSize: size * 0.42,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// العرض الكلاسيكي لشطري البيت الشعري (صدر وعجز وفاصلة)
class HemistichRow extends StatelessWidget {
  final String sadr;
  final String ajuz;
  final double fontSize;
  final bool isStacked;
  final TextStyle? customStyle;

  const HemistichRow({
    super.key,
    required this.sadr,
    required this.ajuz,
    this.fontSize = 20.0,
    this.isStacked = false,
    this.customStyle,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;
    final defaultStyle = DiwanTypography.verseStyle(
      color: diwan.textPrimary,
      fontSize: fontSize,
      lineHeight: diwan.verseLineHeight,
    );
    final textStyle = customStyle ?? defaultStyle;

    if (isStacked) {
      // الوضع المكدس للشاشات الضيقة أو الخطوط الكبيرة
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            sadr,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: textStyle,
          ),
          const SizedBox(height: 4),
          const RosetteDivider(size: 18),
          const SizedBox(height: 4),
          Text(
            ajuz,
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: textStyle,
          ),
        ],
      );
    }

    // التنسيق الكلاسيكي للشعر العربي: صدر على اليمين وعجز على اليسار
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        // شطر الصدر (الأيمن)
        Expanded(
          child: Text(
            sadr,
            textAlign: TextAlign.left,
            textDirection: TextDirection.rtl,
            style: textStyle,
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 14.0),
          child: RosetteDivider(size: 22),
        ),
        // شطر العجز (الأيسر)
        Expanded(
          child: Text(
            ajuz,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: textStyle,
          ),
        ),
      ],
    );
  }
}
