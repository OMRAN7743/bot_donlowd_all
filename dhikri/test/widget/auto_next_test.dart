import 'package:dhikri/data/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';

void main() {
  /// يُكمل الذكر الأول في القسم الأول (يحتاج ثلاث ضغطات).
  Future<void> completeFirstDhikr(WidgetTester tester) async {
    await tester.tap(find.text('قسم الاختبار الأول').first);
    await tester.pumpAndSettle();

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('تمت القراءة'));
      await tester.pump();
    }
    await tester.pump();
  }

  group('الانتقال التلقائي', () {
    testWidgets('مُطفأ افتراضيًا فيبقى المستخدم على الذكر نفسه', (
      tester,
    ) async {
      await pumpDhikriApp(tester);
      await completeFirstDhikr(tester);

      // ننتظر أكثر من مهلة الانتقال التلقائي.
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('عنصر اختباري أول'), findsOneWidget);
      expect(find.text('تم هذا الذكر'), findsOneWidget);
    });

    testWidgets('عند تفعيله ينتقل للذكر التالي بعد مهلة قصيرة', (tester) async {
      await pumpDhikriApp(tester, settings: const AppSettings(autoNext: true));
      await completeFirstDhikr(tester);

      // قبل انقضاء المهلة ما زلنا على الذكر نفسه.
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('عنصر اختباري أول'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 800));
      await tester.pumpAndSettle();

      expect(find.text('عنصر اختباري ثانٍ'), findsOneWidget);
      expect(find.text('عنصر اختباري أول'), findsNothing);
    });

    testWidgets('لا ينتقل قبل اكتمال العدد المطلوب', (tester) async {
      await pumpDhikriApp(tester, settings: const AppSettings(autoNext: true));

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تمت القراءة'));
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();

      expect(find.text('عنصر اختباري أول'), findsOneWidget);
      expect(find.text('١ من ٣'), findsOneWidget);
    });
  });

  group('استئناف القراءة', () {
    testWidgets('بطاقة "أكمل من حيث توقفت" تظهر بعد تقدُّم جزئي', (
      tester,
    ) async {
      await pumpDhikriApp(tester);
      await completeFirstDhikr(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('أكمل من حيث توقفت'), findsOneWidget);
      expect(find.text('متابعة'), findsOneWidget);
    });

    testWidgets('لا تظهر البطاقة عند إطفاء حفظ الموضع', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(saveReadingProgress: false),
      );
      await completeFirstDhikr(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('أكمل من حيث توقفت'), findsNothing);
    });
  });

  group('حالة اليوم في الرئيسية', () {
    testWidgets('تعرض إكمال الورد بعد إنهائه', (tester) async {
      await pumpDhikriApp(tester);

      // القسم الثاني يحتوي ذكرًا واحدًا بعدد تكرار ٢.
      await tester.tap(find.text('قسم الاختبار الثاني').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('تمت القراءة'));
      await tester.pump();
      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();

      // شاشة الإكمال ثم العودة للرئيسية.
      expect(find.text('تم وردك'), findsOneWidget);
      await tester.tap(find.text('العودة للرئيسية'));
      await tester.pumpAndSettle();

      expect(find.text('أكملت قسم الاختبار الثاني'), findsOneWidget);
    });
  });
}
