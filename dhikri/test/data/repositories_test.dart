import 'package:dhikri/core/services/preferences_service.dart';
import 'package:dhikri/data/models/app_settings.dart';
import 'package:dhikri/data/models/reading_progress.dart';
import 'package:dhikri/data/repositories/favorites_repository.dart';
import 'package:dhikri/data/repositories/progress_repository.dart';
import 'package:dhikri/data/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsRepository', () {
    test('يعيد القيم الافتراضية المعتمدة عندما يكون التخزين فارغًا', () async {
      final settings = await SettingsRepository(InMemoryKeyValueStore()).load();

      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.textScalePreset, TextScalePreset.medium);
      expect(settings.seniorMode, isFalse);
      expect(settings.highContrast, isFalse);
      expect(settings.reduceMotion, isFalse);
      expect(settings.saveReadingProgress, isTrue);
      expect(settings.showSource, isTrue);
      expect(settings.autoNext, isFalse);
      expect(settings.keepScreenAwake, isFalse);
      expect(settings.audioEnabled, isTrue);
      expect(settings.speechRate, 0.9);
      expect(settings.repeatPauseMode, RepeatPauseMode.manual);
      expect(settings.completionHaptics, isTrue);
      expect(settings.tapHaptics, isFalse);
      expect(settings.tasbihHaptics, isFalse);
      expect(settings.morningReminderEnabled, isFalse);
      expect(settings.eveningReminderEnabled, isFalse);
      expect(settings.customReminderEnabled, isFalse);
    });

    test('يحفظ ثم يقرأ نفس الإعدادات', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);

      const saved = AppSettings(
        themePreference: AppThemePreference.dark,
        textScalePreset: TextScalePreset.extraLarge,
        seniorMode: true,
        highContrast: true,
        reduceMotion: true,
        saveReadingProgress: false,
        showSource: false,
        autoNext: true,
        audioEnabled: false,
        speechRate: 1.2,
        repeatPauseMode: RepeatPauseMode.seconds5,
        continueSessionAudio: true,
        preferredVoiceId: 'voice-a|ar-SA',
        completionHaptics: false,
        tapHaptics: true,
        tasbihHaptics: true,
        morningReminderEnabled: true,
        morningReminderTime: ReminderTime(5, 45),
        eveningReminderEnabled: true,
        eveningReminderTime: ReminderTime(18, 15),
      );

      await repo.save(saved);
      final loaded = await repo.load();

      expect(loaded.themePreference, AppThemePreference.dark);
      expect(loaded.textScalePreset, TextScalePreset.extraLarge);
      expect(loaded.seniorMode, isTrue);
      expect(loaded.speechRate, 1.2);
      expect(loaded.repeatPauseMode, RepeatPauseMode.seconds5);
      expect(loaded.preferredVoiceId, 'voice-a|ar-SA');
      expect(loaded.completionHaptics, isFalse);
      expect(loaded.morningReminderTime, const ReminderTime(5, 45));
      expect(loaded.eveningReminderTime, const ReminderTime(18, 15));
    });

    test('يتجاهل القيم التالفة ويعود للافتراضي بلا انهيار', () async {
      final store = InMemoryKeyValueStore(<String, Object>{
        PrefKeys.themePreference: 'neon',
        PrefKeys.textScalePreset: 'gigantic',
        PrefKeys.speechRate: 9.0,
        PrefKeys.repeatPauseMode: 'whenever',
        PrefKeys.morningReminderTime: 5000,
      });

      final settings = await SettingsRepository(store).load();

      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.textScalePreset, TextScalePreset.medium);
      expect(settings.speechRate, 0.9);
      expect(settings.repeatPauseMode, RepeatPauseMode.manual);
      expect(settings.morningReminderTime, const ReminderTime(6, 30));
    });

    test('resetToDefaults يمسح الإعدادات والتذكيرات فقط', () async {
      final store = InMemoryKeyValueStore();
      final repo = SettingsRepository(store);

      await repo.save(
        const AppSettings(seniorMode: true, morningReminderEnabled: true),
      );
      await store.setStringList(PrefKeys.favoriteIds, <String>['keep_me']);
      await repo.resetToDefaults();

      final settings = await repo.load();
      expect(settings.seniorMode, isFalse);
      expect(settings.morningReminderEnabled, isFalse);
      expect(await store.getStringList(PrefKeys.favoriteIds), <String>[
        'keep_me',
      ]);
    });

    test('علامة إنهاء شاشات التعريف تُحفظ', () async {
      final repo = SettingsRepository(InMemoryKeyValueStore());
      expect(await repo.isOnboardingCompleted(), isFalse);
      await repo.setOnboardingCompleted();
      expect(await repo.isOnboardingCompleted(), isTrue);
    });
  });

  group('FavoritesRepository', () {
    test('يبدأ فارغًا', () async {
      expect(
        await FavoritesRepository(InMemoryKeyValueStore()).load(),
        isEmpty,
      );
    });

    test('toggle يضيف ثم يحذف', () async {
      final repo = FavoritesRepository(InMemoryKeyValueStore());

      expect(await repo.toggle('a'), <String>{'a'});
      expect(await repo.toggle('b'), <String>{'a', 'b'});
      expect(await repo.toggle('a'), <String>{'b'});
      expect(await repo.load(), <String>{'b'});
    });

    test('clear يحذف الكل', () async {
      final repo = FavoritesRepository(InMemoryKeyValueStore());
      await repo.save(<String>{'a', 'b'});
      await repo.clear();
      expect(await repo.load(), isEmpty);
    });

    test('يتجاهل المعرّفات الفارغة المخزَّنة', () async {
      final store = InMemoryKeyValueStore(<String, Object>{
        PrefKeys.favoriteIds: <String>['a', '', '  '],
      });
      expect(await FavoritesRepository(store).load(), <String>{'a'});
    });
  });

  group('ProgressRepository', () {
    ReadingProgress sample(DateTime now) => ReadingProgress(
      categoryId: 'morning',
      dhikrId: 'test_002',
      currentRepeat: 2,
      completedDhikrIds: const <String>{'test_001'},
      updatedAt: now,
    );

    test('يحفظ التقدُّم ويستعيده بعد إعادة الفتح', () async {
      final store = InMemoryKeyValueStore();
      final now = DateTime(2026, 8, 28, 7, 30);
      await ProgressRepository(store).saveProgress(sample(now));

      // مستودع جديد فوق نفس التخزين = محاكاة إعادة تشغيل التطبيق.
      final restored = await ProgressRepository(store)
          .loadCategoryProgress('morning');

      expect(restored, isNotNull);
      expect(restored!.dhikrId, 'test_002');
      expect(restored.currentRepeat, 2);
      expect(restored.completedDhikrIds, <String>{'test_001'});
      expect(restored.updatedAt, now);
    });

    test('آخر جلسة تُحفظ أيضًا عبر الأقسام', () async {
      final store = InMemoryKeyValueStore();
      final repo = ProgressRepository(store);
      await repo.saveProgress(sample(DateTime(2026, 8, 28)));

      final last = await repo.loadLastSession();
      expect(last?.categoryId, 'morning');
    });

    test('التخزين التالف لا يسبب انهيارًا', () async {
      final store = InMemoryKeyValueStore(<String, Object>{
        PrefKeys.lastSession: 'not-json-at-all',
        PrefKeys.dailyCompletion: '{{{',
      });
      final repo = ProgressRepository(store);

      expect(await repo.loadLastSession(), isNull);
      expect(await repo.loadCompletionLog(), isEmpty);
    });

    test('clearCategoryProgress يمسح القسم وآخر جلسة إن طابقته', () async {
      final store = InMemoryKeyValueStore();
      final repo = ProgressRepository(store);
      await repo.saveProgress(sample(DateTime(2026, 8, 28)));
      await repo.clearCategoryProgress('morning');

      expect(await repo.loadCategoryProgress('morning'), isNull);
      expect(await repo.loadLastSession(), isNull);
    });

    test('يسجّل الإكمال اليومي ويقرأه', () async {
      final repo = ProgressRepository(InMemoryKeyValueStore());
      final now = DateTime(2026, 8, 28, 6);

      await repo.recordCompletion(categoryId: 'morning', when: now);
      await repo.recordCompletion(categoryId: 'evening', when: now);

      expect(await repo.completedToday(now), <String>{'morning', 'evening'});
    });

    test('recentDays يعيد سبعة أيام بالترتيب الصاعد', () async {
      final repo = ProgressRepository(InMemoryKeyValueStore());
      final now = DateTime(2026, 8, 28);
      await repo.recordCompletion(categoryId: 'morning', when: now);

      final days = await repo.recentDays(now);
      expect(days, hasLength(7));
      expect(days.last.day, DailyCompletion.dayKey(now));
      expect(days.last.categoryIds, contains('morning'));
      expect(days.first.isEmpty, isTrue);
    });

    test('resetAll يمسح التقدُّم وسجلّ المداومة', () async {
      final store = InMemoryKeyValueStore();
      final repo = ProgressRepository(store);
      await repo.saveProgress(sample(DateTime(2026, 8, 28)));
      await repo.recordCompletion(
        categoryId: 'morning',
        when: DateTime(2026, 8, 28),
      );

      await repo.resetAll();

      expect(await repo.loadLastSession(), isNull);
      expect(await repo.loadCompletionLog(), isEmpty);
    });
  });

  group('ReadingProgress', () {
    test('isStale يعتمد على المدة المحددة', () {
      final now = DateTime(2026, 8, 28, 20);
      final fresh = ReadingProgress(
        categoryId: 'morning',
        dhikrId: 'a',
        currentRepeat: 0,
        completedDhikrIds: const <String>{},
        updatedAt: now.subtract(const Duration(hours: 2)),
      );
      final old = fresh.copyWith(
        updatedAt: now.subtract(const Duration(days: 3)),
      );

      expect(fresh.isStale(now, const Duration(hours: 12)), isFalse);
      expect(old.isStale(now, const Duration(hours: 12)), isTrue);
    });

    test('tryFromJson يرفض البيانات الناقصة', () {
      expect(ReadingProgress.tryFromJson(<String, dynamic>{}), isNull);
      expect(
        ReadingProgress.tryFromJson(<String, dynamic>{
          'categoryId': 'morning',
          'dhikrId': 'a',
        }),
        isNull,
      );
    });
  });
}
