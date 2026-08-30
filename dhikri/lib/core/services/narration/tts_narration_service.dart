import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show MissingPluginException;
import 'package:flutter_tts/flutter_tts.dart';

import '../../../data/models/dhikr.dart';
import 'narration_service.dart';

/// النطق باستخدام محرك الجهاز عبر `flutter_tts`.
///
/// لا يُرسل نص الذكر إلى أي خدمة سحابية — كل شيء يجري على الجهاز.
class TtsNarrationService implements NarrationService {
  TtsNarrationService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  /// اللهجات العربية التي نجرّبها بالترتيب، ولا نفرض واحدة إن لم توجد.
  static const List<String> preferredLocales = <String>[
    'ar-SA',
    'ar-EG',
    'ar-AE',
    'ar-JO',
    'ar',
  ];

  final FlutterTts _tts;

  bool _configured = false;
  String? _resolvedLocale;
  Completer<void>? _speaking;

  /// اللهجة العربية التي وقع عليها الاختيار على هذا الجهاز.
  @visibleForTesting
  String? get resolvedLocale => _resolvedLocale;

  Future<void> _configure() async {
    if (_configured) return;

    // ننتظر انتهاء النطق فعليًا حتى تعمل مرحلة "ردد الآن" بشكل صحيح.
    await _tts.awaitSpeakCompletion(true);
    _tts.setCompletionHandler(_finishSpeaking);
    _tts.setCancelHandler(_finishSpeaking);
    _tts.setErrorHandler((dynamic message) {
      if (kDebugMode) debugPrint('TTS error: $message');
      _finishSpeaking();
    });
    _configured = true;
  }

  void _finishSpeaking() {
    final completer = _speaking;
    _speaking = null;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  @override
  Future<NarrationAvailability> checkAvailability() async {
    try {
      await _configure();
      final locale = await _resolveArabicLocale();
      if (locale == null) {
        return const NarrationAvailability.unavailable(
          NarrationUnavailableReason.arabicVoiceMissing,
        );
      }
      return const NarrationAvailability.available();
    } on MissingPluginException {
      return const NarrationAvailability.unavailable(
        NarrationUnavailableReason.platformUnsupported,
      );
    } catch (error) {
      if (kDebugMode) debugPrint('TTS availability check failed: $error');
      return const NarrationAvailability.unavailable(
        NarrationUnavailableReason.engineMissing,
      );
    }
  }

  /// يبحث عن أول لهجة عربية مدعومة فعلًا على الجهاز.
  Future<String?> _resolveArabicLocale() async {
    if (_resolvedLocale != null) return _resolvedLocale;

    for (final locale in preferredLocales) {
      final available = await _tts.isLanguageAvailable(locale);
      if (available != true) continue;

      // على أندرويد نتأكد أن ملفات الصوت مثبَّتة فعلًا وليست معرَّفة فقط.
      if (defaultTargetPlatform == TargetPlatform.android) {
        try {
          final installed = await _tts.isLanguageInstalled(locale);
          if (installed != true) continue;
        } on MissingPluginException {
          // بعض الأجهزة لا توفّر هذا الفحص — نقبل نتيجة isLanguageAvailable.
        }
      }

      _resolvedLocale = locale;
      return locale;
    }
    return null;
  }

  @override
  Future<List<NarrationVoice>> arabicVoices() async {
    try {
      await _configure();
      final raw = await _tts.getVoices;
      if (raw is! List) return const <NarrationVoice>[];

      final voices = <NarrationVoice>[];
      for (final entry in raw) {
        if (entry is! Map) continue;
        final locale = entry['locale']?.toString() ?? '';
        if (!locale.toLowerCase().startsWith('ar')) continue;

        final name = entry['name']?.toString() ?? '';
        if (name.isEmpty) continue;
        voices.add(
          NarrationVoice(id: '$name|$locale', name: name, locale: locale),
        );
      }
      return voices;
    } catch (error) {
      if (kDebugMode) debugPrint('Reading voices failed: $error');
      return const <NarrationVoice>[];
    }
  }

  @override
  Future<void> playDhikr(Dhikr dhikr) async {
    await _configure();
    final locale = await _resolveArabicLocale();
    if (locale == null) return;

    await stop();
    await _tts.setLanguage(locale);

    final completer = Completer<void>();
    _speaking = completer;
    try {
      await _tts.speak(dhikr.text);
    } catch (error) {
      if (kDebugMode) debugPrint('TTS speak failed: $error');
      _finishSpeaking();
      return;
    }
    // مع awaitSpeakCompletion يعود speak بعد الانتهاء، والمُكمِّل حماية إضافية.
    _finishSpeaking();
    await completer.future;
  }

  @override
  Future<void> pause() async {
    try {
      await _tts.pause();
    } catch (error) {
      if (kDebugMode) debugPrint('TTS pause failed: $error');
    }
  }

  /// محرك الجهاز لا يدعم الاستئناف من موضع التوقف، فنكتفي بإنهاء الحالة.
  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (error) {
      if (kDebugMode) debugPrint('TTS stop failed: $error');
    }
    _finishSpeaking();
  }

  @override
  Future<void> setRate(double rate) async {
    // نطاق flutter_tts على أندرويد 0.0 – 1.0 حيث 0.5 ≈ السرعة الطبيعية.
    final normalized = (rate / 2).clamp(0.0, 1.0);
    try {
      await _tts.setSpeechRate(normalized);
    } catch (error) {
      if (kDebugMode) debugPrint('TTS setSpeechRate failed: $error');
    }
  }

  @override
  Future<void> setVoice(String? voiceId) async {
    if (voiceId == null) return;
    final parts = voiceId.split('|');
    if (parts.length != 2) return;
    try {
      await _tts.setVoice(<String, String>{
        'name': parts[0],
        'locale': parts[1],
      });
      _resolvedLocale = parts[1];
    } catch (error) {
      if (kDebugMode) debugPrint('TTS setVoice failed: $error');
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
  }
}
