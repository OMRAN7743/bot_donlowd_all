import 'package:flutter/foundation.dart';

import '../../data/models/dhikr.dart';
import '../../data/models/dhikr_category.dart';

/// ماذا حدث نتيجة ضغطة "تمت القراءة".
enum RepeatOutcome {
  /// زاد العدّاد ولم يكتمل الذكر بعد.
  counted,

  /// اكتمل الذكر الحالي، وبقي أذكار أخرى في القسم.
  dhikrCompleted,

  /// اكتمل الذكر الأخير، فاكتمل الورد كله.
  sessionCompleted,

  /// الذكر مكتمل أصلًا — لا نتجاوز العدد المطلوب.
  alreadyComplete,
}

/// حالة قراءة قسم واحد.
@immutable
class ReadingSessionState {
  const ReadingSessionState({
    required this.category,
    required this.adhkar,
    required this.index,
    required this.currentRepeat,
    required this.completedIds,
  });

  final DhikrCategory category;
  final List<Dhikr> adhkar;

  /// موضع الذكر الحالي داخل القسم.
  final int index;

  /// عدد مرات القراءة المسجَّلة للذكر الحالي.
  final int currentRepeat;

  final Set<String> completedIds;

  bool get isEmpty => adhkar.isEmpty;

  Dhikr? get current =>
      (index >= 0 && index < adhkar.length) ? adhkar[index] : null;

  int get total => adhkar.length;

  /// عدد الأذكار المكتملة في هذا القسم.
  int get completedCount =>
      adhkar.where((d) => completedIds.contains(d.id)).length;

  /// الرقم المعروض في "٥ من ٢٠" (موضع الذكر الحالي، يبدأ من 1).
  int get positionLabel => isEmpty ? 0 : index + 1;

  int get requiredRepeats => current?.repeatCount ?? 0;

  bool get isCurrentComplete =>
      current != null && completedIds.contains(current!.id);

  bool get hasNext => index < adhkar.length - 1;

  bool get hasPrevious => index > 0;

  /// اكتمل الورد كله.
  bool get isSessionComplete =>
      adhkar.isNotEmpty && completedCount == adhkar.length;

  ReadingSessionState copyWith({
    int? index,
    int? currentRepeat,
    Set<String>? completedIds,
  }) {
    return ReadingSessionState(
      category: category,
      adhkar: adhkar,
      index: index ?? this.index,
      currentRepeat: currentRepeat ?? this.currentRepeat,
      completedIds: completedIds ?? this.completedIds,
    );
  }
}

/// منطق العدّ والتنقل داخل الورد — خالص وقابل للاختبار بلا واجهة.
abstract final class ReadingSessionLogic {
  /// ينفّذ ضغطة "تمت القراءة" ويُعيد الحالة الجديدة مع وصف ما حدث.
  static (ReadingSessionState, RepeatOutcome) increment(
    ReadingSessionState state,
  ) {
    final dhikr = state.current;
    if (dhikr == null) return (state, RepeatOutcome.alreadyComplete);

    // لا نسمح بتجاوز العدد المطلوب.
    if (state.completedIds.contains(dhikr.id)) {
      return (state, RepeatOutcome.alreadyComplete);
    }

    final required = dhikr.repeatCount < 1 ? 1 : dhikr.repeatCount;
    final next = state.currentRepeat + 1;

    if (next < required) {
      return (state.copyWith(currentRepeat: next), RepeatOutcome.counted);
    }

    final completed = <String>{...state.completedIds, dhikr.id};
    final updated = state.copyWith(
      currentRepeat: required,
      completedIds: Set<String>.unmodifiable(completed),
    );

    return (
      updated,
      updated.isSessionComplete
          ? RepeatOutcome.sessionCompleted
          : RepeatOutcome.dhikrCompleted,
    );
  }

  /// ينتقل إلى ذكر آخر ويضبط العدّاد وفق حالته المحفوظة.
  static ReadingSessionState moveTo(ReadingSessionState state, int index) {
    if (state.isEmpty) return state;
    final safeIndex = index.clamp(0, state.adhkar.length - 1);
    final target = state.adhkar[safeIndex];
    final alreadyDone = state.completedIds.contains(target.id);

    return state.copyWith(
      index: safeIndex,
      currentRepeat: alreadyDone ? target.repeatCount : 0,
    );
  }

  static ReadingSessionState next(ReadingSessionState state) =>
      state.hasNext ? moveTo(state, state.index + 1) : state;

  static ReadingSessionState previous(ReadingSessionState state) =>
      state.hasPrevious ? moveTo(state, state.index - 1) : state;

  /// أول ذكر غير مكتمل — نقطة الاستئناف الطبيعية.
  static int firstIncompleteIndex(ReadingSessionState state) {
    for (var i = 0; i < state.adhkar.length; i++) {
      if (!state.completedIds.contains(state.adhkar[i].id)) return i;
    }
    return state.adhkar.isEmpty ? 0 : state.adhkar.length - 1;
  }

  /// يبدأ الورد من جديد مع إبقاء نفس القسم.
  static ReadingSessionState restart(ReadingSessionState state) => state
      .copyWith(index: 0, currentRepeat: 0, completedIds: const <String>{});
}
