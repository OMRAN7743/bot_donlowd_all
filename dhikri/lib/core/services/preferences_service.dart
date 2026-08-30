import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مفاتيح التخزين المحلي، منظَّمة ببادئات واضحة (المواصفات §27).
///
/// لا نخزّن نص الأذكار هنا إطلاقًا — المعرّفات فقط.
abstract final class PrefKeys {
  static const String settingsPrefix = 'dhikri.settings.';
  static const String progressPrefix = 'dhikri.progress.';
  static const String favoritesPrefix = 'dhikri.favorites.';
  static const String remindersPrefix = 'dhikri.reminders.';
  static const String onboardingPrefix = 'dhikri.onboarding.';
  static const String tasbihPrefix = 'dhikri.tasbih.';

  // الإعدادات
  static const String themePreference = '${settingsPrefix}themePreference';
  static const String textScalePreset = '${settingsPrefix}textScalePreset';
  static const String seniorMode = '${settingsPrefix}seniorMode';
  static const String highContrast = '${settingsPrefix}highContrast';
  static const String reduceMotion = '${settingsPrefix}reduceMotion';
  static const String saveReadingProgress =
      '${settingsPrefix}saveReadingProgress';
  static const String showSource = '${settingsPrefix}showSource';
  static const String autoNext = '${settingsPrefix}autoNext';
  static const String keepScreenAwake = '${settingsPrefix}keepScreenAwake';
  static const String audioEnabled = '${settingsPrefix}audioEnabled';
  static const String speechRate = '${settingsPrefix}speechRate';
  static const String repeatPauseMode = '${settingsPrefix}repeatPauseMode';
  static const String continueSessionAudio =
      '${settingsPrefix}continueSessionAudio';
  static const String preferredVoiceId = '${settingsPrefix}preferredVoiceId';
  static const String completionHaptics = '${settingsPrefix}completionHaptics';
  static const String tapHaptics = '${settingsPrefix}tapHaptics';
  static const String tasbihHaptics = '${settingsPrefix}tasbihHaptics';

  // التذكيرات
  static const String morningReminderEnabled =
      '${remindersPrefix}morningEnabled';
  static const String morningReminderTime = '${remindersPrefix}morningTime';
  static const String eveningReminderEnabled =
      '${remindersPrefix}eveningEnabled';
  static const String eveningReminderTime = '${remindersPrefix}eveningTime';
  static const String customReminderEnabled = '${remindersPrefix}customEnabled';
  static const String customReminderTime = '${remindersPrefix}customTime';

  // التقدُّم
  static const String lastSession = '${progressPrefix}lastSession';
  static const String dailyCompletion = '${progressPrefix}dailyCompletion';
  static String categoryProgress(String categoryId) =>
      '$progressPrefix.category.$categoryId';

  // المفضلة
  static const String favoriteIds = '${favoritesPrefix}ids';

  // أول تشغيل
  static const String onboardingCompleted = '${onboardingPrefix}completed';

  // التسبيح
  static const String tasbihCount = '${tasbihPrefix}count';
  static const String tasbihTarget = '${tasbihPrefix}target';
  static const String tasbihPhraseIndex = '${tasbihPrefix}phraseIndex';
}

/// واجهة تخزين مفتاح/قيمة بسيطة.
///
/// وجودها يسمح باختبار كل المستودعات بدون قنوات النظام الأصلية.
abstract interface class KeyValueStore {
  Future<bool?> getBool(String key);
  Future<int?> getInt(String key);
  Future<double?> getDouble(String key);
  Future<String?> getString(String key);
  Future<List<String>?> getStringList(String key);

  Future<void> setBool(String key, bool value);
  Future<void> setInt(String key, int value);
  Future<void> setDouble(String key, double value);
  Future<void> setString(String key, String value);
  Future<void> setStringList(String key, List<String> value);

  Future<void> remove(String key);
  Future<Set<String>> keys();

  /// يحذف كل المفاتيح التي تبدأ بـ[prefix].
  Future<void> removeWithPrefix(String prefix);
}

/// التنفيذ الحقيقي فوق `SharedPreferencesAsync`.
///
/// كل عملية قراءة محميّة: عند تلف التخزين نُعيد `null` فيستخدم النداء
/// القيمة الافتراضية بدل أن ينهار التطبيق (المواصفات §53).
class SharedPreferencesStore implements KeyValueStore {
  SharedPreferencesStore([SharedPreferencesAsync? prefs])
    : _prefs = prefs ?? SharedPreferencesAsync();

  final SharedPreferencesAsync _prefs;

  Future<T?> _read<T>(String key, Future<T?> Function() action) async {
    try {
      return await action();
    } catch (error, stack) {
      _logFailure('read', key, error, stack);
      return null;
    }
  }

  Future<void> _write(String key, Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stack) {
      _logFailure('write', key, error, stack);
    }
  }

  void _logFailure(String op, String key, Object error, StackTrace stack) {
    // التسجيل في وضع التطوير فقط، وبدون أي محتوى مستخدم.
    if (kDebugMode) {
      debugPrint('PreferencesStore $op failed for "$key": $error');
    }
  }

  @override
  Future<bool?> getBool(String key) => _read(key, () => _prefs.getBool(key));

  @override
  Future<int?> getInt(String key) => _read(key, () => _prefs.getInt(key));

  @override
  Future<double?> getDouble(String key) =>
      _read(key, () => _prefs.getDouble(key));

  @override
  Future<String?> getString(String key) =>
      _read(key, () => _prefs.getString(key));

  @override
  Future<List<String>?> getStringList(String key) =>
      _read(key, () => _prefs.getStringList(key));

  @override
  Future<void> setBool(String key, bool value) =>
      _write(key, () => _prefs.setBool(key, value));

  @override
  Future<void> setInt(String key, int value) =>
      _write(key, () => _prefs.setInt(key, value));

  @override
  Future<void> setDouble(String key, double value) =>
      _write(key, () => _prefs.setDouble(key, value));

  @override
  Future<void> setString(String key, String value) =>
      _write(key, () => _prefs.setString(key, value));

  @override
  Future<void> setStringList(String key, List<String> value) =>
      _write(key, () => _prefs.setStringList(key, value));

  @override
  Future<void> remove(String key) => _write(key, () => _prefs.remove(key));

  @override
  Future<Set<String>> keys() async =>
      await _read('<keys>', () => _prefs.getKeys()) ?? <String>{};

  @override
  Future<void> removeWithPrefix(String prefix) async {
    final all = await keys();
    for (final key in all.where((k) => k.startsWith(prefix))) {
      await remove(key);
    }
  }
}

/// تخزين في الذاكرة — للاختبارات ولحالات فشل التهيئة.
class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, Object>? seed])
    : _values = <String, Object>{...?seed};

  final Map<String, Object> _values;

  Map<String, Object> get snapshot => Map<String, Object>.unmodifiable(_values);

  T? _get<T>(String key) {
    final value = _values[key];
    return value is T ? value : null;
  }

  @override
  Future<bool?> getBool(String key) async => _get<bool>(key);

  @override
  Future<int?> getInt(String key) async => _get<int>(key);

  @override
  Future<double?> getDouble(String key) async => _get<double>(key);

  @override
  Future<String?> getString(String key) async => _get<String>(key);

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _values[key];
    return value is List<String> ? List<String>.from(value) : null;
  }

  @override
  Future<void> setBool(String key, bool value) async => _values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => _values[key] = value;

  @override
  Future<void> setDouble(String key, double value) async =>
      _values[key] = value;

  @override
  Future<void> setString(String key, String value) async =>
      _values[key] = value;

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      _values[key] = List<String>.from(value);

  @override
  Future<void> remove(String key) async => _values.remove(key);

  @override
  Future<Set<String>> keys() async => _values.keys.toSet();

  @override
  Future<void> removeWithPrefix(String prefix) async {
    _values.removeWhere((key, _) => key.startsWith(prefix));
  }
}
