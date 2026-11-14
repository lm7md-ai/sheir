import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/data/models/poem.dart';
import 'core/data/models/verse.dart';
import 'core/errors/diwan_error_boundary.dart';
import 'core/logs/diwan_logger.dart';
import 'core/nlp/recitation_alignment_engine.dart';
import 'core/theme/diwan_colors.dart';
import 'core/theme/theme_extension.dart';
import 'core/theme/typography.dart';
import 'features/gallery/gallery_screen.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/logs/logs_screen.dart';
import 'features/memorization/memorization_screen.dart';
import 'features/poem/poem_screen.dart';
import 'features/recitation/recitation_screen.dart';
import 'features/report/report_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/stats/stats_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // تسجيل أول نبضة في سجل التشخيص
  DiwanLogger.instance.info('AppLifecycle', 'تطبيق ديوان يبدأ العمل بنجاح (Milestone 1)');

  FlutterError.onError = (details) {
    DiwanErrorBoundary.reportError(details.exception, details.stack);
  };

  runApp(const ProviderScope(child: DiwanApp()));
}

/// موفر حالة السمة المختارة (Midnight Ink, Parchment, Sepia)
final diwanThemeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

class DiwanApp extends ConsumerWidget {
  const DiwanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(diwanThemeModeProvider);

    return MaterialApp(
      title: 'ديوان',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: themeMode,

      // السمة الفاتحة: الرّقّ والعاج (Parchment)
      theme: ThemeData(
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
      ),

      // السمة الداكنة: حبر الليل المخصص لشاشات AMOLED (Midnight Ink - Default)
      darkTheme: ThemeData(
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
      ),

      home: const DiwanRootNavigation(),
    );
  }
}

class DiwanRootNavigation extends StatefulWidget {
  const DiwanRootNavigation({super.key});

  @override
  State<DiwanRootNavigation> createState() => _DiwanRootNavigationState();
}

class _DiwanRootNavigationState extends State<DiwanRootNavigation> {
  int _currentIndex = 0;
  Poem? _selectedPoem;
  bool _isReciting = false;
  RecitationEvaluationResult? _recitationResult;
  bool _isMemorizing = false;
  bool _isGalleryOpen = false;
  bool _isLogsOpen = false;

  // القصائد النموذجية الأولية المستخرجة من poems.db
  late final List<Poem> _samplePoems = [
    Poem(
      id: 1,
      title: 'واحرّ قلباه',
      poetName: 'أبو الطيب المتنبي',
      era: 'العباسي',
      meterName: 'البسيط',
      rawiy: 'الميم',
      theme: 'عتاب وفخر',
      verses: const [
        Verse(
          id: 1,
          poemId: 1,
          verseOrder: 1,
          sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
          ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ',
        ),
        Verse(
          id: 2,
          poemId: 1,
          verseOrder: 2,
          sadr: 'مَا لِي أُكَتِّمُ حُبّاً قَدْ بَرَى جَسَدِي',
          ajuz: 'وَتَدَّعِي حُبَّ سَيْفِ الدَّوْلَةِ الأُمَمُ',
        ),
        Verse(
          id: 3,
          poemId: 1,
          verseOrder: 3,
          sadr: 'إِنْ كَانَ يَجْمَعُنَا حُبٌّ لِغُرَّتِهِ',
          ajuz: 'فَلَيْتَ أَنَّا بِقَدْرِ الحُبِّ نَقْتَسِمُ',
        ),
        Verse(
          id: 4,
          poemId: 1,
          verseOrder: 4,
          sadr: 'يَا أَعْدَلَ النَّاسِ إِلَّا فِي مُعَامَلَتِي',
          ajuz: 'فِيكَ الخِصَامُ وَأَنْتَ الخَصْمُ وَالحَكَمُ',
        ),
      ],
    ),
    Poem(
      id: 2,
      title: 'قِفَا نَبْكِ (المعلقة)',
      poetName: 'امرؤ القيس الكندي',
      era: 'الجاهلي',
      meterName: 'الطويل',
      rawiy: 'اللام',
      theme: 'وقوف على الأطلال',
      verses: const [
        Verse(
          id: 5,
          poemId: 2,
          verseOrder: 1,
          sadr: 'قِفَا نَبْكِ مِنْ ذِكْرَى حَبِيبٍ وَمَنْزِلِ',
          ajuz: 'بِسِقْطِ اللِّوَى بَيْنَ الدَّخُولِ فَحَوْمَلِ',
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final diwan = context.diwan;

    // إذا كانت شاشة سجل العمليات والتشخيص مفتوحة
    if (_isLogsOpen) {
      return LogsScreen(onBack: () => setState(() => _isLogsOpen = false));
    }

    // إذا كانت شاشة المعرض مفتوحة
    if (_isGalleryOpen) {
      return GalleryScreen(onBack: () => setState(() => _isGalleryOpen = false));
    }

    // إذا كانت شاشة التسميع مفتوحة
    if (_isReciting && _selectedPoem != null) {
      return RecitationScreen(
        verse: _selectedPoem!.verses.first,
        onEvaluationComplete: (res) {
          setState(() {
            _isReciting = false;
            _recitationResult = res;
          });
        },
        onCancel: () => setState(() => _isReciting = false),
      );
    }

    // إذا كانت شاشة تقرير التسميع مفتوحة
    if (_recitationResult != null) {
      return ReportScreen(
        result: _recitationResult!,
        onClose: () => setState(() => _recitationResult = null),
        onRetryMistakesOnly: () {
          setState(() {
            _recitationResult = null;
            _isReciting = true;
          });
        },
        onSaveProgress: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تدوين وحفظ التسميع بنجاح في صحيفة حفظك!')),
          );
          setState(() => _recitationResult = null);
        },
      );
    }

    // إذا كانت شاشة التدريب مفتوحة لقصيدة محددة
    if (_isMemorizing && _selectedPoem != null) {
      return MemorizationScreen(
        verse: _selectedPoem!.verses.first,
        onBack: () => setState(() => _isMemorizing = false),
        onRatingSubmitted: (rating) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تحديث جدول الاستذكار المتباعد بنجاح!')),
          );
          setState(() => _isMemorizing = false);
        },
      );
    }

    // إذا تم فتح قصيدة معينة
    if (_selectedPoem != null) {
      return PoemScreen(
        poem: _selectedPoem!,
        onBack: () => setState(() => _selectedPoem = null),
        onStartRecitation: () => setState(() => _isReciting = true),
        onStartMemorization: () => setState(() => _isMemorizing = true),
      );
    }

    // التبويبات الخمسة الرئيسية
    final screens = [
      HomeScreen(
        onSelectPoem: (id) {
          final found = _samplePoems.firstWhere((p) => p.id == id, orElse: () => _samplePoems.first);
          setState(() => _selectedPoem = found);
        },
        onStartSrsReview: () {
          setState(() {
            _selectedPoem = _samplePoems.first;
            _isMemorizing = true;
          });
        },
        onOpenSearch: () => setState(() => _currentIndex = 1),
      ),
      LibraryScreen(
        poems: _samplePoems,
        onPoemSelected: (p) => setState(() => _selectedPoem = p),
      ),
      MemorizationScreen(
        verse: _samplePoems.first.verses.first,
        onRatingSubmitted: (r) {},
      ),
      const StatsScreen(),
      SettingsScreen(
        onOpenGallery: () => setState(() => _isGalleryOpen = true),
        onOpenLogs: () => setState(() => _isLogsOpen = true),
      ),
    ];

    return DiwanErrorBoundary(
      onOpenLogs: () => setState(() => _isLogsOpen = true),
      child: Scaffold(
        body: screens[_currentIndex],
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: diwan.surface,
            border: Border(top: BorderSide(color: diwan.border)),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (idx) => setState(() => _currentIndex = idx),
            backgroundColor: diwan.surface,
            selectedItemColor: diwan.accentGold,
            unselectedItemColor: diwan.textMuted,
            selectedLabelStyle: DiwanTypography.uiBody(
              color: diwan.accentGold,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: DiwanTypography.uiBody(
              color: diwan.textMuted,
              fontSize: 11,
            ),
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.menu_book_outlined),
                activeIcon: Icon(Icons.menu_book_rounded),
                label: 'المكتبة',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.psychology_outlined),
                activeIcon: Icon(Icons.psychology_rounded),
                label: 'التدريب',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_outlined),
                activeIcon: Icon(Icons.insights_rounded),
                label: 'الإحصاء',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
