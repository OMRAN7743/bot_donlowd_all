import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../settings/widgets/setting_tiles.dart';
import 'app_info_provider.dart';

/// شاشة "عن ذكري" (المواصفات §44).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('عن ذكري')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          20,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/branding/app_icon.png',
                    width: 108,
                    height: 108,
                    filterQuality: FilterQuality.medium,
                    errorBuilder: (_, _, _) => Container(
                      width: 108,
                      height: 108,
                      color: theme.colorScheme.primaryContainer,
                      alignment: Alignment.center,
                      child: Text(
                        AppConstants.appNameArabic,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  AppConstants.appNameArabic,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'الإصدار ${version.value?.display ?? AppVersionInfo.unknown.display}',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Text(
              'ذكري تطبيق أذكار عربي صُمِّم ليكون بسيطًا ومريحًا ويعمل محليًا '
              'دون الحاجة إلى حساب أو اتصال دائم بالإنترنت.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          SettingSection(
            title: 'المزيد',
            children: <Widget>[
              SettingNavTile(
                title: 'مصادر الأذكار',
                icon: Icons.menu_book_outlined,
                onTap: () => context.push(AppRoutes.sources),
              ),
              SettingNavTile(
                title: 'سياسة الخصوصية',
                icon: Icons.privacy_tip_outlined,
                onTap: () => context.push(AppRoutes.privacy),
              ),
              SettingNavTile(
                title: 'التراخيص',
                subtitle: 'تراخيص المكتبات والخطوط المستخدمة',
                icon: Icons.article_outlined,
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppConstants.appNameArabic,
                  applicationVersion:
                      version.value?.display ?? AppVersionInfo.unknown.display,
                ),
              ),
              SettingNavTile(
                title: 'تواصل مع المطوّر',
                icon: Icons.support_agent_rounded,
                onTap: () => context.push(AppRoutes.contact),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            'نحرص على توثيق نصوص الأذكار ومصادرها. وإذا لاحظت ملاحظة على نص أو '
            'مرجع فتواصل معنا لتصحيحه.',
            style: theme.textTheme.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
