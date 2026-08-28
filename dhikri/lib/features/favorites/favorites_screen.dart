import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/arabic_search_normalizer.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/dhikr.dart';

/// صفحة المفضلة: بحث، إزالة، والانتقال إلى الذكر داخل قسمه.
class FavoritesScreen extends ConsumerStatefulWidget {
  const FavoritesScreen({super.key});

  @override
  ConsumerState<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends ConsumerState<FavoritesScreen> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DhikriTokens.of(context);
    final repository = ref.watch(adhkarRepositoryProvider);
    final favoriteIds = ref.watch(favoritesProvider);

    final all = repository?.resolveAll(favoriteIds) ?? const <Dhikr>[];
    final filtered = _filter(all, _query.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('المفضلة'),
        actions: <Widget>[
          if (favoriteIds.isNotEmpty)
            IconButton(
              onPressed: _confirmClear,
              tooltip: 'حذف كل المفضلة',
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: all.isEmpty
          ? const EmptyState(
              icon: Icons.favorite_border_rounded,
              title: 'لا توجد أذكار في المفضلة',
              message: 'اضغط على رمز القلب بجانب أي ذكر لتحفظه هنا.',
            )
          : Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    tokens.pagePadding,
                    8,
                    tokens.pagePadding,
                    10,
                  ),
                  child: TextField(
                    controller: _query,
                    onChanged: (_) => setState(() {}),
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'ابحث في المفضلة',
                      prefixIcon: const Icon(Icons.search_rounded),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      suffixIcon: _query.text.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () => setState(_query.clear),
                              icon: const Icon(Icons.close_rounded),
                              tooltip: 'مسح',
                            ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const EmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'لم نجد ذكرًا مطابقًا',
                          message: 'جرّب كلمة أخرى',
                        )
                      : ListView.separated(
                          padding: EdgeInsets.fromLTRB(
                            tokens.pagePadding,
                            0,
                            tokens.pagePadding,
                            24,
                          ),
                          itemCount: filtered.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final dhikr = filtered[index];
                            return _FavoriteTile(
                              dhikr: dhikr,
                              categoryName:
                                  repository
                                      ?.categoryById(dhikr.categoryId)
                                      ?.name ??
                                  '',
                              onOpen: () =>
                                  context.push(AppRoutes.dhikr(dhikr.id)),
                              onRemove: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(dhikr.id),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  List<Dhikr> _filter(List<Dhikr> source, String query) {
    final tokens = ArabicSearchNormalizer.tokenize(query);
    if (tokens.isEmpty) return source;

    return source
        .where((dhikr) {
          final haystack = ArabicSearchNormalizer.normalize(
            '${dhikr.title} ${dhikr.text} ${dhikr.keywords.join(' ')}',
          );
          return tokens.every(haystack.contains);
        })
        .toList(growable: false);
  }

  Future<void> _confirmClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('حذف المفضلة'),
        content: const Text(
          'سيتم حذف كل الأذكار المحفوظة في المفضلة. هل تريد المتابعة؟',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(favoritesProvider.notifier).clearAll();
    }
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.dhikr,
    required this.categoryName,
    required this.onOpen,
    required this.onRemove,
  });

  final Dhikr dhikr;
  final String categoryName;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      dhikr.title,
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: onRemove,
                    tooltip: 'إزالة من المفضلة',
                    icon: Icon(
                      Icons.favorite_rounded,
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ),
              Text(
                dhikr.text,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (categoryName.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.folder_outlined,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(categoryName, style: theme.textTheme.labelSmall),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
