import 'package:flutter/foundation.dart';

/// تقدُّم قراءة قسم واحد: أين توقف المستخدم وكم أتمّ.
@immutable
class ReadingProgress {
  const ReadingProgress({
    required this.categoryId,
    required this.dhikrId,
    required this.currentRepeat,
    required this.completedDhikrIds,
    required this.updatedAt,
  });

  factory ReadingProgress.fresh({
    required String categoryId,
    required String dhikrId,
    required DateTime now,
  }) {
    return ReadingProgress(
      categoryId: categoryId,
      dhikrId: dhikrId,
      currentRepeat: 0,
      completedDhikrIds: const <String>{},
      updatedAt: now,
    );
  }

  /// يقرأ الحالة المخزَّنة. يُعيد `null` بدل الانهيار عند أي تلف في البيانات.
  static ReadingProgress? tryFromJson(Map<String, dynamic> json) {
    final categoryId = json['categoryId'];
    final dhikrId = json['dhikrId'];
    if (categoryId is! String || categoryId.isEmpty) return null;
    if (dhikrId is! String || dhikrId.isEmpty) return null;

    final rawRepeat = json['currentRepeat'];
    final currentRepeat = rawRepeat is num ? rawRepeat.toInt() : 0;

    final rawUpdated = json['updatedAt'];
    final updatedAt = rawUpdated is num
        ? DateTime.fromMillisecondsSinceEpoch(rawUpdated.toInt())
        : null;
    if (updatedAt == null) return null;

    final rawCompleted = json['completedDhikrIds'];
    final completed = <String>{};
    if (rawCompleted is List) {
      for (final id in rawCompleted) {
        if (id is String && id.isNotEmpty) completed.add(id);
      }
    }

    return ReadingProgress(
      categoryId: categoryId,
      dhikrId: dhikrId,
      currentRepeat: currentRepeat < 0 ? 0 : currentRepeat,
      completedDhikrIds: Set<String>.unmodifiable(completed),
      updatedAt: updatedAt,
    );
  }

  final String categoryId;
  final String dhikrId;

  /// عدد المرات التي ضغط فيها المستخدم "تمت القراءة" للذكر الحالي.
  final int currentRepeat;

  /// معرّفات الأذكار المكتملة داخل هذا القسم.
  final Set<String> completedDhikrIds;
  final DateTime updatedAt;

  int get completedCount => completedDhikrIds.length;

  /// هل مرّ وقت طويل بحيث نسأل المستخدم قبل استئناف الورد؟
  bool isStale(DateTime now, Duration threshold) =>
      now.difference(updatedAt) > threshold;

  ReadingProgress copyWith({
    String? dhikrId,
    int? currentRepeat,
    Set<String>? completedDhikrIds,
    DateTime? updatedAt,
  }) {
    return ReadingProgress(
      categoryId: categoryId,
      dhikrId: dhikrId ?? this.dhikrId,
      currentRepeat: currentRepeat ?? this.currentRepeat,
      completedDhikrIds: completedDhikrIds ?? this.completedDhikrIds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'categoryId': categoryId,
    'dhikrId': dhikrId,
    'currentRepeat': currentRepeat,
    'completedDhikrIds': completedDhikrIds.toList(growable: false),
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  @override
  bool operator ==(Object other) =>
      other is ReadingProgress &&
      other.categoryId == categoryId &&
      other.dhikrId == dhikrId &&
      other.currentRepeat == currentRepeat &&
      other.updatedAt == updatedAt &&
      setEquals(other.completedDhikrIds, completedDhikrIds);

  @override
  int get hashCode =>
      Object.hash(categoryId, dhikrId, currentRepeat, updatedAt);
}

/// يوم واحد في سجلّ المداومة: أي الأقسام أُكملت فيه.
@immutable
class DailyCompletion {
  const DailyCompletion({required this.day, required this.categoryIds});

  /// مفتاح اليوم بصيغة `yyyy-mm-dd` بالتوقيت المحلي.
  static String dayKey(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  final String day;
  final Set<String> categoryIds;

  bool get isEmpty => categoryIds.isEmpty;

  @override
  bool operator ==(Object other) =>
      other is DailyCompletion &&
      other.day == day &&
      setEquals(other.categoryIds, categoryIds);

  @override
  int get hashCode => Object.hash(day, categoryIds.length);
}
