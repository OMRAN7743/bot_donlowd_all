import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/services/preferences_service.dart';
import '../models/reading_progress.dart';

/// يحفظ موضع القراءة وسجلّ المداومة اليومي محليًا.
///
/// الكتابة تحدث عند تغيّر منطقي (تكرار جديد أو ذكر جديد) — لا في كل إطار رسم.
class ProgressRepository {
  const ProgressRepository(this._store);

  final KeyValueStore _store;

  /// آخر جلسة قراءة عبر كل الأقسام (لبطاقة "أكمل من حيث توقفت").
  Future<ReadingProgress?> loadLastSession() =>
      _readProgress(PrefKeys.lastSession);

  Future<ReadingProgress?> loadCategoryProgress(String categoryId) =>
      _readProgress(PrefKeys.categoryProgress(categoryId));

  /// يحفظ التقدُّم في مكانين: الخاص بالقسم، والأخير عبر التطبيق.
  Future<void> saveProgress(ReadingProgress progress) async {
    final encoded = jsonEncode(progress.toJson());
    await _store.setString(
      PrefKeys.categoryProgress(progress.categoryId),
      encoded,
    );
    await _store.setString(PrefKeys.lastSession, encoded);
  }

  Future<void> clearCategoryProgress(String categoryId) async {
    await _store.remove(PrefKeys.categoryProgress(categoryId));
    final last = await loadLastSession();
    if (last != null && last.categoryId == categoryId) {
      await _store.remove(PrefKeys.lastSession);
    }
  }

  /// يمسح كل تقدُّم القراءة وسجلّ المداومة.
  Future<void> resetAll() => _store.removeWithPrefix(PrefKeys.progressPrefix);

  // ---------------- سجلّ المداومة اليومي ----------------

  /// خريطة: مفتاح اليوم (`yyyy-mm-dd`) -> معرّفات الأقسام المكتملة فيه.
  Future<Map<String, Set<String>>> loadCompletionLog() async {
    final raw = await _store.getString(PrefKeys.dailyCompletion);
    if (raw == null || raw.isEmpty) return <String, Set<String>>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return <String, Set<String>>{};
      final result = <String, Set<String>>{};
      decoded.forEach((key, value) {
        if (key is String && value is List) {
          result[key] = value.whereType<String>().toSet();
        }
      });
      return result;
    } catch (error) {
      if (kDebugMode) {
        debugPrint('Completion log unreadable, resetting: $error');
      }
      return <String, Set<String>>{};
    }
  }

  /// يسجّل إكمال قسم في يوم معيّن، ويحتفظ بآخر 60 يومًا فقط.
  Future<void> recordCompletion({
    required String categoryId,
    required DateTime when,
  }) async {
    final log = await loadCompletionLog();
    final key = DailyCompletion.dayKey(when);
    log.putIfAbsent(key, () => <String>{}).add(categoryId);

    final cutoff = when.subtract(const Duration(days: 60));
    log.removeWhere((day, _) {
      final parsed = DateTime.tryParse(day);
      return parsed != null && parsed.isBefore(cutoff);
    });

    await _store.setString(
      PrefKeys.dailyCompletion,
      jsonEncode(log.map((k, v) => MapEntry(k, v.toList(growable: false)))),
    );
  }

  /// الأقسام المكتملة اليوم.
  Future<Set<String>> completedToday(DateTime now) async {
    final log = await loadCompletionLog();
    return log[DailyCompletion.dayKey(now)] ?? <String>{};
  }

  /// آخر [days] يومًا بترتيب تصاعدي — لعرض "المداومة" الأسبوعية.
  Future<List<DailyCompletion>> recentDays(DateTime now, {int days = 7}) async {
    final log = await loadCompletionLog();
    return List<DailyCompletion>.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final key = DailyCompletion.dayKey(date);
      return DailyCompletion(
        day: key,
        categoryIds: log[key] ?? const <String>{},
      );
    });
  }

  Future<ReadingProgress?> _readProgress(String key) async {
    final raw = await _store.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return ReadingProgress.tryFromJson(decoded);
    } catch (error) {
      // تخزين تالف: نتجاهله بهدوء ونبدأ من جديد بدل الانهيار.
      if (kDebugMode) debugPrint('Progress "$key" unreadable: $error');
      return null;
    }
  }
}
