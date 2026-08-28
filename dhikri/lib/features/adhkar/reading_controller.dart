import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/models/dhikr_category.dart';
import '../../data/models/reading_progress.dart';
import 'progress_controller.dart';
import 'reading_session.dart';

/// يقود جلسة قراءة قسم واحد: العدّاد، التنقل، والحفظ التلقائي.
class ReadingController extends Notifier<ReadingSessionState> {
  ReadingController(this.categoryId);

  final String categoryId;

  @override
  ReadingSessionState build() {
    final repository = ref.watch(adhkarRepositoryProvider);
    final category = repository?.categoryById(categoryId);
    final adhkar = repository?.adhkarInCategory(categoryId) ?? const [];

    final empty = ReadingSessionState(
      category: category ?? _missingCategory(categoryId),
      adhkar: adhkar,
      index: 0,
      currentRepeat: 0,
      completedIds: const <String>{},
    );

    // نستأنف من الحالة المحفوظة إن وُجدت وكان الحفظ مُفعَّلًا.
    final saved = ref.read(progressProvider).forCategory(categoryId);
    if (saved == null || adhkar.isEmpty) return empty;

    final validIds = adhkar.map((d) => d.id).toSet();
    final completed = saved.completedDhikrIds.where(validIds.contains).toSet();
    final restored = empty.copyWith(
      completedIds: Set<String>.unmodifiable(completed),
    );

    final savedIndex = adhkar.indexWhere((d) => d.id == saved.dhikrId);
    if (savedIndex < 0) {
      return ReadingSessionLogic.moveTo(
        restored,
        ReadingSessionLogic.firstIncompleteIndex(restored),
      );
    }

    final target = adhkar[savedIndex];
    return restored.copyWith(
      index: savedIndex,
      currentRepeat: completed.contains(target.id)
          ? target.repeatCount
          : saved.currentRepeat.clamp(0, target.repeatCount),
    );
  }

  /// ضغطة "تمت القراءة".
  Future<RepeatOutcome> registerRepeat() async {
    final (next, outcome) = ReadingSessionLogic.increment(state);
    if (outcome == RepeatOutcome.alreadyComplete) return outcome;

    state = next;
    await _persist();

    if (outcome == RepeatOutcome.sessionCompleted) {
      await ref
          .read(progressProvider.notifier)
          .recordCompletion(categoryId, DateTime.now());
    }
    return outcome;
  }

  Future<void> goToNext() async {
    if (!state.hasNext) return;
    state = ReadingSessionLogic.next(state);
    await _persist();
  }

  Future<void> goToPrevious() async {
    if (!state.hasPrevious) return;
    state = ReadingSessionLogic.previous(state);
    await _persist();
  }

  Future<void> goToIndex(int index) async {
    state = ReadingSessionLogic.moveTo(state, index);
    await _persist();
  }

  /// يبدأ الورد من أوله ويمسح تقدُّم هذا القسم.
  Future<void> restart() async {
    state = ReadingSessionLogic.restart(state);
    await ref.read(progressProvider.notifier).clearCategory(categoryId);
  }

  /// ينتقل إلى أول ذكر غير مكتمل.
  Future<void> resumeAtFirstIncomplete() async {
    state = ReadingSessionLogic.moveTo(
      state,
      ReadingSessionLogic.firstIncompleteIndex(state),
    );
    await _persist();
  }

  Future<void> _persist() async {
    final current = state.current;
    if (current == null) return;

    await ref
        .read(progressProvider.notifier)
        .save(
          ReadingProgress(
            categoryId: categoryId,
            dhikrId: current.id,
            currentRepeat: state.currentRepeat,
            completedDhikrIds: state.completedIds,
            updatedAt: DateTime.now(),
          ),
        );
  }

  /// قسم غير موجود في ملف البيانات: نعرض حالة فارغة محترمة بدل الانهيار.
  static DhikrCategory _missingCategory(String id) => DhikrCategory(
    id: id,
    name: 'قسم غير متوفر',
    iconKey: 'unknown',
    order: 0,
  );
}

final readingControllerProvider =
    NotifierProvider.family<ReadingController, ReadingSessionState, String>(
      ReadingController.new,
    );
