import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/arabic_numbers.dart';
import '../../core/widgets/app_components.dart';
import 'reading_controller.dart';

/// شاشة "تم وردك" — رسالة قصيرة هادئة بلا وعود مخترعة (المواصفات §33).
class CompletionScreen extends ConsumerWidget {
  const CompletionScreen({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final session = ref.watch(readingControllerProvider(categoryId));
    final reduceMotion = shouldReduceMotion(context, settings);

    return Scaffold(
      appBar: AppBar(title: Text(session.category.name)),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
          child: Column(
            children: <Widget>[
              const Spacer(),
              SoftFadeIn(
                reduceMotion: reduceMotion,
                duration: AppConstants.completionMotion,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: tokens.success.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    size: 62,
                    color: tokens.success,
                  ),
                ),
              ),
              const SizedBox(height: 26),
              Text(
                'تم وردك',
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'تقبّل الله منا ومنكم',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'أكملت ${ArabicNumbers.outOf(session.completedCount, session.total)} من ${session.category.name}',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              PrimaryActionButton(
                label: 'العودة للرئيسية',
                icon: Icons.home_rounded,
                onPressed: () => context.go(AppRoutes.home),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(readingControllerProvider(categoryId).notifier)
                      .goToIndex(0);
                  if (context.mounted) context.pop();
                },
                icon: const Icon(Icons.replay_rounded),
                label: const Text('مراجعة الورد'),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(
                    double.infinity,
                    tokens.primaryButtonHeight - 6,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
