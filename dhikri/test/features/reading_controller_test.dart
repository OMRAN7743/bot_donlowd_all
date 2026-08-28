import 'package:dhikri/app/bootstrap.dart';
import 'package:dhikri/app/providers.dart';
import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/data/datasources/bundled_adhkar_source.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/data/repositories/progress_repository.dart';
import 'package:dhikri/features/adhkar/progress_controller.dart';
import 'package:dhikri/features/adhkar/reading_controller.dart';
import 'package:dhikri/features/adhkar/reading_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/test_data.dart';

ProviderContainer makeContainer({
  KeyValueStore? store,
  AppSettings settings = AppSettings.defaults,
}) {
  final container = ProviderContainer(
    overrides: [
      bootstrapProvider.overrideWithValue(
        TestData.bootstrap(store: store, settings: settings),
      ),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('ReadingController', () {
    test('يبدأ من أول ذكر بعدّاد صفر', () {
      final container = makeContainer();
      final state = container.read(readingControllerProvider('morning'));

      expect(state.index, 0);
      expect(state.currentRepeat, 0);
      expect(state.total, 2);
      expect(state.category.name, 'قسم الاختبار الأول');
    });

    test('registerRepeat يعدّ ويحفظ التقدُّم', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      final controller = container.read(
        readingControllerProvider('morning').notifier,
      );

      expect(await controller.registerRepeat(), RepeatOutcome.counted);
      expect(
        container.read(readingControllerProvider('morning')).currentRepeat,
        1,
      );

      final saved = await ProgressRepository(store)
          .loadCategoryProgress('morning');
      expect(saved?.dhikrId, 'test_001');
      expect(saved?.currentRepeat, 1);
    });

    test('إكمال ذكر يسجّله ضمن المكتملات', () async {
      final container = makeContainer();
      final controller = container.read(
        readingControllerProvider('morning').notifier,
      );

      await controller.registerRepeat();
      await controller.registerRepeat();
      expect(await controller.registerRepeat(), RepeatOutcome.dhikrCompleted);

      final state = container.read(readingControllerProvider('morning'));
      expect(state.isCurrentComplete, isTrue);
      expect(state.completedCount, 1);
    });

    test('إكمال كل الأذكار يسجّل إكمال الورد اليومي', () async {
      final container = makeContainer();
      final controller = container.read(
        readingControllerProvider('morning').notifier,
      );

      // الذكر الأول: 3 مرات.
      for (var i = 0; i < 3; i++) {
        await controller.registerRepeat();
      }
      await controller.goToNext();
      // الذكر الثاني: مرة واحدة.
      expect(await controller.registerRepeat(), RepeatOutcome.sessionCompleted);

      final completed = container
          .read(progressProvider)
          .completedOn(DateTime.now());
      expect(completed, contains('morning'));
    });

    test('يستأنف من الحالة المحفوظة بعد إعادة التشغيل', () async {
      final store = InMemoryKeyValueStore();

      // الجلسة الأولى.
      final first = makeContainer(store: store);
      final controller = first.read(
        readingControllerProvider('morning').notifier,
      );
      for (var i = 0; i < 3; i++) {
        await controller.registerRepeat();
      }
      await controller.goToNext();

      // جلسة جديدة فوق نفس التخزين (محاكاة إعادة فتح التطبيق).
      final bootstrap = await AppBootstrap.load(
        store: store,
        source: BundledAdhkarSource(TestData.bundle()),
      );
      final second = ProviderContainer(
        overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
      );
      addTearDown(second.dispose);

      final restored = second.read(readingControllerProvider('morning'));
      expect(restored.index, 1);
      expect(restored.completedIds, contains('test_001'));
    });

    test('لا يُحفظ التقدُّم عندما يطفئ المستخدم الميزة', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(
        store: store,
        settings: const AppSettings(saveReadingProgress: false),
      );

      await container
          .read(readingControllerProvider('morning').notifier)
          .registerRepeat();

      expect(
        await ProgressRepository(store).loadCategoryProgress('morning'),
        isNull,
      );
    });

    test('restart يمسح تقدُّم القسم', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      final controller = container.read(
        readingControllerProvider('morning').notifier,
      );

      await controller.registerRepeat();
      await controller.restart();

      final state = container.read(readingControllerProvider('morning'));
      expect(state.index, 0);
      expect(state.currentRepeat, 0);
      expect(state.completedIds, isEmpty);
      expect(
        await ProgressRepository(store).loadCategoryProgress('morning'),
        isNull,
      );
    });

    test('قسم غير موجود يعطي حالة فارغة بلا انهيار', () {
      final container = makeContainer();
      final state = container.read(readingControllerProvider('ghost'));

      expect(state.isEmpty, isTrue);
      expect(state.category.name, 'قسم غير متوفر');
    });
  });

  group('FavoritesController', () {
    test('toggle يضيف ويحذف ويُبقي التخزين متسقًا', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);
      final favorites = container.read(favoritesProvider.notifier);

      await favorites.toggle('test_001');
      expect(container.read(favoritesProvider), <String>{'test_001'});
      expect(await store.getStringList(PrefKeys.favoriteIds), <String>[
        'test_001',
      ]);

      await favorites.toggle('test_001');
      expect(container.read(favoritesProvider), isEmpty);
    });

    test('clearAll يفرغ المفضلة', () async {
      final container = makeContainer();
      final favorites = container.read(favoritesProvider.notifier);

      await favorites.toggle('a');
      await favorites.toggle('b');
      await favorites.clearAll();

      expect(container.read(favoritesProvider), isEmpty);
    });
  });

  group('SettingsController', () {
    test('التعديل يُحفظ فورًا في التخزين', () async {
      final store = InMemoryKeyValueStore();
      final container = makeContainer(store: store);

      await container.read(settingsProvider.notifier).setSeniorMode(true);
      await container.read(settingsProvider.notifier).setAutoNext(true);

      expect(container.read(settingsProvider).seniorMode, isTrue);
      expect(await store.getBool(PrefKeys.seniorMode), isTrue);
      expect(await store.getBool(PrefKeys.autoNext), isTrue);
    });

    test('سرعة القراءة تُقرَّب إلى أقرب قيمة مدعومة', () async {
      final container = makeContainer();
      await container.read(settingsProvider.notifier).setSpeechRate(0.93);

      expect(container.read(settingsProvider).speechRate, 0.9);
    });

    test('resetToDefaults يعيد كل شيء للافتراضي', () async {
      final container = makeContainer();
      final controller = container.read(settingsProvider.notifier);

      await controller.setSeniorMode(true);
      await controller.setCompletionHaptics(false);
      await controller.resetToDefaults();

      final settings = container.read(settingsProvider);
      expect(settings.seniorMode, isFalse);
      expect(settings.completionHaptics, isTrue);
    });
  });
}
