import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_components.dart';
import '../../data/models/app_settings.dart';

/// ثلاث شاشات تعريفية قابلة للتخطي، بلا تسجيل دخول وبلا طلب صلاحيات.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const int _pageCount = 3;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(onboardingCompletedProvider.notifier).complete();
    if (mounted) context.go(AppRoutes.home);
  }

  void _next() {
    if (_page >= _pageCount - 1) {
      _finish();
      return;
    }
    _controller.nextPage(
      duration: AppConstants.mediumMotion,
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final isLast = _page == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: tokens.pagePadding),
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('تخطّي'),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (value) => setState(() => _page = value),
                children: const <Widget>[
                  _OnboardingPage(
                    icon: Icons.wifi_off_rounded,
                    title: 'أذكارك معك دائمًا',
                    body:
                        'يعمل التطبيق بدون إنترنت، وبدون حساب، وبدون إعلانات.',
                  ),
                  _OnboardingPage(
                    icon: Icons.headset_mic_outlined,
                    title: 'اقرأ أو استمع',
                    body:
                        'ميزة الصوت اختيارية، وتوفّر العربية يعتمد على '
                        'الصوت المثبَّت في جهازك ما لم توجد تسجيلات محلية.',
                  ),
                  _ComfortPage(),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                tokens.pagePadding,
                8,
                tokens.pagePadding,
                20,
              ),
              child: Column(
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      for (var i = 0; i < _pageCount; i++)
                        AnimatedContainer(
                          duration: AppConstants.shortMotion,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _page ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outlineVariant,
                            borderRadius: BorderRadius.circular(99),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  PrimaryActionButton(
                    label: isLast ? 'ابدأ' : 'التالي',
                    icon: isLast ? Icons.check_rounded : null,
                    onPressed: _next,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.pagePadding + 8,
        vertical: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(height: 20),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 60, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: 34),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 14),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// الشاشة الثالثة: اختيارات راحة سريعة قبل الدخول.
class _ComfortPage extends ConsumerWidget {
  const _ComfortPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: tokens.pagePadding + 8,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'اجعله مريحًا لك',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك تغيير هذه الاختيارات في أي وقت من الإعدادات.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 26),
          Text('حجم الخط', style: theme.textTheme.titleSmall),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final preset in TextScalePreset.values)
                ChoiceChip(
                  label: Text(preset.label),
                  selected: settings.textScalePreset == preset,
                  onSelected: (_) => controller.setTextScale(preset),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Card(
            child: SwitchListTile.adaptive(
              value: settings.seniorMode,
              onChanged: controller.setSeniorMode,
              title: const Text('وضع كبار السن'),
              subtitle: const Text('خط أكبر وأزرار أوضح'),
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: <Widget>[
                Icon(
                  Icons.notifications_none_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'التذكيرات اختيارية، ويمكنك تفعيلها لاحقًا من الإعدادات.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
