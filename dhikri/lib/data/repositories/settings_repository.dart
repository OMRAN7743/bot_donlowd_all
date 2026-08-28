import '../../core/services/preferences_service.dart';
import '../models/app_settings.dart';

/// يقرأ ويكتب إعدادات المستخدم في التخزين المحلي.
///
/// أي قيمة مفقودة أو تالفة تعود إلى الافتراضي في [AppSettings.defaults]
/// بدل أن ترفع خطأ.
class SettingsRepository {
  const SettingsRepository(this._store);

  final KeyValueStore _store;

  Future<AppSettings> load() async {
    const d = AppSettings.defaults;

    return AppSettings(
      themePreference:
          _parseEnum(
            await _store.getString(PrefKeys.themePreference),
            AppThemePreference.values,
            (e) => e.name,
          ) ??
          d.themePreference,
      textScalePreset:
          _parseEnum(
            await _store.getString(PrefKeys.textScalePreset),
            TextScalePreset.values,
            (e) => e.name,
          ) ??
          d.textScalePreset,
      seniorMode: await _store.getBool(PrefKeys.seniorMode) ?? d.seniorMode,
      highContrast:
          await _store.getBool(PrefKeys.highContrast) ?? d.highContrast,
      reduceMotion:
          await _store.getBool(PrefKeys.reduceMotion) ?? d.reduceMotion,
      saveReadingProgress:
          await _store.getBool(PrefKeys.saveReadingProgress) ??
          d.saveReadingProgress,
      showSource: await _store.getBool(PrefKeys.showSource) ?? d.showSource,
      autoNext: await _store.getBool(PrefKeys.autoNext) ?? d.autoNext,
      keepScreenAwake:
          await _store.getBool(PrefKeys.keepScreenAwake) ?? d.keepScreenAwake,
      audioEnabled:
          await _store.getBool(PrefKeys.audioEnabled) ?? d.audioEnabled,
      speechRate:
          _sanitizeRate(await _store.getDouble(PrefKeys.speechRate)) ??
          d.speechRate,
      repeatPauseMode:
          _parseEnum(
            await _store.getString(PrefKeys.repeatPauseMode),
            RepeatPauseMode.values,
            (e) => e.name,
          ) ??
          d.repeatPauseMode,
      continueSessionAudio:
          await _store.getBool(PrefKeys.continueSessionAudio) ??
          d.continueSessionAudio,
      preferredVoiceId: await _store.getString(PrefKeys.preferredVoiceId),
      completionHaptics:
          await _store.getBool(PrefKeys.completionHaptics) ??
          d.completionHaptics,
      tapHaptics: await _store.getBool(PrefKeys.tapHaptics) ?? d.tapHaptics,
      tasbihHaptics:
          await _store.getBool(PrefKeys.tasbihHaptics) ?? d.tasbihHaptics,
      morningReminderEnabled:
          await _store.getBool(PrefKeys.morningReminderEnabled) ??
          d.morningReminderEnabled,
      morningReminderTime:
          _parseTime(await _store.getInt(PrefKeys.morningReminderTime)) ??
          d.morningReminderTime,
      eveningReminderEnabled:
          await _store.getBool(PrefKeys.eveningReminderEnabled) ??
          d.eveningReminderEnabled,
      eveningReminderTime:
          _parseTime(await _store.getInt(PrefKeys.eveningReminderTime)) ??
          d.eveningReminderTime,
      customReminderEnabled:
          await _store.getBool(PrefKeys.customReminderEnabled) ??
          d.customReminderEnabled,
      customReminderTime:
          _parseTime(await _store.getInt(PrefKeys.customReminderTime)) ??
          d.customReminderTime,
    );
  }

  /// يكتب الإعدادات كاملة. يُستدعى عند كل تغيير — وليس في كل إطار رسم.
  Future<void> save(AppSettings s) async {
    await _store.setString(PrefKeys.themePreference, s.themePreference.name);
    await _store.setString(PrefKeys.textScalePreset, s.textScalePreset.name);
    await _store.setBool(PrefKeys.seniorMode, s.seniorMode);
    await _store.setBool(PrefKeys.highContrast, s.highContrast);
    await _store.setBool(PrefKeys.reduceMotion, s.reduceMotion);
    await _store.setBool(PrefKeys.saveReadingProgress, s.saveReadingProgress);
    await _store.setBool(PrefKeys.showSource, s.showSource);
    await _store.setBool(PrefKeys.autoNext, s.autoNext);
    await _store.setBool(PrefKeys.keepScreenAwake, s.keepScreenAwake);
    await _store.setBool(PrefKeys.audioEnabled, s.audioEnabled);
    await _store.setDouble(PrefKeys.speechRate, s.speechRate);
    await _store.setString(PrefKeys.repeatPauseMode, s.repeatPauseMode.name);
    await _store.setBool(PrefKeys.continueSessionAudio, s.continueSessionAudio);
    if (s.preferredVoiceId == null) {
      await _store.remove(PrefKeys.preferredVoiceId);
    } else {
      await _store.setString(PrefKeys.preferredVoiceId, s.preferredVoiceId!);
    }
    await _store.setBool(PrefKeys.completionHaptics, s.completionHaptics);
    await _store.setBool(PrefKeys.tapHaptics, s.tapHaptics);
    await _store.setBool(PrefKeys.tasbihHaptics, s.tasbihHaptics);
    await _store.setBool(
      PrefKeys.morningReminderEnabled,
      s.morningReminderEnabled,
    );
    await _store.setInt(
      PrefKeys.morningReminderTime,
      s.morningReminderTime.asMinutes,
    );
    await _store.setBool(
      PrefKeys.eveningReminderEnabled,
      s.eveningReminderEnabled,
    );
    await _store.setInt(
      PrefKeys.eveningReminderTime,
      s.eveningReminderTime.asMinutes,
    );
    await _store.setBool(
      PrefKeys.customReminderEnabled,
      s.customReminderEnabled,
    );
    await _store.setInt(
      PrefKeys.customReminderTime,
      s.customReminderTime.asMinutes,
    );
  }

  /// يعيد كل الإعدادات والتذكيرات إلى الوضع الافتراضي.
  Future<void> resetToDefaults() async {
    await _store.removeWithPrefix(PrefKeys.settingsPrefix);
    await _store.removeWithPrefix(PrefKeys.remindersPrefix);
  }

  Future<bool> isOnboardingCompleted() async =>
      await _store.getBool(PrefKeys.onboardingCompleted) ?? false;

  Future<void> setOnboardingCompleted({bool value = true}) =>
      _store.setBool(PrefKeys.onboardingCompleted, value);

  static double? _sanitizeRate(double? raw) {
    if (raw == null) return null;
    if (raw.isNaN || raw < SpeechRates.min || raw > SpeechRates.max) {
      return null;
    }
    return SpeechRates.nearest(raw);
  }

  static ReminderTime? _parseTime(int? minutes) {
    if (minutes == null || minutes < 0 || minutes >= 24 * 60) return null;
    return ReminderTime.fromMinutes(minutes);
  }

  static T? _parseEnum<T>(
    String? raw,
    List<T> values,
    String Function(T) nameOf,
  ) {
    if (raw == null) return null;
    for (final value in values) {
      if (nameOf(value) == raw) return value;
    }
    return null;
  }
}
