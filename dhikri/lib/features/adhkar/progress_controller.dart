import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/reading_progress.dart';

/// كل ما يخص تقدُّم القراءة والمداومة، في مكان واحد.
@immutable
class ProgressState {
  const ProgressState({
    required this.byCategory,
    required this.lastSession,
    required this.completionLog,
  });

  final Map<String, ReadingProgress> byCategory;
  final ReadingProgress? lastSession;
  final Map<String, Set<String>> completionLog;

  ReadingProgress? forCategory(String categoryId) => byCategory[categoryId];

  Set<String> completedOn(DateTime day) =>
      completionLog[DailyCompletion.dayKey(day)] ?? const <String>{};

  bool isCompletedToday(String categoryId, DateTime now) =>
      completedOn(now).contains(categoryId);

  /// آخر [days] يومًا بترتيب تصاعدي — لعرض المداومة الأسبوعية.
  List<DailyCompletion> recentDays(DateTime now, {int days = 7}) {
    return List<DailyCompletion>.generate(days, (i) {
      final date = now.subtract(Duration(days: days - 1 - i));
      final key = DailyCompletion.dayKey(date);
      return DailyCompletion(
        day: key,
        categoryIds: completionLog[key] ?? const <String>{},
      );
    });
  }

  ProgressState copyWith({
    Map<String, ReadingProgress>? byCategory,
    ReadingProgress? lastSession,
    bool clearLastSession = false,
    Map<String, Set<String>>? completionLog,
  }) {
    return ProgressState(
      byCategory: byCategory ?? this.byCategory,
      lastSession: clearLastSession ? null : (lastSession ?? this.lastSession),
      completionLog: completionLog ?? this.completionLog,
    );
  }
}

/// يكتب التقدُّم إلى القرص عند كل تغيّر منطقي — لا في كل إطار رسم.
class ProgressController extends Notifier<ProgressState> {
  @override
  ProgressState build() {
    final boot = ref.watch(bootstrapProvider);
    return ProgressState(
      byCategory: Map<String, ReadingProgress>.from(boot.categoryProgress),
      lastSession: boot.lastSession,
      completionLog: Map<String, Set<String>>.from(boot.completionLog),
    );
  }

  /// يحفظ موضع القراءة الحالي. يتجاهل الحفظ إذا أطفأ المستخدم الميزة.
  Future<void> save(ReadingProgress progress) async {
    if (!ref.read(settingsProvider).saveReadingProgress) return;

    state = state.copyWith(
      byCategory: <String, ReadingProgress>{
        ...state.byCategory,
        progress.categoryId: progress,
      },
      lastSession: progress,
    );
    await ref.read(progressRepositoryProvider).saveProgress(progress);
  }

  /// يسجّل إكمال ورد قسم في يوم معيّن.
  Future<void> recordCompletion(String categoryId, DateTime when) async {
    final key = DailyCompletion.dayKey(when);
    final updated = Map<String, Set<String>>.from(state.completionLog);
    updated[key] = <String>{...?updated[key], categoryId};
    state = state.copyWith(completionLog: updated);

    await ref
        .read(progressRepositoryProvider)
        .recordCompletion(categoryId: categoryId, when: when);
  }

  Future<void> clearCategory(String categoryId) async {
    final byCategory = Map<String, ReadingProgress>.from(state.byCategory)
      ..remove(categoryId);
    final dropLast = state.lastSession?.categoryId == categoryId;
    state = state.copyWith(byCategory: byCategory, clearLastSession: dropLast);
    await ref
        .read(progressRepositoryProvider)
        .clearCategoryProgress(categoryId);
  }

  /// يمسح كل تقدُّم القراءة وسجلّ المداومة.
  Future<void> resetAll() async {
    state = const ProgressState(
      byCategory: <String, ReadingProgress>{},
      lastSession: null,
      completionLog: <String, Set<String>>{},
    );
    await ref.read(progressRepositoryProvider).resetAll();
  }
}

final progressProvider = NotifierProvider<ProgressController, ProgressState>(
  ProgressController.new,
);
