import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../adhkar/progress_controller.dart';
import 'widgets/setting_tiles.dart';

/// صفحة الإعدادات الرئيسية — مقسَّمة إلى أقسام واضحة (المواصفات §22).
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    final activeReminders = <String>[
      if (settings.morningReminderEnabled) 'الصباح',
      if (settings.eveningReminderEnabled) 'المساء',
      if (settings.customReminderEnabled) 'إضافي',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('الإعدادات')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          0,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          SettingSection(
            title: 'المظهر',
            children: <Widget>[
              SettingNavTile(
                title: 'المظهر وحجم النص',
                subtitle: 'النمط، حجم الخط، وضع كبار السن، التباين',
                icon: Icons.palette_outlined,
                onTap: () => context.push(AppRoutes.appearanceSettings),
              ),
            ],
          ),

          SettingSection(
            title: 'القراءة',
            children: <Widget>[
              SettingSwitchTile(
                title: 'الانتقال التلقائي بعد إكمال الذكر',
                subtitle: 'ينتقل للذكر التالي بعد لحظة قصيرة',
                icon: Icons.skip_next_rounded,
                value: settings.autoNext,
                onChanged: controller.setAutoNext,
              ),
              SettingSwitchTile(
                title: 'حفظ موضع القراءة',
                subtitle: 'يعود بك إلى حيث توقفت',
                icon: Icons.bookmark_outline_rounded,
                value: settings.saveReadingProgress,
                onChanged: controller.setSaveReadingProgress,
              ),
              SettingSwitchTile(
                title: 'إظهار المصدر',
                subtitle: 'عرض المصدر والمرجع تحت نص الذكر',
                icon: Icons.menu_book_outlined,
                value: settings.showSource,
                onChanged: controller.setShowSource,
              ),
            ],
          ),

          SettingSection(
            title: 'الصوت',
            children: <Widget>[
              SettingNavTile(
                title: 'القراءة الصوتية',
                subtitle: 'التشغيل، السرعة، مدة الترديد، اختيار الصوت',
                icon: Icons.headset_mic_outlined,
                trailingText: settings.audioEnabled ? 'مُفعَّلة' : 'مُطفأة',
                onTap: () => context.push(AppRoutes.audioSettings),
              ),
            ],
          ),

          SettingSection(
            title: 'الاهتزاز',
            footnote:
                'عند إطفاء أي مفتاح هنا لا يهتزّ الجهاز لهذا الحدث إطلاقًا.',
            children: <Widget>[
              SettingSwitchTile(
                title: 'الاهتزاز عند إكمال الذكر',
                icon: Icons.vibration_rounded,
                value: settings.completionHaptics,
                onChanged: controller.setCompletionHaptics,
              ),
              SettingSwitchTile(
                title: 'اهتزاز خفيف عند كل ضغطة',
                value: settings.tapHaptics,
                onChanged: controller.setTapHaptics,
              ),
              SettingSwitchTile(
                title: 'اهتزاز عدّاد التسبيح',
                value: settings.tasbihHaptics,
                onChanged: controller.setTasbihHaptics,
              ),
            ],
          ),

          SettingSection(
            title: 'التذكيرات',
            children: <Widget>[
              SettingNavTile(
                title: 'تذكيرات الأذكار',
                subtitle: 'تذكيرات محلية على جهازك فقط',
                icon: Icons.notifications_none_rounded,
                trailingText: activeReminders.isEmpty
                    ? 'مُطفأة'
                    : activeReminders.join('، '),
                onTap: () => context.push(AppRoutes.remindersSettings),
              ),
            ],
          ),

          SettingSection(
            title: 'البيانات والخصوصية',
            children: <Widget>[
              SettingNavTile(
                title: 'سياسة الخصوصية',
                icon: Icons.privacy_tip_outlined,
                onTap: () => context.push(AppRoutes.privacy),
              ),
              SettingNavTile(
                title: 'إعادة تعيين تقدُّم القراءة',
                icon: Icons.restart_alt_rounded,
                isDestructive: true,
                onTap: () => _confirm(
                  context,
                  title: 'إعادة تعيين تقدُّم القراءة',
                  message: 'سيُحذف موضع القراءة المحفوظ وسجلّ المداومة. لن تتأثر المفضلة ولا الإعدادات.',
                  confirmLabel: 'إعادة تعيين',
                  onConfirm: () =>
                      ref.read(progressProvider.notifier).resetAll(),
                ),
              ),
              SettingNavTile(
                title: 'حذف المفضلة',
                icon: Icons.heart_broken_outlined,
                isDestructive: true,
                onTap: () => _confirm(
                  context,
                  title: 'حذف المفضلة',
                  message: 'سيتم حذف كل الأذكار المحفوظة في المفضلة.',
                  confirmLabel: 'حذف',
                  onConfirm: () =>
                      ref.read(favoritesProvider.notifier).clearAll(),
                ),
              ),
              SettingNavTile(
                title: 'إعادة جميع الإعدادات للوضع الافتراضي',
                icon: Icons.settings_backup_restore_rounded,
                isDestructive: true,
                onTap: () => _confirm(
                  context,
                  title: 'إعادة الإعدادات',
                  message: 'ستعود كل الإعدادات والتذكيرات إلى وضعها الافتراضي. لن تتأثر المفضلة ولا تقدُّم القراءة.',
                  confirmLabel: 'إعادة',
                  onConfirm: () async {
                    await controller.resetToDefaults();
                    await NotificationService.instance.cancelAll();
                  },
                ),
              ),
            ],
          ),

          SettingSection(
            title: 'عن التطبيق',
            children: <Widget>[
              SettingNavTile(
                title: 'عن ذكري',
                icon: Icons.info_outline_rounded,
                onTap: () => context.push(AppRoutes.about),
              ),
              SettingNavTile(
                title: 'تواصل مع المطوّر',
                icon: Icons.support_agent_rounded,
                onTap: () => context.push(AppRoutes.contact),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required Future<void> Function() onConfirm,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );

    if (confirmed ?? false) {
      await onConfirm();
      messenger.showSnackBar(const SnackBar(content: Text('تم بنجاح')));
    }
  }
}
