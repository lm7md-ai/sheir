import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/data/models/verse.dart';
import 'package:diwan/core/nlp/recitation_alignment_engine.dart';
import 'package:diwan/core/theme/diwan_colors.dart';
import 'package:diwan/core/theme/theme_extension.dart';
import 'package:diwan/core/theme/typography.dart';
import 'package:diwan/design_system/design_system.dart';

void main() {
  Widget buildHarness({
    required Widget child,
    bool isDark = true,
    double fontScale = 1.0,
  }) {
    final theme = isDark
        ? ThemeData(
            brightness: Brightness.dark,
            scaffoldBackgroundColor: DiwanColors.darkBackground,
            primaryColor: DiwanColors.darkPrimary,
            fontFamily: DiwanTypography.fontUI,
            extensions: const [DiwanThemeExtension.midnightInk],
          )
        : ThemeData(
            brightness: Brightness.light,
            scaffoldBackgroundColor: DiwanColors.lightBackground,
            primaryColor: DiwanColors.lightPrimary,
            fontFamily: DiwanTypography.fontUI,
            extensions: const [DiwanThemeExtension.parchment],
          );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: MediaQuery(
          data: MediaQueryData(textScaleFactor: fontScale),
          child: Scaffold(
            body: Center(child: child),
          ),
        ),
      ),
    );
  }

  const sampleVerse = Verse(
    id: 1,
    poemId: 1,
    verseOrder: 1,
    sadr: 'وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ',
    ajuz: 'وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ',
  );

  group('Design System Components Golden & Render Tests (Gate 1)', () {
    testWidgets('1. DiwanCard renders correctly in Dark, Light, Large Font, RTL', (tester) async {
      await tester.pumpWidget(buildHarness(
        child: const DiwanCard(
          hasGoldBorder: true,
          child: Text('بطاقة ديوان المخطوطية'),
        ),
        isDark: true,
      ));
      expect(find.text('بطاقة ديوان المخطوطية'), findsOneWidget);

      await tester.pumpWidget(buildHarness(
        child: const DiwanCard(
          hasGoldBorder: false,
          child: Text('بطاقة ديوان المخطوطية'),
        ),
        isDark: false,
        fontScale: 1.5,
      ));
      expect(find.text('بطاقة ديوان المخطوطية'), findsOneWidget);
    });

    testWidgets('2. VerseTile & HemistichRow render classic and stacked modes in RTL', (tester) async {
      await tester.pumpWidget(buildHarness(
        child: const VerseTile(verse: sampleVerse, isStacked: false),
        isDark: true,
      ));
      expect(find.text('وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ'), findsOneWidget);
      expect(find.text('وَمَنْ بِجِسْمِي وَحَالِي عِنْدَهُ سَقَمُ'), findsOneWidget);

      // Stacked mode with large font
      await tester.pumpWidget(buildHarness(
        child: const VerseTile(verse: sampleVerse, isStacked: true),
        isDark: false,
        fontScale: 1.5,
      ));
      expect(find.text('وَا حَرَّ قَلْبَاهُ مِمَّنْ قَلْبُهُ شَبِمُ'), findsOneWidget);
    });

    testWidgets('3. WordChip renders all 5 dual-coded recitation states in RTL', (tester) async {
      const states = [
        RecitationWordStatus.correct,
        RecitationWordStatus.wrong,
        RecitationWordStatus.hesitation,
        RecitationWordStatus.missing,
        RecitationWordStatus.extra,
      ];

      for (final st in states) {
        await tester.pumpWidget(buildHarness(
          child: WordChip(
            token: RecitationWordToken(
              expectedWord: 'كلمة',
              heardWord: st == RecitationWordStatus.wrong ? 'بديلة' : null,
              status: st,
            ),
          ),
          isDark: true,
        ));
        expect(find.byType(WordChip), findsOneWidget);
      }
    });

    testWidgets('4. AccuracyGauge renders circle and rank percentage in Light and Dark', (tester) async {
      await tester.pumpWidget(buildHarness(
        child: const AccuracyGauge(percentage: 95.0, rankTitle: 'شاعرٌ مُفْلِق'),
        isDark: true,
      ));
      expect(find.byType(AccuracyGauge), findsOneWidget);
      expect(find.text('شاعرٌ مُفْلِق'), findsOneWidget);
    });

    testWidgets('5. ErrorLegend, RecordButton, SkeletonList, EmptyState, SectionHeader, DiwanChip', (tester) async {
      // ErrorLegend
      await tester.pumpWidget(buildHarness(child: const ErrorLegend(), isDark: true));
      expect(find.text('صحيح'), findsOneWidget);

      // RecordButton
      await tester.pumpWidget(buildHarness(child: const RecordButton(isRecording: false), isDark: true));
      expect(find.byType(RecordButton), findsOneWidget);

      // SkeletonList
      await tester.pumpWidget(buildHarness(child: const SkeletonList(itemCount: 2), isDark: true));
      expect(find.byType(SkeletonList), findsOneWidget);

      // EmptyState
      await tester.pumpWidget(buildHarness(
        child: const EmptyState(title: 'لا توجد عناصر', subtitle: 'وصف حالة الخلو'),
        isDark: true,
      ));
      expect(find.text('لا توجد عناصر'), findsOneWidget);

      // SectionHeader
      await tester.pumpWidget(buildHarness(child: const SectionHeader(title: 'عنوان القسم'), isDark: true));
      expect(find.text('عنوان القسم'), findsOneWidget);

      // DiwanChip
      await tester.pumpWidget(buildHarness(
        child: const DiwanChip(label: 'العصر العباسي', variant: DiwanChipVariant.primary),
        isDark: true,
      ));
      expect(find.text('العصر العباسي'), findsOneWidget);
    });
  });
}
