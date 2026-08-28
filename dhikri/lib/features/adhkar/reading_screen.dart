import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/empty_state.dart';
import 'narration_controller.dart';
import 'reading_session.dart';
import 'reading_controller.dart';
import 'widgets/audio_control.dart';
import 'widgets/dhikr_view.dart';
import 'widgets/repeat_counter.dart';

/// شاشة قراءة الورد — قلب التطبيق (المواصفات §11 و§12).
///
/// ذكر واحد في كل شاشة، بخط كبير، مع عدّاد تكرار واضح وأزرار سابق/تالي ظاهرة.
class ReadingScreen extends ConsumerStatefulWidget {
  const ReadingScreen({
    super.key,
    required this.categoryId,
    this.initialDhikrId,
  });

  /// يفتح الشاشة عند ذكر محدد (من المفضلة أو البحث).
  factory ReadingScreen.forDhikr({required String dhikrId}) =>
      ReadingScreen(categoryId: _pendingCategory, initialDhikrId: dhikrId);

  /// علامة داخلية تعني: استخرج القسم من الذكر نفسه.
  static const String _pendingCategory = '';

  final String categoryId;
  final String? initialDhikrId;

  @override
  ConsumerState<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends ConsumerState<ReadingScreen> {
  Timer? _autoNextTimer;
  bool _positioned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _positionAtInitialDhikr(),
    );
  }

  @override
  void dispose() {
    _autoNextTimer?.cancel();
    super.dispose();
  }

  /// يحل القسم الفعلي عندما نأتي من مسار `/dhikr/:id`.
  String? get _resolvedCategoryId {
    if (widget.categoryId.isNotEmpty) return widget.categoryId;
    final id = widget.initialDhikrId;
    if (id == null) return null;
    return ref.read(adhkarRepositoryProvider)?.dhikrById(id)?.categoryId;
  }

  Future<void> _positionAtInitialDhikr() async {
    if (_positioned) return;
    _positioned = true;

    final categoryId = _resolvedCategoryId;
    final dhikrId = widget.initialDhikrId;
    if (categoryId == null || dhikrId == null) return;

    final repository = ref.read(adhkarRepositoryProvider);
    final index = repository?.indexInCategory(categoryId, dhikrId) ?? -1;
    if (index >= 0) {
      await ref
          .read(readingControllerProvider(categoryId).notifier)
          .goToIndex(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryId = _resolvedCategoryId;
    if (categoryId == null) {
      return const _MissingDhikrScreen();
    }

    final session = ref.watch(readingControllerProvider(categoryId));
    final settings = ref.watch(settingsProvider);
    final narration = ref.watch(listenRepeatProvider(categoryId));
    final favorites = ref.watch(favoritesProvider);
    final tokens = DhikriTokens.of(context);
    final reduceMotion = shouldReduceMotion(context, settings);

    final dhikr = session.current;

    return Scaffold(
      appBar: AppBar(
        title: Text(session.category.name),
        actions: <Widget>[
          if (!session.isEmpty)
            IconButton(
              onPressed: () => _showIndexSheet(context, categoryId, session),
              tooltip: 'قائمة أذكار القسم',
              icon: const Icon(Icons.list_rounded),
            ),
        ],
      ),
      body: session.isEmpty || dhikr == null
          ? const EmptyState(
              icon: Icons.menu_book_outlined,
              title: 'لا توجد أذكار في هذا القسم بعد',
              message: 'سيتم إضافة الأذكار بعد اعتماد نصوصها ومراجعة مصادرها.',
            )
          : SafeArea(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      tokens.pagePadding,
                      4,
                      tokens.pagePadding,
                      12,
                    ),
                    child: ProgressHeader(
                      completed: session.completedCount,
                      total: session.total,
                      label: ArabicNumbers.outOf(
                        session.positionLabel,
                        session.total,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        tokens.pagePadding,
                        0,
                        tokens.pagePadding,
                        16,
                      ),
                      child: SoftFadeIn(
                        key: ValueKey<String>(dhikr.id),
                        reduceMotion: reduceMotion,
                        child: DhikrView(
                          dhikr: dhikr,
                          showSource: settings.showSource,
                          isFavorite: favorites.contains(dhikr.id),
                          onToggleFavorite: () => ref
                              .read(favoritesProvider.notifier)
                              .toggle(dhikr.id),
                        ),
                      ),
                    ),
                  ),
                  _BottomControls(
                    categoryId: categoryId,
                    session: session,
                    narration: narration,
                    reduceMotion: reduceMotion,
                    onCount: () => _registerRepeat(categoryId),
                    onNext: () => _goNext(categoryId),
                    onPrevious: () => ref
                        .read(readingControllerProvider(categoryId).notifier)
                        .goToPrevious(),
                  ),
                ],
              ),
            ),
    );
  }

  /// ضغطة "تمت القراءة": عدّ، ثم اهتزاز إكمال واحد، ثم انتقال اختياري.
  Future<void> _registerRepeat(String categoryId) async {
    final settings = ref.read(settingsProvider);
    final haptics = ref.read(hapticsProvider);
    final controller = ref.read(readingControllerProvider(categoryId).notifier);

    final outcome = await controller.registerRepeat();

    // الاهتزاز أثر جانبي: نطلقه ولا ننتظره، حتى لا يؤخّر الانتقال أو يعلّقه
    // على جهاز لا يرد على قناة الاهتزاز.
    switch (outcome) {
      case RepeatOutcome.counted:
        unawaited(haptics.counterTap());
      case RepeatOutcome.dhikrCompleted:
        unawaited(haptics.completion());
        if (settings.autoNext) _scheduleAutoNext(categoryId);
      case RepeatOutcome.sessionCompleted:
        unawaited(haptics.completion());
        if (mounted) context.push(AppRoutes.completion(categoryId));
      case RepeatOutcome.alreadyComplete:
        break;
    }
  }

  void _scheduleAutoNext(String categoryId) {
    _autoNextTimer?.cancel();
    _autoNextTimer = Timer(AppConstants.autoNextDelay, () {
      if (mounted) _goNext(categoryId);
    });
  }

  Future<void> _goNext(String categoryId) async {
    _autoNextTimer?.cancel();
    await ref.read(readingControllerProvider(categoryId).notifier).goToNext();
  }

  /// قائمة مصغّرة لأذكار القسم — بديل ظاهر للتمرير الجانبي.
  Future<void> _showIndexSheet(
    BuildContext context,
    String categoryId,
    ReadingSessionState session,
  ) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.7,
            ),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: session.adhkar.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, index) {
                final item = session.adhkar[index];
                final done = session.completedIds.contains(item.id);
                return ListTile(
                  selected: index == session.index,
                  leading: Text(
                    ArabicNumbers.format(index + 1),
                    style: theme.textTheme.labelMedium,
                  ),
                  title: Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: done
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: DhikriTokens.of(sheetContext).success,
                        )
                      : null,
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    ref
                        .read(readingControllerProvider(categoryId).notifier)
                        .goToIndex(index);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// أزرار الأسفل: العدّاد، الاستماع، والتنقّل.
class _BottomControls extends ConsumerWidget {
  const _BottomControls({
    required this.categoryId,
    required this.session,
    required this.narration,
    required this.reduceMotion,
    required this.onCount,
    required this.onNext,
    required this.onPrevious,
  });

  final String categoryId;
  final ReadingSessionState session;
  final ListenRepeatState narration;
  final bool reduceMotion;
  final VoidCallback onCount;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(listenRepeatProvider(categoryId).notifier);

    return Container(
      padding: EdgeInsets.fromLTRB(
        tokens.pagePadding,
        14,
        tokens.pagePadding,
        14,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          RepeatCounter(
            currentRepeat: session.currentRepeat,
            requiredRepeats: session.requiredRepeats,
            isComplete: session.isCurrentComplete,
            onTap: onCount,
            reduceMotion: reduceMotion,
          ),
          const SizedBox(height: 12),
          AudioControl(
            state: narration,
            audioEnabled: settings.audioEnabled,
            onStart: () => controller.start(
              readState: () => ref.read(readingControllerProvider(categoryId)),
              registerRepeat: () => ref
                  .read(readingControllerProvider(categoryId).notifier)
                  .registerRepeat(),
            ),
            onStop: controller.stop,
            onPauseResume: () =>
                narration.isPaused ? controller.resume() : controller.pause(),
            onConfirmRepeat: controller.confirmRepeatDone,
            onOpenAudioSettings: () => context.push(AppRoutes.audioSettings),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: session.hasPrevious ? onPrevious : null,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                  label: const Text('السابق'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: session.hasNext ? onNext : null,
                  icon: const Icon(Icons.arrow_back_rounded, size: 20),
                  label: const Text('التالي'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MissingDhikrScreen extends StatelessWidget {
  const _MissingDhikrScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الذكر')),
      body: EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لم نجد هذا الذكر',
        message: 'ربما تغيّرت بيانات التطبيق. جرّب العودة إلى الرئيسية.',
        action: FilledButton(
          onPressed: () => context.go(AppRoutes.home),
          child: const Text('العودة للرئيسية'),
        ),
      ),
    );
  }
}
