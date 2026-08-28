import 'package:flutter/material.dart';

import '../../app/theme/app_theme.dart';

/// سياسة الخصوصية — صفحة محلية داخل التطبيق، بلا أي اتصال بالإنترنت.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  static const List<({IconData icon, String title, String body})>
  _points = <({IconData icon, String title, String body})>[
    (
      icon: Icons.person_off_outlined,
      title: 'لا يوجد حساب',
      body: 'لا يطلب التطبيق تسجيل دخول ولا بريدًا ولا رقم هاتف.',
    ),
    (
      icon: Icons.block_rounded,
      title: 'لا نجمع بيانات شخصية',
      body:
          'لا يجمع التطبيق اسمك ولا موقعك ولا جهات اتصالك ولا أي معرّف لجهازك.',
    ),
    (
      icon: Icons.analytics_outlined,
      title: 'لا توجد تحليلات ولا تتبّع',
      body: 'لا توجد أدوات تحليل أو تتبّع أو إعلانات داخل التطبيق.',
    ),
    (
      icon: Icons.phone_android_rounded,
      title: 'تقدُّمك محفوظ على جهازك',
      body:
          'المفضلة وموضع القراءة والإعدادات كلها مخزَّنة محليًا فقط، '
          'وتُحذف بحذف التطبيق.',
    ),
    (
      icon: Icons.notifications_none_rounded,
      title: 'التذكيرات محلية',
      body: 'تُجدول التذكيرات على جهازك، بلا خادم ولا رسائل سحابية.',
    ),
    (
      icon: Icons.open_in_new_rounded,
      title: 'التطبيقات الخارجية',
      body:
          'عند فتح واتساب أو الرسائل أو الهاتف تنتقل إلى تطبيق خارجي، '
          'ويسري عليك حينها نظام ذلك التطبيق. ولا يرسل ذكري أي شيء نيابة عنك.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = DhikriTokens.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('سياسة الخصوصية')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          tokens.pagePadding,
          16,
          tokens.pagePadding,
          32,
        ),
        children: <Widget>[
          Text(
            'تطبيق ذكري صُمِّم ليعمل محليًا على جهازك.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          for (final point in _points) ...<Widget>[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(point.icon, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(point.title, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(point.body, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
