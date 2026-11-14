import 'package:flutter/material.dart';
import 'diwan_colors.dart';

/// ملحق سمة ديوان المخصص لحمل الرموز البصرية والألوان الدلالية للتسميع
@immutable
class DiwanThemeExtension extends ThemeExtension<DiwanThemeExtension> {
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color border;
  final Color borderGold;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color primary;
  final Color accentGold;
  final Color secondaryBurgundy;

  // ألوان التسميع الدلالية
  final Color recitationCorrect;
  final Color recitationWrong;
  final Color recitationHesitation;
  final Color recitationMissing;
  final Color recitationExtra;

  final double cardRadius;
  final double verseLineHeight;

  const DiwanThemeExtension({
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.border,
    required this.borderGold,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.primary,
    required this.accentGold,
    required this.secondaryBurgundy,
    required this.recitationCorrect,
    required this.recitationWrong,
    required this.recitationHesitation,
    required this.recitationMissing,
    required this.recitationExtra,
    this.cardRadius = 20.0,
    this.verseLineHeight = 2.2,
  });

  // 1. سمة حبر الليل (Midnight Ink) — الافتراضية لشاشات AMOLED
  static const DiwanThemeExtension midnightInk = DiwanThemeExtension(
    background: DiwanColors.darkBackground,
    surface: DiwanColors.darkSurface,
    surfaceElevated: DiwanColors.darkSurfaceElevated,
    border: DiwanColors.darkBorder,
    borderGold: DiwanColors.darkBorderGold,
    textPrimary: DiwanColors.darkTextPrimary,
    textSecondary: DiwanColors.darkTextSecondary,
    textMuted: DiwanColors.darkTextMuted,
    primary: DiwanColors.darkPrimary,
    accentGold: DiwanColors.darkAccentGold,
    secondaryBurgundy: DiwanColors.darkSecondaryBurgundy,
    recitationCorrect: DiwanColors.recitationCorrectDark,
    recitationWrong: DiwanColors.recitationWrongDark,
    recitationHesitation: DiwanColors.recitationHesitationDark,
    recitationMissing: DiwanColors.recitationMissingDark,
    recitationExtra: DiwanColors.recitationExtraDark,
  );

  // 2. سمة الرَّقّ والعاج (Parchment - Light)
  static const DiwanThemeExtension parchment = DiwanThemeExtension(
    background: DiwanColors.lightBackground,
    surface: DiwanColors.lightSurface,
    surfaceElevated: DiwanColors.lightSurfaceElevated,
    border: DiwanColors.lightBorder,
    borderGold: DiwanColors.lightBorderGold,
    textPrimary: DiwanColors.lightTextPrimary,
    textSecondary: DiwanColors.lightTextSecondary,
    textMuted: DiwanColors.lightTextMuted,
    primary: DiwanColors.lightPrimary,
    accentGold: DiwanColors.lightAccentGold,
    secondaryBurgundy: DiwanColors.lightSecondaryBurgundy,
    recitationCorrect: DiwanColors.recitationCorrectLight,
    recitationWrong: DiwanColors.recitationWrongLight,
    recitationHesitation: DiwanColors.recitationHesitationLight,
    recitationMissing: DiwanColors.recitationMissingLight,
    recitationExtra: DiwanColors.recitationExtraLight,
  );

  // 3. سمة السيبيا العتيقة (Sepia)
  static const DiwanThemeExtension sepia = DiwanThemeExtension(
    background: DiwanColors.sepiaBackground,
    surface: DiwanColors.sepiaSurface,
    surfaceElevated: DiwanColors.sepiaSurfaceElevated,
    border: DiwanColors.sepiaBorder,
    borderGold: DiwanColors.sepiaAccentGold,
    textPrimary: DiwanColors.sepiaTextPrimary,
    textSecondary: DiwanColors.sepiaTextSecondary,
    textMuted: DiwanColors.sepiaTextSecondary,
    primary: DiwanColors.sepiaPrimary,
    accentGold: DiwanColors.sepiaAccentGold,
    secondaryBurgundy: DiwanColors.lightSecondaryBurgundy,
    recitationCorrect: DiwanColors.recitationCorrectLight,
    recitationWrong: DiwanColors.recitationWrongLight,
    recitationHesitation: DiwanColors.recitationHesitationLight,
    recitationMissing: DiwanColors.recitationMissingLight,
    recitationExtra: DiwanColors.recitationExtraLight,
  );

  @override
  DiwanThemeExtension copyWith({
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? border,
    Color? borderGold,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? primary,
    Color? accentGold,
    Color? secondaryBurgundy,
    Color? recitationCorrect,
    Color? recitationWrong,
    Color? recitationHesitation,
    Color? recitationMissing,
    Color? recitationExtra,
    double? cardRadius,
    double? verseLineHeight,
  }) {
    return DiwanThemeExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      borderGold: borderGold ?? this.borderGold,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      accentGold: accentGold ?? this.accentGold,
      secondaryBurgundy: secondaryBurgundy ?? this.secondaryBurgundy,
      recitationCorrect: recitationCorrect ?? this.recitationCorrect,
      recitationWrong: recitationWrong ?? this.recitationWrong,
      recitationHesitation: recitationHesitation ?? this.recitationHesitation,
      recitationMissing: recitationMissing ?? this.recitationMissing,
      recitationExtra: recitationExtra ?? this.recitationExtra,
      cardRadius: cardRadius ?? this.cardRadius,
      verseLineHeight: verseLineHeight ?? this.verseLineHeight,
    );
  }

  @override
  DiwanThemeExtension lerp(ThemeExtension<DiwanThemeExtension>? other, double t) {
    if (other is! DiwanThemeExtension) return this;
    return DiwanThemeExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderGold: Color.lerp(borderGold, other.borderGold, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      accentGold: Color.lerp(accentGold, other.accentGold, t)!,
      secondaryBurgundy: Color.lerp(secondaryBurgundy, other.secondaryBurgundy, t)!,
      recitationCorrect: Color.lerp(recitationCorrect, other.recitationCorrect, t)!,
      recitationWrong: Color.lerp(recitationWrong, other.recitationWrong, t)!,
      recitationHesitation: Color.lerp(recitationHesitation, other.recitationHesitation, t)!,
      recitationMissing: Color.lerp(recitationMissing, other.recitationMissing, t)!,
      recitationExtra: Color.lerp(recitationExtra, other.recitationExtra, t)!,
      cardRadius: cardRadius + (other.cardRadius - cardRadius) * t,
      verseLineHeight: verseLineHeight + (other.verseLineHeight - verseLineHeight) * t,
    );
  }
}

/// امتداد مساعد للوصول السريع إلى رموز ديوان عبر السياق `context.diwan`
extension DiwanThemeContext on BuildContext {
  DiwanThemeExtension get diwan =>
      Theme.of(this).extension<DiwanThemeExtension>() ?? DiwanThemeExtension.midnightInk;
}
