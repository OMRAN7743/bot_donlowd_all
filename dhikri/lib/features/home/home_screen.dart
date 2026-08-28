import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/bootstrap.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/error_state.dart';
import '../../data/models/dhikr_category.dart';
import '../adhkar/progress_controller.dart';
import '../adhkar/reading_controller.dart';
import 'widgets/category_card.dart';
import 'widgets/continuity_strip.dart';
import 'widgets/resume_card.dart';

/// الصفحة الرئيسية: الوصول للورد بأقل عدد من اللمسات (المواصفات §10).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(contentStateProvider);

    return Scaffold(
      appBar: const _HomeAppBar(),
      body: switch (content) {
        ContentFailed(:final error) => ErrorStateView(error: error),
        ContentReady(:final repository) =>
          repository.isEmpty
              ? const _NoContentYet()
              : _HomeBody(categories: repository.categories),
      },
    );
  }
}

class _HomeAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const _HomeAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppBar(
      centerTitle: false,
      title: const Text(AppConstants.appNameArabic),
      actions: <Widget>[
        IconButton(
          onPressed: () => context.push(AppRoutes.search),
          icon: const Icon(Icons.search_rounded),
          tooltip: 'البحث في الأذكار',
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}

class _HomeBody extends ConsumerWidget {
  const _HomeBody({required this.categories});

  final List<DhikrCategory> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final repository = ref.watch(adhkarRepositoryProvider)!;
    final progress = ref.watch(progressProvider);
    final settings = ref.watch(settingsProvider);
    final now = DateTime.now();
    final completedToday = progress.completedOn(now);

    final primary = repository.primaryCategories;
    final secondary = repository.secondaryCategories;
    final resume = _resumeInfo(ref, now);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        tokens.pagePadding,
        8,
        tokens.pagePadding,
        28,
      ),
      children: <Widget>[
        Text(_greeting(now), style: theme.textTheme.bodySmall),
        const SizedBox(height: 4),
        Text('وردك اليوم', style: theme.textTheme.headlineSmall),
        SizedBox(height: tokens.sectionGap - 6),

        if (primary.isNotEmpty)
          LayoutBuilder(
            builder: (context, constraints) {
              // في الشاشات الضيقة جدًا أو مع تكبير خط كبير نضع البطاقات عموديًا.
              final stacked =
                  constraints.maxWidth < 340 ||
                  MediaQuery.textScalerOf(context).scale(16) > 24;
              final cards = <Widget>[
                for (final category in primary)
                  PrimaryCategoryCard(
                    category: category,
                    count: repository.countInCategory(category.id),
                    completedToday: completedToday.contains(category.id),
                    onTap: () => context.push(AppRoutes.category(category.id)),
                  ),
              ];
              if (stacked) {
                return Column(
                  children: <Widget>[
                    for (var i = 0; i < cards.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(height: 12),
                      cards[i],
                    ],
                  ],
                );
              }
              // IntrinsicHeight يمنح البطاقتين ارتفاعًا موحّدًا داخل قائمة
              // غير محدودة الارتفاع، حيث لا يصلح CrossAxisAlignment.stretch.
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    for (var i = 0; i < cards.length; i++) ...<Widget>[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: cards[i]),
                    ],
                  ],
                ),
              );
            },
          ),

        if (resume != null) ...<Widget>[
          SizedBox(height: tokens.sectionGap),
          ResumeCard(
            categoryName: resume.categoryName,
            completed: resume.completed,
            total: resume.total,
            onResume: () => context.push(AppRoutes.category(resume.categoryId)),
            onRestart: resume.isStale
                ? () async {
                    await ref
                        .read(
                          readingControllerProvider(resume.categoryId).notifier,
                        )
                        .restart();
                    if (context.mounted) {
                      context.push(AppRoutes.category(resume.categoryId));
                    }
                  }
                : null,
          ),
        ],

        SizedBox(height: tokens.sectionGap),
        SectionHeader(
          title: 'اليوم',
          trailing: Text(
            '${completedToday.length} من ${primary.isEmpty ? categories.length : primary.length}',
            style: theme.textTheme.labelSmall,
          ),
        ),
        _TodayStatus(primary: primary, completedToday: completedToday),

        SizedBox(height: tokens.sectionGap),
        const SectionHeader(title: 'المداومة'),
        ContinuityStrip(days: progress.recentDays(now), today: now),

        SizedBox(height: tokens.sectionGap),
        const SectionHeader(title: 'كل الأقسام'),
        for (final category in secondary) ...<Widget>[
          CategoryListTile(
            category: category,
            count: repository.countInCategory(category.id),
            completedToday: completedToday.contains(category.id),
            onTap: () => context.push(AppRoutes.category(category.id)),
          ),
          const SizedBox(height: 10),
        ],

        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => context.push(AppRoutes.search),
          icon: const Icon(Icons.manage_search_rounded),
          label: Text('جميع الأذكار (${repository.allAdhkar.length})'),
        ),

        if (settings.seniorMode) ...<Widget>[
          const SizedBox(height: 18),
          SeniorModeBanner(
            onDisable: () =>
                ref.read(settingsProvider.notifier).setSeniorMode(false),
          ),
        ],
      ],
    );
  }

  /// تحية بسيطة حسب الوقت — بلا أي معلومة شخصية.
  static String _greeting(DateTime now) {
    if (now.hour < 12) return 'صباح الخير';
    if (now.hour < 17) return 'طاب يومك';
    return 'مساء الخير';
  }

  _ResumeInfo? _resumeInfo(WidgetRef ref, DateTime now) {
    final settings = ref.read(settingsProvider);
    if (!settings.saveReadingProgress) return null;

    final last = ref.watch(progressProvider).lastSession;
    if (last == null) return null;

    final repository = ref.read(adhkarRepositoryProvider);
    final category = repository?.categoryById(last.categoryId);
    if (repository == null || category == null) return null;

    final total = repository.countInCategory(last.categoryId);
    final completed = last.completedDhikrIds.length;
    if (total == 0 || completed >= total) return null;

    return _ResumeInfo(
      categoryId: last.categoryId,
      categoryName: category.name,
      completed: completed,
      total: total,
      isStale: last.isStale(now, AppConstants.staleSessionThreshold),
    );
  }
}

class _ResumeInfo {
  const _ResumeInfo({
    required this.categoryId,
    required this.categoryName,
    required this.completed,
    required this.total,
    required this.isStale,
  });

  final String categoryId;
  final String categoryName;
  final int completed;
  final int total;
  final bool isStale;
}

/// حالة اليوم: أُكملت أذكار الصباح/المساء أم لا — بلا لوم.
class _TodayStatus extends StatelessWidget {
  const _TodayStatus({required this.primary, required this.completedToday});

  final List<DhikrCategory> primary;
  final Set<String> completedToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: <Widget>[
          for (var i = 0; i < primary.length; i++) ...<Widget>[
            if (i > 0) const Divider(height: 18),
            Row(
              children: <Widget>[
                Icon(
                  completedToday.contains(primary[i].id)
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: completedToday.contains(primary[i].id)
                      ? tokens.success
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    completedToday.contains(primary[i].id)
                        ? 'أكملت ${primary[i].name}'
                        : '${primary[i].name} — لم تكتمل بعد',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// تظهر عندما لا تحتوي حزمة التطبيق على أذكار موثقة بعد.
class _NoContentYet extends StatelessWidget {
  const _NoContentYet();

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.library_books_outlined,
      title: 'لا توجد أذكار في هذه النسخة بعد',
      message:
          'سيتم إضافة الأذكار بعد اعتماد نصوصها ومراجعة مصادرها. '
          'كل ما عدا ذلك في التطبيق جاهز للاستخدام.',
    );
  }
}
