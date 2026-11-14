import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// وحدة تحكم بالتقطيع والتحميل المسبق (Prefetching Paging Controller)
class MockPagingController {
  final int totalItems;
  final int pageSize;
  final int prefetchThreshold;
  int loadedCount;
  bool isFetching = false;
  final VoidCallback onPageLoaded;

  MockPagingController({
    this.totalItems = 100000,
    this.pageSize = 20,
    this.prefetchThreshold = 5,
    required this.onPageLoaded,
  }) : loadedCount = pageSize;

  void onItemVisible(int index) {
    if (!isFetching && index >= loadedCount - prefetchThreshold && loadedCount < totalItems) {
      isFetching = true;
      loadedCount = (loadedCount + pageSize).clamp(0, totalItems);
      isFetching = false;
      onPageLoaded();
    }
  }
}

void main() {
  group('100k Keyset Paged List Widget Scroll Test (Gate 4)', () {
    testWidgets('التمرير عبر قائمة 100 ألف عنصر مع تحكم التقطيع المسبق يبني فقط عدداً محدوداً ومحصوراً في الذاكرة (Bounded Memory)', (tester) async {
      final builtItemIndices = <int>{};
      const totalItems = 100000;
      late MockPagingController pagingController;
      late StateSetter triggerRebuild;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                triggerRebuild = setState;
                pagingController = MockPagingController(
                  totalItems: totalItems,
                  pageSize: 25,
                  prefetchThreshold: 6,
                  onPageLoaded: () {
                    triggerRebuild(() {});
                  },
                );

                return Directionality(
                  textDirection: TextDirection.rtl,
                  child: ListView.builder(
                    itemCount: pagingController.loadedCount,
                    itemExtent: 80.0, // Fixed item extent for constant-time layout & 120fps budget
                    itemBuilder: (context, index) {
                      builtItemIndices.add(index);
                      pagingController.onItemVisible(index);

                      return RepaintBoundary(
                        key: ValueKey('item_$index'),
                        child: Container(
                          height: 80.0,
                          padding: const EdgeInsets.all(8.0),
                          alignment: Alignment.center,
                          child: Text('قصيدة رقم $index من مئة ألف'),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // في الحالة الابتدائية: يجب بناء عدد محدود جداً من العناصر يغطي الشاشة فقط (أقل من 20 عنصر)
      expect(find.byType(RepaintBoundary), findsWidgets);
      final initialRenderedCount = tester.widgetList(find.byType(RepaintBoundary)).length;
      expect(initialRenderedCount, lessThan(20));

      // محاكاة تمرير سريع نحو الأسفل
      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      // التحقق من أن عدد العناصر النشطة في شجرة العناصر ظل محدوداً ومحصوراً
      final scrolledRenderedCount = tester.widgetList(find.byType(RepaintBoundary)).length;
      expect(scrolledRenderedCount, lessThan(25));
      expect(scrolledRenderedCount, greaterThan(0));

      // تأكيد أن الذاكرة لم تقم ببناء 100 ألف عنصر إطلاقاً، بل عدد محصور جداً
      expect(builtItemIndices.length, lessThan(50));
    });
  });
}
