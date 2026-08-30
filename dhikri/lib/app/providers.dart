import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/services/haptics_service.dart';
import '../core/services/screen_wake_service.dart';
import '../core/services/preferences_service.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/adhkar_repository.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/settings_repository.dart';
import 'bootstrap.dart';

/// يُحقن دائمًا عبر `overrideWithValue` في `main()` أو في الاختبارات.
final bootstrapProvider = Provider<AppBootstrap>((ref) {
  throw StateError(
    'bootstrapProvider يجب تجاوزه بـ overrideWithValue قبل تشغيل التطبيق.',
  );
});

final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => ref.watch(bootstrapProvider).store,
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => SettingsRepository(ref.watch(keyValueStoreProvider)),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => FavoritesRepository(ref.watch(keyValueStoreProvider)),
);

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => ProgressRepository(ref.watch(keyValueStoreProvider)),
);

final contentStateProvider = Provider<ContentState>(
  (ref) => ref.watch(bootstrapProvider).content,
);

/// مستودع الأذكار عندما ينجح التحميل، وإلا `null`.
final adhkarRepositoryProvider = Provider<AdhkarRepository?>((ref) {
  final content = ref.watch(contentStateProvider);
  return content is ContentReady ? content.repository : null;
});

/// خدمة الاهتزاز — تحترم إعدادات المستخدم قبل أي نبضة.
final hapticsProvider = Provider<HapticsService>((ref) {
  return HapticsService(() => ref.read(settingsProvider));
});

/// خدمة إبقاء الشاشة مستيقظة أثناء الورد.
final screenWakeProvider = Provider<ScreenWakeService>(
  (ref) => const PlatformScreenWakeService(),
);

// ---------------------------------------------------------------------------
// الإعدادات
// ---------------------------------------------------------------------------

/// حالة الإعدادات الحيّة. كل تعديل يُحفظ فورًا في التخزين المحلي.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.watch(bootstrapProvider).settings;

  Future<void> _apply(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemePreference(AppThemePreference value) =>
      _apply(state.copyWith(themePreference: value));

  Future<void> setTextScale(TextScalePreset value) =>
      _apply(state.copyWith(textScalePreset: value));

  Future<void> setSeniorMode(bool value) =>
      _apply(state.copyWith(seniorMode: value));

  Future<void> setHighContrast(bool value) =>
      _apply(state.copyWith(highContrast: value));

  Future<void> setReduceMotion(bool value) =>
      _apply(state.copyWith(reduceMotion: value));

  Future<void> setSaveReadingProgress(bool value) =>
      _apply(state.copyWith(saveReadingProgress: value));

  Future<void> setShowSource(bool value) =>
      _apply(state.copyWith(showSource: value));

  Future<void> setAutoNext(bool value) =>
      _apply(state.copyWith(autoNext: value));

  Future<void> setKeepScreenAwake(bool value) =>
      _apply(state.copyWith(keepScreenAwake: value));

  Future<void> setAudioEnabled(bool value) =>
      _apply(state.copyWith(audioEnabled: value));

  Future<void> setSpeechRate(double value) =>
      _apply(state.copyWith(speechRate: SpeechRates.nearest(value)));

  Future<void> setRepeatPauseMode(RepeatPauseMode value) =>
      _apply(state.copyWith(repeatPauseMode: value));

  Future<void> setContinueSessionAudio(bool value) =>
      _apply(state.copyWith(continueSessionAudio: value));

  Future<void> setPreferredVoice(String? voiceId) => _apply(
    state.copyWith(
      preferredVoiceId: voiceId,
      clearPreferredVoiceId: voiceId == null,
    ),
  );

  Future<void> setCompletionHaptics(bool value) =>
      _apply(state.copyWith(completionHaptics: value));

  Future<void> setTapHaptics(bool value) =>
      _apply(state.copyWith(tapHaptics: value));

  Future<void> setTasbihHaptics(bool value) =>
      _apply(state.copyWith(tasbihHaptics: value));

  Future<void> setMorningReminder({bool? enabled, ReminderTime? time}) =>
      _apply(
        state.copyWith(
          morningReminderEnabled: enabled,
          morningReminderTime: time,
        ),
      );

  Future<void> setEveningReminder({bool? enabled, ReminderTime? time}) =>
      _apply(
        state.copyWith(
          eveningReminderEnabled: enabled,
          eveningReminderTime: time,
        ),
      );

  Future<void> setCustomReminder({bool? enabled, ReminderTime? time}) => _apply(
    state.copyWith(customReminderEnabled: enabled, customReminderTime: time),
  );

  /// يعيد كل الإعدادات إلى الوضع الافتراضي المعتمد.
  Future<void> resetToDefaults() async {
    state = AppSettings.defaults;
    await ref.read(settingsRepositoryProvider).resetToDefaults();
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

/// هل نقلّل الحركة؟ إعداد المستخدم أو إعداد النظام — أيّهما طلب التقليل.
bool shouldReduceMotion(BuildContext context, AppSettings settings) =>
    settings.reduceMotion || MediaQuery.disableAnimationsOf(context);

// ---------------------------------------------------------------------------
// المفضلة
// ---------------------------------------------------------------------------

class FavoritesController extends Notifier<Set<String>> {
  @override
  Set<String> build() => ref.watch(bootstrapProvider).favorites;

  bool isFavorite(String dhikrId) => state.contains(dhikrId);

  Future<void> toggle(String dhikrId) async {
    final next = <String>{...state};
    if (!next.remove(dhikrId)) next.add(dhikrId);
    state = Set<String>.unmodifiable(next);
    await ref.read(favoritesRepositoryProvider).save(next);
  }

  Future<void> clearAll() async {
    state = const <String>{};
    await ref.read(favoritesRepositoryProvider).clear();
  }
}

final favoritesProvider = NotifierProvider<FavoritesController, Set<String>>(
  FavoritesController.new,
);

// ---------------------------------------------------------------------------
// أول تشغيل
// ---------------------------------------------------------------------------

/// هل أنهى المستخدم شاشات التعريف؟
class OnboardingController extends Notifier<bool> {
  @override
  bool build() => ref.watch(bootstrapProvider).onboardingCompleted;

  Future<void> complete() async {
    state = true;
    await ref.read(settingsRepositoryProvider).setOnboardingCompleted();
  }
}

final onboardingCompletedProvider =
    NotifierProvider<OnboardingController, bool>(OnboardingController.new);
