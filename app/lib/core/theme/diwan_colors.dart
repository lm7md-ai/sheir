import 'package:flutter/material.dart';

/// ألوان وهوية ديوان البصرية المستوحاة من المخطوطات الأندلسية والعباسية
class DiwanColors {
  DiwanColors._();

  // -------------------------------------------------------------
  // سمة حبر الليل (Midnight Ink) — AMOLED OLED Optimized (Default)
  // -------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0B0D10);
  static const Color darkSurface = Color(0xFF14181D);
  static const Color darkSurfaceElevated = Color(0xFF1C2229);
  static const Color darkBorder = Color(0xFF262E38);
  static const Color darkBorderGold = Color(0xFF4A3E25);
  static const Color darkTextPrimary = Color(0xFFEDE6D6); // عاجي دافئ
  static const Color darkTextSecondary = Color(0xFFA89F91);
  static const Color darkTextMuted = Color(0xFF6B655B);
  static const Color darkPrimary = Color(0xFF2FA58B); // زمردي
  static const Color darkAccentGold = Color(0xFFD4AF6A); // ذهب عتيق
  static const Color darkSecondaryBurgundy = Color(0xFF9E3D4D);

  // -------------------------------------------------------------
  // سمة الرّقّ والعاج (Parchment - Light)
  // -------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF6EFE0); // كريمي دافئ
  static const Color lightSurface = Color(0xFFFCF8F0);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2D5BE);
  static const Color lightBorderGold = Color(0xFFD1B272);
  static const Color lightTextPrimary = Color(0xFF1E1A16); // حبر أسود عتيق
  static const Color lightTextSecondary = Color(0xFF635B50);
  static const Color lightTextMuted = Color(0xFF91887D);
  static const Color lightPrimary = Color(0xFF0F5C4D); // زمردي عميق
  static const Color lightAccentGold = Color(0xFFB8893B); // ذهب أثري
  static const Color lightSecondaryBurgundy = Color(0xFF7A2E3A);

  // -------------------------------------------------------------
  // سمة السيبيا العتيقة (Vintage Sepia - للقراءة الهادئة الممتدة)
  // -------------------------------------------------------------
  static const Color sepiaBackground = Color(0xFFEDE1CB);
  static const Color sepiaSurface = Color(0xFFF5EBD7);
  static const Color sepiaSurfaceElevated = Color(0xFFFAF3E4);
  static const Color sepiaBorder = Color(0xFFD6C4A6);
  static const Color sepiaTextPrimary = Color(0xFF2D241E);
  static const Color sepiaTextSecondary = Color(0xFF6B5848);
  static const Color sepiaPrimary = Color(0xFF1A5B4C);
  static const Color sepiaAccentGold = Color(0xFFA8792A);

  // -------------------------------------------------------------
  // الألوان الدلالية للتسميع (Recitation Semantic Feedback - WCAG AA)
  // -------------------------------------------------------------
  // صحيح: أخضر زمردي
  static const Color recitationCorrectDark = Color(0xFF2FA58B);
  static const Color recitationCorrectLight = Color(0xFF0E6E52);

  // خطأ: أحمر قرمزي
  static const Color recitationWrongDark = Color(0xFFE04848);
  static const Color recitationWrongLight = Color(0xFFC22323);

  // تردد: كهرماني ذهبي
  static const Color recitationHesitationDark = Color(0xFFEAB308);
  static const Color recitationHesitationLight = Color(0xFF9E6700);

  // منسية / سقطت: رمادي حبري
  static const Color recitationMissingDark = Color(0xFF7D838D);
  static const Color recitationMissingLight = Color(0xFF5A606A);

  // زائدة: بنفسجي أرجواني
  static const Color recitationExtraDark = Color(0xFFA855F7);
  static const Color recitationExtraLight = Color(0xFF7E22CE);
}
