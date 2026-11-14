import 'package:flutter_test/flutter_test.dart';
import 'package:diwan/core/data/models/poem.dart';
import 'package:diwan/core/data/models/verse.dart';
import 'package:diwan/core/data/paged_poem_repository.dart';

void main() {
  group('PagedPoemRepository Tests', () {
    late PagedPoemRepository repository;

    setUp(() {
      final samplePoems = List.generate(50, (i) {
        return Poem(
          id: i + 1,
          title: 'قصيدة رقم ${i + 1}',
          poetName: i % 2 == 0 ? 'أبو الطيب المتنبي' : 'امرؤ القيس',
          era: i % 2 == 0 ? 'العباسي' : 'الجاهلي',
          meterName: 'الطويل',
          rawiy: 'الميم',
          theme: 'فخر',
          verses: [
            Verse(
              id: (i * 2) + 1,
              poemId: i + 1,
              verseOrder: 1,
              sadr: 'الخَيْلُ وَاللَّيْلُ وَالبَيْدَاءُ تَعْرِفُنِي',
              ajuz: 'وَالسَّيْفُ وَالرُّمْحُ وَالقِرْطَاسُ وَالقَلَمُ',
            ),
          ],
        );
      });

      repository = PagedPoemRepository(seedPoems: samplePoems);
    });

    test('جلب الصفحة الأولى بعدد محدد دون تحميل كامل الجدول', () async {
      final page1 = await repository.getPoemsPaged(page: 1, pageSize: 15);
      expect(page1.items.length, equals(15));
      expect(page1.page, equals(1));
      expect(page1.totalCount, equals(50));
      expect(page1.hasMore, isTrue);
      expect(page1.queryDurationMs, lessThan(50));
    });

    test('جلب الصفحة الثانية مع إزاحة صحيحة (Offset)', () async {
      final page2 = await repository.getPoemsPaged(page: 2, pageSize: 15);
      expect(page2.items.length, equals(15));
      expect(page2.items.first.id, equals(16));
      expect(page2.hasMore, isTrue);
    });

    test('تصفية النتائج بالعصر الأدبي مع استمرار التقطيع الصفحي', () async {
      final abbasid = await repository.getPoemsPaged(
        page: 1,
        pageSize: 10,
        era: 'العباسي',
      );
      expect(abbasid.totalCount, equals(25));
      expect(abbasid.items.length, equals(10));
      expect(abbasid.items.every((p) => p.era == 'العباسي'), isTrue);
    });

    test('بحث FTS5 مفهرس بدون تشكيل في أجزاء الأبيات', () async {
      final searchResult = await repository.searchVersesPaged(
        query: 'البيداء',
        page: 1,
        pageSize: 10,
      );
      expect(searchResult.items.length, equals(10));
      expect(searchResult.items.first.sadr, contains('البَيْدَاءُ'));
    });
  });
}
