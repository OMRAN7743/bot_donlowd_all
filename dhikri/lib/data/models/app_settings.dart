import 'package:flutter/material.dart';

/// نمط عرض التطبيق.
enum AppThemePreference { system, light, dark }

/// أحجام النص المتاحة للمستخدم.
enum TextScalePreset {
  small(0.9, 'صغير'),
  medium(1.0, 'متوسط'),
  large(1.15, 'كبير'),
  extraLarge(1.3, 'كبير جدًا');

  const TextScalePreset(this.factor, this.label);

  /// معامل الضرب المطبَّق على أحجام الخط الأساسية.
  final double factor;
  final String label;
}

/// كيف ينتظر التطبيق المستخدم ليُردّد بعد قراءة الذكر صوتيًا.
enum RepeatPauseMode {
  manual(null, 'يدوي — اضغط عند الانتهاء'),
  seconds3(Duration(seconds: 3), '٣ ثوانٍ'),
  seconds5(Duration(seconds: 5), '٥ ثوانٍ'),
  seconds8(Duration(seconds: 8), '٨ ثوانٍ');

  const RepeatPauseMode(this.duration, this.label);

  /// `null` تعني أن المستخدم هو من يقرر متى ينتهي الترديد.
  final Duration? duration;
  final String label;
}

/// السرعات المسموح بها للقراءة الصوتية.
abstract final class SpeechRates {
  static const List<double> values = <double>[0.75, 0.9, 1.0, 1.1, 1.2];
  static const double min = 0.75;
  static const double max = 1.2;

  static String label(double rate) => '${rate.toStringAsFixed(2)}×';

  /// يُقرّب أي قيمة محفوظة إلى أقرب سرعة مدعومة.
  static double nearest(double rate) {
    var best = values.first;
    for (final v in values) {
      if ((v - rate).abs() < (best - rate).abs()) best = v;
    }
    return best;
  }
}

/// وقت تذكير محلي (ساعة/دقيقة) قابل للتخزين كعدد دقائق من منتصف الليل.
@immutable
class ReminderTime {
  const ReminderTime(this.hour, this.minute);

  factory ReminderTime.fromMinutes(int minutes) {
    final safe = minutes % (24 * 60);
    return ReminderTime(safe ~/ 60, safe % 60);
  }

  final int hour;
  final int minute;

  int get asMinutes => hour * 60 + minute;

  TimeOfDay get asTimeOfDay => TimeOfDay(hour: hour, minute: minute);

  /// صيغة عربية بسيطة مثل "٦:٣٠ صباحًا".
  String get label {
    final isMorning = hour < 12;
    final displayHour = hour % 12 == 0 ? 12 : hour % 12;
    final mm = minute.toString().padLeft(2, '0');
    return '$displayHour:$mm ${isMorning ? 'صباحًا' : 'مساءً'}';
  }

  @override
  bool operator ==(Object other) =>
      other is ReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'ReminderTime($hour:$minute)';
}

/// كل إعدادات المستخدم. غير قابلة للتعديل — استخدم [copyWith].
@immutable
class AppSettings {
  const AppSettings({
    this.themePreference = AppThemePreference.system,
    this.textScalePreset = TextScalePreset.medium,
    this.seniorMode = false,
    this.highContrast = false,
    this.reduceMotion = false,
    this.saveReadingProgress = true,
    this.showSource = true,
    this.autoNext = false,
    this.keepScreenAwake = false,
    this.audioEnabled = true,
    this.speechRate = 0.9,
    this.repeatPauseMode = RepeatPauseMode.manual,
    this.continueSessionAudio = false,
    this.preferredVoiceId,
    this.completionHaptics = true,
    this.tapHaptics = false,
    this.tasbihHaptics = false,
    this.morningReminderEnabled = false,
    this.morningReminderTime = const ReminderTime(6, 30),
    this.eveningReminderEnabled = false,
    this.eveningReminderTime = const ReminderTime(17, 0),
    this.customReminderEnabled = false,
    this.customReminderTime = const ReminderTime(21, 0),
  });

  /// القيم الافتراضية المعتمدة في المواصفات (§52).
  static const AppSettings defaults = AppSettings();

  // المظهر
  final AppThemePreference themePreference;
  final TextScalePreset textScalePreset;
  final bool seniorMode;
  final bool highContrast;
  final bool reduceMotion;

  // القراءة
  final bool saveReadingProgress;
  final bool showSource;
  final bool autoNext;
  final bool keepScreenAwake;

  // الصوت
  final bool audioEnabled;
  final double speechRate;
  final RepeatPauseMode repeatPauseMode;
  final bool continueSessionAudio;
  final String? preferredVoiceId;

  // الاهتزاز
  final bool completionHaptics;
  final bool tapHaptics;
  final bool tasbihHaptics;

  // التذكيرات
  final bool morningReminderEnabled;
  final ReminderTime morningReminderTime;
  final bool eveningReminderEnabled;
  final ReminderTime eveningReminderTime;
  final bool customReminderEnabled;
  final ReminderTime customReminderTime;

  /// معامل حجم النص الفعلي بعد أخذ وضع كبار السن في الحسبان.
  double get effectiveTextScale =>
      textScalePreset.factor * (seniorMode ? 1.25 : 1.0);

  /// هل يوجد أي تذكير مفعَّل؟ يُستخدم لتفادي عمل لا لزوم له عند كل استئناف.
  bool get hasAnyReminder =>
      morningReminderEnabled || eveningReminderEnabled || customReminderEnabled;

  ThemeMode get materialThemeMode => switch (themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  AppSettings copyWith({
    AppThemePreference? themePreference,
    TextScalePreset? textScalePreset,
    bool? seniorMode,
    bool? highContrast,
    bool? reduceMotion,
    bool? saveReadingProgress,
    bool? showSource,
    bool? autoNext,
    bool? keepScreenAwake,
    bool? audioEnabled,
    double? speechRate,
    RepeatPauseMode? repeatPauseMode,
    bool? continueSessionAudio,
    String? preferredVoiceId,
    bool clearPreferredVoiceId = false,
    bool? completionHaptics,
    bool? tapHaptics,
    bool? tasbihHaptics,
    bool? morningReminderEnabled,
    ReminderTime? morningReminderTime,
    bool? eveningReminderEnabled,
    ReminderTime? eveningReminderTime,
    bool? customReminderEnabled,
    ReminderTime? customReminderTime,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      textScalePreset: textScalePreset ?? this.textScalePreset,
      seniorMode: seniorMode ?? this.seniorMode,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
      saveReadingProgress: saveReadingProgress ?? this.saveReadingProgress,
      showSource: showSource ?? this.showSource,
      autoNext: autoNext ?? this.autoNext,
      keepScreenAwake: keepScreenAwake ?? this.keepScreenAwake,
      audioEnabled: audioEnabled ?? this.audioEnabled,
      speechRate: speechRate ?? this.speechRate,
      repeatPauseMode: repeatPauseMode ?? this.repeatPauseMode,
      continueSessionAudio: continueSessionAudio ?? this.continueSessionAudio,
      preferredVoiceId: clearPreferredVoiceId
          ? null
          : (preferredVoiceId ?? this.preferredVoiceId),
      completionHaptics: completionHaptics ?? this.completionHaptics,
      tapHaptics: tapHaptics ?? this.tapHaptics,
      tasbihHaptics: tasbihHaptics ?? this.tasbihHaptics,
      morningReminderEnabled:
          morningReminderEnabled ?? this.morningReminderEnabled,
      morningReminderTime: morningReminderTime ?? this.morningReminderTime,
      eveningReminderEnabled:
          eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderTime: eveningReminderTime ?? this.eveningReminderTime,
      customReminderEnabled:
          customReminderEnabled ?? this.customReminderEnabled,
      customReminderTime: customReminderTime ?? this.customReminderTime,
    );
  }
}
