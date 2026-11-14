import 'package:flutter/material.dart';
import '../data/models/verse.dart';
import '../theme/theme_extension.dart';
import '../theme/typography.dart';
import 'diwan_card.dart';
import 'hemistich_row.dart';

/// بلاطة البيت الشعري الكاملة مع رقم البيت والإجراءات التفاعلية
class VerseTile extends StatelessWidget {
  final Verse verse;
  final bool isStacked;
  final double fontSize;
  final VoidCallback? onRecite;
  final VoidCallback? onMemorize;
  final VoidCallback? onPlayAudio;
  final bool isBookmarked;
  final VoidCallback? onToggleBookmark;

  const VerseTile({
    super.key,
    required this.verse,
    this.isStacked = false,
    this.fontSize = 20.0,
    this.onRecite,
    this.onMemorize,
    this.onPlayAudio,
    this.isBookmarked = false,
    this.onToggleBookmark,
  });

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
      child: DiwanCard(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        child: Column(
          children: [
            Row(
              textDirection: TextDirection.rtl,
              children: [
                VerseRosette(number: verse.verseOrder),
                const Spacer(),
                if (onPlayAudio != null)
                  IconButton(
                    icon: Icon(Icons.volume_up_rounded, color: diwan.accentGold, size: 22),
                    tooltip: 'استمع للبيت',
                    onPressed: onPlayAudio,
                  ),
                if (onToggleBookmark != null)
                  IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                      color: isBookmarked ? diwan.accentGold : diwan.textMuted,
                      size: 22,
                    ),
                    tooltip: 'حفظ في المفضلة',
                    onPressed: onToggleBookmark,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            HemistichRow(
              sadr: verse.sadr,
              ajuz: verse.ajuz,
              fontSize: fontSize,
              isStacked: isStacked,
            ),
            if (onRecite != null || onMemorize != null) ...[
              const SizedBox(height: 12),
              Divider(color: diwan.border, height: 1),
              const SizedBox(height: 8),
              Row(
                textDirection: TextDirection.rtl,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onMemorize != null)
                    TextButton.icon(
                      onPressed: onMemorize,
                      icon: Icon(Icons.psychology_rounded, size: 18, color: diwan.primary),
                      label: Text(
                        'تدريب الحفظ',
                        style: DiwanTypography.uiBody(color: diwan.primary, fontSize: 13),
                      ),
                    ),
                  const SizedBox(width: 8),
                  if (onRecite != null)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: diwan.surfaceElevated,
                        foregroundColor: diwan.accentGold,
                        side: BorderSide(color: diwan.borderGold),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      onPressed: onRecite,
                      icon: const Icon(Icons.mic_rounded, size: 16),
                      label: Text(
                        'تسميع البيت',
                        style: DiwanTypography.uiBody(
                          color: diwan.accentGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
