import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/models/app_settings.dart';

/// نتيجة محاولة تفعيل التذكيرات.
enum ReminderPermissionResult {
  /// مُنحت الصلاحية والتذكير مجدول.
  granted,

  /// رفض المستخدم — نعرض شرحًا وزر فتح إعدادات النظام.
  denied,

  /// المنصة لا تدعم التذكيرات (اختبارات، سطح مكتب غير مهيأ).
  unsupported,
}

/// أنواع التذكيرات المدعومة، ولكلٍّ معرّف ثابت حتى يمكن تحديثه أو إلغاؤه.
enum ReminderKind {
  morning(1001, 'أذكار الصباح', 'ورد الصباح جاهز لك'),
  evening(1002, 'أذكار المساء', 'وقت مناسب لأذكار المساء'),
  custom(1003, 'تذكير الأذكار', 'وقفة قصيرة مع أذكارك');

  const ReminderKind(this.id, this.title, this.body);

  final int id;
  final String title;

  /// نص هادئ غير ضاغط — بلا لوم ولا تهديد.
  final String body;
}

/// تذكيرات محلية بالكامل: لا خادم، ولا Firebase، ولا اتصال بالشبكة.
class NotificationService {
  NotificationService._(this._plugin);

  static final NotificationService instance = NotificationService._(
    FlutterLocalNotificationsPlugin(),
  );

  /// نسخة للاختبارات تعمل بدون قنوات النظام.
  @visibleForTesting
  factory NotificationService.forTesting(
    FlutterLocalNotificationsPlugin plugin,
  ) => NotificationService._(plugin);

  static const String _channelId = 'dhikri_reminders';
  static const String _channelName = 'تذكيرات الأذكار';
  static const String _channelDescription =
      'تذكيرات محلية اختيارية بأوقات الأذكار';

  final FlutterLocalNotificationsPlugin _plugin;

  bool _initialized = false;
  bool _timezoneReady = false;

  bool get isInitialized => _initialized;

  /// تهيئة المكتبة والمنطقة الزمنية. آمنة للاستدعاء أكثر من مرة.
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      await _ensureTimezone();

      const settings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          // لا نطلب أي صلاحية عند الإقلاع — فقط عندما يفعّل المستخدم تذكيرًا.
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      );

      await _plugin.initialize(settings: settings);
      _initialized = true;
    } catch (error, stack) {
      // بيئة لا تدعم الإشعارات: التطبيق يكمل عمله بلا تذكيرات.
      if (kDebugMode) {
        debugPrint('NotificationService init skipped: $error\n$stack');
      }
    }
  }

  /// يضبط المنطقة الزمنية من الجهاز، ويتعامل مع تغيّرها لاحقًا.
  Future<void> _ensureTimezone() async {
    if (_timezoneReady) return;
    tz_data.initializeTimeZones();
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name.identifier));
    } catch (error) {
      // إن تعذّر تحديد المنطقة نُبقي الافتراضية بدل الفشل.
      if (kDebugMode) debugPrint('Timezone detection failed: $error');
    }
    _timezoneReady = true;
  }

  /// يعيد ضبط المنطقة الزمنية ثم يعيد جدولة كل التذكيرات المفعّلة.
  ///
  /// يُستدعى عند عودة التطبيق للمقدمة تحسّبًا لتغيّر المنطقة الزمنية.
  Future<void> refreshTimezoneAndReschedule(AppSettings settings) async {
    _timezoneReady = false;
    await _ensureTimezone();
    await syncAll(settings);
  }

  /// يطلب صلاحية الإشعارات — فقط عند تفعيل المستخدم لتذكير.
  Future<ReminderPermissionResult> requestPermission() async {
    if (!_initialized) await initialize();
    if (!_initialized) return ReminderPermissionResult.unsupported;

    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? false
            ? ReminderPermissionResult.granted
            : ReminderPermissionResult.denied;
      }

      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        final granted = await ios.requestPermissions(
          alert: true,
          badge: false,
          sound: true,
        );
        return granted ?? false
            ? ReminderPermissionResult.granted
            : ReminderPermissionResult.denied;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('Permission request failed: $error');
    }
    return ReminderPermissionResult.unsupported;
  }

  Future<bool> areNotificationsEnabled() async {
    if (!_initialized) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
    } catch (error) {
      if (kDebugMode) debugPrint('areNotificationsEnabled failed: $error');
    }
    return _initialized;
  }

  /// يجدول تذكيرًا يوميًا متكررًا في نفس الساعة.
  ///
  /// نستخدم جدولة غير دقيقة عمدًا حتى لا نطلب صلاحية `SCHEDULE_EXACT_ALARM`
  /// الحساسة — دقة الدقيقة ليست مطلوبة لتذكير أذكار.
  Future<void> schedule(ReminderKind kind, ReminderTime time) async {
    if (!_initialized) await initialize();
    if (!_initialized) return;

    try {
      await _ensureTimezone();
      await _plugin.zonedSchedule(
        id: kind.id,
        title: kind.title,
        body: kind.body,
        scheduledDate: _nextInstanceOf(time),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Scheduling ${kind.name} failed: $error\n$stack');
      }
    }
  }

  Future<void> cancel(ReminderKind kind) async {
    if (!_initialized) return;
    try {
      await _plugin.cancel(id: kind.id);
    } catch (error) {
      if (kDebugMode) debugPrint('Cancel ${kind.name} failed: $error');
    }
  }

  /// يوائم كل التذكيرات مع الإعدادات الحالية.
  Future<void> syncAll(AppSettings settings) async {
    await _applyOne(
      ReminderKind.morning,
      settings.morningReminderEnabled,
      settings.morningReminderTime,
    );
    await _applyOne(
      ReminderKind.evening,
      settings.eveningReminderEnabled,
      settings.eveningReminderTime,
    );
    await _applyOne(
      ReminderKind.custom,
      settings.customReminderEnabled,
      settings.customReminderTime,
    );
  }

  Future<void> cancelAll() async {
    for (final kind in ReminderKind.values) {
      await cancel(kind);
    }
  }

  Future<void> _applyOne(
    ReminderKind kind,
    bool enabled,
    ReminderTime time,
  ) async {
    if (enabled) {
      await schedule(kind, time);
    } else {
      await cancel(kind);
    }
  }

  NotificationDetails _details() => const NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      enableVibration: false,
      tag: 'dhikri_reminder',
    ),
    iOS: DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    ),
  );

  /// أقرب حدوث قادم للوقت المطلوب بالتوقيت المحلي.
  @visibleForTesting
  static tz.TZDateTime nextInstanceOf(ReminderTime time, {tz.TZDateTime? now}) {
    final current = now ?? tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      current.year,
      current.month,
      current.day,
      time.hour,
      time.minute,
    );
    if (!scheduled.isAfter(current)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  tz.TZDateTime _nextInstanceOf(ReminderTime time) => nextInstanceOf(time);
}
