import 'package:dhikri/app/providers.dart';
import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/features/tasbih/tasbih_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_data.dart';

ProviderContainer makeContainer(KeyValueStore store) {
  final container = ProviderContainer(
    overrides: [
      bootstrapProvider.overrideWithValue(TestData.bootstrap(store: store)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('عدّاد التسبيح', () {
    test('يبدأ من الصفر بهدف ٣٣', () {
      final container = makeContainer(InMemoryKeyValueStore());
      final state = container.read(tasbihProvider);

      expect(state.count, 0);
      expect(state.target, TasbihTarget.thirtyThree);
      expect(state.phrase, TasbihPhrase.subhanAllah);
    });

    test('الزيادة تعدّ وتحفظ', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store);
      final controller = container.read(tasbihProvider.notifier);

      expect(await controller.increment(), isFalse);
      expect(container.read(tasbihProvider).count, 1);
      expect(await store.getInt(PrefKeys.tasbihCount), 1);
    });

    test('يُبلغ عن بلوغ الهدف مرة واحدة فقط', () async {
      final container = makeContainer(InMemoryKeyValueStore());
      final controller = container.read(tasbihProvider.notifier);
      await controller.setTarget(TasbihTarget.thirtyThree);

      var reachedCount = 0;
      for (var i = 0; i < 40; i++) {
        if (await controller.increment()) reachedCount += 1;
      }

      expect(reachedCount, 1);
      expect(container.read(tasbihProvider).count, 33);
      expect(container.read(tasbihProvider).isTargetReached, isTrue);
    });

    test('لا يتجاوز العدّاد الهدف', () async {
      final container = makeContainer(InMemoryKeyValueStore());
      final controller = container.read(tasbihProvider.notifier);

      for (var i = 0; i < 50; i++) {
        await controller.increment();
      }
      expect(container.read(tasbihProvider).count, 33);
    });

    test('العدّ المفتوح بلا سقف', () async {
      final container = makeContainer(InMemoryKeyValueStore());
      final controller = container.read(tasbihProvider.notifier);
      await controller.setTarget(TasbihTarget.open);

      for (var i = 0; i < 120; i++) {
        expect(await controller.increment(), isFalse);
      }

      final state = container.read(tasbihProvider);
      expect(state.count, 120);
      expect(state.hasTarget, isFalse);
      expect(state.isTargetReached, isFalse);
      expect(state.ratio, 0);
    });

    test('التصفير يعيد العدّ للصفر ويحفظ', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store);
      final controller = container.read(tasbihProvider.notifier);

      await controller.increment();
      await controller.increment();
      await controller.reset();

      expect(container.read(tasbihProvider).count, 0);
      expect(await store.getInt(PrefKeys.tasbihCount), 0);
    });

    test('تغيير الهدف يصفّر العدّاد', () async {
      final container = makeContainer(InMemoryKeyValueStore());
      final controller = container.read(tasbihProvider.notifier);

      await controller.increment();
      await controller.setTarget(TasbihTarget.hundred);

      expect(container.read(tasbihProvider).count, 0);
      expect(container.read(tasbihProvider).target, TasbihTarget.hundred);
    });

    test('اختيار العبارة يُحفظ', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store);

      await container
          .read(tasbihProvider.notifier)
          .setPhrase(TasbihPhrase.tahlil);

      expect(container.read(tasbihProvider).phrase, TasbihPhrase.tahlil);
      expect(
        await store.getInt(PrefKeys.tasbihPhraseIndex),
        TasbihPhrase.tahlil.index,
      );
    });

    test('hydrate يستعيد الحالة المحفوظة', () async {
      final store = InMemoryKeyValueStore(<String, Object>{
        PrefKeys.tasbihCount: 12,
        PrefKeys.tasbihTarget: 100,
        PrefKeys.tasbihPhraseIndex: TasbihPhrase.allahuAkbar.index,
      });
      final container = makeContainer(store);

      await container.read(tasbihProvider.notifier).hydrate();
      final state = container.read(tasbihProvider);

      expect(state.count, 12);
      expect(state.target, TasbihTarget.hundred);
      expect(state.phrase, TasbihPhrase.allahuAkbar);
    });

    test('hydrate يتجاهل القيم التالفة', () async {
      final store = InMemoryKeyValueStore(<String, Object>{
        PrefKeys.tasbihCount: -5,
        PrefKeys.tasbihPhraseIndex: 99,
      });
      final container = makeContainer(store);

      await container.read(tasbihProvider.notifier).hydrate();
      final state = container.read(tasbihProvider);

      expect(state.count, 0);
      expect(state.phrase, TasbihPhrase.subhanAllah);
    });

    test('نسبة التقدُّم محسوبة بشكل صحيح', () async {
      final container = makeContainer(InMemoryKeyValueStore());
      final controller = container.read(tasbihProvider.notifier);
      await controller.setTarget(TasbihTarget.hundred);

      for (var i = 0; i < 25; i++) {
        await controller.increment();
      }
      expect(container.read(tasbihProvider).ratio, closeTo(0.25, 0.001));
    });
  });
}
