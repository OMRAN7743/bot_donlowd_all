import 'package:dhikri/core/services/notification_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(() {
    tz_data.initializeTimeZones();
    // منطقة ثابتة حتى تكون النتائج قابلة للتكرار.
    tz.setLocalLocation(tz.getLocation('Asia/Aden'));
  });

  group('حساب موعد التذكير القادم', () {
    test('يجدول اليوم إذا لم يمض الوقت بعد', () {
      final now = tz.TZDateTime(tz.local, 2026, 8, 28, 5, 0);
      final next = NotificationService.nextInstanceOf(
        const ReminderTime(6, 30),
        now: now,
      );

      expect(next.year, 2026);
      expect(next.month, 8);
      expect(next.day, 28);
      expect(next.hour, 6);
      expect(next.minute, 30);
    });

    test('يجدول الغد إذا مضى الوقت', () {
      final now = tz.TZDateTime(tz.local, 2026, 8, 28, 20, 0);
      final next = NotificationService.nextInstanceOf(
        const ReminderTime(6, 30),
        now: now,
      );

      expect(next.day, 29);
      expect(next.hour, 6);
    });

    test('الوقت المطابق للحظة الحالية يُجدول للغد', () {
      final now = tz.TZDateTime(tz.local, 2026, 8, 28, 6, 30);
      final next = NotificationService.nextInstanceOf(
        const ReminderTime(6, 30),
        now: now,
      );

      expect(next.day, 29);
    });

    test('يعبر حدّ الشهر بشكل صحيح', () {
      final now = tz.TZDateTime(tz.local, 2026, 8, 31, 23, 30);
      final next = NotificationService.nextInstanceOf(
        const ReminderTime(6, 0),
        now: now,
      );

      expect(next.month, 9);
      expect(next.day, 1);
    });

    test('الموعد القادم دائمًا في المستقبل', () {
      for (var hour = 0; hour < 24; hour++) {
        final now = tz.TZDateTime(tz.local, 2026, 8, 28, hour, 15);
        final next = NotificationService.nextInstanceOf(
          ReminderTime(hour, 15),
          now: now,
        );
        expect(next.isAfter(now), isTrue, reason: 'الساعة $hour');
      }
    });
  });

  group('أنواع التذكيرات', () {
    test('لكل نوع معرّف فريد وثابت', () {
      final ids = ReminderKind.values.map((k) => k.id).toSet();
      expect(ids, hasLength(ReminderKind.values.length));
      expect(ReminderKind.morning.id, 1001);
      expect(ReminderKind.evening.id, 1002);
      expect(ReminderKind.custom.id, 1003);
    });

    test('نصوص التذكير هادئة وبلا لوم', () {
      const blaming = <String>[
        'متأخر',
        'لا تنسَ وإلا',
        'فاتك',
        'أهملت',
        'قصّرت',
      ];

      for (final kind in ReminderKind.values) {
        expect(kind.title, isNotEmpty);
        expect(kind.body, isNotEmpty);
        for (final word in blaming) {
          expect(
            kind.body.contains(word),
            isFalse,
            reason: '${kind.name}: $word',
          );
        }
      }
    });

    test('النصوص عربية وتذكر الأذكار', () {
      expect(ReminderKind.morning.body, 'ورد الصباح جاهز لك');
      expect(ReminderKind.evening.body, 'وقت مناسب لأذكار المساء');
    });
  });

  group('ReminderTime', () {
    test('التحويل من وإلى الدقائق', () {
      const time = ReminderTime(6, 30);
      expect(time.asMinutes, 390);
      expect(ReminderTime.fromMinutes(390), time);
    });

    test('يلتف حول حدود اليوم بدل الخروج عن النطاق', () {
      expect(ReminderTime.fromMinutes(24 * 60), const ReminderTime(0, 0));
      expect(ReminderTime.fromMinutes(24 * 60 + 90), const ReminderTime(1, 30));
    });

    test('التسمية العربية تفرّق بين الصباح والمساء', () {
      expect(const ReminderTime(6, 30).label, '6:30 صباحًا');
      expect(const ReminderTime(17, 5).label, '5:05 مساءً');
      expect(const ReminderTime(0, 0).label, '12:00 صباحًا');
      expect(const ReminderTime(12, 0).label, '12:00 مساءً');
    });
  });

  group('الافتراضيات', () {
    test('كل التذكيرات مُطفأة افتراضيًا فلا تُطلب صلاحية عند الإقلاع', () {
      const defaults = AppSettings.defaults;
      expect(defaults.morningReminderEnabled, isFalse);
      expect(defaults.eveningReminderEnabled, isFalse);
      expect(defaults.customReminderEnabled, isFalse);
    });

    test('أوقات التذكير الافتراضية معقولة', () {
      const defaults = AppSettings.defaults;
      expect(defaults.morningReminderTime, const ReminderTime(6, 30));
      expect(defaults.eveningReminderTime, const ReminderTime(17, 0));
    });
  });
}
