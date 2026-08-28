import 'package:flutter/foundation.dart';

import '../../../data/models/dhikr.dart';

/// لماذا قد لا يتوفّر الصوت؟
enum NarrationUnavailableReason {
  /// المستخدم أطفأ القراءة الصوتية من الإعدادات.
  disabledByUser,

  /// لا يوجد محرك نطق على الجهاز.
  engineMissing,

  /// المحرك موجود لكن بلا صوت عربي مثبَّت.
  arabicVoiceMissing,

  /// المنصة لا تدعم النطق (اختبارات، بيئة غير مهيأة).
  platformUnsupported,
}

/// حالة توفّر الصوت مع رسالة عربية جاهزة للعرض عند الحاجة.
@immutable
class NarrationAvailability {
  const NarrationAvailability.available() : isAvailable = true, reason = null;

  const NarrationAvailability.unavailable(this.reason) : isAvailable = false;

  final bool isAvailable;
  final NarrationUnavailableReason? reason;

  /// رسالة محترمة تشرح الوضع وتقترح حلًّا — بلا مصطلحات تقنية معقّدة.
  String get message => switch (reason) {
    null => '',
    NarrationUnavailableReason.disabledByUser =>
      'القراءة الصوتية مُطفأة. يمكنك تشغيلها من إعدادات الصوت.',
    NarrationUnavailableReason.arabicVoiceMissing =>
      'الصوت العربي غير متوفر على هذا الجهاز حاليًا.\n'
          'يمكنك تثبيت صوت عربي من إعدادات تحويل النص إلى كلام في جهازك.',
    NarrationUnavailableReason.engineMissing =>
      'لا يوجد محرك نطق على هذا الجهاز.\n'
          'يمكنك تثبيت محرك تحويل النص إلى كلام من إعدادات جهازك.',
    NarrationUnavailableReason.platformUnsupported =>
      'القراءة الصوتية غير مدعومة على هذا الجهاز.',
  };
}

/// صوت عربي متاح على الجهاز.
@immutable
class NarrationVoice {
  const NarrationVoice({
    required this.id,
    required this.name,
    required this.locale,
  });

  final String id;
  final String name;
  final String locale;

  @override
  bool operator ==(Object other) => other is NarrationVoice && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// الواجهة التي تعتمد عليها الشاشات.
///
/// وجودها يسمح باستبدال محرك النطق لاحقًا بتسجيلات بشرية موثقة دون تغيير
/// أي كود واجهة (المواصفات §14 و§15).
abstract interface class NarrationService {
  /// هل يمكن النطق الآن؟ تُفحص قبل إظهار زر الاستماع.
  Future<NarrationAvailability> checkAvailability();

  /// الأصوات العربية المتاحة على الجهاز (قد تكون فارغة).
  Future<List<NarrationVoice>> arabicVoices();

  /// يقرأ الذكر. يكتمل الـ Future عند نهاية القراءة أو عند الإيقاف.
  Future<void> playDhikr(Dhikr dhikr);

  Future<void> pause();

  Future<void> resume();

  Future<void> stop();

  /// سرعة القراءة ضمن 0.75 – 1.2.
  Future<void> setRate(double rate);

  Future<void> setVoice(String? voiceId);

  Future<void> dispose();
}
