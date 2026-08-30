import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/repositories/adhkar_repository.dart';

/// بحث عربي محلي سريع (المواصفات §18).
///
/// التطبيع يُستخدم للمطابقة فقط — النص المعروض يبقى كما ورد في المصدر.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focus.requestFocus());
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens = DhikriTokens.of(context);
    final repository = ref.watch(adhkarRepositoryProvider);
    final query = _controller.text.trim();
    final results = query.isEmpty
        ? const <DhikrSearchResult>[]
        : repository?.search(query) ?? const <DhikrSearchResult>[];

    return Scaffold(
      appBar: AppBar(title: const Text('البحث في الأذكار')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.pagePadding,
                8,
                tokens.pagePadding,
                12,
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: (_) => setState(() {}),
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'اكتب كلمة من الذكر أو عنوانه',
                  prefixIcon: const Icon(Icons.search_rounded),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () => setState(_controller.clear),
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'مسح',
                        ),
                ),
              ),
            ),
            Expanded(child: _buildBody(context, query, results, repository)),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    String query,
    List<DhikrSearchResult> results,
    AdhkarRepository? repository,
  ) {
    final tokens = DhikriTokens.of(context);
    final theme = Theme.of(context);

    if (repository == null || repository.isEmpty) {
      return const EmptyState(
        icon: Icons.library_books_outlined,
        title: 'لا توجد أذكار للبحث فيها بعد',
        message: 'سيتم إضافة الأذكار بعد اعتماد نصوصها ومراجعة مصادرها.',
      );
    }

    if (query.isEmpty) {
      return const EmptyState(
        icon: Icons.manage_search_rounded,
        title: 'ابحث في كل الأذكار',
        message: 'يمكنك البحث بعنوان الذكر أو بكلمة من نصه أو باسم القسم.',
      );
    }

    if (results.isEmpty) {
      return const EmptyState(
        icon: Icons.search_off_rounded,
        title: 'لم نجد ذكرًا مطابقًا',
        message: 'جرّب كلمة أخرى',
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(
        tokens.pagePadding,
        0,
        tokens.pagePadding,
        24,
      ),
      itemCount: results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final dhikr = results[index].dhikr;
        final categoryName =
            repository.categoryById(dhikr.categoryId)?.name ?? '';

        return Card(
          child: InkWell(
            onTap: () => context.push(AppRoutes.dhikr(dhikr.id)),
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(dhikr.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 6),
                  Text(
                    dhikr.text,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (categoryName.isNotEmpty) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(categoryName, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
