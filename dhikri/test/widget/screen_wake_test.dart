import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/core/services/screen_wake_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/features/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/harness.dart';

void main() {
  group('إبقاء الشاشة مستيقظة', () {
    testWidgets('لا يُطلب إبقاء الشاشة عندما يكون الإعداد مُطفأً', (
      tester,
    ) async {
      final wake = RecordingScreenWakeService();
      await pumpDhikriApp(tester, screenWake: wake);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(wake.isEnabled, isFalse);
    });

    testWidgets('يُطلب إبقاء الشاشة داخل شاشة الورد عند تفعيل الإعداد', (
      tester,
    ) async {
      final wake = RecordingScreenWakeService();
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(keepScreenAwake: true),
        screenWake: wake,
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      expect(wake.isEnabled, isTrue);
    });

    testWidgets('يُلغى الطلب عند مغادرة شاشة الورد', (tester) async {
      final wake = RecordingScreenWakeService();
      await pumpDhikriApp(
        tester,
        settings: const AppSettings(keepScreenAwake: true),
        screenWake: wake,
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();
      expect(wake.isEnabled, isTrue);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(wake.isEnabled, isFalse);
      expect(wake.calls.last, 'disable');
    });

    testWidgets('تغيير الإعداد أثناء وجود المستخدم في الشاشة يسري فورًا', (
      tester,
    ) async {
      final wake = RecordingScreenWakeService();
      final store = await pumpDhikriApp(
        tester,
        settings: const AppSettings(keepScreenAwake: true),
        screenWake: wake,
      );

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();
      expect(wake.isEnabled, isTrue);

      // نغيّر الإعداد من التخزين عبر صفحة الإعدادات بعد الرجوع.
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await scrollToText(
        tester,
        SettingsScreen,
        'إبقاء الشاشة مستيقظة أثناء الورد',
      );
      await tester.tap(find.text('إبقاء الشاشة مستيقظة أثناء الورد'));
      await tester.pumpAndSettle();

      expect(await store.getBool(PrefKeys.keepScreenAwake), isFalse);
    });

    testWidgets('الإعداد يظهر في قسم القراءة ومُطفأ افتراضيًا', (tester) async {
      await pumpDhikriApp(tester);

      await tester.tap(find.text('الإعدادات'));
      await tester.pumpAndSettle();
      await scrollToText(
        tester,
        SettingsScreen,
        'إبقاء الشاشة مستيقظة أثناء الورد',
      );

      final tile = tester.widget<SwitchListTile>(
        find.ancestor(
          of: find.text('إبقاء الشاشة مستيقظة أثناء الورد'),
          matching: find.byType(SwitchListTile),
        ),
      );
      expect(tile.value, isFalse);
    });
  });

  group('إيقاف الصوت عند مغادرة الورد', () {
    testWidgets('تُوقَف القراءة الصوتية عند الرجوع من شاشة الذكر', (
      tester,
    ) async {
      final narration = FakeNarrationService();
      await pumpDhikriApp(tester, narration: narration);

      await tester.tap(find.text('قسم الاختبار الأول').first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('استمع وردّد'));
      await tester.pump();
      await tester.pumpAndSettle();

      narration.stopped = false;
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(narration.stopped, isTrue);
    });
  });
}
