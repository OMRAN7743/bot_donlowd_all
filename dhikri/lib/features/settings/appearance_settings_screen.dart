import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import 'widgets/setting_tiles.dart';

/// إعدادات المظهر: النمط، حجم النص، وضع كبار السن، التباين، الحركة.
class AppearanceSettingsScreen extends ConsumerWidget {
  const AppearanceSettingsScreen({super.key});

  static String _themeLabel(AppThemePreference value) => switch (value) {
    AppThemePreference.system => 'حسب النظام',
    AppThemePreference.light => 'فاتح',
    AppThemePreference.dark => 'داكن',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('المظهر وحجم النص')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          0,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          SettingSection(
            title: 'نمط التطبيق',
            children: <Widget>[
              SettingChoiceTile<AppThemePreference>(
                title: 'النمط',
                options: AppThemePreference.values,
                selected: settings.themePreference,
                labelOf: _themeLabel,
                onSelected: controller.setThemePreference,
              ),
            ],
          ),
          SettingSection(
            title: 'حجم النص',
            footnote: 'يتأثر حجم النص أيضًا بإعداد حجم الخط في نظام جهازك.',
            children: <Widget>[
              SettingChoiceTile<TextScalePreset>(
                title: 'حجم النص',
                options: TextScalePreset.values,
                selected: settings.textScalePreset,
                labelOf: (preset) => preset.label,
                onSelected: controller.setTextScale,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('معاينة', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 8),
                      Text(
                        'هكذا سيظهر نص الذكر في التطبيق.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SettingSection(
            title: 'الراحة وسهولة الوصول',
            children: <Widget>[
              SettingSwitchTile(
                title: 'وضع كبار السن',
                subtitle: 'خط أكبر، أزرار أوضح، ومسافات أوسع',
                icon: Icons.accessibility_new_rounded,
                value: settings.seniorMode,
                onChanged: controller.setSeniorMode,
              ),
              SettingSwitchTile(
                title: 'التباين العالي',
                subtitle: 'ألوان نص أقوى لتسهيل القراءة',
                icon: Icons.contrast_rounded,
                value: settings.highContrast,
                onChanged: controller.setHighContrast,
              ),
              SettingSwitchTile(
                title: 'تقليل الحركة',
                subtitle: 'إيقاف الحركات الانتقالية داخل التطبيق',
                icon: Icons.motion_photos_off_outlined,
                value: settings.reduceMotion,
                onChanged: controller.setReduceMotion,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
