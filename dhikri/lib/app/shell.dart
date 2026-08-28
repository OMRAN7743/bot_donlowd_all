import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// الهيكل الرئيسي: شريط سفلي من أربعة أقسام فقط (المواصفات §8).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const List<_ShellTab> _tabs = <_ShellTab>[
    _ShellTab('الرئيسية', Icons.home_outlined, Icons.home_rounded),
    _ShellTab(
      'المفضلة',
      Icons.favorite_outline_rounded,
      Icons.favorite_rounded,
    ),
    _ShellTab('التسبيح', Icons.radio_button_unchecked, Icons.adjust_rounded),
    _ShellTab('الإعدادات', Icons.settings_outlined, Icons.settings_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // الضغط على القسم الحالي يعيده إلى جذره.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: <Widget>[
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selectedIcon),
              label: tab.label,
              tooltip: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
