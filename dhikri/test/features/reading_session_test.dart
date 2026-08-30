import 'package:dhikri/data/models/dhikr.dart';
import 'package:dhikri/data/models/dhikr_category.dart';
import 'package:dhikri/features/adhkar/reading_session.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_data.dart';

ReadingSessionState buildSession({
  int index = 0,
  int currentRepeat = 0,
  Set<String> completed = const <String>{},
  List<Dhikr>? adhkar,
}) {
  final list =
      adhkar ??
      TestData.dhikrModels.where((d) => d.categoryId == 'morning').toList();
  return ReadingSessionState(
    category: const DhikrCategory(
      id: 'morning',
      name: 'قسم الاختبار الأول',
      iconKey: 'sunrise',
      order: 1,
    ),
    adhkar: list,
    index: index,
    currentRepeat: currentRepeat,
    completedIds: completed,
  );
}

void main() {
  group('منطق العدّ', () {
    test('كل ضغطة تزيد العدّاد حتى العدد المطلوب', () {
      var state = buildSession(); // أول ذكر repeatCount = 3
      var outcome = RepeatOutcome.counted;

      (state, outcome) = ReadingSessionLogic.increment(state);
      expect(state.currentRepeat, 1);
      expect(outcome, RepeatOutcome.counted);

      (state, outcome) = ReadingSessionLogic.increment(state);
      expect(state.currentRepeat, 2);
      expect(outcome, RepeatOutcome.counted);

      (state, outcome) = ReadingSessionLogic.increment(state);
      expect(state.currentRepeat, 3);
      expect(outcome, RepeatOutcome.dhikrCompleted);
      expect(state.isCurrentComplete, isTrue);
    });

    test('لا يتجاوز العدّاد العدد المطلوب مهما تكرّر الضغط', () {
      var state = buildSession();
      for (var i = 0; i < 20; i++) {
        (state, _) = ReadingSessionLogic.increment(state);
      }

      expect(state.currentRepeat, 3);
      expect(state.completedIds, <String>{'test_001'});
    });

    test('الضغط بعد الإكمال يُعيد alreadyComplete ولا يغيّر الحالة', () {
      var state = buildSession(
        currentRepeat: 3,
        completed: const <String>{'test_001'},
      );
      final before = state.currentRepeat;

      final RepeatOutcome outcome;
      (state, outcome) = ReadingSessionLogic.increment(state);

      expect(outcome, RepeatOutcome.alreadyComplete);
      expect(state.currentRepeat, before);
    });

    test('إكمال آخر ذكر يُنهي الورد كله', () {
      // ذكر واحد فقط بعدد تكرار 1.
      final single = <Dhikr>[TestData.dhikrModels[1]]; // repeatCount = 1
      var state = buildSession(adhkar: single);

      final RepeatOutcome outcome;
      (state, outcome) = ReadingSessionLogic.increment(state);

      expect(outcome, RepeatOutcome.sessionCompleted);
      expect(state.isSessionComplete, isTrue);
    });

    test('repeatCount غير الصالح يُعامَل كمرة واحدة', () {
      final broken = <Dhikr>[
        Dhikr(
          id: 'broken',
          categoryId: 'morning',
          title: 'عنصر',
          text: 'نص',
          repeatCount: 0,
          order: 1,
          verificationStatus: VerificationStatus.verified,
        ),
      ];
      var state = buildSession(adhkar: broken);

      final RepeatOutcome outcome;
      (state, outcome) = ReadingSessionLogic.increment(state);

      expect(outcome, RepeatOutcome.sessionCompleted);
    });
  });

  group('التنقل', () {
    test('next وprevious يحترمان الحدود', () {
      var state = buildSession();
      expect(state.hasPrevious, isFalse);

      state = ReadingSessionLogic.next(state);
      expect(state.index, 1);
      expect(state.hasNext, isFalse);

      state = ReadingSessionLogic.next(state);
      expect(state.index, 1, reason: 'لا تجاوز لآخر ذكر');

      state = ReadingSessionLogic.previous(state);
      expect(state.index, 0);

      state = ReadingSessionLogic.previous(state);
      expect(state.index, 0, reason: 'لا تجاوز لأول ذكر');
    });

    test('الانتقال إلى ذكر مكتمل يضبط العدّاد على العدد الكامل', () {
      final state = buildSession(completed: const <String>{'test_002'});
      final moved = ReadingSessionLogic.moveTo(state, 1);

      expect(moved.index, 1);
      expect(moved.currentRepeat, moved.current!.repeatCount);
      expect(moved.isCurrentComplete, isTrue);
    });

    test('الانتقال إلى ذكر غير مكتمل يصفّر العدّاد', () {
      final state = buildSession(index: 0, currentRepeat: 2);
      final moved = ReadingSessionLogic.moveTo(state, 1);

      expect(moved.currentRepeat, 0);
    });

    test('moveTo يقصّ الفهرس خارج المدى', () {
      final state = buildSession();
      expect(ReadingSessionLogic.moveTo(state, 99).index, 1);
      expect(ReadingSessionLogic.moveTo(state, -5).index, 0);
    });

    test('firstIncompleteIndex يجد أول ذكر غير مكتمل', () {
      expect(
        ReadingSessionLogic.firstIncompleteIndex(
          buildSession(completed: const <String>{'test_001'}),
        ),
        1,
      );
      expect(ReadingSessionLogic.firstIncompleteIndex(buildSession()), 0);
    });

    test('restart يمسح كل الإكمال ويعود للبداية', () {
      final state = buildSession(
        index: 1,
        currentRepeat: 3,
        completed: const <String>{'test_001', 'test_002'},
      );
      final restarted = ReadingSessionLogic.restart(state);

      expect(restarted.index, 0);
      expect(restarted.currentRepeat, 0);
      expect(restarted.completedIds, isEmpty);
      expect(restarted.isSessionComplete, isFalse);
    });
  });

  group('حسابات العرض', () {
    test('positionLabel يبدأ من واحد', () {
      expect(buildSession(index: 0).positionLabel, 1);
      expect(buildSession(index: 1).positionLabel, 2);
    });

    test('completedCount يحسب أذكار هذا القسم فقط', () {
      final state = buildSession(
        completed: const <String>{
          'test_001',
          'test_003',
        }, // test_003 في قسم آخر
      );
      expect(state.completedCount, 1);
    });

    test('القسم الفارغ لا ينهار', () {
      final empty = buildSession(adhkar: const <Dhikr>[]);

      expect(empty.isEmpty, isTrue);
      expect(empty.current, isNull);
      expect(empty.positionLabel, 0);
      expect(empty.isSessionComplete, isFalse);
      expect(ReadingSessionLogic.next(empty).index, 0);

      final (state, outcome) = ReadingSessionLogic.increment(empty);
      expect(outcome, RepeatOutcome.alreadyComplete);
      expect(state.isEmpty, isTrue);
    });
  });
}
