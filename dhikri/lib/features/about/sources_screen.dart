import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/dhikr.dart';

/// صفحة "مصادر المحتوى" — تعرض المصادر المستخدمة فعليًا فقط.
class SourcesScreen extends ConsumerWidget {
  const SourcesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final repository = ref.watch(adhkarRepositoryProvider);
    final adhkar = repository?.allAdhkar ?? const <Dhikr>[];

    // نجمع المصادر من البيانات نفسها — فلا نعرض مصدرًا لم يُستخدم.
    final sources = <String, int>{};
    for (final dhikr in adhkar) {
      final name = dhikr.sourceName;
      if (name == null || name.isEmpty) continue;
      sources[name] = (sources[name] ?? 0) + 1;
    }
    final sorted = sources.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('مصادر المحتوى')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          16,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          if (sorted.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'لا توجد مصادر لعرضها بعد',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'تظهر هنا مصادر الأذكار المستخدمة فعليًا داخل التطبيق فور '
                    'إضافة نصوص موثقة ومراجَعة.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            )
          else ...<Widget>[
            Text(
              'المصادر المستخدمة في نصوص هذا التطبيق:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            for (final entry in sorted)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(
                      Icons.menu_book_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(entry.key, style: theme.textTheme.titleSmall),
                    ),
                    Text('${entry.value}', style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'يحرص التطبيق على ذكر مصدر كل نص. وإذا لاحظت خطأً في نص أو مرجع، '
              'فتواصل مع المطوّر ليُراجَع.',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
