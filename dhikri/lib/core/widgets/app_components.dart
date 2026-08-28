import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';
import '../constants/app_constants.dart';

/// عنوان قسم داخل صفحة، بمسافة علوية سخيّة.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Semantics(
              header: true,
              child: Text(title, style: theme.textTheme.titleMedium),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// الزر الرئيسي الكبير — "تمت القراءة"، "استمع"، وما شابه.
///
/// يحترم وضع كبار السن بارتفاع أكبر ونص أوضح.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.semanticLabel,
    this.backgroundColor,
    this.foregroundColor,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final String? semanticLabel;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final tokens = DhikriTokens.of(context);

    final button = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(
          expand ? double.infinity : 96,
          tokens.primaryButtonHeight,
        ),
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: tokens.seniorMode ? 28 : 24),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      label: semanticLabel ?? label,
      excludeSemantics: semanticLabel != null,
      child: button,
    );
  }
}

/// شريط التقدُّم أعلى القسم: "٥ من ٢٠".
class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.completed,
    required this.total,
    this.label,
  });

  final int completed;
  final int total;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final safeTotal = total <= 0 ? 1 : total;
    final ratio = (completed / safeTotal).clamp(0.0, 1.0);
    final text = '$completed من $total';

    return Semantics(
      label: label == null ? 'التقدُّم: $text' : '${label!} — التقدُّم: $text',
      value: text,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (label != null)
                Expanded(
                  child: Text(
                    label!,
                    style: theme.textTheme.labelMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              else
                const Spacer(),
              Text(
                text,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// بطاقة المصدر والمرجع تحت نص الذكر — قابلة للطي إذا طالت.
class SourceReferenceTile extends StatefulWidget {
  const SourceReferenceTile({
    super.key,
    required this.sourceLine,
    this.note,
    this.initiallyExpanded = false,
  });

  final String sourceLine;
  final String? note;
  final bool initiallyExpanded;

  @override
  State<SourceReferenceTile> createState() => _SourceReferenceTileState();
}

class _SourceReferenceTileState extends State<SourceReferenceTile> {
  late bool _expanded = widget.initiallyExpanded;

  bool get _isLong =>
      widget.sourceLine.length > 60 || (widget.note?.isNotEmpty ?? false);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showToggle = _isLong;
    final showBody = _expanded || !showToggle;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                Icons.menu_book_rounded,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text('المصدر', style: theme.textTheme.labelMedium),
              ),
              if (showToggle)
                TextButton(
                  onPressed: () => setState(() => _expanded = !_expanded),
                  child: Text(_expanded ? 'إخفاء' : 'إظهار'),
                ),
            ],
          ),
          AnimatedSize(
            duration: AppConstants.shortMotion,
            alignment: Alignment.topCenter,
            child: showBody
                ? Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.sourceLine,
                          style: theme.textTheme.bodySmall,
                        ),
                        if (widget.note != null && widget.note!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              widget.note!,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// لافتة تُذكِّر بأن وضع كبار السن مُفعَّل، مع اختصار لإيقافه.
class SeniorModeBanner extends StatelessWidget {
  const SeniorModeBanner({super.key, required this.onDisable});

  final VoidCallback onDisable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.accessibility_new_rounded,
            color: theme.colorScheme.primary,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'وضع كبار السن مُفعَّل',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          TextButton(onPressed: onDisable, child: const Text('إيقاف')),
        ],
      ),
    );
  }
}

/// حركة ظهور خفيفة تحترم "تقليل الحركة".
class SoftFadeIn extends StatelessWidget {
  const SoftFadeIn({
    super.key,
    required this.child,
    required this.reduceMotion,
    this.duration = AppConstants.mediumMotion,
  });

  final Widget child;
  final bool reduceMotion;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    if (reduceMotion) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOut,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, (1 - value) * 8),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
