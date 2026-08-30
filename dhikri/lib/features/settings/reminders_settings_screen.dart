import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/providers.dart';
import '../../app/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../data/models/app_settings.dart';
import 'widgets/setting_tiles.dart';

/// إعدادات التذكيرات المحلية (المواصفات §21).
///
/// لا نطلب صلاحية الإشعارات إلا عند تفعيل المستخدم لتذكير فعلي.
class RemindersSettingsScreen extends ConsumerStatefulWidget {
  const RemindersSettingsScreen({super.key});

  @override
  ConsumerState<RemindersSettingsScreen> createState() =>
      _RemindersSettingsScreenState();
}

class _RemindersSettingsScreenState
    extends ConsumerState<RemindersSettingsScreen> {
  bool _permissionDenied = false;

  /// حالة صلاحية الإشعارات على مستوى النظام، تُقرأ عند فتح الصفحة.
  bool? _systemNotificationsEnabled;

  NotificationService get _notifications => NotificationService.instance;

  @override
  void initState() {
    super.initState();
    _refreshSystemPermission();
  }

  Future<void> _refreshSystemPermission() async {
    final enabled = await _notifications.areNotificationsEnabled();
    if (mounted) setState(() => _systemNotificationsEnabled = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تذكيرات الأذكار')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          0,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(
                  Icons.phonelink_lock_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'كل التذكيرات محلية على جهازك. لا يوجد خادم، ولا تُرسل أي بيانات.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),

          // نعرض التنبيه عند رفض صريح، أو عندما يكون للمستخدم تذكير مفعَّل
          // بينما الإشعارات مُطفأة من إعدادات النظام.
          if (_permissionDenied ||
              (_systemNotificationsEnabled == false && settings.hasAnyReminder))
            _PermissionDeniedNotice(onOpenSettings: _openSystemSettings),

          SettingSection(
            title: 'المواعيد',
            children: <Widget>[
              _ReminderTile(
                title: 'أذكار الصباح',
                icon: Icons.wb_twilight_rounded,
                enabled: settings.morningReminderEnabled,
                time: settings.morningReminderTime,
                onToggle: (value) => _toggle(
                  value,
                  ReminderKind.morning,
                  (v) => ref
                      .read(settingsProvider.notifier)
                      .setMorningReminder(enabled: v),
                  settings.morningReminderTime,
                ),
                onPickTime: () => _pickTime(settings.morningReminderTime, (
                  time,
                ) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setMorningReminder(time: time);
                  if (settings.morningReminderEnabled) {
                    await _notifications.schedule(ReminderKind.morning, time);
                  }
                }),
              ),
              _ReminderTile(
                title: 'أذكار المساء',
                icon: Icons.nights_stay_outlined,
                enabled: settings.eveningReminderEnabled,
                time: settings.eveningReminderTime,
                onToggle: (value) => _toggle(
                  value,
                  ReminderKind.evening,
                  (v) => ref
                      .read(settingsProvider.notifier)
                      .setEveningReminder(enabled: v),
                  settings.eveningReminderTime,
                ),
                onPickTime: () => _pickTime(settings.eveningReminderTime, (
                  time,
                ) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setEveningReminder(time: time);
                  if (settings.eveningReminderEnabled) {
                    await _notifications.schedule(ReminderKind.evening, time);
                  }
                }),
              ),
              _ReminderTile(
                title: 'تذكير إضافي',
                icon: Icons.alarm_add_outlined,
                enabled: settings.customReminderEnabled,
                time: settings.customReminderTime,
                onToggle: (value) => _toggle(
                  value,
                  ReminderKind.custom,
                  (v) => ref
                      .read(settingsProvider.notifier)
                      .setCustomReminder(enabled: v),
                  settings.customReminderTime,
                ),
                onPickTime: () => _pickTime(settings.customReminderTime, (
                  time,
                ) async {
                  await ref
                      .read(settingsProvider.notifier)
                      .setCustomReminder(time: time);
                  if (settings.customReminderEnabled) {
                    await _notifications.schedule(ReminderKind.custom, time);
                  }
                }),
              ),
            ],
          ),

          SettingSection(
            title: 'صلاحية الإشعارات',
            children: <Widget>[
              SettingNavTile(
                title: 'إدارة صلاحية الإشعارات',
                subtitle: 'يفتح إعدادات الإشعارات في نظام جهازك',
                icon: Icons.open_in_new_rounded,
                onTap: _openSystemSettings,
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// يطلب الصلاحية عند التفعيل فقط، ويعكس المفتاح إن رُفضت.
  Future<void> _toggle(
    bool value,
    ReminderKind kind,
    Future<void> Function(bool) persist,
    ReminderTime time,
  ) async {
    if (!value) {
      await persist(false);
      await _notifications.cancel(kind);
      setState(() => _permissionDenied = false);
      return;
    }

    final result = await _notifications.requestPermission();
    if (result == ReminderPermissionResult.denied) {
      setState(() => _permissionDenied = true);
      await persist(false);
      return;
    }

    setState(() => _permissionDenied = false);
    await persist(true);
    await _notifications.schedule(kind, time);
    await _refreshSystemPermission();
  }

  Future<void> _pickTime(
    ReminderTime current,
    Future<void> Function(ReminderTime) onPicked,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current.asTimeOfDay,
      helpText: 'اختر وقت التذكير',
    );
    if (picked == null) return;
    await onPicked(ReminderTime(picked.hour, picked.minute));
  }

  Future<void> _openSystemSettings() async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('app-settings:');
    try {
      final opened = await launchUrl(uri);
      if (!opened) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text(
              'افتح إعدادات جهازك ثم الإشعارات لتفعيلها لتطبيق ذكري',
            ),
          ),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('افتح إعدادات جهازك ثم الإشعارات لتفعيلها لتطبيق ذكري'),
        ),
      );
    }
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.title,
    required this.icon,
    required this.enabled,
    required this.time,
    required this.onToggle,
    required this.onPickTime,
  });

  final String title;
  final IconData icon;
  final bool enabled;
  final ReminderTime time;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: <Widget>[
        SwitchListTile.adaptive(
          value: enabled,
          onChanged: onToggle,
          secondary: Icon(icon),
          title: Text(title),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: <Widget>[
              Text('الوقت', style: theme.textTheme.labelMedium),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: onPickTime,
                icon: const Icon(Icons.schedule_rounded, size: 20),
                label: Text(time.label),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PermissionDeniedNotice extends StatelessWidget {
  const _PermissionDeniedNotice({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'لم تُمنح صلاحية الإشعارات',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'لتصلك التذكيرات، فعّل الإشعارات لتطبيق ذكري من إعدادات جهازك.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 10),
          FilledButton.tonal(
            onPressed: onOpenSettings,
            child: const Text('فتح إعدادات الإشعارات'),
          ),
        ],
      ),
    );
  }
}
