import 'package:flutter/material.dart';

/// منظومة الخطوط والطباعة العربية لديوان
/// تطبق بدقة القواعد الذهبية للخط العربي:
/// 1. حظر تام لاستخدام letterSpacing منعاً لتفكك اتصال الحروف.
/// 2. ارتفاع سطر وافر (2.1 - 2.4) لحماية الحركات والتشكيل من التداخل.
/// 3. التوجيه القسري لليمين TextDirection.rtl.
class DiwanTypography {
  DiwanTypography._();

  static const String fontPoetry = 'Amiri';
  static const String fontPoetryQuran = 'AmiriQuran';
  static const String fontDisplay = 'ArefRuqaa';
  static const String fontUI = 'Cairo';

  /// نمط أبيات الشعر الكلاسيكية المشكولة
  static TextStyle verseStyle({
    required Color color,
    double fontSize = 21.0,
    double lineHeight = 2.2,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: fontPoetry,
      fontSize: fontSize,
      height: lineHeight,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.0, // حظر التباعد منعاً لكسر الاتصال
    );
  }

  /// نمط عناوين الطغراء وأسماء الشعراء في خراطيش التذهيب
  static TextStyle displayCartouche({
    required Color color,
    double fontSize = 24.0,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: fontDisplay,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.4,
      letterSpacing: 0.0,
    );
  }

  /// نمط واجهة المستخدم والأزرار والتبويبات
  static TextStyle uiBody({
    required Color color,
    double fontSize = 14.0,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    return TextStyle(
      fontFamily: fontUI,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.5,
      letterSpacing: 0.0,
    );
  }

  /// نمط الأزرار والعناوين البارزة في واجهة المستخدم
  static TextStyle uiTitle({
    required Color color,
    double fontSize = 16.0,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return TextStyle(
      fontFamily: fontUI,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.4,
      letterSpacing: 0.0,
    );
  }

  /// نمط أرقام الأبيات والنسب المئوية
  static TextStyle uiNumber({
    required Color color,
    double fontSize = 15.0,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return TextStyle(
      fontFamily: fontUI,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: 0.0,
    );
  }
}
