import 'package:flutter/material.dart';
import '../../core/theme/theme_extension.dart';
import '../../core/theme/typography.dart';
import '../../core/widgets/diwan_card.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback? onOpenGallery;

  const SettingsScreen({super.key, this.onOpenGallery});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentTheme = 'midnightInk';
  bool _dialectTolerance = true;
  bool _ignoreDiacritics = false;
  String _strictness = 'medium';
  String _asrModel = 'sherpa_arabic_onnx';
  double _hesitationThreshold = 2.0;
  int _dailyGoalVerses = 10;

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
          // 1. مظهر المخطوطة والسمات
          _buildSectionTitle('مظهر المخطوطة والألوان', diwan),
          DiwanCard(
            child: Column(
              children: [
                _buildRadioTile('حبر الليل (Dark OLED / AMOLED - الافتراضي)', 'midnightInk', diwan),
                const Divider(),
                _buildRadioTile('الرَّقّ والعاج الأثري (Light Parchment)', 'parchment', diwan),
                const Divider(),
                _buildRadioTile('السيبيا العتيقة (Vintage Sepia للقراءة الممتدة)', 'sepia', diwan),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 2. معايير التسميع والتحليل اللغوي
          _buildSectionTitle('محرك التسميع والتعرف الصوتي', diwan),
          DiwanCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: Text(
                    'تسامح مخارج الحروف واللهجات',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    'التسامح الصوتي بين القاف والهمزة، والضاد والظاء في الإلقاء',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12),
                  ),
                  value: _dialectTolerance,
                  activeColor: diwan.accentGold,
                  onChanged: (val) => setState(() => _dialectTolerance = val),
                ),
                const Divider(),
                SwitchListTile(
                  title: Text(
                    'تجاهل علامات التشكيل وحركات الإعراب',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  subtitle: Text(
                    'مطابقة حروف الكلمات فقط دون التشدد في الحركات الإعرابية',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12),
                  ),
                  value: _ignoreDiacritics,
                  activeColor: diwan.accentGold,
                  onChanged: (val) => setState(() => _ignoreDiacritics = val),
                ),
                const Divider(),
                ListTile(
                  title: Text(
                    'حساسية التردد والتوقف (ثواني)',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  subtitle: Slider(
                    value: _hesitationThreshold,
                    min: 1.0,
                    max: 4.0,
                    divisions: 6,
                    label: '${_hesitationThreshold.toStringAsFixed(1)} ثانية',
                    activeColor: diwan.accentGold,
                    onChanged: (val) => setState(() => _hesitationThreshold = val),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. أهداف الحفظ والورد اليومي
          _buildSectionTitle('أهداف الحفظ والتذكير', diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.flag_rounded, color: diwan.primary),
                  title: Text(
                    'الورد اليومي المستهدف',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  trailing: Text(
                    '$_dailyGoalVerses أبيات',
                    style: DiwanTypography.uiNumber(color: diwan.accentGold, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. معرض مكونات التصميم (Design Gallery)
          if (widget.onOpenGallery != null) ...[
            _buildSectionTitle('أدوات التطوير والمصمم', diwan),
            DiwanCard(
              onTap: widget.onOpenGallery,
              child: ListTile(
                leading: Icon(Icons.palette_rounded, color: diwan.accentGold),
                title: Text(
                  'معرض منظومة التصميم (Design Gallery)',
                  textDirection: TextDirection.rtl,
                  style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 14),
                ),
                subtitle: Text(
                  'استعراض كافة المكونات المخطوطية والرموز البصرية حياً',
                  textDirection: TextDirection.rtl,
                  style: DiwanTypography.uiBody(color: diwan.textSecondary, fontSize: 12),
                ),
                trailing: Icon(Icons.arrow_back_ios_new_rounded, color: diwan.accentGold, size: 16),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. النسخ الاحتياطي وسجلات التشخيص
          _buildSectionTitle('البيانات وسجلات التشخيص', diwan),
          DiwanCard(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.backup_rounded, color: diwan.accentGold),
                  title: Text(
                    'النسخ الاحتياطي لتقدم الحفظ',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  trailing: TextButton(
                    onPressed: () {},
                    child: Text('تصدير', style: TextStyle(color: diwan.accentGold)),
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.receipt_long_rounded, color: diwan.textSecondary),
                  title: Text(
                    'سجل التشخيص والعمليات (Logs)',
                    textDirection: TextDirection.rtl,
                    style: DiwanTypography.uiTitle(color: diwan.textPrimary, fontSize: 14),
                  ),
                  trailing: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: diwan.border),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, DiwanThemeExtension diwan) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: DiwanTypography.uiTitle(color: diwan.accentGold, fontSize: 15),
      ),
    );
  }

  Widget _buildRadioTile(String label, String value, DiwanThemeExtension diwan) {
    return RadioListTile<String>(
      title: Text(
        label,
        textDirection: TextDirection.rtl,
        style: DiwanTypography.uiBody(
          color: _currentTheme == value ? diwan.accentGold : diwan.textPrimary,
          fontSize: 14,
          fontWeight: _currentTheme == value ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      value: value,
      groupValue: _currentTheme,
      activeColor: diwan.accentGold,
      onChanged: (val) {
        if (val != null) setState(() => _currentTheme = val);
      },
    );
  }
}
