import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/theme/diwan_colors.dart';
import 'package:diwan/core/theme/theme_extension.dart';
import 'package:diwan/core/theme/typography.dart';
import 'package:diwan/core/theme/spacing.dart';
import 'package:diwan/core/theme/radii.dart';

void main() {
  group('Diwan Theme Contract & Non-Material Assertion (Gate 2)', () {
    test('السمة الداكنة لا تستخدم اللون الأزرق الافتراضي وتعتمد الزمردي الأندلسي', () {
      final darkTheme = ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: DiwanColors.darkBackground,
        primaryColor: DiwanColors.darkPrimary,
        fontFamily: DiwanTypography.fontUI,
        extensions: const [DiwanThemeExtension.midnightInk],
        colorScheme: const ColorScheme.dark(
          primary: DiwanColors.darkPrimary,
          secondary: DiwanColors.darkAccentGold,
          surface: DiwanColors.darkSurface,
          background: DiwanColors.darkBackground,
        ),
      );

      // تأكيد أن اللون الأساسي هو الزمردي (#2FA58B) وليس أزرق Material (#2196F3 أو البنفسجي الافتراضي)
      expect(darkTheme.colorScheme.primary, equals(const Color(0xFF2FA58B)));
      expect(darkTheme.colorScheme.primary, isNot(equals(Colors.blue)));
      expect(darkTheme.primaryColor, equals(const Color(0xFF2FA58B)));

      // تأكيد أن خط الواجهة هو الخط العربي المضمن وليس Roboto
      expect(darkTheme.textTheme.bodyMedium?.fontFamily ?? darkTheme.fontFamily, equals('Cairo'));
      expect(darkTheme.fontFamily, isNot(equals('Roboto')));
      expect(darkTheme.fontFamily, isNot(equals('')));
    });

    test('السمة الفاتحة (Parchment) تستخدم الرق والعاج والزمردي المعتمد', () {
      final lightTheme = ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: DiwanColors.lightBackground,
        primaryColor: DiwanColors.lightPrimary,
        fontFamily: DiwanTypography.fontUI,
        extensions: const [DiwanThemeExtension.parchment],
        colorScheme: const ColorScheme.light(
          primary: DiwanColors.lightPrimary,
          secondary: DiwanColors.lightAccentGold,
          surface: DiwanColors.lightSurface,
          background: DiwanColors.lightBackground,
        ),
      );

      expect(lightTheme.colorScheme.primary, equals(const Color(0xFF1B6B59)));
      expect(lightTheme.colorScheme.background, equals(const Color(0xFFF6EFE0)));
      expect(lightTheme.fontFamily, equals('Cairo'));
    });

    test('ملحق السمة DiwanThemeExtension يحتوي كافة رموز الألوان والتسميع الدلالية', () {
      final midnight = DiwanThemeExtension.midnightInk;
      expect(midnight.primary, equals(const Color(0xFF2FA58B)));
      expect(midnight.accentGold, equals(const Color(0xFFD4AF6A)));
      expect(midnight.recitationCorrect, equals(const Color(0xFF2FA58B)));
      expect(midnight.recitationWrong, equals(const Color(0xFFE05252)));
      expect(midnight.recitationHesitation, equals(const Color(0xFFD99B26)));
      expect(midnight.recitationMissing, equals(const Color(0xFF8C827A)));
      expect(midnight.recitationExtra, equals(const Color(0xFF8B5CF6)));

      // التحقق من ارتفاع السطر للأبيات المشكولة
      expect(midnight.verseLineHeight, greaterThanOrEqualTo(2.1));
    });

    test('رموز المسافات والأنصاف الدائرية (Spacing & Radii) معرفة ومطابقة للمواصفات', () {
      expect(DiwanSpacing.xs, equals(8.0));
      expect(DiwanSpacing.md, equals(16.0));
      expect(DiwanSpacing.lg, equals(24.0));

      expect(DiwanRadii.sm, equals(12.0));
      expect(DiwanRadii.md, equals(20.0));
      expect(DiwanRadii.lg, equals(28.0));
    });

    test('حظر letterSpacing على النصوص العربية لمنع كسر التماسك الخطي', () {
      final verseStyle = DiwanTypography.verseStyle();
      expect(verseStyle.letterSpacing, isNull);

      final titleStyle = DiwanTypography.displayCartouche();
      expect(titleStyle.letterSpacing, isNull);
    });
  });
}
