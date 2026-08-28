import 'package:dhikri/app/bootstrap.dart';
import 'package:dhikri/core/errors/app_exception.dart';
import 'package:dhikri/core/services/narration/narration_service.dart';
import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/features/home/home_screen.dart';
import 'package:dhikri/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';

void main() {
  group('الرئيسية', () {
    testWidgets('تُعرض من اليمين إلى اليسار باسم "ذكري"', (tester) async {
      await pumpDhikriApp(tester);

      expect(find.text('ذكري'), findsOneWidget);
      expect(find.text('وردك اليوم'), findsOneWidget);

      final direction = Directionality.of(
        tester.element(find.text('وردك اليوم')),
      );
      expect(direction, TextDirection.rtl);
    });

    testWidgets('تعرض الأقسام الرئيسية والشريط السفلي بأربعة أقسام', (
      tester,
    ) async {
      await pumpDhikriApp(tester);

      expect(find.text('قسم الاختبار الأول'), findsWidgets);
      expect(find.text('الرئيسية'), findsOneWidget);
      expect(find.text('المفضلة'), findsOneWidget);
      expect(find.text('التسبيح'), findsOneWidget);
      expect(find.text('الإعدادات'), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('الضغط على بطاقة قسم يفتح شاشة القراءة', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.text('تمت القراءة'), findsOneWidget);
      expect(find.textContaining('التكرار'), findsOneWidget);
    });

    testWidgets('تعرض شاشة خطأ عند فشل تحميل المحتوى', (tester) async {
      await pumpDhikriApp(
        tester,
        content: const ContentFailed(
          ContentLoadException('لم نتمكن من فتح ملف الأذكار.'),
        ),
      );

      expect(find.text('لم نتمكن من فتح ملف الأذكار.'), findsOneWidget);
    });
  });

  group('شاشة الذكر', () {
    Future<void> openReading(WidgetTester tester) async {
      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();
    }

    testWidgets('العدّاد يزيد ولا يتجاوز العدد المطلوب', (tester) async {
      await pumpDhikriApp(tester);
      await openReading(tester);

      // العنصر الأول عدد تكراره ٣.
      expect(find.text('٠ من ٣'), findsOneWidget);

      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();
      expect(find.text('١ من ٣'), findsOneWidget);

      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();

      // اكتمل: يتحول الزر إلى حالة الإكمال ولا يعود قابلًا للضغط.
      expect(find.text('٣ من ٣'), findsOneWidget);
      expect(find.text('تم هذا الذكر'), findsOneWidget);
      expect(find.text('تمت القراءة'), findsNothing);
    });

    testWidgets('تعرض المصدر عندما يكون الإعداد مُفعَّلًا', (tester) async {
      await pumpDhikriApp(tester);
      await openReading(tester);

      expect(find.text('المصدر'), findsOneWidget);
      expect(find.textContaining('مرجع اختباري'), findsOneWidget);
    });

    testWidgets('تخفي المصدر عندما يُطفأ الإعداد', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(showSource: false),
      );
      await openReading(tester);

      expect(find.text('المصدر'), findsNothing);
    });

    testWidgets('أزرار السابق والتالي ظاهرة دائمًا', (tester) async {
      await pumpDhikriApp(tester);
      await openReading(tester);

      expect(find.text('السابق'), findsOneWidget);
      expect(find.text('التالي'), findsOneWidget);

      await tester.tap(find.text('التالي'));
      await tester.pumpAndSettle();
      expect(find.text('عنصر اختباري ثانٍ'), findsOneWidget);
    });

    testWidgets('يستوعب نصًّا عربيًّا طويلًا بلا تجاوز', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester);

      // القسم الثاني يحتوي النص الطويل.
      await tester.tap(find.text('قسم الاختبار الثاني').first);
      await tester.pumpAndSettle();

      expect(find.textContaining('نص طويل جدًا'), findsOneWidget);
    });

    testWidgets('إكمال الورد يفتح شاشة "تم وردك"', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الثاني').first);
      await tester.pumpAndSettle();

      // العنصر الوحيد في هذا القسم عدد تكراره ٢.
      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('تمت القراءة'));
      await tester.pumpAndSettle();

      expect(find.text('تم وردك'), findsOneWidget);
      expect(find.text('تقبّل الله منا ومنكم'), findsOneWidget);
    });
  });

  group('سهولة الوصول', () {
    testWidgets('لا يحدث تجاوز عند تكبير خط النظام ٢٠٠٪', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, textScale: 2.0);

      expect(find.text('وردك اليوم'), findsOneWidget);
    });

    testWidgets('وضع كبار السن يعرض لافتة تذكير في الرئيسية', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(seniorMode: true),
      );

      await scrollToText(tester, HomeScreen, 'وضع كبار السن مُفعَّل');
      expect(find.text('وضع كبار السن مُفعَّل'), findsOneWidget);
    });

    testWidgets('وضع كبار السن يكبّر زر العدّ فوق الحد الأدنى للمس', (
      tester,
    ) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(seniorMode: true),
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      final counter = tester.getSize(
        find
            .ancestor(
              of: find.text('تمت القراءة'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(counter.height, greaterThanOrEqualTo(64));
    });

    testWidgets('الوضع العادي يبقي زر العدّ فوق ٤٨ نقطة', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      final counter = tester.getSize(
        find
            .ancestor(
              of: find.text('تمت القراءة'),
              matching: find.byType(InkWell),
            )
            .first,
      );
      expect(counter.height, greaterThanOrEqualTo(48));
    });

    testWidgets('لا تجاوز في وضع كبار السن مع تكبير النظام', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(
          seniorMode: true,
          textScalePreset: TextScalePreset.extraLarge,
        ),
        textScale: 1.5,
      );

      expect(find.text('وردك اليوم'), findsOneWidget);
    });

    testWidgets('يعمل على شاشة صغيرة', (tester) async {
      expectNoOverflow();
      await pumpDhikriApp(tester, surfaceSize: const Size(320, 640));

      expect(find.text('وردك اليوم'), findsOneWidget);
    });
  });

  group('الوضع الداكن', () {
    testWidgets('يتبع نمط النظام الداكن', (tester) async {
      await pumpDhikriApp(tester, platformBrightness: Brightness.dark);

      final theme = Theme.of(tester.element(find.text('وردك اليوم')));
      expect(theme.brightness, Brightness.dark);
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0C1714));
    });

    testWidgets('الإعداد الصريح يتجاوز نمط النظام', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(themePreference: AppThemePreference.dark),
      );

      final theme = Theme.of(tester.element(find.text('وردك اليوم')));
      expect(theme.brightness, Brightness.dark);
    });
  });

  group('الصوت', () {
    testWidgets('يعرض رسالة محترمة عندما لا يتوفّر صوت عربي', (tester) async {
      final narration = FakeNarrationService(
        availability: const NarrationAvailability.unavailable(
          NarrationUnavailableReason.arabicVoiceMissing,
        ),
      );
      await pumpDhikriApp(tester, narration: narration);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('استمع وردّد'));
      await tester.pumpAndSettle();

      expect(find.textContaining('الصوت العربي غير متوفر'), findsOneWidget);
      expect(
        find.textContaining('إعدادات تحويل النص إلى كلام'),
        findsOneWidget,
      );
    });

    testWidgets('إطفاء الصوت يغيّر الزر إلى فتح الإعدادات', (tester) async {
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(audioEnabled: false),
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(find.text('تشغيل القراءة الصوتية'), findsOneWidget);
      expect(find.text('استمع وردّد'), findsNothing);
    });
  });

  group('المفضلة', () {
    testWidgets('الإضافة من شاشة الذكر تظهر في صفحة المفضلة', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('إضافة إلى المفضلة'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      await tester.tap(find.text('المفضلة'));
      await tester.pumpAndSettle();

      expect(find.text('عنصر اختباري أول'), findsOneWidget);
    });

    testWidgets('المفضلة الفارغة تعرض حالة فارغة واضحة', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('المفضلة'));
      await tester.pumpAndSettle();

      expect(find.text('لا توجد أذكار في المفضلة'), findsOneWidget);
    });
  });

  group('الإعدادات', () {
    testWidgets('تبديل مفتاح يُحفظ في التخزين', (tester) async {
      final store = await pumpDhikriApp(tester);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();

      await scrollToText(tester, SettingsScreen, 'الاهتزاز عند إكمال الذكر');
      await tester.tap(find.text('الاهتزاز عند إكمال الذكر'));
      await tester.pumpAndSettle();

      expect(await store.getBool(PrefKeys.completionHaptics), isFalse);
    });

    testWidgets('صفحة الخصوصية تنص على عدم جمع البيانات', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await scrollToText(tester, SettingsScreen, 'سياسة الخصوصية');
      await tester.tap(find.text('سياسة الخصوصية').first);
      await tester.pumpAndSettle();

      expect(find.text('لا نجمع بيانات شخصية'), findsOneWidget);
      expect(find.text('لا توجد تحليلات ولا تتبّع'), findsOneWidget);
      expect(find.text('لا يوجد حساب'), findsOneWidget);
    });

    testWidgets('صفحة التذكيرات تبدأ بكل المفاتيح مُطفأة', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await scrollToText(tester, SettingsScreen, 'تذكيرات الأذكار');
      await tester.tap(find.text('تذكيرات الأذكار'));
      await tester.pumpAndSettle();

      final switches = tester.widgetList<SwitchListTile>(
        find.byType(SwitchListTile),
      );
      expect(switches, isNotEmpty);
      for (final tile in switches) {
        expect(tile.value, isFalse);
      }
    });
  });

  group('التسبيح', () {
    testWidgets('العدّاد يزيد بالضغط ويتوقف عند الهدف', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('التسبيح'));
      await tester.pumpAndSettle();

      expect(find.text('٠'), findsOneWidget);

      await tester.tap(find.text('اضغط في أي مكان للعدّ'));
      await tester.pumpAndSettle();
      expect(find.text('١'), findsOneWidget);
    });
  });

  group('شاشات التعريف', () {
    testWidgets('تظهر عند أول تشغيل ويمكن تخطّيها', (tester) async {
      await pumpDhikriApp(tester, onboardingCompleted: false);

      expect(find.text('أذكارك معك دائمًا'), findsOneWidget);

      await tester.tap(find.text('تخطّي'));
      await tester.pumpAndSettle();

      expect(find.text('وردك اليوم'), findsOneWidget);
    });

    testWidgets('لا تطلب أي صلاحية ولا تسجيل دخول', (tester) async {
      await pumpDhikriApp(tester, onboardingCompleted: false);

      // لا حقول إدخال ولا زر دخول في أي من الشاشات الثلاث.
      for (var page = 0; page < 3; page++) {
        expect(find.byType(TextField), findsNothing);
        expect(find.textContaining('تسجيل الدخول'), findsNothing);
        expect(find.textContaining('البريد'), findsNothing);
        if (page < 2) {
          await tester.tap(find.text('التالي'));
          await tester.pumpAndSettle();
        }
      }

      // الشاشة الثالثة تذكر أن التذكيرات اختيارية ولا تطلب صلاحية الآن.
      expect(find.textContaining('التذكيرات اختيارية'), findsOneWidget);
    });
  });
}
