import 'package:dhikri/data/models/reading_progress.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';

/// يبني تقدُّمًا محفوظًا لقسم الاختبار الأول عند ذكر واحد مكتمل من اثنين.
ReadingProgress partialProgress(DateTime updatedAt) => ReadingProgress(
  categoryId: 'morning',
  dhikrId: 'test_002',
  currentRepeat: 0,
  completedDhikrIds: const <String>{'test_001'},
  updatedAt: updatedAt,
);

void main() {
  group('استئناف الورد', () {
    testWidgets('جلسة حديثة تعرض زر متابعة واحدًا بلا سؤال', (tester) async {
      final recent = partialProgress(
        DateTime.now().subtract(const Duration(minutes: 30)),
      );
      await pumpDhikriApp(
        tester,
        lastSession: recent,
        categoryProgress: <String, ReadingProgress>{'morning': recent},
      );

      expect(find.text('أكمل من حيث توقفت'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
      expect(find.text('البدء من جديد'), findsNothing);
    });

    testWidgets('جلسة قديمة تسأل: متابعة أم البدء من جديد؟', (tester) async {
      final stale = partialProgress(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      await pumpDhikriApp(
        tester,
        lastSession: stale,
        categoryProgress: <String, ReadingProgress>{'morning': stale},
      );

      expect(find.text('هل تريد متابعة وردك السابق؟'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
      expect(find.text('البدء من جديد'), findsOneWidget);
    });

    testWidgets('المتابعة تفتح الورد عند أول ذكر غير مكتمل', (tester) async {
      final recent = partialProgress(
        DateTime.now().subtract(const Duration(minutes: 5)),
      );
      await pumpDhikriApp(
        tester,
        lastSession: recent,
        categoryProgress: <String, ReadingProgress>{'morning': recent},
      );

      await tester.tap(find.text('متابعة'));
      await tester.pumpAndSettle();

      // الذكر الأول مكتمل، فالاستئناف عند الثاني.
      expect(find.text('عنصر اختباري ثانٍ'), findsOneWidget);
    });

    testWidgets('البدء من جديد يمسح التقدُّم ويفتح من أول ذكر', (tester) async {
      final stale = partialProgress(
        DateTime.now().subtract(const Duration(days: 3)),
      );
      await pumpDhikriApp(
        tester,
        lastSession: stale,
        categoryProgress: <String, ReadingProgress>{'morning': stale},
      );

      await tester.tap(find.text('البدء من جديد'));
      await tester.pumpAndSettle();

      expect(find.text('عنصر اختباري أول'), findsOneWidget);
      expect(find.text('٠ من ٣'), findsOneWidget);
    });

    testWidgets('لا تظهر البطاقة عندما يكون الورد مكتملًا', (tester) async {
      final done = ReadingProgress(
        categoryId: 'morning',
        dhikrId: 'test_002',
        currentRepeat: 1,
        completedDhikrIds: const <String>{'test_001', 'test_002'},
        updatedAt: DateTime.now(),
      );
      await pumpDhikriApp(
        tester,
        lastSession: done,
        categoryProgress: <String, ReadingProgress>{'morning': done},
      );

      expect(find.text('أكمل من حيث توقفت'), findsNothing);
      expect(find.text('هل تريد متابعة وردك السابق؟'), findsNothing);
    });

    testWidgets('التقدُّم المحفوظ يظهر في شريط تقدُّم القسم', (tester) async {
      final recent = partialProgress(DateTime.now());
      await pumpDhikriApp(
        tester,
        lastSession: recent,
        categoryProgress: <String, ReadingProgress>{'morning': recent},
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      // ذكر واحد مكتمل من اثنين.
      expect(find.text('1 من 2'), findsOneWidget);
    });
  });
}
