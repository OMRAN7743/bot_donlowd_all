import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/utils/arabic_numbers.dart';
import 'tasbih_controller.dart';

/// عدّاد التسبيح — واجهة هادئة جدًا ومساحة لمس كبيرة (المواصفات §19).
class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasbihProvider.notifier).hydrate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final state = ref.watch(tasbihProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('التسبيح'),
        actions: <Widget>[
          IconButton(
            onPressed: _confirmReset,
            tooltip: 'تصفير العدّاد',
            icon: const Icon(Icons.restart_alt_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
          child: Column(
            children: <Widget>[
              const SizedBox(height: 8),
              _PhraseSelector(
                selected: state.phrase,
                onSelected: (phrase) =>
                    ref.read(tasbihProvider.notifier).setPhrase(phrase),
              ),
              const SizedBox(height: 10),
              _TargetSelector(
                selected: state.target,
                onSelected: (target) =>
                    ref.read(tasbihProvider.notifier).setTarget(target),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _CounterSurface(state: state, onTap: _tap),
              ),
              const SizedBox(height: 12),
              if (state.isTargetReached)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        Icons.check_circle_rounded,
                        color: tokens.success,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'بلغت العدد المختار',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: tokens.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _tap() async {
    final controller = ref.read(tasbihProvider.notifier);
    final haptics = ref.read(hapticsProvider);

    final reachedTarget = await controller.increment();
    // نطلق الاهتزاز ولا ننتظره — العدّاد يجب أن يستجيب فورًا.
    unawaited(
      reachedTarget ? haptics.tasbihTargetReached() : haptics.tasbihTap(),
    );
  }

  Future<void> _confirmReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('تصفير العدّاد'),
        content: const Text('سيعود العدّاد إلى الصفر. هل تريد المتابعة؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تصفير'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      await ref.read(tasbihProvider.notifier).reset();
    }
  }
}

/// مساحة العدّ الكبيرة — الشاشة كلها تقريبًا قابلة للضغط.
class _CounterSurface extends StatelessWidget {
  const _CounterSurface({required this.state, required this.onTap});

  final TasbihState state;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Semantics(
      button: true,
      label:
          'عدّاد التسبيح، العدد الحالي ${ArabicNumbers.format(state.count)}'
          '${state.hasTarget ? ' من ${ArabicNumbers.format(state.target.value!)}' : ''}',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(26),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (state.phrase != TasbihPhrase.free)
                  Text(
                    state.phrase.label,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge,
                  ),
                const SizedBox(height: 20),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    ArabicNumbers.format(state.count),
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontSize: 84 * tokens.textScale,
                      height: 1.1,
                      color: state.isTargetReached
                          ? tokens.success
                          : theme.colorScheme.primary,
                    ),
                  ),
                ),
                if (state.hasTarget) ...<Widget>[
                  const SizedBox(height: 14),
                  SizedBox(
                    width: 200,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: state.ratio,
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.outlineVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          state.isTargetReached
                              ? tokens.success
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    ArabicNumbers.outOf(state.count, state.target.value!),
                    style: theme.textTheme.labelMedium,
                  ),
                ],
                const SizedBox(height: 20),
                Text(
                  'اضغط في أي مكان للعدّ',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PhraseSelector extends StatelessWidget {
  const _PhraseSelector({required this.selected, required this.onSelected});

  final TasbihPhrase selected;
  final ValueChanged<TasbihPhrase> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: <Widget>[
          for (final phrase in TasbihPhrase.values)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: ChoiceChip(
                label: Text(phrase.label),
                selected: selected == phrase,
                onSelected: (_) => onSelected(phrase),
              ),
            ),
        ],
      ),
    );
  }
}

class _TargetSelector extends StatelessWidget {
  const _TargetSelector({required this.selected, required this.onSelected});

  final TasbihTarget selected;
  final ValueChanged<TasbihTarget> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final target in TasbihTarget.values)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: OutlinedButton(
                onPressed: () => onSelected(target),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  backgroundColor: selected == target
                      ? Theme.of(context).colorScheme.primaryContainer
                      : null,
                ),
                child: Text(target.label, overflow: TextOverflow.ellipsis),
              ),
            ),
          ),
      ],
    );
  }
}
