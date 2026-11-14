import 'package:flutter/material.dart';

enum DiwanThemeType { midnightInk, parchment, sepia }
enum DiwanStrictness { loose, medium, strict }
enum AsrModelChoice {
  sherpaArabicOnnx,  // Sherpa-ONNX Arabic (35 MB)
  wav2vec2Quantized, // Wav2Vec2 Arabic CTC (85 MB)
  whisperTinyArabic, // Whisper.cpp Tiny Arabic (39 MB)
}

/// موفر وإدارة تفضيلات وإعدادات تطبيق ديوان الشاملة
class DiwanSettingsState {
  final DiwanThemeType theme;
  final String fontFamily;
  final double fontScale;
  final bool dialectTolerance;
  final DiwanStrictness strictness;
  final bool ignoreDiacritics;
  final AsrModelChoice asrModel;
  final double hesitationThresholdSeconds;
  final int dailyGoalVerses;
  final TimeOfDay morningReminderTime;
  final TimeOfDay eveningReminderTime;
  final bool notificationsEnabled;

  const DiwanSettingsState({
    this.theme = DiwanThemeType.midnightInk,
    this.fontFamily = 'Amiri',
    this.fontScale = 1.0,
    this.dialectTolerance = true,
    this.strictness = DiwanStrictness.medium,
    this.ignoreDiacritics = false,
    this.asrModel = AsrModelChoice.sherpaArabicOnnx,
    this.hesitationThresholdSeconds = 2.0,
    this.dailyGoalVerses = 10,
    this.morningReminderTime = const TimeOfDay(hour: 6, minute: 0),
    this.eveningReminderTime = const TimeOfDay(hour: 20, minute: 30),
    this.notificationsEnabled = true,
  });

  DiwanSettingsState copyWith({
    DiwanThemeType? theme,
    String? fontFamily,
    double? fontScale,
    bool? dialectTolerance,
    DiwanStrictness? strictness,
    bool? ignoreDiacritics,
    AsrModelChoice? asrModel,
    double? hesitationThresholdSeconds,
    int? dailyGoalVerses,
    TimeOfDay? morningReminderTime,
    TimeOfDay? eveningReminderTime,
    bool? notificationsEnabled,
  }) {
    return DiwanSettingsState(
      theme: theme ?? this.theme,
      fontFamily: fontFamily ?? this.fontFamily,
      fontScale: fontScale ?? this.fontScale,
      dialectTolerance: dialectTolerance ?? this.dialectTolerance,
      strictness: strictness ?? this.strictness,
      ignoreDiacritics: ignoreDiacritics ?? this.ignoreDiacritics,
      asrModel: asrModel ?? this.asrModel,
      hesitationThresholdSeconds: hesitationThresholdSeconds ?? this.hesitationThresholdSeconds,
      dailyGoalVerses: dailyGoalVerses ?? this.dailyGoalVerses,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
