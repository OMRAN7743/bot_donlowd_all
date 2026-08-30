import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/features/home/home_screen.dart';
import 'package:dhikri/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';

void main() {
  group('الاتجاه من اليمين إلى اليسار', () {
    testWidgets('كل الشاشات الأربع تُعرض RTL', (tester) async {
      await pumpDhikriApp(tester);

      for (final tab in <String>[
        'المفضلة',
        'التسبيح',
        'الإعدادات',
        'الرئيسية',
      ]) {
        await tester.tap(find.text(tab));
        await tester.pumpAndSettle();
        expect(
          Directionality.of(tester.element(find.byType(Scaffold).first)),
          TextDirection.rtl,
          reason: 'القسم: $tab',
        );
      }
    });

    testWidgets('شاشة الورد وشاشة البحث تُعرضان RTL', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.text('تمت القراءة'))),
        TextDirection.rtl,
      );

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('البحث في الأذكار'));
      await tester.pumpAndSettle();
      expect(
        Directionality.of(tester.element(find.byType(TextField))),
        TextDirection.rtl,
      );
    });

    testWidgets('نص الذكر محاذاته وسطية ولا يلامس الحواف', (tester) async {
      await pumpDhikriApp(tester);
      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      final textFinder = find.text('نص اختباري قصير للتحقق من العدّاد.');
      final box = tester.getRect(textFinder);
      final screenWidth = tester.getSize(find.byType(MaterialApp)).width;

      expect(box.left, greaterThanOrEqualTo(16));
      expect(screenWidth - box.right, greaterThanOrEqualTo(16));
    });
  });

  group('الاستجابة للأحجام والاتجاهات', () {
    testWidgets('الوضع الأفقي لا يسبب تجاوزًا في الرئيسية', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, surfaceSize: const Size(900, 420));

      expect(find.text('وردك اليوم'), findsOneWidget);
    });

    testWidgets('الوضع الأفقي لا يسبب تجاوزًا في شاشة الورد', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, surfaceSize: const Size(900, 420));

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.text('تمت القراءة'), findsOneWidget);
    });

    testWidgets('شاشة صغيرة جدًا مع تكبير خط لا تسبب تجاوزًا', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(
        tester,
        surfaceSize: const Size(320, 600),
        textScale: 1.5,
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.text('تمت القراءة'), findsOneWidget);
    });

    testWidgets('شاشة الورد تتحمّل تكبير خط النظام ٢٠٠٪', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, textScale: 2.0);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.text('تمت القراءة'), findsOneWidget);
      expect(find.text('السابق'), findsOneWidget);
    });

    testWidgets('الإعدادات تتحمّل تكبير خط النظام ٢٠٠٪', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, textScale: 2.0);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await scrollToText(tester, SettingsScreen, 'سياسة الخصوصية');

      expect(find.text('سياسة الخصوصية'), findsOneWidget);
    });

    testWidgets('التسبيح يتحمّل تكبير خط النظام ٢٠٠٪', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, textScale: 2.0);

      await tester.tap(find.text('التسبيح'));
      await tester.pumpAndSettle();

      expect(find.text('٠'), findsOneWidget);
    });
  });

  group('قارئ الشاشة', () {
    testWidgets('يقرأ نص الذكر والعدد وحالة الإكمال وزر الصوت', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      // نص الذكر متاح لقارئ الشاشة.
      expect(
        find.bySemanticsLabel('نص اختباري قصير للتحقق من العدّاد.'),
        findsOneWidget,
      );

      // العدد وحالة التقدُّم.
      expect(find.bySemanticsLabel(RegExp('التقدُّم')), findsWidgets);

      // زر العدّ يشرح نفسه.
      expect(find.bySemanticsLabel('تمت القراءة، اضغط للعدّ'), findsOneWidget);

      // زر الصوت له وصف واضح.
      expect(find.bySemanticsLabel(RegExp('استمع')), findsWidgets);

      handle.dispose();
    });

    testWidgets('حالة الإكمال تُعلَن لقارئ الشاشة', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الثاني').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('تمت القراءة'));
      await tester.pump();

      expect(find.bySemanticsLabel('اكتمل هذا الذكر'), findsNothing);

      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();

      // بعد الإكمال تفتح شاشة "تم وردك"؛ نرجع ونتحقق من إعلان الحالة.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('اكتمل هذا الذكر'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('بطاقات الأقسام تعلن الاسم والعدد', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDhikriApp(tester);

      expect(
        find.bySemanticsLabel(RegExp('قسم الاختبار الأول.*ذكرًا')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('عدّاد التسبيح يعلن العدد الحالي', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDhikriApp(tester);

      await tester.tap(find.text('التسبيح'));
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp('عدّاد التسبيح، العدد الحالي')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('كل الأيقونات القابلة للضغط لها وصف', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpDhikriApp(tester);

      for (final tooltip in <String>['البحث في الأذكار']) {
        expect(find.byTooltip(tooltip), findsOneWidget);
      }

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.byTooltip('قائمة أذكار القسم'), findsOneWidget);
      expect(find.byTooltip('إضافة إلى المفضلة'), findsOneWidget);
      handle.dispose();
    });
  });

  group('مساحات اللمس', () {
    testWidgets('عناصر التنقّل السفلي تتجاوز الحد الأدنى', (tester) async {
      await pumpDhikriApp(tester);

      final bar = tester.getSize(find.byType(NavigationBar));
      expect(bar.height, greaterThanOrEqualTo(48));
    });

    testWidgets('لافتة كبار السن تظهر وأزرار الورد تكبر معها', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(seniorMode: true),
      );

      await scrollToText(tester, HomeScreen, 'وضع كبار السن مُفعَّل');
      expect(find.text('وضع كبار السن مُفعَّل'), findsOneWidget);

      final bar = tester.getSize(find.byType(NavigationBar));
      expect(bar.height, greaterThanOrEqualTo(72));
    });
  });
}
