import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// بطاقة "أكمل من حيث توقفت" — تظهر فقط عند وجود ورد غير مكتمل.
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.categoryName,
    required this.completed,
    required this.total,
    required this.onResume,
    this.onRestart,
  });

  final String categoryName;
  final int completed;
  final int total;
  final VoidCallback onResume;

  /// يظهر عندما تكون الجلسة قديمة فنسأل: نتابع أم نبدأ من جديد؟
  final VoidCallback? onRestart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final safeTotal = total <= 0 ? 1 : total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.play_circle_outline_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  onRestart == null
                      ? 'أكمل من حيث توقفت'
                      : 'هل تريد متابعة وردك السابق؟',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$categoryName — $completed من $total',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          if (onRestart == null)
            FilledButton(
              onPressed: onResume,
              style: FilledButton.styleFrom(
                minimumSize: Size(
                  double.infinity,
                  tokens.primaryButtonHeight - 6,
                ),
              ),
              child: const Text('متابعة'),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                FilledButton(onPressed: onResume, child: const Text('متابعة')),
                OutlinedButton(
                  onPressed: onRestart,
                  child: const Text('البدء من جديد'),
                ),
              ],
            ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (completed / safeTotal).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: theme.colorScheme.surface,
            ),
          ),
        ],
      ),
    );
  }
}
