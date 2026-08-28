import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../../../data/models/dhikr.dart';
import 'narration_service.dart';

/// تشغيل التسجيلات البشرية الموثقة المرفقة في `assets/audio/`.
///
/// هذه هي الأولوية الأولى في المواصفات §14: إذا كان للذكر `audioAssetPath`
/// فالتسجيل البشري أدقّ من أي محرك نطق آلي.
class AssetNarrationService implements NarrationService {
  AssetNarrationService([AudioPlayer? player])
    : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Future<NarrationAvailability> checkAvailability() async =>
      const NarrationAvailability.available();

  @override
  Future<List<NarrationVoice>> arabicVoices() async => const <NarrationVoice>[];

  /// يشغّل تسجيل الذكر ويعود بعد انتهائه.
  @override
  Future<void> playDhikr(Dhikr dhikr) async {
    final path = dhikr.audioAssetPath;
    if (path == null || path.isEmpty) return;

    try {
      await _player.setAsset(path);
      await _player.play();
      // ننتظر وصول المشغّل إلى نهاية المقطع.
      await _player.processingStateStream.firstWhere(
        (state) => state == ProcessingState.completed,
      );
      await _player.stop();
    } catch (error) {
      if (kDebugMode) debugPrint('Asset narration failed for $path: $error');
    }
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> resume() => _player.play();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> setRate(double rate) => _player.setSpeed(rate);

  @override
  Future<void> setVoice(String? voiceId) async {}

  @override
  Future<void> dispose() => _player.dispose();
}

/// يوجّه كل ذكر إلى أنسب مصدر صوتي حسب أولويات المواصفات §14.
///
/// 1) تسجيل بشري موثق مرفق مع التطبيق.
/// 2) محرك النطق المثبَّت على الجهاز.
class RoutingNarrationService implements NarrationService {
  RoutingNarrationService({
    required NarrationService assetService,
    required NarrationService ttsService,
  }) : _assets = assetService,
       _tts = ttsService;

  final NarrationService _assets;
  final NarrationService _tts;

  NarrationService? _active;

  @override
  Future<NarrationAvailability> checkAvailability() => _tts.checkAvailability();

  @override
  Future<List<NarrationVoice>> arabicVoices() => _tts.arabicVoices();

  @override
  Future<void> playDhikr(Dhikr dhikr) async {
    final service = dhikr.hasRecordedAudio ? _assets : _tts;
    _active = service;
    await service.playDhikr(dhikr);
  }

  @override
  Future<void> pause() async => _active?.pause();

  @override
  Future<void> resume() async => _active?.resume();

  @override
  Future<void> stop() async {
    await _assets.stop();
    await _tts.stop();
  }

  @override
  Future<void> setRate(double rate) async {
    await _assets.setRate(rate);
    await _tts.setRate(rate);
  }

  @override
  Future<void> setVoice(String? voiceId) => _tts.setVoice(voiceId);

  @override
  Future<void> dispose() async {
    await _assets.dispose();
    await _tts.dispose();
  }
}
