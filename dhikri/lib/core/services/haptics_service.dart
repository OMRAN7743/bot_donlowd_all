import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../data/models/app_settings.dart';

/// الواجهة التي تنفّذ الاهتزاز فعليًا — تُستبدل في الاختبارات.
abstract interface class HapticsBackend {
  Future<void> light();
  Future<void> medium();
  Future<void> selection();
}

/// التنفيذ الحقيقي عبر Flutter SDK. لا حاجة لمكتبة اهتزاز خارجية.
class PlatformHapticsBackend implements HapticsBackend {
  const PlatformHapticsBackend();

  @override
  Future<void> light() => HapticFeedback.lightImpact();

  @override
  Future<void> medium() => HapticFeedback.mediumImpact();

  @override
  Future<void> selection() => HapticFeedback.selectionClick();
}

/// بوابة الاهتزاز الوحيدة في التطبيق.
///
/// قاعدة صارمة: عند إطفاء أي مفتاح اهتزاز، لا يُستدعى النظام إطلاقًا.
class HapticsService {
  HapticsService(
    this._settings, [
    this._backend = const PlatformHapticsBackend(),
  ]);

  final AppSettings Function() _settings;
  final HapticsBackend _backend;

  /// نبضة واحدة عند اكتمال الذكر. الافتراضي: مُفعَّل.
  Future<void> completion() =>
      _pulse(_settings().completionHaptics, _backend.medium);

  /// نبضة خفيفة عند كل ضغطة عدّ. الافتراضي: مُعطَّل.
  Future<void> counterTap() => _pulse(_settings().tapHaptics, _backend.light);

  /// نبضة عدّاد التسبيح. الافتراضي: مُعطَّل.
  Future<void> tasbihTap() =>
      _pulse(_settings().tasbihHaptics, _backend.selection);

  /// نبضة إكمال هدف التسبيح — تتبع نفس مفتاح التسبيح.
  Future<void> tasbihTargetReached() =>
      _pulse(_settings().tasbihHaptics, _backend.medium);

  /// ينفّذ النبضة إن كان مفتاحها مُفعَّلًا، ولا يسمح لفشل الجهاز بالتسرّب.
  ///
  /// جهاز بلا هزّاز — أو منصّة لا ترد على القناة — يجب ألا يُفشل أي تدفّق
  /// في الواجهة.
  Future<void> _pulse(bool enabled, Future<void> Function() pulse) async {
    if (!enabled) return;
    try {
      await pulse();
    } catch (error) {
      if (kDebugMode) debugPrint('Haptic feedback unavailable: $error');
    }
  }
}
