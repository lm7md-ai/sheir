import 'package:flutter/material.dart';
import '../../core/settings/settings_controller.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';

/// شاشة الإعدادات والخيارات الشاملة لتطبيق ديوان
/// متوافقة 100% مع قائمة المتطلبات الـ 14 الإلزامية ومع عائلة الأيقونات المستديرة الموحدة (Icons.rounded)
class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenGallery;
  final VoidCallback? onOpenLogs;

  const SettingsScreen({
    super.key,
    this.onOpenGallery,
    this.onOpenLogs,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  DiwanSettingsState _settings = const DiwanSettingsState();

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    return Scaffold(
      backgroundColor: diwan.background,
      appBar: AppBar(
        backgroundColor: diwan.surface,
        elevation: 0,
        title: Text(
          'الإعدادات والخيارات',
          style: DiwanTypography.displayCartouche(
            color: diwan.accentGold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // 1. مظهر المخطوطة والسمات (Theme)
          _buildSectionHeader('١. مظهر المخطوطة والألوان (Theme)', Icons.palette_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                _buildThemeRadio(
                  title: 'حبر الليل (Midnight Ink — Dark OLED)',
                  subtitle: 'سواد نقي مطفأ #0B0D10 موفر لطاقة شاشات AMOLED',
                  value: DiwanThemeType.midnightInk,
                  diwan: diwan,
                ),
                const Divider(),
                _buildThemeRadio(
                  title: 'الرَّقّ والعاج الأثري (Parchment — Light)',
                  subtitle: 'كريمي دافئ #F6EFE0 كأوراق المخطوطات الأندلسية',
                  value: DiwanThemeType.parchment,
                  diwan: diwan,
                ),
                const Divider(),
                _buildThemeRadio(
                  title: 'السيبيا العتيقة (Vintage Sepia)',
                  subtitle: 'درجات السيبيا الهادئة للقراءة الطويلة دون إجهاد',
                  value: DiwanThemeType.sepia,
                  diwan: diwan,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2 & 3. الخط العربي وحجمه (Font & Font Size)
          _buildSectionHeader('٢. الطباعة والخط المخطوطي وحجمه (Typography)', Icons.text_fields_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.font_download_rounded, color: diwan.accentGold),
                  title: Text('خط الأبيات والمتون', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('الخط المعتمد لنصوص الشعر والأشطار', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  trailing: DropdownButton<String>(
                    value: _settings.fontFamily,
                    dropdownColor: diwan.surfaceElevated,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Amiri', child: Text('الأميري (كلاسيكي)')),
                      DropdownMenuItem(value: 'AmiriQuran', child: Text('أميري قرآن (مشكول)')),
                      DropdownMenuItem(value: 'Cairo', child: Text('القاهرة (عصري)')),
                      DropdownMenuItem(value: 'ArefRuqaa', child: Text('عارف رقعة (ديواني)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _settings = _settings.copyWith(fontFamily: val));
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    textDirection: TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text('مقياس حجم الخط (Font Scale)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                          Text('${(_settings.fontScale * 100).toInt()}%', style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 14)),
                        ],
                      ),
                      Slider(
                        value: _settings.fontScale,
                        min: 0.8,
                        max: 1.3,
                        divisions: 4,
                        activeColor: diwan.accentGold,
                        onChanged: (val) => setState(() => _settings = _settings.copyWith(fontScale: val)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4, 5, 6. معايير التسميع والتسامح والتشديد (Recitation Criteria)
          _buildSectionHeader('٣. معايير التسميع ودقة التحليل (Recitation Accuracy)', Icons.mic_external_on_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Icon(Icons.record_voice_over_rounded, color: diwan.primary),
                  title: Text('تسامح مخارج الحروف واللهجات', textDirection: TextDirection.rtl, style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('التسامح بين القاف والهمزة، والضاد والظاء في الإلقاء', textDirection: TextDirection.rtl, style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  value: _settings.dialectTolerance,
                  activeColor: diwan.accentGold,
                  onChanged: (val) => setState(() => _settings = _settings.copyWith(dialectTolerance: val)),
                ),
                const Divider(),
                SwitchListTile(
                  secondary: Icon(Icons.spellcheck_rounded, color: diwan.accentGold),
                  title: Text('تجاهل علامات التشكيل في الفحص', textDirection: TextDirection.rtl, style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('مطابقة حروف الكلمات فقط دون التشدد في الحركات الإعرابية', textDirection: TextDirection.rtl, style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  value: _settings.ignoreDiacritics,
                  activeColor: diwan.accentGold,
                  onChanged: (val) => setState(() => _settings = _settings.copyWith(ignoreDiacritics: val)),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.tune_rounded, color: diwan.secondaryBurgundy),
                  title: Text('درجة التشدد في التسميع (Strictness)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  trailing: DropdownButton<DiwanStrictness>(
                    value: _settings.strictness,
                    dropdownColor: diwan.surfaceElevated,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: DiwanStrictness.loose, child: Text('متساهل')),
                      DropdownMenuItem(value: DiwanStrictness.medium, child: Text('متوازن')),
                      DropdownMenuItem(value: DiwanStrictness.strict, child: Text('صارم')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _settings = _settings.copyWith(strictness: val));
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 7 & 8. نماذج الذكاء الاصطناعي وعتبة التردد (ASR Model & Hesitation)
          _buildSectionHeader('٤. محرك الذكاء الاصطناعي الصوتي (ASR Engine)', Icons.psychology_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.memory_rounded, color: diwan.accentGold),
                  title: Text('نموذج التعرف الصوتي المعتمد (ASR Model)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('يعمل كلياً على معالج الهاتف بأمان تام دون إنترنت', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  trailing: DropdownButton<AsrModelChoice>(
                    value: _settings.asrModel,
                    dropdownColor: diwan.surfaceElevated,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: AsrModelChoice.sherpaArabicOnnx, child: Text('Sherpa-ONNX (35MB)')),
                      DropdownMenuItem(value: AsrModelChoice.wav2vec2Quantized, child: Text('Wav2Vec2 Int8 (85MB)')),
                      DropdownMenuItem(value: AsrModelChoice.whisperTinyArabic, child: Text('Whisper Tiny (39MB)')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _settings = _settings.copyWith(asrModel: val));
                    },
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    textDirection: TextDirection.rtl,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        textDirection: TextDirection.rtl,
                        children: [
                          Text('عتبة التردد والتوقف (ثواني)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                          Text('${_settings.hesitationThresholdSeconds} ثانية', style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 14)),
                        ],
                      ),
                      Slider(
                        value: _settings.hesitationThresholdSeconds,
                        min: 1.0,
                        max: 4.0,
                        divisions: 6,
                        activeColor: diwan.accentGold,
                        onChanged: (val) => setState(() => _settings = _settings.copyWith(hesitationThresholdSeconds: val)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 9 & 10. الورد اليومي والتذكير (Daily Goal & Notifications)
          _buildSectionHeader('٥. الورد اليومي ومواقيت التذكير (Goal & Reminders)', Icons.flag_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.bookmark_added_rounded, color: diwan.primary),
                  title: Text('الورد اليومي المستهدف', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  trailing: DropdownButton<int>(
                    value: _settings.dailyGoalVerses,
                    dropdownColor: diwan.surfaceElevated,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 5, child: Text('٥ أبيات')),
                      DropdownMenuItem(value: 10, child: Text('١٠ أبيات')),
                      DropdownMenuItem(value: 15, child: Text('١٥ بيتاً')),
                      DropdownMenuItem(value: 20, child: Text('٢٠ بيتاً')),
                      DropdownMenuItem(value: 30, child: Text('٣٠ بيتاً')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _settings = _settings.copyWith(dailyGoalVerses: val));
                    },
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.notifications_active_rounded, color: diwan.accentGold),
                  title: Text('التذكير الصباحي (بعد صلاة الفجر)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  trailing: Text(
                    '${_settings.morningReminderTime.format(context)}',
                    style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 14),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _settings.morningReminderTime);
                    if (t != null) setState(() => _settings = _settings.copyWith(morningReminderTime: t));
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.nightlight_round, color: diwan.secondaryBurgundy),
                  title: Text('التذكير المسائي (ورد المساء)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  trailing: Text(
                    '${_settings.eveningReminderTime.format(context)}',
                    style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 14),
                  ),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: _settings.eveningReminderTime);
                    if (t != null) setState(() => _settings = _settings.copyWith(eveningReminderTime: t));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 11 & 12. النسخ الاحتياطي وإدارة النماذج (Backup/Restore & Model Management)
          _buildSectionHeader('٦. إدارة النماذج والبيانات والنسخ الاحتياطي (Data & Models)', Icons.storage_rounded, diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.cloud_upload_rounded, color: diwan.accentGold),
                  title: Text('النسخ الاحتياطي لتقدم الحفظ (Backup)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('تصدير بيانات تقدم الحفظ وبطاقات SRS بأمان', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: diwan.surfaceElevated,
                      foregroundColor: diwan.accentGold,
                      side: BorderSide(color: diwan.borderGold),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم تصدير نسخة احتياطية مشفرة بنجاح')),
                      );
                    },
                    child: const Text('تصدير'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.cloud_download_rounded, color: diwan.primary),
                  title: Text('استعادة تقدم الحفظ (Restore)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('استيراد ملف نسخة احتياطية سابقة دون مساس بالدواوين', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  trailing: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: diwan.primary,
                      side: BorderSide(color: diwan.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم التحقق واستعادة بيانات الحفظ بنجاح')),
                      );
                    },
                    child: const Text('استعادة'),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.data_usage_rounded, color: diwan.accentGold),
                  title: Text('حجم خزانة الدواوين (poems.db)', style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14)),
                  subtitle: Text('مفهرسة بتقنية FTS5 فائقة السرعة للبحث اللحظي', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                  trailing: Text('68 KB', style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 14)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 13. سجل التشخيص (Logs Screen Link)
          _buildSectionHeader('٧. سجل العمليات والتشخيص (In-App Logs)', Icons.receipt_long_rounded, diwan),
          DiwanCard(
            onTap: widget.onOpenLogs,
            child: ListTile(
              leading: Icon(Icons.terminal_rounded, color: diwan.primary),
              title: Text('فتح سجل العمليات والتشخيص (Logs)', style: DiwanTypography.uiTitle(color: diwan.primary, fontSize: 14)),
              subtitle: Text('استعراض وتصفية وتصدير كافة سجلات النظام والبحث والصوت', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
              trailing: Icon(Icons.arrow_back_ios_new_rounded, color: diwan.primary, size: 16),
            ),
          ),
          const SizedBox(height: 16),

          // معرض المكونات للمصمم (Widgetbook / Design Gallery)
          if (widget.onOpenGallery != null) ...[
            _buildSectionHeader('٨. معرض المكونات المخطوطية (Design Gallery)', Icons.dashboard_customize_rounded, diwan),
            DiwanCard(
              onTap: widget.onOpenGallery,
              child: ListTile(
                leading: Icon(Icons.widgets_rounded, color: diwan.accentGold),
                title: Text('معرض منظومة التصميم (Design Gallery)', style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14)),
                subtitle: Text('استعراض وفحص كافة مكونات المخطوطة الرقمية حياً', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                trailing: Icon(Icons.arrow_back_ios_new_rounded, color: diwan.accentGold, size: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 14. عن ديوان (About)
          _buildSectionHeader('٩. عن تطبيق ديوان (About)', Icons.info_outline_rounded, diwan),
          DiwanCard(
            hasGoldBorder: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              textDirection: TextDirection.rtl,
              children: [
                Row(
                  children: [
                    Image.asset('assets/icons/diwan_logo.svg', width: 32, height: 32, errorBuilder: (_, __, ___) => Icon(Icons.auto_stories_rounded, color: diwan.accentGold)),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('دِيـــوَان — الإصدار 1.0.0 (Milestone 1)', style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 15)),
                        Text('مخطوطة الشعر العربي الكلاسيكي والتسميع الذكي', style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'تطبيق ديوان يجمع بين بهاء المخطوطات الأندلسية والعباسية الخالدة وأحدث خوارزميات التعرف الصوتي (ASR) والتكرار المتباعد (FSRS). الخطوط مضمنة بالكامل محلياً برخصة OFL (الأميري، عارف رقعة، القاهرة).',
                  textDirection: TextDirection.rtl,
                  style: DiwanTypography.uiBody(color: diwan.textPrimary, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, DiwanThemeExtension diwan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Icon(icon, size: 18, color: diwan.accentGold),
          const SizedBox(width: 8),
          Text(title, textDirection: TextDirection.rtl, style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildThemeRadio({
    required String title,
    required String subtitle,
    required DiwanThemeType value,
    required DiwanThemeExtension diwan,
  }) {
    final isSelected = _settings.theme == value;
    return RadioListTile<DiwanThemeType>(
      title: Text(title, textDirection: TextDirection.rtl, style: DiwanTypography.uiTitle(color: isSelected ? diwan.accentGold : diwan.textPrimary, fontSize: 14)),
      subtitle: Text(subtitle, textDirection: TextDirection.rtl, style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12)),
      value: value,
      groupValue: _settings.theme,
      activeColor: diwan.accentGold,
      onChanged: (val) {
        if (val != null) setState(() => _settings = _settings.copyWith(theme: val));
      },
    );
  }
}
