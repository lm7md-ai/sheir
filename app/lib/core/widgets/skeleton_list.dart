import 'package:flutter/material.dart';
import '../theme/theme_extension.dart';

/// وميض المخطوطة العاجي لحالة التحميل (Manuscript Shimmer Skeleton)
class SkeletonList extends StatefulWidget {
  final int itemCount;

  const SkeletonList({super.key, this.itemCount = 5});

  @override
  State<SkeletonList> createState() => _SkeletonListState();
}

class _SkeletonListState extends State<SkeletonList> with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final baseColor = diwan.surface;
        final highlightColor = diwan.borderGold.withOpacity(0.18);

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.itemCount,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemBuilder: (ctx, index) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: baseColor,
                borderRadius: BorderRadius.circular(diwan.cardRadius),
                border: Border.all(color: diwan.border),
              ),
              child: Column(
                children: [
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      _buildShimmerBox(30, 30, true, highlightColor, diwan),
                      const Spacer(),
                      _buildShimmerBox(60, 18, false, highlightColor, diwan),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Expanded(child: _buildShimmerBox(double.infinity, 16, false, highlightColor, diwan)),
                      const SizedBox(width: 16),
                      _buildShimmerBox(18, 18, true, highlightColor, diwan),
                      const SizedBox(width: 16),
                      Expanded(child: _buildShimmerBox(double.infinity, 16, false, highlightColor, diwan)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildShimmerBox(
    double width,
    double height,
    bool isCircle,
    Color highlight,
    DiwanThemeExtension diwan,
  ) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: diwan.surfaceElevated,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(8),
        border: Border.all(color: highlight, width: 0.8),
      ),
    );
  }
}
