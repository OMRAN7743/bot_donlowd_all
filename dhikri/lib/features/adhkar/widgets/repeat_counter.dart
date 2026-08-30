import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/arabic_numbers.dart';

/// منطقة التكرار: العدد المطلوب، والتقدُّم، وزر "تمت القراءة" الكبير.
class RepeatCounter extends StatelessWidget {
  const RepeatCounter({
    super.key,
    required this.currentRepeat,
    required this.requiredRepeats,
    required this.isComplete,
    required this.onTap,
    required this.reduceMotion,
  });

  final int currentRepeat;
  final int requiredRepeats;
  final bool isComplete;
  final VoidCallback onTap;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final ratio = requiredRepeats <= 0
        ? 0.0
        : (currentRepeat / requiredRepeats).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(
              Icons.repeat_rounded,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'التكرار: ${ArabicNumbers.timesLabel(requiredRepeats)}',
                style: theme.textTheme.labelMedium,
              ),
            ),
            Text(
              ArabicNumbers.outOf(currentRepeat, requiredRepeats),
              style: theme.textTheme.titleSmall?.copyWith(
                color: isComplete ? tokens.success : theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 10,
            backgroundColor: theme.colorScheme.outlineVariant,
            valueColor: AlwaysStoppedAnimation<Color>(
              isComplete ? tokens.success : theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _CountButton(
          isComplete: isComplete,
          onTap: onTap,
          reduceMotion: reduceMotion,
        ),
      ],
    );
  }
}

/// الزر الرئيسي — يتحوّل إلى علامة إكمال واضحة عند بلوغ العدد.
class _CountButton extends StatelessWidget {
  const _CountButton({
    required this.isComplete,
    required this.onTap,
    required this.reduceMotion,
  });

  final bool isComplete;
  final VoidCallback onTap;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    final child = isComplete
        ? Row(
            key: const ValueKey<String>('complete'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(Icons.check_circle_rounded, color: tokens.success, size: 28),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'تم هذا الذكر',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: tokens.success,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          )
        : Row(
            key: const ValueKey<String>('count'),
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.touch_app_rounded,
                color: theme.colorScheme.onPrimary,
                size: 26,
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'تمت القراءة',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: !isComplete,
      label: isComplete ? 'اكتمل هذا الذكر' : 'تمت القراءة، اضغط للعدّ',
      excludeSemantics: true,
      child: Material(
        color: isComplete
            ? tokens.success.withValues(alpha: 0.12)
            : theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: isComplete ? null : onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            constraints: BoxConstraints(
              minHeight: tokens.primaryButtonHeight + 8,
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: isComplete
                  ? Border.all(color: tokens.success, width: 1.5)
                  : null,
            ),
            child: reduceMotion
                ? child
                : AnimatedSwitcher(
                    duration: AppConstants.completionMotion,
                    child: child,
                  ),
          ),
        ),
      ),
    );
  }
}
