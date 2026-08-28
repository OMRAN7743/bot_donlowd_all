import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/widgets/category_icons.dart';
import '../../../data/models/dhikr_category.dart';

/// بطاقة قسم كبيرة — تُستخدم لأذكار الصباح والمساء في "وردك اليوم".
class PrimaryCategoryCard extends StatelessWidget {
  const PrimaryCategoryCard({
    super.key,
    required this.category,
    required this.count,
    required this.completedToday,
    required this.onTap,
  });

  final DhikrCategory category;
  final int count;
  final bool completedToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Semantics(
      button: true,
      label: <String>[
        category.name,
        if (count > 0) '$count ذكرًا',
        if (completedToday) 'اكتمل اليوم',
      ].join('، '),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: EdgeInsets.all(tokens.seniorMode ? 20 : 18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        categoryIcon(category.iconKey),
                        color: theme.colorScheme.primary,
                        size: tokens.seniorMode ? 30 : 26,
                      ),
                    ),
                    const Spacer(),
                    if (completedToday) _CompletedBadge(color: tokens.success),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  category.name,
                  style: theme.textTheme.titleSmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (category.subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(
                    category.subtitle!,
                    style: theme.textTheme.labelSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// شارة الإكمال: أيقونة ونص معًا — لا نعتمد على اللون وحده للدلالة.
class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.check_circle_rounded, size: 18, color: color),
        const SizedBox(width: 4),
        Text(
          'اكتمل',
          style: theme.textTheme.labelSmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

/// صف قسم عادي في قائمة الأقسام.
class CategoryListTile extends StatelessWidget {
  const CategoryListTile({
    super.key,
    required this.category,
    required this.count,
    required this.completedToday,
    required this.onTap,
  });

  final DhikrCategory category;
  final int count;
  final bool completedToday;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Semantics(
      button: true,
      label: <String>[
        category.name,
        if (count > 0) '$count ذكرًا',
        if (completedToday) 'اكتمل اليوم',
      ].join('، '),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: BoxConstraints(minHeight: tokens.seniorMode ? 76 : 64),
            padding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: tokens.seniorMode ? 14 : 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  categoryIcon(category.iconKey),
                  color: theme.colorScheme.primary,
                  size: tokens.seniorMode ? 28 : 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        category.name,
                        style: theme.textTheme.titleSmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (count > 0)
                        Text('$count ذكرًا', style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                if (completedToday)
                  Icon(
                    Icons.check_circle_rounded,
                    size: 20,
                    color: tokens.success,
                  ),
                const SizedBox(width: 6),
                Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
