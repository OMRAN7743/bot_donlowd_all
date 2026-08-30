import 'package:flutter/foundation.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// يمنع إطفاء الشاشة أثناء قراءة الورد.
///
/// مُجرَّد خلف واجهة حتى تُختبر الشاشات بلا قنوات نظام، ولأن الميزة اختيارية
/// ومطفأة افتراضيًا (المواصفات §22-B).
abstract interface class ScreenWakeService {
  /// يطلب إبقاء الشاشة مستيقظة.
  Future<void> enable();

  /// يعيد سلوك الشاشة الطبيعي. آمن للاستدعاء حتى لو لم تُفعَّل.
  Future<void> disable();
}

/// التنفيذ الحقيقي. أي فشل من المنصّة يُبتلع: الميزة كمالية ولا يجوز أن
/// تُفشل القراءة.
class PlatformScreenWakeService implements ScreenWakeService {
  const PlatformScreenWakeService();

  @override
  Future<void> enable() => _guard(() => WakelockPlus.enable());

  @override
  Future<void> disable() => _guard(() => WakelockPlus.disable());

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (kDebugMode) debugPrint('Screen wakelock unavailable: $error');
    }
  }
}

/// تنفيذ يسجّل النداءات — للاختبارات.
@visibleForTesting
class RecordingScreenWakeService implements ScreenWakeService {
  final List<String> calls = <String>[];

  bool get isEnabled => calls.isNotEmpty && calls.last == 'enable';

  @override
  Future<void> enable() async => calls.add('enable');

  @override
  Future<void> disable() async => calls.add('disable');
}
