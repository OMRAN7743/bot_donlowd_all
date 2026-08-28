import 'package:flutter/foundation.dart';

import '../core/errors/app_exception.dart';
import '../core/services/preferences_service.dart';
import '../data/datasources/bundled_adhkar_source.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/adhkar_repository.dart';
import '../data/models/reading_progress.dart';
import '../data/repositories/favorites_repository.dart';
import '../data/repositories/progress_repository.dart';
import '../data/repositories/settings_repository.dart';

/// نتيجة تحميل محتوى الأذكار عند الإقلاع.
sealed class ContentState {
  const ContentState();
}

/// المحتوى جاهز (وقد يكون فارغًا إذا لم تُستورد بيانات موثقة بعد).
class ContentReady extends ContentState {
  const ContentReady(this.repository);

  final AdhkarRepository repository;
}

/// فشل تحميل المحتوى — نعرض شاشة خطأ بدل الانهيار.
class ContentFailed extends ContentState {
  const ContentFailed(this.error);

  final AppException error;
}

/// كل ما يحتاجه التطبيق ليعرض أول إطار بلا انتظار.
@immutable
class AppBootstrap {
  const AppBootstrap({
    required this.store,
    required this.settings,
    required this.content,
    required this.favorites,
    required this.onboardingCompleted,
    required this.categoryProgress,
    required this.lastSession,
    required this.completionLog,
  });

  final KeyValueStore store;
  final AppSettings settings;
  final ContentState content;
  final Set<String> favorites;
  final bool onboardingCompleted;

  /// تقدُّم القراءة لكل قسم، محمَّل مسبقًا حتى تبقى شاشة الورد متزامنة بلا انتظار.
  final Map<String, ReadingProgress> categoryProgress;

  /// آخر جلسة قراءة عبر كل الأقسام — لبطاقة "أكمل من حيث توقفت".
  final ReadingProgress? lastSession;

  /// سجلّ المداومة: مفتاح اليوم -> الأقسام المكتملة فيه.
  final Map<String, Set<String>> completionLog;

  /// يقرأ كل شيء من القرص والأصول. لا يرمي أبدًا — يلتقط الفشل في [content].
  static Future<AppBootstrap> load({
    KeyValueStore? store,
    BundledAdhkarSource source = const BundledAdhkarSource(),
  }) async {
    final resolvedStore = store ?? SharedPreferencesStore();
    final settingsRepo = SettingsRepository(resolvedStore);
    final favoritesRepo = FavoritesRepository(resolvedStore);

    final settings = await settingsRepo.load();
    final favorites = await favoritesRepo.load();
    final onboardingCompleted = await settingsRepo.isOnboardingCompleted();

    ContentState content;
    try {
      content = ContentReady(await AdhkarRepository.fromSource(source));
    } on AppException catch (error) {
      if (kDebugMode) debugPrint('Content load failed: $error');
      content = ContentFailed(error);
    } catch (error, stack) {
      if (kDebugMode) debugPrint('Content load crashed: $error\n$stack');
      content = ContentFailed(
        ContentLoadException(
          'تعذّر تحميل الأذكار.',
          debugDetail: error.toString(),
        ),
      );
    }

    final progressRepo = ProgressRepository(resolvedStore);
    final categoryProgress = <String, ReadingProgress>{};
    if (content is ContentReady) {
      for (final category in content.repository.categories) {
        final saved = await progressRepo.loadCategoryProgress(category.id);
        if (saved != null) categoryProgress[category.id] = saved;
      }
    }

    return AppBootstrap(
      store: resolvedStore,
      settings: settings,
      content: content,
      favorites: favorites,
      onboardingCompleted: onboardingCompleted,
      categoryProgress: categoryProgress,
      lastSession: await progressRepo.loadLastSession(),
      completionLog: await progressRepo.loadCompletionLog(),
    );
  }
}
