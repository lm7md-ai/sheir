import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';

/// عداد دقة التسميع الدائري الأندلسي المذهب (Illuminated Manuscript Accuracy Gauge)
class AccuracyGauge extends StatefulWidget {
  final double percentage;
  final String rankTitle;
  final double size;

  const AccuracyGauge({
    super.key,
    required this.percentage,
    required this.rankTitle,
    this.size = 180.0,
  });

  @override
  State<AccuracyGauge> createState() => _AccuracyGaugeState();
}

class _AccuracyGaugeState extends State<AccuracyGauge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _animation = Tween<double>(begin: 0.0, end: widget.percentage).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AccuracyGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.percentage != widget.percentage) {
      _animation = Tween<double>(begin: _animation.value, end: widget.percentage).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _GaugePainter(
            percentage: _animation.value,
            diwan: diwan,
          ),
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${_animation.value.toStringAsFixed(0)}%',
                  style: DiwanTypography.uiNumber(
                    color: diwan.accentGold,
                    fontSize: widget.size * 0.22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.rankTitle,
                  textDirection: TextDirection.rtl,
                  style: DiwanTypography.displayCartouche(
                    color: diwan.primary,
                    fontSize: widget.size * 0.095,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  final DiwanThemeExtension diwan;

  _GaugePainter({required this.percentage, required this.diwan});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 12;

    // الحلقة المدارية الخلفية
    final trackPaint = Paint()
      ..color = diwan.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;

    // مسار القوس المفتوح من الأسفل (240 درجة)
    const startAngle = 150 * (math.pi / 180);
    const sweepTotal = 240 * (math.pi / 180);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepTotal,
      false,
      trackPaint,
    );

    // قوس الإنجاز المتدرج (Emerald & Gold)
    final progressSweep = sweepTotal * (percentage / 100.0).clamp(0.0, 1.0);
    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: startAngle,
        endAngle: startAngle + sweepTotal,
        colors: [
          diwan.primary,
          diwan.accentGold,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9.0
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      progressSweep,
      false,
      progressPaint,
    );

    // دائرة تأطير زخرفية داخلية
    final innerFrame = Paint()
      ..color = diwan.borderGold.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius - 16, innerFrame);
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.percentage != percentage || oldDelegate.diwan != diwan;
}
