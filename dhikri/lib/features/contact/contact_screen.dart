import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_theme.dart';
import '../../core/constants/developer_contact.dart';
import '../../core/errors/app_exception.dart';
import '../../core/services/contact_service.dart';
import '../about/app_info_provider.dart';

final contactServiceProvider = Provider<ContactService>(
  (ref) => const ContactService(),
);

/// صفحة "تواصل مع المطوّر" (المواصفات §23).
///
/// كل زر يفتح تطبيقًا خارجيًا فقط — لا إرسال تلقائي إطلاقًا.
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);
    final version = ref.watch(appVersionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('تواصل مع المطوّر')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          16,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          Text(
            'لديك اقتراح أو واجهتك مشكلة؟ يمكنك التواصل بالطريقة المناسبة لك',
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),

          _ContactButton(
            icon: Icons.chat_rounded,
            label: 'واتساب',
            description: 'يفتح محادثة جاهزة، وأنت من يضغط إرسال',
            onTap: () => _run(
              context,
              () => ref
                  .read(contactServiceProvider)
                  .openWhatsApp(
                    version:
                        version.value?.display ??
                        AppVersionInfo.unknown.display,
                    platform: currentPlatformLabel(),
                  ),
            ),
          ),
          const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.sms_outlined,
            label: 'رسالة نصية',
            description: 'يفتح تطبيق الرسائل برسالة جاهزة',
            onTap: () =>
                _run(context, () => ref.read(contactServiceProvider).openSms()),
          ),
          const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.call_rounded,
            label: 'اتصال',
            description: 'يفتح تطبيق الهاتف، والاتصال بيدك',
            onTap: () => _run(
              context,
              () => ref.read(contactServiceProvider).openCall(),
            ),
          ),
          const SizedBox(height: 12),
          _ContactButton(
            icon: Icons.bug_report_outlined,
            label: 'الإبلاغ عن مشكلة',
            description: 'يفتح واتساب بنموذج بلاغ جاهز',
            onTap: () => _run(
              context,
              () => ref
                  .read(contactServiceProvider)
                  .openWhatsApp(
                    version:
                        version.value?.display ??
                        AppVersionInfo.unknown.display,
                    platform: currentPlatformLabel(),
                  ),
            ),
          ),

          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(
                      Icons.phone_outlined,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text('رقم المطوّر', style: theme.textTheme.labelMedium),
                  ],
                ),
                const SizedBox(height: 6),
                SelectableText(
                  DeveloperContact.phoneE164,
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  'لا يقرأ التطبيق سجلّ مكالماتك ولا رسائلك، ولا يرسل شيئًا نيابة عنك.',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _run(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action();
    } on AppException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.userMessage)));
    }
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Semantics(
      button: true,
      label: '$label. $description',
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            constraints: BoxConstraints(minHeight: tokens.primaryButtonHeight),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(label, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(description, style: theme.textTheme.labelSmall),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
