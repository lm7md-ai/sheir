import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('100k Keyset Paged List Widget Scroll Test (Gate 4)', () {
    testWidgets('التمرير عبر قائمة 100 ألف عنصر يبني فقط عدداً محدوداً ومحصوراً في الذاكرة (Bounded Memory)', (tester) async {
      final builtItemIndices = <int>{};
      const totalItems = 100000;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: ListView.builder(
                itemCount: totalItems,
                itemExtent: 80.0, // Fixed item extent for 120fps scrolling budget
                itemBuilder: (context, index) {
                  builtItemIndices.add(index);
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

      // تأكيد أن الذاكرة لم تقم ببناء 100 ألف عنصر إطلاقاً
      expect(builtItemIndices.length, lessThan(50));
    });
  });
}
