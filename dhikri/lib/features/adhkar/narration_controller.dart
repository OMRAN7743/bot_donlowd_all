import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/services/narration/asset_narration_service.dart';
import '../../core/services/narration/narration_service.dart';
import '../../core/services/narration/tts_narration_service.dart';
import '../../data/models/app_settings.dart';
import 'reading_session.dart';

/// مراحل وضع "استمع وردد" (المواصفات §13).
enum NarrationPhase {
  idle,
  preparing,
  speaking,
  paused,
  waitingForRepeat,
  completed,
  error,
}

/// حالة الاستماع المعروضة في الشاشة.
@immutable
class ListenRepeatState {
  const ListenRepeatState({
    this.phase = NarrationPhase.idle,
    this.errorMessage,
    this.secondsRemaining,
  });

  final NarrationPhase phase;

  /// رسالة عربية تُعرض عند تعذّر الصوت.
  final String? errorMessage;

  /// العدّ التنازلي أثناء "ردد الآن" في الوضع الزمني.
  final int? secondsRemaining;

  bool get isBusy =>
      phase == NarrationPhase.preparing ||
      phase == NarrationPhase.speaking ||
      phase == NarrationPhase.waitingForRepeat;

  bool get isPaused => phase == NarrationPhase.paused;

  ListenRepeatState copyWith({
    NarrationPhase? phase,
    String? errorMessage,
    bool clearError = false,
    int? secondsRemaining,
    bool clearCountdown = false,
  }) {
    return ListenRepeatState(
      phase: phase ?? this.phase,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      secondsRemaining: clearCountdown
          ? null
          : (secondsRemaining ?? this.secondsRemaining),
    );
  }
}

/// خدمة النطق الحيّة — تُغلق مواردها تلقائيًا عند التخلص من المزوّد.
final narrationServiceProvider = Provider<NarrationService>((ref) {
  final service = RoutingNarrationService(
    assetService: AssetNarrationService(),
    ttsService: TtsNarrationService(),
  );
  ref.onDispose(service.dispose);
  return service;
});

/// هل الصوت متاح؟ يُفحص مرة عند فتح الشاشة، ولا يبدأ أي صوت تلقائيًا.
final narrationAvailabilityProvider = FutureProvider<NarrationAvailability>((
  ref,
) async {
  final settings = ref.watch(settingsProvider);
  if (!settings.audioEnabled) {
    return const NarrationAvailability.unavailable(
      NarrationUnavailableReason.disabledByUser,
    );
  }
  return ref.watch(narrationServiceProvider).checkAvailability();
});

/// الأصوات العربية المتاحة على الجهاز — لقائمة اختيار الصوت في الإعدادات.
final arabicVoicesProvider = FutureProvider<List<NarrationVoice>>(
  (ref) => ref.watch(narrationServiceProvider).arabicVoices(),
);

/// يقود دورة "اقرأ ← ردد ← كرّر" لقسم واحد.
class ListenRepeatController extends Notifier<ListenRepeatState> {
  ListenRepeatController(this.categoryId);

  final String categoryId;

  /// نحتفظ بمرجع الخدمة لأن `ref` ممنوع استخدامه داخل onDispose.
  NarrationService? _narrationService;

  /// بعد التخلص من المزوّد يصبح كل تعديل على الحالة خطأً في Riverpod.
  /// قد تصل نداءات متأخرة (مثل `stop` عند مغادرة الشاشة) بعد التخلص، فنتجاهلها.
  bool _disposed = false;

  Timer? _countdown;
  Completer<void>? _manualRepeat;
  bool _stopRequested = false;
  bool _sessionConfigured = false;
  StreamSubscription<AudioInterruptionEvent>? _interruptions;

  @override
  ListenRepeatState build() {
    _narrationService = ref.read(narrationServiceProvider);
    _disposed = false;
    ref.onDispose(() {
      _disposed = true;
      _teardown();
    });
    return const ListenRepeatState();
  }

  /// يكتب الحالة ما لم يكن المزوّد قد تُخلِّص منه.
  void _set(ListenRepeatState next) {
    if (_disposed) return;
    state = next;
  }

  /// الحالة الحالية، أو حالة سكون إن تُخلِّص من المزوّد.
  ListenRepeatState get _current =>
      _disposed ? const ListenRepeatState() : state;

  NarrationService get _narration =>
      _narrationService ?? ref.read(narrationServiceProvider);

  AppSettings get _settings => ref.read(settingsProvider);

  /// يبدأ الاستماع من الذكر الحالي.
  ///
  /// [onRepeatRegistered] تُستدعى بعد كل ترديد مكتمل، وتُعيد ما حدث حتى
  /// تتولى الشاشة الاهتزاز والانتقال.
  Future<void> start({
    required ReadingSessionState Function() readState,
    required Future<RepeatOutcome> Function() registerRepeat,
  }) async {
    if (_disposed || _current.isBusy) return;

    _stopRequested = false;
    _set(const ListenRepeatState(phase: NarrationPhase.preparing));

    final availability = await _narration.checkAvailability();
    if (!_settings.audioEnabled) {
      _set(
        ListenRepeatState(
          phase: NarrationPhase.error,
          errorMessage: const NarrationAvailability.unavailable(
            NarrationUnavailableReason.disabledByUser,
          ).message,
        ),
      );
      return;
    }
    if (!availability.isAvailable) {
      _set(
        ListenRepeatState(
          phase: NarrationPhase.error,
          errorMessage: availability.message,
        ),
      );
      return;
    }

    // تهيئة جلسة الصوت أثر جانبي: نطلقها ولا ننتظرها حتى لا يتعطّل بدء
    // القراءة على جهاز أو منصّة لا تردّ على قناة جلسة الصوت.
    unawaited(_configureAudioSession());
    await _narration.setRate(_settings.speechRate);
    await _narration.setVoice(_settings.preferredVoiceId);

    await _runLoop(readState: readState, registerRepeat: registerRepeat);
  }

  Future<void> _runLoop({
    required ReadingSessionState Function() readState,
    required Future<RepeatOutcome> Function() registerRepeat,
  }) async {
    while (!_stopRequested) {
      final session = readState();
      final dhikr = session.current;
      if (dhikr == null) break;

      _set(
        _current.copyWith(
          phase: NarrationPhase.speaking,
          clearError: true,
          clearCountdown: true,
        ),
      );

      try {
        await _narration.playDhikr(dhikr);
      } catch (error) {
        if (kDebugMode) debugPrint('Narration playback failed: $error');
        _set(
          const ListenRepeatState(
            phase: NarrationPhase.error,
            errorMessage: 'تعذّر تشغيل الصوت. يمكنك متابعة القراءة نصًّا.',
          ),
        );
        return;
      }
      if (_stopRequested) break;

      // مرحلة "ردد الآن".
      await _waitForRepeat();
      if (_stopRequested) break;

      final outcome = await registerRepeat();
      if (outcome == RepeatOutcome.sessionCompleted) {
        _set(const ListenRepeatState(phase: NarrationPhase.completed));
        return;
      }
      if (outcome == RepeatOutcome.dhikrCompleted ||
          outcome == RepeatOutcome.alreadyComplete) {
        // ننتقل للذكر التالي فقط إذا طلب المستخدم متابعة الورد صوتيًا.
        if (!_settings.continueSessionAudio) {
          _set(const ListenRepeatState(phase: NarrationPhase.completed));
          return;
        }
      }
    }

    if (_current.phase != NarrationPhase.completed) {
      _set(const ListenRepeatState());
    }
  }

  /// ينتظر المستخدم ليردّد: مدة محددة أو حتى يضغط "انتهيت".
  Future<void> _waitForRepeat() async {
    final mode = _settings.repeatPauseMode;
    final duration = mode.duration;

    if (duration == null) {
      _set(
        _current.copyWith(
          phase: NarrationPhase.waitingForRepeat,
          clearCountdown: true,
        ),
      );
      final completer = Completer<void>();
      _manualRepeat = completer;
      await completer.future;
      _manualRepeat = null;
      return;
    }

    var remaining = duration.inSeconds;
    _set(
      _current.copyWith(
        phase: NarrationPhase.waitingForRepeat,
        secondsRemaining: remaining,
      ),
    );

    final completer = Completer<void>();
    _manualRepeat = completer;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      remaining -= 1;
      if (remaining <= 0) {
        timer.cancel();
        if (!completer.isCompleted) completer.complete();
        return;
      }
      _set(_current.copyWith(secondsRemaining: remaining));
    });

    await completer.future;
    _countdown?.cancel();
    _countdown = null;
    _manualRepeat = null;
  }

  /// يضغطها المستخدم في وضع الترديد اليدوي.
  void confirmRepeatDone() {
    final completer = _manualRepeat;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  Future<void> pause() async {
    if (_disposed || _current.phase != NarrationPhase.speaking) return;
    await _narration.pause();
    _set(_current.copyWith(phase: NarrationPhase.paused));
  }

  Future<void> resume() async {
    if (_disposed || _current.phase != NarrationPhase.paused) return;
    await _narration.resume();
    _set(_current.copyWith(phase: NarrationPhase.speaking));
  }

  /// يوقف كل شيء ويعيد الحالة إلى السكون.
  Future<void> stop() async {
    _stopRequested = true;
    _countdown?.cancel();
    _countdown = null;
    final completer = _manualRepeat;
    if (completer != null && !completer.isCompleted) completer.complete();
    _manualRepeat = null;
    await _narration.stop();
    _set(const ListenRepeatState());
  }

  /// يهيّئ جلسة الصوت ويتعامل مع المقاطعات (مكالمة، تنبيه من تطبيق آخر).
  Future<void> _configureAudioSession() async {
    if (_sessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      _interruptions = session.interruptionEventStream.listen((event) {
        if (event.begin) {
          // لا نشغّل الصوت فوق مكالمة — نتوقف بأدب.
          unawaited(pause());
        }
      });
      _sessionConfigured = true;
    } catch (error) {
      // بيئة بلا جلسة صوت: نكمل بلا معالجة مقاطعات بدل الفشل.
      if (kDebugMode) debugPrint('Audio session unavailable: $error');
      _sessionConfigured = true;
    }
  }

  void _teardown() {
    _stopRequested = true;
    _countdown?.cancel();
    final completer = _manualRepeat;
    if (completer != null && !completer.isCompleted) completer.complete();
    unawaited(_interruptions?.cancel());
    unawaited(_narrationService?.stop());
  }
}

final listenRepeatProvider =
    NotifierProvider.family<ListenRepeatController, ListenRepeatState, String>(
      ListenRepeatController.new,
    );
