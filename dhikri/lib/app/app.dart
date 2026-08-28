import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import 'providers.dart';
import 'router.dart';
import 'theme/app_theme.dart';

/// جذر تطبيق "ذكري".
///
/// الواجهة عربية RTL من الجذر، والثيم يتبع إعدادات المستخدم مباشرة.
class DhikriApp extends ConsumerWidget {
  const DhikriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(routerProvider);
    final scale = settings.effectiveTextScale;

    return MaterialApp.router(
      title: AppConstants.appNameArabic,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      locale: const Locale('ar'),
      supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.materialThemeMode,
      theme: AppTheme.light(
        textScale: scale,
        highContrast: settings.highContrast,
        seniorMode: settings.seniorMode,
      ),
      darkTheme: AppTheme.dark(
        textScale: scale,
        highContrast: settings.highContrast,
        seniorMode: settings.seniorMode,
      ),
      builder: (context, child) {
        // نُبقي تكبير خط النظام كما هو — الشاشات مبنية لتتحمّله.
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
