import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/theme_extension.dart';

/// زر التسجيل النابض مع موجات صوتية حية واهتزازات لمسية (Animated Pulse Record Button)
class RecordButton extends StatefulWidget {
  final bool isRecording;
  final VoidCallback? onToggle;
  final VoidCallback? onTap;
  final double size;

  const RecordButton({
    super.key,
    required this.isRecording,
    this.onToggle,
    this.onTap,
    this.size = 76.0,
  });

  @override
  State<RecordButton> createState() => _RecordButtonState();
}

class _RecordButtonState extends State<RecordButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isRecording) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant RecordButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isRecording != oldWidget.isRecording) {
      if (widget.isRecording) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.mediumImpact();
    (widget.onToggle ?? widget.onTap)?.call();
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Center(
      child: GestureDetector(
        onTap: _handleTap,
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            final scale = widget.isRecording ? _pulseAnimation.value : 1.0;
            return Stack(
              alignment: Alignment.center,
              children: [
                // موجة الهالة النابضة أثناء التسجيل
                if (widget.isRecording)
                  Container(
                    width: widget.size * scale * 1.35,
                    height: widget.size * scale * 1.35,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: diwan.primary.withOpacity(0.18),
                    ),
                  ),
                if (widget.isRecording)
                  Container(
                    width: widget.size * scale * 1.15,
                    height: widget.size * scale * 1.15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: diwan.accentGold.withOpacity(0.22),
                    ),
                  ),
                // الزر الرئيسي
                Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: widget.isRecording
                          ? [diwan.recitationWrong, diwan.secondaryBurgundy]
                          : [diwan.primary, diwan.accentGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: diwan.accentGold,
                      width: 2.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (widget.isRecording ? diwan.recitationWrong : diwan.primary)
                            .withOpacity(0.35),
                        blurRadius: 18,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                    color: Colors.white,
                    size: widget.size * 0.44,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
